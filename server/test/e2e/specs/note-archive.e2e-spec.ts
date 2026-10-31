import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import {
  Actor,
  createE2EApp,
  E2EApp,
  entryFor,
  ExportManifestOnWire,
  SharePermission,
  TagOnWire,
} from '../support';

/**
 * Archive belongs to the person, not the note: everyone who can see a note
 * archives it for themselves, and nobody else's lists change.
 */
describe('note archive', () => {
  let ctx: E2EApp;
  let owner: Actor;
  let sharee: Actor;

  beforeAll(async () => {
    ctx = await createE2EApp();
  });

  afterAll(async () => {
    await ctx.close();
  });

  beforeEach(async () => {
    await ctx.resetDb();
    owner = await ctx.registerUser('Owner');
    sharee = await ctx.registerUser('Sharee');
  });

  const sharedNote = async (permission: SharePermission = 'viewer') => {
    const note = await owner.notes.create({ title: 'shared note' });
    const share = await owner.shares.grant(note.id, sharee.id, permission);
    return { note, share };
  };

  const ids = (notes: { id: string }[]) => notes.map((n) => n.id);

  it('a sharee archives a shared note for themselves only', async () => {
    const { note } = await sharedNote();

    expect(await sharee.notes.bulkArchive([note.id])).toEqual({ count: 1 });

    expect(ids(await sharee.notes.list())).toEqual([]);
    const [archived] = await sharee.notes.listArchived();
    expect(archived).toMatchObject({
      id: note.id,
      isArchived: true,
      permission: 'viewer',
      sharedBy: { id: owner.id },
    });

    expect(ids(await owner.notes.list())).toEqual([note.id]);
    expect(await owner.notes.listArchived()).toEqual([]);
    expect((await owner.notes.read(note.id)).isArchived).toBe(false);
  });

  it("the owner's archive leaves the sharee's lists alone", async () => {
    const { note } = await sharedNote();

    await owner.notes.update(note.id, { isArchived: true });

    expect(ids(await owner.notes.listArchived())).toEqual([note.id]);
    expect(ids(await sharee.notes.list())).toEqual([note.id]);
    expect(await sharee.notes.listArchived()).toEqual([]);
  });

  it('a viewer archives and unarchives from the note but still cannot edit it', async () => {
    const { note } = await sharedNote('viewer');

    const archived = await sharee.notes.update(note.id, { isArchived: true });
    expect(archived).toMatchObject({ isArchived: true, permission: 'viewer' });

    const back = await sharee.notes.update(note.id, { isArchived: false });
    expect(back.isArchived).toBe(false);
    expect(ids(await sharee.notes.list())).toEqual([note.id]);

    await sharee.http
      .patch(`/api/notes/${note.id}`)
      .send({ title: 'viewer edit', isArchived: true })
      .expect(403);
    expect((await sharee.notes.read(note.id)).isArchived).toBe(false);
  });

  it("archiving leaves the note's version and edit time alone", async () => {
    const { note } = await sharedNote('editor');

    await sharee.notes.update(note.id, { isArchived: true });
    await owner.notes.update(note.id, { isArchived: true });

    const row = await ctx.prisma.note.findUniqueOrThrow({
      where: { id: note.id },
    });
    expect(row.version).toBe(note.version);
    expect(row.updatedAt.toISOString()).toBe(note.updatedAt);
  });

  it("an owner's phone archive leaves the version, edit time and sharees alone", async () => {
    const { note } = await sharedNote();
    const shareeFeed = await sharee.sync.drain();

    const res = await owner.sync.push([
      {
        type: 'note',
        id: note.id,
        title: note.title,
        content: note.content ?? undefined,
        baseVersion: note.version,
        isArchived: true,
      },
    ]);

    expect(res.results).toEqual([
      { type: 'note', id: note.id, status: 'applied', version: note.version },
    ]);
    const row = await ctx.prisma.note.findUniqueOrThrow({
      where: { id: note.id },
    });
    expect(row.updatedAt.toISOString()).toBe(note.updatedAt);
    const shareeDelta = await sharee.sync.drain({ cursor: shareeFeed.cursor });
    expect(shareeDelta.entries).toEqual([]);
  });

  it('a save that only pins leaves the edit time alone', async () => {
    const note = await owner.notes.create({ title: 'pin me', content: 'x' });

    await owner.notes.update(note.id, {
      title: note.title,
      content: note.content,
      isPinned: true,
      baseVersion: note.version,
    });

    const row = await ctx.prisma.note.findUniqueOrThrow({
      where: { id: note.id },
    });
    expect(row.version).toBe(note.version);
    expect(row.updatedAt.toISOString()).toBe(note.updatedAt);
  });

  it("a viewer's out-of-date push adds no copy of old text to the history", async () => {
    const { note } = await sharedNote('viewer');
    await owner.notes.update(note.id, { title: 'newer' });

    await sharee.sync.push([
      {
        type: 'note',
        id: note.id,
        title: note.title,
        baseVersion: note.version,
        isArchived: true,
      },
    ]);

    const revisions = await ctx.prisma.noteRevision.findMany({
      where: { noteId: note.id },
    });
    expect(revisions.map((r) => [r.title, r.cause])).toEqual([
      [note.title, 'edit'],
    ]);
    expect(ids(await sharee.notes.listArchived())).toEqual([note.id]);
  });

  it("reaches only the archiver's own feed", async () => {
    const { note } = await sharedNote();
    const ownerFeed = await owner.sync.drain();
    const shareeFeed = await sharee.sync.drain();

    await sharee.notes.bulkArchive([note.id]);

    const shareeDelta = await sharee.sync.drain({ cursor: shareeFeed.cursor });
    expect(entryFor(shareeDelta.entries, 'note', note.id).note).toMatchObject({
      isArchived: true,
      version: note.version,
    });

    const ownerDelta = await owner.sync.drain({ cursor: ownerFeed.cursor });
    expect(ownerDelta.entries).toEqual([]);
  });

  it("a viewer's phone push archives the note for them", async () => {
    const { note } = await sharedNote('viewer');

    const res = await sharee.sync.push([
      {
        type: 'note',
        id: note.id,
        title: note.title,
        baseVersion: note.version,
        isArchived: true,
      },
    ]);

    expect(res.results).toEqual([
      { type: 'note', id: note.id, status: 'applied', version: note.version },
    ]);
    expect(ids(await sharee.notes.listArchived())).toEqual([note.id]);
    expect(ids(await owner.notes.list())).toEqual([note.id]);
  });

  it("an editor's content push carries their own archive, not the owner's", async () => {
    const { note } = await sharedNote('editor');
    await owner.notes.update(note.id, { isArchived: true });

    const res = await sharee.sync.push([
      {
        type: 'note',
        id: note.id,
        title: 'edited by sharee',
        baseVersion: note.version,
        isArchived: false,
      },
    ]);

    expect(res.results[0]).toMatchObject({ status: 'applied' });
    expect(ids(await owner.notes.listArchived())).toEqual([note.id]);
    expect(ids(await sharee.notes.list())).toEqual([note.id]);
  });

  it('revoke clears the sharee archive, so a re-share starts fresh', async () => {
    const { note, share } = await sharedNote();
    await sharee.notes.bulkArchive([note.id]);

    await owner.shares.revoke(note.id, share.id);
    const row = await ctx.prisma.noteArchive.findUnique({
      where: { userId_noteId: { userId: sharee.id, noteId: note.id } },
    });
    expect(row).toBeNull();

    await owner.shares.grant(note.id, sharee.id, 'viewer');
    expect(ids(await sharee.notes.list())).toEqual([note.id]);
  });

  it('tag counts keep archived notes, for whoever archived them', async () => {
    const { note } = await sharedNote('editor');
    const ownerTag = await owner.tags.create({ name: 'owner-tag' });
    const shareeTag = await sharee.tags.create({ name: 'sharee-tag' });
    await owner.notes.update(note.id, { tagIds: [ownerTag.id] });
    await sharee.notes.update(note.id, { tagIds: [shareeTag.id] });

    await sharee.notes.bulkArchive([note.id]);

    const countOf = async (actor: Actor) => {
      const res = await actor.http.get('/api/tags').expect(200);
      return (res.body as TagOnWire[])[0]._count?.notes;
    };
    expect(await countOf(sharee)).toBe(1);
    expect(await countOf(owner)).toBe(1);

    await owner.notes.trash(note.id);
    expect(await countOf(sharee)).toBe(0);
    expect(await countOf(owner)).toBe(0);
  });

  it("an export carries the exporter's own archive", async () => {
    const { note } = await sharedNote();
    await sharee.notes.bulkArchive([note.id]);

    const manifestOf = async (actor: Actor) =>
      (await actor.export.download()).zip.json<ExportManifestOnWire>(
        'manifest.json',
      );

    expect((await manifestOf(sharee)).notes[0]).toMatchObject({
      origin: 'shared',
      isArchived: true,
    });
    expect((await manifestOf(owner)).notes[0]).toMatchObject({
      origin: 'owned',
      isArchived: false,
    });
  });
});
