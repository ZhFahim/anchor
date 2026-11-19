import request from 'supertest';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import {
  Actor,
  bodyOf,
  createE2EApp,
  E2EApp,
  PNG_1PX,
  PublicNoteOnWire,
} from '../support';

/**
 * A note's public link: what the owner controls, and what anyone holding the
 * link can read without signing in.
 */
describe('note links', () => {
  let ctx: E2EApp;
  let owner: Actor;
  let other: Actor;

  beforeAll(async () => {
    ctx = await createE2EApp();
  });

  afterAll(async () => {
    await ctx.close();
  });

  beforeEach(async () => {
    await ctx.resetDb();
    owner = await ctx.registerUser('Owner');
    other = await ctx.registerUser('Other');
  });

  // No Authorization header: a stranger with the link.
  const anonymous = () => request(ctx.http);

  it('serves the note to anyone with the link', async () => {
    const note = await owner.notes.create({
      title: 'Trip',
      content: '{"ops":[{"insert":"Pack light\\n"}]}',
      background: 'color_blue',
    });
    const link = await owner.links.create(note.id);

    const res = await anonymous()
      .get(`/api/public/notes/${link.token}`)
      .expect(200);

    expect(bodyOf<PublicNoteOnWire>(res)).toMatchObject({
      title: 'Trip',
      content: '{"ops":[{"insert":"Pack light\\n"}]}',
      background: 'color_blue',
      attachments: [],
    });
    expect(res.headers['cache-control']).toBe('no-store');
  });

  it('gives nothing about the owner away', async () => {
    const note = await owner.notes.create({ title: 'Trip' });
    const link = await owner.links.create(note.id);

    const res = await anonymous()
      .get(`/api/public/notes/${link.token}`)
      .expect(200);

    expect(res.text).not.toContain(owner.id);
    expect(res.text).not.toContain(owner.email);
    expect(res.text).not.toContain(note.id);
  });

  it('hands out one link per note', async () => {
    const note = await owner.notes.create({ title: 'Trip' });
    const first = await owner.links.create(note.id);
    const second = await owner.links.create(note.id);

    expect(second.token).toBe(first.token);
    expect(first.token).toMatch(/^[A-Za-z0-9_-]{32}$/);
    expect(await owner.links.get(note.id)).toEqual(first);
  });

  it('stops working once turned off, and a new link is a new token', async () => {
    const note = await owner.notes.create({ title: 'Trip' });
    const old = await owner.links.create(note.id);

    await owner.links.remove(note.id);
    expect(await owner.links.get(note.id)).toBeNull();
    await anonymous().get(`/api/public/notes/${old.token}`).expect(404);

    const fresh = await owner.links.create(note.id);
    expect(fresh.token).not.toBe(old.token);
  });

  it('hides a trashed note until it is restored', async () => {
    const note = await owner.notes.create({ title: 'Trip' });
    const link = await owner.links.create(note.id);

    await owner.notes.trash(note.id);
    await anonymous().get(`/api/public/notes/${link.token}`).expect(404);

    await owner.notes.restore(note.id);
    await anonymous().get(`/api/public/notes/${link.token}`).expect(200);
  });

  it('goes with the note when it is deleted for good', async () => {
    const note = await owner.notes.create({ title: 'Trip' });
    const link = await owner.links.create(note.id);

    await owner.notes.trash(note.id);
    await owner.notes.purge(note.id);

    await anonymous().get(`/api/public/notes/${link.token}`).expect(404);
  });

  it('answers 404 for a token that never existed', async () => {
    await anonymous().get('/api/public/notes/not-a-real-token').expect(404);
  });

  it('serves the note’s attachments, and only them', async () => {
    const note = await owner.notes.create({ title: 'Trip' });
    const picture = await owner.attachments.upload(note.id);
    const elsewhere = await owner.notes.create({ title: 'Private' });
    const hidden = await owner.attachments.upload(elsewhere.id);
    const link = await owner.links.create(note.id);

    const res = await anonymous()
      .get(`/api/public/notes/${link.token}`)
      .expect(200);
    expect(bodyOf<PublicNoteOnWire>(res).attachments).toEqual([
      {
        id: picture.id,
        type: 'image',
        mimeType: 'image/png',
        originalFilename: 'pixel.png',
      },
    ]);

    const file = await anonymous()
      .get(`/api/public/notes/${link.token}/attachments/${picture.id}`)
      .expect(200);
    expect(file.headers['content-type']).toBe('image/png');
    expect(Buffer.compare(file.body as Buffer, PNG_1PX)).toBe(0);

    await anonymous()
      .get(`/api/public/notes/${link.token}/attachments/${hidden.id}`)
      .expect(404);
  });

  it('lets only the owner see or change the link', async () => {
    const note = await owner.notes.create({ title: 'Trip' });
    await owner.shares.grant(note.id, other.id, 'editor');

    await other.http.get(`/api/notes/${note.id}/link`).expect(403);
    await other.http.post(`/api/notes/${note.id}/link`).expect(403);
    await other.http.delete(`/api/notes/${note.id}/link`).expect(403);
    await anonymous().post(`/api/notes/${note.id}/link`).expect(401);
  });

  it('refuses a link for a note in the trash', async () => {
    const note = await owner.notes.create({ title: 'Trip' });
    await owner.notes.trash(note.id);

    await owner.http.post(`/api/notes/${note.id}/link`).expect(400);
  });
});
