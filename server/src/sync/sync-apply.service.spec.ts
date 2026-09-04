import { Logger } from '@nestjs/common';
import { NoteSharePermission, NoteState } from 'src/generated/prisma/enums';
import { PrismaService } from '../prisma/prisma.service';
import { NoteAccessService } from '../notes/services/note-access.service';
import { SyncApplyService } from './sync-apply.service';
import type { SyncChange } from './dto/sync-request.dto';
import type { SyncTagPayload } from './dto/sync-response.dto';
import type {
  NotePermission,
  TransformedNote,
} from '../notes/utils/note-transformer.util';
import {
  asNoteRevisions,
  asSyncEmitter,
  createMockNoteRevisions,
  createMockSyncEmitter,
} from '../../test/sync-mocks';

/**
 * The conflict matrix, per-change dedup, and the paths e2e can't reach (the
 * in-transaction version-guard race).
 */
describe('SyncApplyService', () => {
  const USER = 'user-1';
  const OTHER = 'user-2';
  const AT = new Date('2026-08-01T00:00:00.000Z');

  let service: SyncApplyService;
  let emitter: ReturnType<typeof createMockSyncEmitter>;
  let revisions: ReturnType<typeof createMockNoteRevisions>;

  // note.findUnique serves three different calls, told apart by their args:
  // {select} = existence probe, {include} = serverCopy hydration, bare =
  // the in-transaction prior read.
  let noteExists: boolean;
  let priorNote: Record<string, unknown> | null;
  let fullNote: Record<string, unknown> | null;
  let updateManyCount: number;

  const noteFindUnique = jest.fn(
    (args: { select?: unknown; include?: unknown }) => {
      if (args.select) {
        return Promise.resolve(noteExists ? { id: 'n1' } : null);
      }
      if (args.include) {
        return Promise.resolve(fullNote);
      }
      return Promise.resolve(priorNote);
    },
  );
  let createdNote: { state: NoteState; version: number };
  const noteCreate = jest.fn((args: { data: { title: string } }) => {
    void args;
    return Promise.resolve(createdNote);
  });
  const noteUpdateMany = jest.fn(
    (args: { where: unknown; data: Record<string, unknown> }) => {
      void args;
      return Promise.resolve({ count: updateManyCount });
    },
  );

  let existingTag: Record<string, unknown> | null;
  let collidingTag: Record<string, unknown> | null;
  const tagFindUnique = jest.fn(() => Promise.resolve(existingTag));
  const tagFindFirst = jest.fn(() => Promise.resolve(collidingTag));
  const tagCreate = jest.fn();
  const tagUpdateMany = jest.fn(() =>
    Promise.resolve({ count: updateManyCount }),
  );

  let pinRow: { noteId: string } | null;
  const pinFindUnique = jest.fn(() => Promise.resolve(pinRow));
  const pinUpsert = jest.fn().mockResolvedValue({});
  const pinDeleteMany = jest.fn().mockResolvedValue({ count: 1 });

  let reminderRow: Record<string, unknown> | null;
  let reminderWriteCount: number;
  const reminderFindUnique = jest.fn(() => Promise.resolve(reminderRow));
  const reminderCreate = jest.fn((args: { data: Record<string, unknown> }) =>
    Promise.resolve({ ...args.data, version: 1 }),
  );
  const reminderUpdateMany = jest.fn(() =>
    Promise.resolve({ count: reminderWriteCount }),
  );
  const reminderDeleteMany = jest.fn(() =>
    Promise.resolve({ count: reminderWriteCount }),
  );

  const prisma = {
    $transaction: (cb: (tx: unknown) => unknown) => cb(prisma),
    note: {
      findUnique: noteFindUnique,
      create: noteCreate,
      updateMany: noteUpdateMany,
    },
    tag: {
      findUnique: tagFindUnique,
      findFirst: tagFindFirst,
      create: tagCreate,
      updateMany: tagUpdateMany,
      findMany: jest.fn().mockResolvedValue([]),
    },
    notePin: {
      findUnique: pinFindUnique,
      upsert: pinUpsert,
      deleteMany: pinDeleteMany,
    },
    noteReminder: {
      findUnique: reminderFindUnique,
      create: reminderCreate,
      updateMany: reminderUpdateMany,
      deleteMany: reminderDeleteMany,
    },
  } as unknown as PrismaService;

  const hasNoteAccess = jest.fn();
  const noteAccess = { hasNoteAccess } as unknown as NoteAccessService;

  const makeFullNote = (overrides: Record<string, unknown> = {}) => ({
    id: 'n1',
    title: 'server title',
    content: 'server content',
    version: 5,
    isArchived: false,
    background: null,
    state: NoteState.active,
    createdAt: AT,
    updatedAt: AT,
    userId: USER,
    pins: [],
    tags: [],
    sharedWith: [],
    _count: { attachments: 0 },
    attachments: [],
    ...overrides,
  });

  const makePrior = (overrides: Record<string, unknown> = {}) => ({
    id: 'n1',
    title: 'server title',
    content: 'server content',
    version: 5,
    isArchived: false,
    background: null,
    state: NoteState.active,
    userId: USER,
    ...overrides,
  });

  const noteChange = (overrides: Record<string, unknown> = {}): SyncChange =>
    ({
      type: 'note',
      id: 'n1',
      title: 'client title',
      ...overrides,
    }) as unknown as SyncChange;

  const tagChange = (overrides: Record<string, unknown> = {}): SyncChange =>
    ({
      type: 'tag',
      id: 't1',
      name: 'client name',
      ...overrides,
    }) as unknown as SyncChange;

  const clientRevision = (id: string) => ({
    id,
    title: 'earlier title',
    content: 'earlier content',
    cause: 'edit' as const,
    createdAt: '2026-08-01T10:00:00.000Z',
  });

  beforeEach(() => {
    emitter = createMockSyncEmitter();
    revisions = createMockNoteRevisions();
    service = new SyncApplyService(
      prisma,
      noteAccess,
      asSyncEmitter(emitter),
      asNoteRevisions(revisions),
    );
    noteExists = false;
    priorNote = null;
    fullNote = null;
    existingTag = null;
    collidingTag = null;
    pinRow = null;
    reminderRow = null;
    reminderWriteCount = 1;
    updateManyCount = 1;
    jest.clearAllMocks();
    emitter.noteRecipients.mockResolvedValue([USER]);
  });

  describe('notes', () => {
    it('coalesces repeated changes to the last occurrence', async () => {
      createdNote = { state: NoteState.active, version: 1 };

      const results = await service.apply(USER, [
        noteChange({ title: 'first' }),
        noteChange({ title: 'last' }),
      ]);

      expect(results).toHaveLength(1);
      expect(noteCreate).toHaveBeenCalledTimes(1);
      expect(noteCreate.mock.calls[0][0].data.title).toBe('last');
    });

    it('creates an unknown note at version 1 and emits to the owner', async () => {
      createdNote = { state: NoteState.active, version: 1 };

      const results = await service.apply(USER, [noteChange()]);

      expect(results).toEqual([
        { type: 'note', id: 'n1', status: 'applied', version: 1 },
      ]);
      expect(emitter.emit).toHaveBeenCalledWith(prisma, [
        expect.objectContaining({
          recipientUserId: USER,
          entityType: 'note',
          entityId: 'n1',
          op: 'upsert',
        }),
      ]);
    });

    it('a created tombstone emits a remove instead of an upsert', async () => {
      createdNote = { state: NoteState.deleted, version: 1 };

      const results = await service.apply(USER, [
        noteChange({ state: 'deleted' }),
      ]);

      expect(results[0].status).toBe('applied');
      expect(emitter.removeNote).toHaveBeenCalledWith(prisma, [USER], 'n1');
      expect(emitter.emit).not.toHaveBeenCalled();
    });

    it('denies a push against an inaccessible existing note', async () => {
      noteExists = true;
      hasNoteAccess.mockResolvedValue({ hasAccess: false, isOwner: false });

      const results = await service.apply(USER, [noteChange()]);

      expect(results).toEqual([{ type: 'note', id: 'n1', status: 'denied' }]);
      expect(noteUpdateMany).not.toHaveBeenCalled();
      expect(revisions.recordConflict).not.toHaveBeenCalled();
    });

    it("conflicts a viewer's content push but preserves it as a revision", async () => {
      noteExists = true;
      fullNote = makeFullNote();
      hasNoteAccess.mockResolvedValue({
        hasAccess: false,
        isOwner: false,
        permission: NoteSharePermission.viewer,
      });

      const results = await service.apply(USER, [
        noteChange({ title: 'viewer edit', baseVersion: 5 }),
      ]);

      expect(results[0].status).toBe('conflict');
      expect((results[0].serverCopy as TransformedNote).title).toBe(
        'server title',
      );
      expect(revisions.recordConflict).toHaveBeenCalledWith(
        prisma,
        {
          noteId: 'n1',
          title: 'viewer edit',
          content: null,
          baseVersion: 5,
        },
        USER,
      );
      expect(noteUpdateMany).not.toHaveBeenCalled();
    });

    it('conflicts a stale baseVersion without attempting the write', async () => {
      noteExists = true;
      priorNote = makePrior();
      fullNote = makeFullNote();
      hasNoteAccess.mockResolvedValue({
        hasAccess: true,
        isOwner: true,
        permission: 'owner',
      });

      const results = await service.apply(USER, [
        noteChange({ baseVersion: 3 }),
      ]);

      expect(results[0].status).toBe('conflict');
      expect((results[0].serverCopy as TransformedNote).version).toBe(5);
      expect(noteUpdateMany).not.toHaveBeenCalled();
      expect(revisions.recordConflict).toHaveBeenCalled();
    });

    it('conflicts an absent baseVersion on an existing note (cutover race)', async () => {
      noteExists = true;
      priorNote = makePrior();
      fullNote = makeFullNote();
      hasNoteAccess.mockResolvedValue({
        hasAccess: true,
        isOwner: true,
        permission: 'owner',
      });

      const results = await service.apply(USER, [noteChange()]);

      expect(results[0].status).toBe('conflict');
      expect(revisions.recordConflict).toHaveBeenCalledWith(
        prisma,
        expect.objectContaining({ baseVersion: undefined }),
        USER,
      );
    });

    it('applies a matching baseVersion with a guarded version bump and an edit revision', async () => {
      noteExists = true;
      priorNote = makePrior();
      hasNoteAccess.mockResolvedValue({
        hasAccess: true,
        isOwner: true,
        permission: 'owner',
      });

      const results = await service.apply(USER, [
        noteChange({ title: 'new title', content: 'new body', baseVersion: 5 }),
      ]);

      expect(results).toEqual([
        { type: 'note', id: 'n1', status: 'applied', version: 6 },
      ]);
      const call = noteUpdateMany.mock.calls[0][0];
      expect(call.where).toEqual({ id: 'n1', version: 5 });
      expect(call.data).toMatchObject({
        title: 'new title',
        version: { increment: 1 },
      });
      expect(revisions.recordEdit).toHaveBeenCalledWith(
        prisma,
        priorNote,
        USER,
      );
    });

    it("keeps the client's own revisions instead of recording one here", async () => {
      noteExists = true;
      priorNote = makePrior();
      hasNoteAccess.mockResolvedValue({
        hasAccess: true,
        isOwner: true,
        permission: 'owner',
      });
      const recorded = [
        {
          id: 'r1',
          version: 5,
          title: 'server title',
          content: 'server content',
          cause: 'edit',
          createdAt: '2026-08-01T10:00:00.000Z',
        },
      ];

      const results = await service.apply(USER, [
        noteChange({
          title: 'new title',
          content: 'new body',
          baseVersion: 5,
          revisions: recorded,
        }),
      ]);

      expect(results[0]).toMatchObject({ status: 'applied', version: 6 });
      expect(revisions.recordClient).toHaveBeenCalledWith(
        prisma,
        'n1',
        recorded,
        USER,
      );
      expect(revisions.recordEdit).not.toHaveBeenCalled();
    });

    it('records the copy a rebased push overwrites, next to the client revisions', async () => {
      noteExists = true;
      priorNote = makePrior({
        title: 'other device title',
        content: 'other device content',
      });
      hasNoteAccess.mockResolvedValue({
        hasAccess: true,
        isOwner: true,
        permission: 'owner',
      });
      const recorded = [
        {
          id: 'r1',
          version: 4,
          title: 'server title',
          content: 'server content',
          cause: 'edit',
          createdAt: '2026-08-01T10:00:00.000Z',
        },
      ];

      const results = await service.apply(USER, [
        noteChange({
          title: 'new title',
          content: 'new body',
          baseVersion: 5,
          revisions: recorded,
        }),
      ]);

      expect(results[0]).toMatchObject({ status: 'applied', version: 6 });
      expect(revisions.recordEdit).toHaveBeenCalledWith(
        prisma,
        priorNote,
        USER,
      );
      expect(revisions.recordClient).toHaveBeenCalledWith(
        prisma,
        'n1',
        recorded,
        USER,
      );
    });

    it('keeps revisions recorded before a note first reached the server', async () => {
      createdNote = { state: NoteState.active, version: 1 };
      const recorded = [
        {
          id: 'r1',
          version: 0,
          title: 'draft',
          content: 'first pass',
          cause: 'edit',
          createdAt: '2026-08-01T10:00:00.000Z',
        },
      ];

      const results = await service.apply(USER, [
        noteChange({ revisions: recorded }),
      ]);

      expect(results[0]).toMatchObject({ status: 'applied', version: 1 });
      expect(revisions.recordClient).toHaveBeenCalledWith(
        prisma,
        'n1',
        recorded,
        USER,
      );
    });

    it('holds back the revisions of a rejected push', async () => {
      noteExists = true;
      priorNote = makePrior();
      fullNote = makeFullNote();
      hasNoteAccess.mockResolvedValue({
        hasAccess: true,
        isOwner: true,
        permission: 'owner',
      });

      const results = await service.apply(USER, [
        noteChange({
          baseVersion: 3,
          revisions: [
            {
              id: 'r1',
              title: 'server title',
              content: 'server content',
              cause: 'edit',
              createdAt: '2026-08-01T10:00:00.000Z',
            },
          ],
        }),
      ]);

      expect(results[0].status).toBe('conflict');
      expect(revisions.recordClient).not.toHaveBeenCalled();
    });

    it('skips the version bump and revision when nothing guarded changed', async () => {
      noteExists = true;
      priorNote = makePrior();
      hasNoteAccess.mockResolvedValue({
        hasAccess: true,
        isOwner: true,
        permission: 'owner',
      });

      const results = await service.apply(USER, [
        noteChange({
          title: 'server title',
          content: 'server content',
          baseVersion: 5,
        }),
      ]);

      expect(results[0]).toMatchObject({ status: 'applied', version: 5 });
      expect(noteUpdateMany.mock.calls[0][0].data.version).toBeUndefined();
      expect(revisions.recordEdit).not.toHaveBeenCalled();
    });

    it('loses the version-guard race as a conflict, like any stale base', async () => {
      noteExists = true;
      priorNote = makePrior();
      fullNote = makeFullNote({ version: 6 });
      updateManyCount = 0;
      hasNoteAccess.mockResolvedValue({
        hasAccess: true,
        isOwner: true,
        permission: 'owner',
      });

      const results = await service.apply(USER, [
        noteChange({ title: 'racer', baseVersion: 5 }),
      ]);

      expect(results[0].status).toBe('conflict');
      expect(revisions.recordConflict).toHaveBeenCalled();
      expect(emitter.emit).not.toHaveBeenCalled();
    });

    it("ignores owner-only fields on an editor's push", async () => {
      noteExists = true;
      priorNote = makePrior({ userId: OTHER });
      hasNoteAccess.mockResolvedValue({
        hasAccess: true,
        isOwner: false,
        permission: NoteSharePermission.editor,
      });

      await service.apply(USER, [
        noteChange({
          title: 'server title',
          content: 'server content',
          isArchived: true,
          state: 'trashed',
          baseVersion: 5,
        }),
      ]);

      const { data } = noteUpdateMany.mock.calls[0][0];
      expect('isArchived' in data).toBe(false);
      expect('state' in data).toBe(false);
    });

    it('denies a push for a note the server purged rather than recreating it', async () => {
      noteExists = false;

      const results = await service.apply(USER, [
        noteChange({ baseVersion: 4 }),
      ]);

      expect(results).toEqual([{ type: 'note', id: 'n1', status: 'denied' }]);
      expect(noteCreate).not.toHaveBeenCalled();
    });

    it('acks a redelivered push whose payload already landed', async () => {
      noteExists = true;
      priorNote = makePrior({ version: 6 });
      fullNote = makeFullNote({ version: 6, title: 'client title' });
      hasNoteAccess.mockResolvedValue({
        hasAccess: true,
        isOwner: true,
        permission: 'owner',
      });

      const results = await service.apply(USER, [
        noteChange({ baseVersion: 5, content: 'server content' }),
      ]);

      expect(results).toEqual([
        { type: 'note', id: 'n1', status: 'applied', version: 6 },
      ]);
      expect(revisions.recordConflict).not.toHaveBeenCalled();
    });

    it('a redelivered ack still keeps the revisions it carried', async () => {
      noteExists = true;
      priorNote = makePrior({ version: 6 });
      fullNote = makeFullNote({ version: 6, title: 'client title' });
      hasNoteAccess.mockResolvedValue({
        hasAccess: true,
        isOwner: true,
        permission: 'owner',
      });

      const results = await service.apply(USER, [
        noteChange({
          baseVersion: 5,
          content: 'server content',
          revisions: [clientRevision('r1')],
        }),
      ]);

      expect(results[0]).toMatchObject({ status: 'applied', version: 6 });
      expect(revisions.recordClient).toHaveBeenCalledWith(
        prisma,
        'n1',
        [expect.objectContaining({ id: 'r1' })],
        USER,
      );
      expect(emitter.emit).toHaveBeenCalled();
    });

    it("a viewer's matching redelivery is acked without keeping revisions", async () => {
      noteExists = true;
      fullNote = makeFullNote({ title: 'client title' });
      hasNoteAccess.mockResolvedValue({
        hasAccess: false,
        isOwner: false,
        permission: NoteSharePermission.viewer,
      });

      const results = await service.apply(USER, [
        noteChange({
          baseVersion: 5,
          content: 'server content',
          revisions: [clientRevision('r1')],
        }),
      ]);

      expect(results[0]).toMatchObject({ status: 'applied', version: 5 });
      expect(revisions.recordClient).not.toHaveBeenCalled();
    });

    it('keeps a revisions-only push without touching the note, even on a stale base', async () => {
      noteExists = true;
      priorNote = makePrior({ version: 8 });
      hasNoteAccess.mockResolvedValue({
        hasAccess: true,
        isOwner: true,
        permission: 'owner',
      });

      const results = await service.apply(USER, [
        noteChange({
          baseVersion: 5,
          revisionsOnly: true,
          revisions: [clientRevision('r1')],
        }),
      ]);

      expect(results).toEqual([
        { type: 'note', id: 'n1', status: 'applied', version: 8 },
      ]);
      expect(revisions.recordClient).toHaveBeenCalledWith(
        prisma,
        'n1',
        [expect.objectContaining({ id: 'r1' })],
        USER,
      );
      expect(revisions.recordConflict).not.toHaveBeenCalled();
      expect(noteUpdateMany).not.toHaveBeenCalled();
      expect(emitter.emit).toHaveBeenCalled();
    });

    it("a demoted viewer's revisions-only push is acked and dropped", async () => {
      noteExists = true;
      priorNote = makePrior();
      hasNoteAccess.mockResolvedValue({
        hasAccess: false,
        isOwner: false,
        permission: NoteSharePermission.viewer,
      });

      const results = await service.apply(USER, [
        noteChange({
          baseVersion: 5,
          revisionsOnly: true,
          revisions: [clientRevision('r1')],
        }),
      ]);

      expect(results).toEqual([
        { type: 'note', id: 'n1', status: 'applied', version: 5 },
      ]);
      expect(revisions.recordClient).not.toHaveBeenCalled();
      expect(emitter.emit).not.toHaveBeenCalled();
    });

    it('returns a retryable failure without dropping the rest of the batch', async () => {
      jest.spyOn(Logger.prototype, 'error').mockImplementation(() => {});
      noteExists = false;
      createdNote = { state: NoteState.active, version: 1 };
      noteCreate.mockImplementationOnce(() => {
        throw new Error('deadlock detected');
      });

      const results = await service.apply(USER, [
        noteChange({ id: 'n1' }),
        noteChange({ id: 'n2' }),
      ]);

      expect(results).toEqual([
        { type: 'note', id: 'n1', status: 'failed' },
        { type: 'note', id: 'n2', status: 'applied', version: 1 },
      ]);
    });
  });

  describe('tags', () => {
    it("denies a push against another user's tag", async () => {
      existingTag = { id: 't1', userId: OTHER };

      const results = await service.apply(USER, [tagChange()]);

      expect(results).toEqual([{ type: 'tag', id: 't1', status: 'denied' }]);
    });

    it('acks a delete for a tag the server never had', async () => {
      const results = await service.apply(USER, [
        tagChange({ isDeleted: true }),
      ]);

      expect(results).toEqual([{ type: 'tag', id: 't1', status: 'applied' }]);
      expect(tagCreate).not.toHaveBeenCalled();
    });

    it('answers a create-collision with the surviving tag under a different id', async () => {
      collidingTag = {
        id: 't-existing',
        name: 'client name',
        color: null,
        userId: USER,
        isDeleted: false,
        version: 2,
        createdAt: AT,
        updatedAt: AT,
      };

      const results = await service.apply(USER, [tagChange()]);

      expect(results[0].status).toBe('conflict');
      expect((results[0].serverCopy as SyncTagPayload).id).toBe('t-existing');
      expect(tagCreate).not.toHaveBeenCalled();
    });

    it('creates an unknown tag at version 1 and emits it', async () => {
      tagCreate.mockResolvedValue({ id: 't1', version: 1 });

      const results = await service.apply(USER, [tagChange()]);

      expect(results).toEqual([
        { type: 'tag', id: 't1', status: 'applied', version: 1 },
      ]);
      expect(emitter.emit).toHaveBeenCalledWith(prisma, [
        expect.objectContaining({ entityType: 'tag', entityId: 't1' }),
      ]);
    });

    it('conflicts a stale baseVersion with the server copy', async () => {
      existingTag = {
        id: 't1',
        name: 'server name',
        color: null,
        userId: USER,
        isDeleted: false,
        version: 3,
        createdAt: AT,
        updatedAt: AT,
      };

      const results = await service.apply(USER, [
        tagChange({ baseVersion: 2 }),
      ]);

      expect(results[0].status).toBe('conflict');
      expect(results[0].serverCopy).toMatchObject({
        id: 't1',
        name: 'server name',
        version: 3,
      });
      expect(tagUpdateMany).not.toHaveBeenCalled();
    });

    it('applies a matching delete with a version bump and a remove emission', async () => {
      existingTag = {
        id: 't1',
        name: 'server name',
        color: null,
        userId: USER,
        isDeleted: false,
        version: 3,
        createdAt: AT,
        updatedAt: AT,
      };

      const results = await service.apply(USER, [
        tagChange({ isDeleted: true, baseVersion: 3 }),
      ]);

      expect(results).toEqual([
        { type: 'tag', id: 't1', status: 'applied', version: 4 },
      ]);
      expect(tagUpdateMany).toHaveBeenCalledWith({
        where: { id: 't1', version: 3 },
        data: { isDeleted: true, version: { increment: 1 } },
      });
      expect(emitter.emit).toHaveBeenCalledWith(prisma, [
        expect.objectContaining({ entityType: 'tag', op: 'remove' }),
      ]);
    });

    it('conflicts a rename that collides with another live tag', async () => {
      existingTag = {
        id: 't1',
        name: 'old name',
        color: null,
        userId: USER,
        isDeleted: false,
        version: 1,
        createdAt: AT,
        updatedAt: AT,
      };
      collidingTag = {
        id: 't-other',
        name: 'client name',
        color: null,
        userId: USER,
        isDeleted: false,
        version: 1,
        createdAt: AT,
        updatedAt: AT,
      };

      const results = await service.apply(USER, [
        tagChange({ baseVersion: 1 }),
      ]);

      expect(results[0].status).toBe('conflict');
      expect((results[0].serverCopy as SyncTagPayload).id).toBe('t-other');
      expect(tagUpdateMany).not.toHaveBeenCalled();
    });
  });

  describe('pins', () => {
    it('denies a pin without read access', async () => {
      hasNoteAccess.mockResolvedValue({ hasAccess: false, isOwner: false });

      const results = await service.apply(USER, [
        { type: 'pin', id: 'n1', isPinned: true } as unknown as SyncChange,
      ]);

      expect(results).toEqual([{ type: 'pin', id: 'n1', status: 'denied' }]);
      expect(pinUpsert).not.toHaveBeenCalled();
    });

    it('applies pin and unpin with matching emissions and no version effects', async () => {
      hasNoteAccess.mockResolvedValue({
        hasAccess: true,
        isOwner: true,
        permission: 'owner',
      });

      const pinned = await service.apply(USER, [
        { type: 'pin', id: 'n1', isPinned: true } as unknown as SyncChange,
      ]);
      expect(pinned).toEqual([{ type: 'pin', id: 'n1', status: 'applied' }]);
      expect(pinUpsert).toHaveBeenCalled();
      expect(emitter.emit).toHaveBeenCalledWith(prisma, [
        expect.objectContaining({ entityType: 'pin', op: 'upsert' }),
      ]);

      pinRow = { noteId: 'n1' };
      const unpinned = await service.apply(USER, [
        { type: 'pin', id: 'n1', isPinned: false } as unknown as SyncChange,
      ]);
      expect(unpinned[0].status).toBe('applied');
      expect(pinDeleteMany).toHaveBeenCalled();
      expect(emitter.emit).toHaveBeenLastCalledWith(prisma, [
        expect.objectContaining({ entityType: 'pin', op: 'remove' }),
      ]);
    });
  });

  describe('reminders', () => {
    const reminderChange = (
      overrides: Record<string, unknown> = {},
    ): SyncChange =>
      ({
        type: 'reminder',
        id: 'n1',
        remindAt: '2026-09-04T09:00',
        ...overrides,
      }) as unknown as SyncChange;

    const stored = (overrides: Record<string, unknown> = {}) => ({
      userId: USER,
      noteId: 'n1',
      remindAt: '2026-09-04T09:00',
      recurrence: 'none',
      version: 3,
      ...overrides,
    });

    const grantAccess = (permission: NotePermission = 'owner') =>
      hasNoteAccess.mockResolvedValue({
        hasAccess: true,
        state: NoteState.active,
        isOwner: permission === 'owner',
        permission,
      });

    it('lets a viewer set a reminder on a note shared with them', async () => {
      grantAccess(NoteSharePermission.viewer);

      const results = await service.apply(USER, [reminderChange()]);

      expect(results).toEqual([
        { type: 'reminder', id: 'n1', status: 'applied', version: 1 },
      ]);
      expect(emitter.emit).toHaveBeenCalledWith(prisma, [
        expect.objectContaining({
          recipientUserId: USER,
          entityType: 'reminder',
          entityId: 'n1',
          op: 'upsert',
        }),
      ]);
    });

    it('denies a reminder on a note it cannot reach', async () => {
      hasNoteAccess.mockResolvedValue({ hasAccess: false });

      const results = await service.apply(USER, [reminderChange()]);

      expect(results[0].status).toBe('denied');
      expect(reminderCreate).not.toHaveBeenCalled();
    });

    it('acks a clear for a reminder that is already gone', async () => {
      grantAccess();

      const results = await service.apply(USER, [
        reminderChange({ remindAt: null }),
      ]);

      expect(results[0].status).toBe('applied');
      expect(reminderDeleteMany).not.toHaveBeenCalled();
    });

    it('denies recreating a reminder the server no longer has', async () => {
      grantAccess();

      const results = await service.apply(USER, [
        reminderChange({ baseVersion: 2 }),
      ]);

      expect(results[0].status).toBe('denied');
      expect(reminderCreate).not.toHaveBeenCalled();
    });

    it('acks a redelivered push that already matches, without conflicting', async () => {
      grantAccess();
      reminderRow = stored();

      const results = await service.apply(USER, [
        reminderChange({ baseVersion: 1 }),
      ]);

      expect(results).toEqual([
        { type: 'reminder', id: 'n1', status: 'applied', version: 3 },
      ]);
      expect(reminderUpdateMany).not.toHaveBeenCalled();
    });

    it('refuses a stale clear and hands back the newer reminder', async () => {
      grantAccess();
      reminderRow = stored({ remindAt: '2026-09-05T18:30', version: 7 });

      const results = await service.apply(USER, [
        reminderChange({ remindAt: null, baseVersion: 3 }),
      ]);

      expect(results[0]).toMatchObject({
        status: 'conflict',
        version: 7,
        serverCopy: { remindAt: '2026-09-05T18:30', version: 7 },
      });
      expect(reminderDeleteMany).not.toHaveBeenCalled();
    });

    it('conflicts when the push carries no baseVersion at all', async () => {
      grantAccess();
      reminderRow = stored();

      const results = await service.apply(USER, [
        reminderChange({ remindAt: '2026-09-09T07:00' }),
      ]);

      expect(results[0].status).toBe('conflict');
      expect(reminderUpdateMany).not.toHaveBeenCalled();
    });

    it('bumps the version and emits on an accepted edit', async () => {
      grantAccess();
      reminderRow = stored();

      const results = await service.apply(USER, [
        reminderChange({
          remindAt: '2026-09-09T07:00',
          recurrence: 'daily',
          baseVersion: 3,
        }),
      ]);

      expect(results).toEqual([
        { type: 'reminder', id: 'n1', status: 'applied', version: 4 },
      ]);
      expect(reminderUpdateMany).toHaveBeenCalledWith({
        where: { userId: USER, noteId: 'n1', version: 3 },
        data: { remindAt: '2026-09-09T07:00', recurrence: 'daily', version: 4 },
      });
    });

    it('clears the reminder and emits a remove', async () => {
      grantAccess();
      reminderRow = stored();

      const results = await service.apply(USER, [
        reminderChange({ remindAt: null, baseVersion: 3 }),
      ]);

      expect(results[0].status).toBe('applied');
      expect(emitter.emit).toHaveBeenCalledWith(prisma, [
        expect.objectContaining({ entityType: 'reminder', op: 'remove' }),
      ]);
    });

    it('conflicts when the guarded write matches no row', async () => {
      grantAccess();
      reminderRow = stored();
      reminderWriteCount = 0;

      const results = await service.apply(USER, [
        reminderChange({ remindAt: '2026-09-09T07:00', baseVersion: 3 }),
      ]);

      expect(results[0].status).toBe('conflict');
      expect(emitter.emit).not.toHaveBeenCalled();
    });
  });
});
