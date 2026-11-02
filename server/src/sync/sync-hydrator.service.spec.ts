import { beforeEach, describe, expect, it, vi } from 'vitest';
import { PrismaService } from '../prisma/prisma.service';
import {
  NoteSharePermission,
  NoteState,
  SyncEntityType,
  SyncOp,
} from 'src/generated/prisma/enums';
import { SyncHydratorService, SyncFeedRow } from './sync-hydrator.service';

/**
 * Payload assembly through transformNote, and the
 * missing/tombstoned/inaccessible -> remove rule.
 */
describe('SyncHydratorService', () => {
  const USER = 'user-1';
  const OTHER = 'user-2';
  const AT = new Date('2026-08-01T00:00:00.000Z');

  let service: SyncHydratorService;
  let notes: unknown[];
  let tags: unknown[];
  let attachments: unknown[];

  const noteFindMany = vi.fn(() => Promise.resolve(notes));
  const tagFindMany = vi.fn(() => Promise.resolve(tags));
  const attachmentFindMany = vi.fn(() => Promise.resolve(attachments));

  const prisma = {
    note: { findMany: noteFindMany },
    tag: { findMany: tagFindMany },
    noteAttachment: { findMany: attachmentFindMany },
    noteFile: { findMany: vi.fn(() => Promise.resolve([])) },
  } as unknown as PrismaService;

  const makeNote = (overrides: Record<string, unknown> & { id: string }) => ({
    title: `title-${overrides.id}`,
    content: null,
    version: 1,
    background: null,
    state: NoteState.active,
    createdAt: AT,
    updatedAt: AT,
    userId: USER,
    pins: [],
    archives: [],
    tags: [],
    sharedWith: [],
    _count: { attachments: 0 },
    attachments: [],
    ...overrides,
  });

  const makeTag = (overrides: Record<string, unknown> & { id: string }) => ({
    name: `name-${overrides.id}`,
    color: null,
    userId: USER,
    isDeleted: false,
    version: 1,
    createdAt: AT,
    updatedAt: AT,
    ...overrides,
  });

  const row = (
    entityType: SyncEntityType,
    entityId: string,
    op: SyncOp = SyncOp.upsert,
    seq = 1n,
  ): SyncFeedRow => ({ seq, entityType, entityId, op });

  beforeEach(() => {
    service = new SyncHydratorService(prisma);
    notes = [];
    tags = [];
    attachments = [];
    vi.clearAllMocks();
  });

  it('hydrates a note upsert through transformNote, version included', async () => {
    notes = [makeNote({ id: 'n1', content: 'body', version: 4 })];

    const entries = await service.hydrate(USER, [
      row(SyncEntityType.note, 'n1', SyncOp.upsert, 7n),
    ]);

    expect(entries).toHaveLength(1);
    expect(entries[0]).toMatchObject({
      seq: '7',
      entityType: SyncEntityType.note,
      entityId: 'n1',
      op: 'upsert',
    });
    expect(entries[0].note).toMatchObject({
      id: 'n1',
      content: 'body',
      version: 4,
      permission: 'owner',
      isPinned: false,
      createdAt: AT.toISOString(),
    });
  });

  it('hydrates missing and tombstoned notes as removes', async () => {
    notes = [makeNote({ id: 'n-dead', state: NoteState.deleted })];

    const entries = await service.hydrate(USER, [
      row(SyncEntityType.note, 'n-gone'),
      row(SyncEntityType.note, 'n-dead'),
    ]);

    expect(entries).toEqual([
      expect.objectContaining({ entityId: 'n-gone', op: 'remove' }),
      expect.objectContaining({ entityId: 'n-dead', op: 'remove' }),
    ]);
    expect(entries[1]).not.toHaveProperty('note');
  });

  it("hydrates someone else's note only through an active share", async () => {
    const share = {
      id: 'share-1',
      permission: NoteSharePermission.editor,
      sharedWithUserId: USER,
      sharedByUser: {
        id: OTHER,
        name: 'Other',
        email: 'other@example.com',
        profileImage: null,
      },
    };
    notes = [
      makeNote({ id: 'n-shared', userId: OTHER, sharedWith: [share] }),
      makeNote({ id: 'n-foreign', userId: OTHER }),
    ];

    const entries = await service.hydrate(USER, [
      row(SyncEntityType.note, 'n-shared'),
      row(SyncEntityType.note, 'n-foreign'),
    ]);

    expect(entries[0].op).toBe('upsert');
    expect(entries[0].note).toMatchObject({ permission: 'editor' });
    expect(entries[1]).toEqual(
      expect.objectContaining({ entityId: 'n-foreign', op: 'remove' }),
    );
  });

  it('hydrates live tags and turns deleted or missing tags into removes', async () => {
    tags = [
      makeTag({ id: 't1', name: 'work', version: 2 }),
      makeTag({ id: 't-dead', isDeleted: true }),
    ];

    const entries = await service.hydrate(USER, [
      row(SyncEntityType.tag, 't1'),
      row(SyncEntityType.tag, 't-dead'),
      row(SyncEntityType.tag, 't-gone'),
    ]);

    expect(entries[0]).toEqual(
      expect.objectContaining({
        op: 'upsert',
        tag: {
          id: 't1',
          name: 'work',
          color: null,
          version: 2,
          createdAt: AT.toISOString(),
          updatedAt: AT.toISOString(),
        },
      }),
    );
    expect(entries[1].op).toBe('remove');
    expect(entries[2].op).toBe('remove');
  });

  it('inlines attachment metadata for accessible notes only', async () => {
    notes = [makeNote({ id: 'n1' })];
    attachments = [
      {
        id: 'a1',
        noteId: 'n1',
        type: 'image',
        originalFilename: 'a.png',
        mimeType: 'image/png',
        fileSize: 42,
        position: 0,
        uploadedByUserId: USER,
        createdAt: AT,
      },
    ];

    const entries = await service.hydrate(USER, [
      row(SyncEntityType.attachments, 'n1'),
      row(SyncEntityType.attachments, 'n-gone'),
    ]);

    expect(entries[0].attachments).toEqual([
      expect.objectContaining({ id: 'a1', noteId: 'n1', position: 0 }),
    ]);
    expect(entries[1].op).toBe('remove');
    // The invisible note is not even queried for.
    expect(attachmentFindMany).toHaveBeenCalledTimes(1);
    expect(attachmentFindMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { noteId: { in: ['n1'] } },
      }),
    );
  });

  it('pin upserts carry no payload and follow note visibility', async () => {
    notes = [makeNote({ id: 'n1' })];

    const entries = await service.hydrate(USER, [
      row(SyncEntityType.pin, 'n1'),
      row(SyncEntityType.pin, 'n-gone'),
    ]);

    expect(entries[0]).toEqual({
      seq: '1',
      entityType: SyncEntityType.pin,
      entityId: 'n1',
      op: 'upsert',
    });
    expect(entries[1].op).toBe('remove');
  });

  it('passes remove rows through without fetching anything', async () => {
    const entries = await service.hydrate(USER, [
      row(SyncEntityType.note, 'n1', SyncOp.remove, 3n),
      row(SyncEntityType.tag, 't1', SyncOp.remove, 4n),
    ]);

    expect(entries).toEqual([
      {
        seq: '3',
        entityType: SyncEntityType.note,
        entityId: 'n1',
        op: 'remove',
      },
      {
        seq: '4',
        entityType: SyncEntityType.tag,
        entityId: 't1',
        op: 'remove',
      },
    ]);
    expect(noteFindMany).not.toHaveBeenCalled();
    expect(tagFindMany).not.toHaveBeenCalled();
    expect(attachmentFindMany).not.toHaveBeenCalled();
  });

  it('batches all note and tag lookups into one query each', async () => {
    notes = [makeNote({ id: 'n1' }), makeNote({ id: 'n2' })];
    tags = [makeTag({ id: 't1' })];

    await service.hydrate(USER, [
      row(SyncEntityType.note, 'n1'),
      row(SyncEntityType.note, 'n2'),
      row(SyncEntityType.pin, 'n1'),
      row(SyncEntityType.tag, 't1'),
    ]);

    expect(noteFindMany).toHaveBeenCalledTimes(1);
    expect(tagFindMany).toHaveBeenCalledTimes(1);
  });
});
