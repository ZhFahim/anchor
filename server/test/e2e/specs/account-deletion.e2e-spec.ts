import * as fs from 'fs';
import * as path from 'path';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import request from 'supertest';
import { PNG_1PX } from '../support/fixtures';
import { Actor, bodyOf, createE2EApp, E2EApp, entryFor } from '../support';

const PASSWORD = 'password-123';

describe('account deletion', () => {
  let ctx: E2EApp;
  let admin: Actor;
  let user: Actor;
  let friend: Actor;

  beforeAll(async () => {
    ctx = await createE2EApp();
  });

  afterAll(async () => {
    await ctx.close();
  });

  beforeEach(async () => {
    await ctx.resetDb();
    admin = await ctx.registerUser('Admin');
    user = await ctx.registerUser('User');
    friend = await ctx.registerUser('Friend');
  });

  const deleteAccount = (actor: Actor, password?: string) =>
    actor.http.post('/api/auth/delete-account').send({ password });

  const attachmentPath = (noteId: string, storedFilename: string) =>
    path.join(ctx.storage.attachmentsDir, noteId, storedFilename);

  const storedFilename = async (attachmentId: string) => {
    const row = await ctx.prisma.noteAttachment.findUniqueOrThrow({
      where: { id: attachmentId },
    });
    return row.storedFilename;
  };

  const uploadProfilePhoto = async (actor: Actor) => {
    const res = await actor.http
      .post('/api/auth/profile/image')
      .attach('image', PNG_1PX, {
        filename: 'me.png',
        contentType: 'image/png',
      })
      .expect(201);
    return path.join(
      ctx.storage.root,
      bodyOf<{ profileImage: string }>(res).profileImage,
    );
  };

  // Files go after the reply, the profile photo last.
  const waitUntilGone = (file: string) =>
    expect.poll(() => fs.existsSync(file)).toBe(false);

  describe('who can delete', () => {
    it('turns down a wrong password and keeps the account', async () => {
      await deleteAccount(user, 'not-my-password')
        .expect(403)
        .expect((res) => {
          expect((res.body as { message: string }).message).toBe(
            'Current password is incorrect',
          );
        });

      await user.notes.create({ title: 'still here' });
    });

    it('turns down a missing password', async () => {
      await deleteAccount(user).expect(403);
    });

    it('needs no password on an account that has none', async () => {
      await ctx.prisma.user.update({
        where: { id: user.id },
        data: { password: null, oidcSubject: 'provider-subject' },
      });

      await deleteAccount(user).expect(200);

      expect(
        await ctx.prisma.user.findUnique({ where: { id: user.id } }),
      ).toBeNull();
    });

    it('needs a signed-in user', async () => {
      await request(ctx.http)
        .post('/api/auth/delete-account')
        .send({ password: PASSWORD })
        .expect(401);
    });

    it('keeps the only admin while other people use the server', async () => {
      await deleteAccount(admin, PASSWORD).expect(409);

      expect(
        await ctx.prisma.user.findUnique({ where: { id: admin.id } }),
      ).not.toBeNull();
    });

    it('lets an admin go when another admin stays', async () => {
      await ctx.prisma.user.update({
        where: { id: user.id },
        data: { isAdmin: true },
      });

      await deleteAccount(admin, PASSWORD).expect(200);
    });

    it('lets the only person on the server go', async () => {
      await ctx.prisma.user.deleteMany({
        where: { id: { in: [user.id, friend.id] } },
      });

      await deleteAccount(admin, PASSWORD).expect(200);

      expect(await ctx.prisma.user.count()).toBe(0);
    });
  });

  describe('what goes', () => {
    it('ends every way of signing in', async () => {
      const login = await request(ctx.http)
        .post('/api/auth/login')
        .send({ email: user.email, password: PASSWORD })
        .expect(200);
      const { refresh_token: refreshToken } = bodyOf<{
        refresh_token: string;
      }>(login);

      await deleteAccount(user, PASSWORD).expect(200);

      await user.http.get('/api/notes').expect(401);
      await request(ctx.http)
        .post('/api/auth/refresh')
        .send({ refresh_token: refreshToken })
        .expect(401);
      await request(ctx.http)
        .post('/api/auth/login')
        .send({ email: user.email, password: PASSWORD })
        .expect(401);
    });

    it('removes notes in every state, and tags', async () => {
      const kept = await user.notes.create({ title: 'active' });
      const trashed = await user.notes.create({ title: 'trashed' });
      await user.notes.trash(trashed.id);
      await user.tags.create({ name: 'mine' });

      await deleteAccount(user, PASSWORD).expect(200);

      expect(
        await ctx.prisma.note.count({
          where: { id: { in: [kept.id, trashed.id] } },
        }),
      ).toBe(0);
      expect(await ctx.prisma.tag.count({ where: { userId: user.id } })).toBe(
        0,
      );
    });

    it('removes attachment and profile photo files', async () => {
      const note = await user.notes.create({ title: 'with a photo' });
      await user.attachments.upload(note.id, 'photo.png');
      const noteDir = path.join(ctx.storage.attachmentsDir, note.id);
      const profileImage = await uploadProfilePhoto(user);
      expect(fs.existsSync(noteDir)).toBe(true);
      expect(fs.existsSync(profileImage)).toBe(true);

      await deleteAccount(user, PASSWORD).expect(200);

      await waitUntilGone(noteDir);
      await waitUntilGone(profileImage);
    });

    it('keeps other people’s files when a note id points outside its folder', async () => {
      const pushed = await user.sync.push([
        { type: 'note', id: '..', title: 'odd id' },
      ]);
      expect(pushed.results).toEqual([
        { type: 'note', id: '..', status: 'denied' },
      ]);
      await ctx.prisma.note.create({
        data: { id: '..', title: 'odd id', userId: user.id },
      });
      const note = await friend.notes.create({ title: 'friend owns this' });
      const attachment = await friend.attachments.upload(note.id, 'photo.png');
      const file = attachmentPath(note.id, await storedFilename(attachment.id));
      const profileImage = await uploadProfilePhoto(user);

      await deleteAccount(user, PASSWORD).expect(200);

      await waitUntilGone(profileImage);
      expect(fs.existsSync(file)).toBe(true);
    });

    it('ends live sync connections', async () => {
      const stream = await user.openEventStream();

      await deleteAccount(user, PASSWORD).expect(200);

      await stream.waitForEnd();
    });
  });

  describe('what other people see', () => {
    it('takes a shared note off the sharee, on their next sync', async () => {
      const note = await user.notes.create({ title: 'shared with friend' });
      await user.shares.grant(note.id, friend.id, 'viewer');
      const first = await friend.sync.drain();
      expect(entryFor(first.entries, 'note', note.id)).toBeDefined();

      await deleteAccount(user, PASSWORD).expect(200);

      const delta = await friend.sync.drain({ cursor: first.cursor });
      expect(entryFor(delta.entries, 'note', note.id)).toMatchObject({
        op: 'remove',
      });
      const fresh = await friend.sync.drain();
      expect(entryFor(fresh.entries, 'note', note.id)).toBeUndefined();
    });

    it('keeps a note shared with them, and updates its owner', async () => {
      const note = await friend.notes.create({ title: 'friend owns this' });
      await friend.shares.grant(note.id, user.id, 'editor');
      const first = await friend.sync.drain();

      await deleteAccount(user, PASSWORD).expect(200);

      expect(await friend.shares.list(note.id)).toEqual([]);
      const delta = await friend.sync.drain({ cursor: first.cursor });
      expect(entryFor(delta.entries, 'note', note.id)).toMatchObject({
        op: 'upsert',
      });
    });

    it('keeps attachments they added to someone else’s note', async () => {
      const note = await friend.notes.create({ title: 'friend owns this' });
      await friend.shares.grant(note.id, user.id, 'editor');
      const attachment = await user.attachments.upload(note.id, 'added.png');
      const file = attachmentPath(note.id, await storedFilename(attachment.id));
      const profileImage = await uploadProfilePhoto(user);

      await deleteAccount(user, PASSWORD).expect(200);

      await waitUntilGone(profileImage);
      const attachments = await friend.attachments.list(note.id);
      expect(attachments.map((a) => a.id)).toEqual([attachment.id]);
      expect(fs.existsSync(file)).toBe(true);
      const row = await ctx.prisma.noteAttachment.findUniqueOrThrow({
        where: { id: attachment.id },
      });
      expect(row.uploadedByUserId).toBe(friend.id);
    });
  });

  it('cleans up the same way when an admin deletes the account', async () => {
    const note = await user.notes.create({ title: 'shared with friend' });
    await user.shares.grant(note.id, friend.id, 'viewer');
    await user.attachments.upload(note.id, 'photo.png');
    const noteDir = path.join(ctx.storage.attachmentsDir, note.id);
    const stream = await user.openEventStream();
    const first = await friend.sync.drain();

    await admin.http.delete(`/api/admin/users/${user.id}`).expect(200);

    await stream.waitForEnd();
    await waitUntilGone(noteDir);
    const delta = await friend.sync.drain({ cursor: first.cursor });
    expect(entryFor(delta.entries, 'note', note.id)).toMatchObject({
      op: 'remove',
    });
  });
});
