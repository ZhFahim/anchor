import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import { Actor, createE2EApp, E2EApp, entryFor } from '../support';

/**
 * Drag and drop order: every person keeps their own order of notes and tags.
 * A place is a fractional key the client makes; it never bumps a version.
 */
describe('positions', () => {
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

  describe('notes', () => {
    it('places notes without touching version or updatedAt', async () => {
      const a = await owner.notes.create({ title: 'a' });
      const b = await owner.notes.create({ title: 'b' });
      expect(a.position).toBeNull();

      const result = await owner.notes.setPositions([
        { noteId: a.id, position: 'a1' },
        { noteId: b.id, position: 'a0' },
      ]);
      expect(result.updated.sort()).toEqual([a.id, b.id].sort());

      const placed = await owner.notes.read(a.id);
      expect(placed).toMatchObject({
        position: 'a1',
        version: a.version,
        updatedAt: a.updatedAt,
      });
      const list = await owner.notes.list();
      expect(list.find((n) => n.id === b.id)?.position).toBe('a0');
    });

    it('reports only the notes whose place changed', async () => {
      const note = await owner.notes.create({ title: 'n' });
      await owner.notes.setPositions([{ noteId: note.id, position: 'a0' }]);

      const again = await owner.notes.setPositions([
        { noteId: note.id, position: 'a0' },
      ]);
      expect(again.updated).toEqual([]);
    });

    it('null takes a note out of the order', async () => {
      const note = await owner.notes.create({ title: 'n' });
      await owner.notes.setPositions([{ noteId: note.id, position: 'a0' }]);

      await owner.notes.setPositions([{ noteId: note.id, position: null }]);
      expect((await owner.notes.read(note.id)).position).toBeNull();
    });

    it('keeps the order through edits, pins and the editor save response', async () => {
      const note = await owner.notes.create({ title: 'n' });
      await owner.notes.setPositions([{ noteId: note.id, position: 'Zz' }]);

      const saved = await owner.notes.update(note.id, {
        title: 'edited',
        baseVersion: note.version,
      });
      expect(saved.position).toBe('Zz');
      await owner.notes.bulkPin([note.id], true);
      expect((await owner.notes.read(note.id)).position).toBe('Zz');
    });

    it("a sharee's order is their own, and goes when the share ends", async () => {
      const note = await owner.notes.create({ title: 'shared' });
      const share = await owner.shares.grant(note.id, sharee.id, 'viewer');

      await sharee.notes.setPositions([{ noteId: note.id, position: 'a5' }]);
      expect((await sharee.notes.read(note.id)).position).toBe('a5');
      expect((await owner.notes.read(note.id)).position).toBeNull();

      await owner.notes.setPositions([{ noteId: note.id, position: 'a0' }]);
      expect((await sharee.notes.read(note.id)).position).toBe('a5');

      await owner.shares.revoke(note.id, share.id);
      await owner.shares.grant(note.id, sharee.id, 'viewer');
      expect((await sharee.notes.read(note.id)).position).toBeNull();
    });

    it('skips notes the caller cannot see', async () => {
      const hidden = await owner.notes.create({ title: 'private' });

      const result = await sharee.notes.setPositions([
        { noteId: hidden.id, position: 'a0' },
      ]);
      expect(result.updated).toEqual([]);
      expect(
        await ctx.prisma.notePosition.count({ where: { noteId: hidden.id } }),
      ).toBe(0);
    });

    it('rejects keys that are not fractional indexes', async () => {
      const note = await owner.notes.create({ title: 'n' });
      for (const position of ['', 'a b', 'ä0', 'x'.repeat(129)])
        await owner.http
          .put('/api/notes/positions')
          .send({ positions: [{ noteId: note.id, position }] })
          .expect(400);
    });

    it("sync tells only the mover's devices, with the place in the note", async () => {
      const note = await owner.notes.create({ title: 'shared' });
      await owner.shares.grant(note.id, sharee.id, 'editor');
      const ownerStart = await owner.sync.drain();
      const shareeStart = await sharee.sync.drain();

      await owner.notes.setPositions([{ noteId: note.id, position: 'a3' }]);

      const ownerDelta = await owner.sync.drain({ cursor: ownerStart.cursor });
      expect(entryFor(ownerDelta.entries, 'note', note.id).note).toMatchObject({
        position: 'a3',
        version: note.version,
      });
      const shareeDelta = await sharee.sync.drain({
        cursor: shareeStart.cursor,
      });
      expect(shareeDelta.entries).toEqual([]);
    });
  });

  describe('tags', () => {
    it('places tags without bumping their version', async () => {
      const work = await owner.tags.create({ name: 'Work' });
      const ideas = await owner.tags.create({ name: 'Ideas' });

      await owner.tags.setPositions([
        { id: work.id, position: 'a0' },
        { id: ideas.id, position: 'a1' },
      ]);

      const tags = await owner.tags.list();
      expect(tags.find((t) => t.id === work.id)).toMatchObject({
        position: 'a0',
        version: 1,
        updatedAt: work.updatedAt,
      });
      expect(tags.find((t) => t.id === ideas.id)?.position).toBe('a1');
    });

    it('a rename from an old client still applies after a reorder', async () => {
      const tag = await owner.tags.create({ name: 'Work' });
      await owner.tags.setPositions([{ id: tag.id, position: 'a0' }]);

      const response = await owner.sync.push([
        { type: 'tag', id: tag.id, baseVersion: 1, name: 'Jobs' },
      ]);
      expect(response.results[0]).toMatchObject({ status: 'applied' });
      const [renamed] = await owner.tags.list();
      expect(renamed).toMatchObject({ name: 'Jobs', position: 'a0' });
    });

    it("leaves other people's tags alone", async () => {
      const tag = await owner.tags.create({ name: 'Work' });

      const result = await sharee.tags.setPositions([
        { id: tag.id, position: 'a0' },
      ]);
      expect(result.updated).toEqual([]);
      const [mine] = await owner.tags.list();
      expect(mine.position).toBeNull();
    });

    it('sync carries the place in the tag payload', async () => {
      const tag = await owner.tags.create({ name: 'Work' });
      const start = await owner.sync.drain();

      await owner.tags.setPositions([{ id: tag.id, position: 'a7' }]);

      const delta = await owner.sync.drain({ cursor: start.cursor });
      expect(entryFor(delta.entries, 'tag', tag.id).tag).toMatchObject({
        position: 'a7',
        version: 1,
      });
    });
  });
});
