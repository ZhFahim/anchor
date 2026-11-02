import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import { Actor, createE2EApp, E2EApp, entryFor } from '../support';

const PDF = Buffer.from('%PDF-1.4\n%%EOF\n');

/**
 * Files other than pictures and recordings are NoteFile rows, so upstream
 * Anchor's server, which knows only those two attachment types, can run on
 * this database. To the apps they're attachments of type "file", in one
 * order with the others.
 */
describe('attached files', () => {
  let ctx: E2EApp;
  let owner: Actor;

  beforeAll(async () => {
    ctx = await createE2EApp();
  });

  afterAll(async () => {
    await ctx.close();
  });

  beforeEach(async () => {
    await ctx.resetDb();
    owner = await ctx.registerUser('Owner');
  });

  const uploadPdf = (noteId: string) =>
    owner.attachments.upload(noteId, 'deed.pdf', PDF, 'application/pdf');

  it('keeps files out of NoteAttachment, among the pictures in order', async () => {
    const note = await owner.notes.create({ title: 'papers' });
    const picture = await owner.attachments.upload(note.id);
    const file = await uploadPdf(note.id);
    expect(file).toMatchObject({ type: 'file', mimeType: 'application/pdf' });

    // The newest comes first, files and pictures alike.
    expect(
      (await owner.attachments.list(note.id)).map((a) => [a.id, a.type]),
    ).toEqual([
      [file.id, 'file'],
      [picture.id, 'image'],
    ]);
    expect((await owner.notes.read(note.id)).attachmentCount).toBe(2);

    const types = await ctx.prisma.$queryRaw<{ type: string }[]>`
      SELECT DISTINCT type::text FROM "NoteAttachment"`;
    expect(types).toEqual([{ type: 'image' }]);
    expect(await ctx.prisma.noteFile.count()).toBe(1);

    const { entries } = await owner.sync.drain();
    expect(
      entryFor(entries, 'attachments', note.id).attachments?.map((a) => a.id),
    ).toEqual([file.id, picture.id]);
  });

  it('serves a file to download, reorders, copies and deletes it', async () => {
    const note = await owner.notes.create({ title: 'papers' });
    const picture = await owner.attachments.upload(note.id);
    const file = await uploadPdf(note.id);

    const served = await owner.http
      .get(`/api/notes/${note.id}/attachments/${file.id}`)
      .expect(200);
    expect(served.headers['content-type']).toBe('application/octet-stream');
    expect(served.headers['content-disposition']).toMatch(/^attachment/);

    await owner.http
      .patch(`/api/notes/${note.id}/attachments/reorder`)
      .send({ orderedIds: [picture.id, file.id] })
      .expect(200);
    expect((await owner.attachments.list(note.id)).map((a) => a.id)).toEqual([
      picture.id,
      file.id,
    ]);

    const copy = await owner.http
      .post(`/api/notes/${note.id}/copy`)
      .expect(201);
    const copied = await owner.attachments.list(
      (copy.body as { id: string }).id,
    );
    expect(copied.map((a) => a.type)).toEqual(['image', 'file']);

    await owner.http
      .delete(`/api/notes/${note.id}/attachments/${file.id}`)
      .expect(200);
    expect((await owner.attachments.list(note.id)).map((a) => a.id)).toEqual([
      picture.id,
    ]);
  });
});
