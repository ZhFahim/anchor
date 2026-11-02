import * as fs from 'fs';
import * as path from 'path';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import request from 'supertest';
import { Actor, bodyOf, createE2EApp, E2EApp, PNG_1PX } from '../support';

const WEB_ORIGIN = process.env.CORS_ORIGINS!;

describe('app setup', () => {
  let ctx: E2EApp;
  let user: Actor;

  beforeAll(async () => {
    ctx = await createE2EApp();
  });

  afterAll(async () => {
    await ctx.close();
  });

  beforeEach(async () => {
    await ctx.resetDb();
    user = await ctx.registerUser();
  });

  it('sends the security headers', async () => {
    const res = await request(ctx.http).get('/api/health').expect(200);

    expect(res.headers['x-content-type-options']).toBe('nosniff');
    expect(res.headers['content-security-policy']).toBeDefined();
  });

  it('tells uptime monitors the server and its database are ready', async () => {
    const res = await request(ctx.http).get('/api/health/ready').expect(200);

    expect(res.body).toEqual({ status: 'ok', database: 'ok' });
  });

  it('allows the configured web origin and no other', async () => {
    const allowed = await request(ctx.http)
      .get('/api/health')
      .set('Origin', WEB_ORIGIN)
      .expect(200);
    expect(allowed.headers['access-control-allow-origin']).toBe(WEB_ORIGIN);

    const foreign = await request(ctx.http)
      .get('/api/health')
      .set('Origin', 'https://elsewhere.test')
      .expect(200);
    expect(foreign.headers['access-control-allow-origin']).toBeUndefined();
  });

  it('takes a note far larger than the default request size', async () => {
    const content = JSON.stringify({
      ops: [{ insert: `${'x'.repeat(2_000_000)}\n` }],
    });

    const note = await user.notes.create({ title: 'long', content });

    expect(note.content).toHaveLength(content.length);
  });

  it('serves profile images without signing in', async () => {
    const res = await user.http
      .post('/api/auth/profile/image')
      .attach('image', PNG_1PX, {
        filename: 'me.png',
        contentType: 'image/png',
      })
      .expect(201);
    const { profileImage } = bodyOf<{ profileImage: string }>(res);

    const image = await request(ctx.http).get(profileImage).expect(200);

    expect(image.headers['content-type']).toBe('image/png');
    expect(image.headers['cache-control']).toBe(
      'private, max-age=31536000, immutable',
    );
    expect(image.body).toEqual(PNG_1PX);
  });

  it('names a profile image after its content, not the uploaded name', async () => {
    const res = await user.http
      .post('/api/auth/profile/image')
      .attach('image', PNG_1PX, {
        filename: 'me.html',
        contentType: 'text/html',
      })
      .expect(201);
    const { profileImage } = bodyOf<{ profileImage: string }>(res);

    expect(profileImage).toMatch(/\.png$/);
    const image = await request(ctx.http).get(profileImage).expect(200);
    expect(image.headers['content-type']).toBe('image/png');
  });

  it('hands out anything but an image in the profiles folder as a download', async () => {
    fs.mkdirSync(ctx.storage.profilesDir, { recursive: true });
    fs.writeFileSync(
      path.join(ctx.storage.profilesDir, 'old-upload.html'),
      '<script>alert(1)</script>',
    );

    const res = await request(ctx.http)
      .get('/uploads/profiles/old-upload.html')
      .expect(200);

    expect(res.headers['content-type']).toBe('application/octet-stream');
    expect(res.headers['content-disposition']).toBe('attachment');
  });

  it('never deletes outside the profiles folder when replacing a picture', async () => {
    const outside = path.join(ctx.storage.root, 'keep-me.txt');
    fs.writeFileSync(outside, 'keep');
    // What a failed OIDC picture download used to store as is.
    await ctx.prisma.user.update({
      where: { id: user.id },
      data: { profileImage: 'https://x.invalid/../../keep-me.txt' },
    });

    await user.http
      .post('/api/auth/profile/image')
      .attach('image', PNG_1PX, { filename: 'me.png' })
      .expect(201);

    expect(fs.existsSync(outside)).toBe(true);
  });

  it('keeps note attachments private', async () => {
    const note = await user.notes.create({ title: 'private file' });
    const attachment = await user.attachments.upload(note.id);
    const { storedFilename } =
      await ctx.prisma.noteAttachment.findUniqueOrThrow({
        where: { id: attachment.id },
      });
    expect(
      fs.existsSync(
        path.join(ctx.storage.attachmentsDir, note.id, storedFilename),
      ),
    ).toBe(true);

    await request(ctx.http)
      .get(`/uploads/attachments/${note.id}/${storedFilename}`)
      .expect(404);
  });
});
