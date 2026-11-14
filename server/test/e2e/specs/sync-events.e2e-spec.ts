import {
  afterAll,
  afterEach,
  beforeAll,
  beforeEach,
  describe,
  expect,
  it,
} from 'vitest';
import { randomUUID } from 'crypto';
import request from 'supertest';
import { Actor, createE2EApp, E2EApp } from '../support';

/**
 * The SSE push channel over real HTTP, and the post-commit poke discipline
 * behind it: a poke must never beat its transaction.
 */
describe('sync events', () => {
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

  afterEach(() => {
    ctx.closeEventStreams();
  });

  it('rejects an unauthenticated stream', async () => {
    await request(ctx.http).get('/api/sync/events').expect(401);
  });

  it('streams a sync poke carrying the new seq when a note is created', async () => {
    const stream = await user.openEventStream();
    expect(stream.status).toBe(200);
    expect(stream.headers['content-type']).toContain('text/event-stream');
    expect(stream.headers['x-accel-buffering']).toBe('no');

    await user.notes.create({ title: 'poked' });

    await stream.waitFor('event: sync');
    expect(stream.read()).toContain('"seq":"1"');
  });

  it('pokes the stream on a sync push', async () => {
    const stream = await user.openEventStream();

    await user.sync.push([{ type: 'note', id: randomUUID(), title: 'pushed' }]);

    await stream.waitFor('event: sync');
  });

  it("fans a shared-note edit out to the sharee's stream", async () => {
    const sharee = await ctx.registerUser();
    const note = await user.notes.create({ title: 'shared' });
    await user.shares.grant(note.id, sharee.id, 'editor');

    const stream = await sharee.openEventStream();

    await user.notes.update(note.id, { title: 'edited by owner' });

    await stream.waitFor('event: sync');
  });

  it('runs afterCommit hooks only once the transaction has committed', async () => {
    const order: string[] = [];

    await ctx.prisma.$transaction(async (tx) => {
      ctx.prisma.afterCommit(() => order.push('hook'));
      await tx.user.count();
      order.push('in-tx');
    });

    expect(order).toEqual(['in-tx', 'hook']);
  });

  it('discards afterCommit hooks when the transaction rolls back', async () => {
    let ran = false;

    await expect(
      ctx.prisma.$transaction(async (tx) => {
        ctx.prisma.afterCommit(() => {
          ran = true;
        });
        await tx.user.count();
        throw new Error('boom');
      }),
    ).rejects.toThrow('boom');

    expect(ran).toBe(false);
  });
});
