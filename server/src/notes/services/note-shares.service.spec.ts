import { beforeEach, describe, expect, it, vi } from 'vitest';
import { Prisma } from '../../generated/prisma/client';
import { NoteSharesService } from './note-shares.service';
import { NoteAccessService } from './note-access.service';
import { PrismaService } from '../../prisma/prisma.service';
import { createMockSyncEmitter, asSyncEmitter } from '../../../test/sync-mocks';

describe('NoteSharesService.shareNote', () => {
  const NOTE_ID = 'note-1';
  const OWNER = 'user-owner';
  const PARTNER = 'user-partner';

  const partner = {
    id: PARTNER,
    name: 'Pat',
    email: 'pat@example.com',
    profileImage: null,
  };
  const storedShare = {
    id: 'share-1',
    noteId: NOTE_ID,
    sharedWithUserId: PARTNER,
    permission: 'editor',
    isDeleted: false,
    createdAt: new Date('2026-09-01T10:00:00Z'),
    updatedAt: new Date('2026-09-01T10:00:00Z'),
    sharedWithUser: partner,
  };

  const uniqueViolation = () =>
    new Prisma.PrismaClientKnownRequestError('Unique constraint failed', {
      code: 'P2002',
      clientVersion: 'test',
    });

  const prisma = {
    $transaction: vi.fn((write: (tx: unknown) => unknown) =>
      Promise.resolve().then(() => write(prisma)),
    ),
    user: { findUnique: vi.fn() },
    noteShare: {
      findUnique: vi.fn(),
      create: vi.fn(),
      update: vi.fn(),
    },
  };

  const noteAccess = {
    verifyNoteOwnership: vi.fn().mockResolvedValue(undefined),
  } as unknown as NoteAccessService;

  const service = new NoteSharesService(
    prisma as unknown as PrismaService,
    noteAccess,
    asSyncEmitter(createMockSyncEmitter()),
  );

  beforeEach(() => {
    vi.clearAllMocks();
    prisma.user.findUnique.mockResolvedValue(partner);
  });

  it('creates a new share', async () => {
    prisma.noteShare.findUnique.mockResolvedValue(null);
    prisma.noteShare.create.mockResolvedValue(storedShare);

    const share = await service.shareNote(OWNER, NOTE_ID, {
      sharedWithUserId: PARTNER,
      permission: 'editor',
    });

    expect(share.id).toBe('share-1');
    expect(prisma.noteShare.create).toHaveBeenCalledTimes(1);
  });

  it('returns the existing share when a racing request created it first', async () => {
    // Both requests saw no share; this one loses the insert.
    prisma.noteShare.findUnique
      .mockResolvedValueOnce(null)
      .mockResolvedValueOnce(storedShare);
    prisma.noteShare.create.mockRejectedValue(uniqueViolation());

    const share = await service.shareNote(OWNER, NOTE_ID, {
      sharedWithUserId: PARTNER,
      permission: 'editor',
    });

    expect(share).toEqual({
      id: 'share-1',
      sharedWithUser: partner,
      permission: 'editor',
      createdAt: '2026-09-01T10:00:00.000Z',
      updatedAt: '2026-09-01T10:00:00.000Z',
    });
  });

  it('still fails on other errors', async () => {
    prisma.noteShare.findUnique.mockResolvedValue(null);
    prisma.noteShare.create.mockRejectedValue(new Error('database down'));

    await expect(
      service.shareNote(OWNER, NOTE_ID, {
        sharedWithUserId: PARTNER,
        permission: 'editor',
      }),
    ).rejects.toThrow('database down');
  });

  it('reactivates a share that was removed', async () => {
    prisma.noteShare.findUnique.mockResolvedValue({
      ...storedShare,
      isDeleted: true,
    });
    prisma.noteShare.update.mockResolvedValue(storedShare);

    await service.shareNote(OWNER, NOTE_ID, {
      sharedWithUserId: PARTNER,
      permission: 'viewer',
    });

    expect(prisma.noteShare.update).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: 'share-1' },
        data: { permission: 'viewer', isDeleted: false },
      }),
    );
    expect(prisma.noteShare.create).not.toHaveBeenCalled();
  });
});
