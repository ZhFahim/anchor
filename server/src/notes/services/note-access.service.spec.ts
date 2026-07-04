import {
  BadRequestException,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import { NoteAccessService } from './note-access.service';
import { PrismaService } from '../../prisma/prisma.service';

/**
 * Access-control matrix for notes: owner / editor share / viewer share /
 * revoked share / no share. Every notes endpoint funnels through this
 * service, so the rules are pinned down exhaustively here.
 */
describe('NoteAccessService', () => {
  const NOTE_ID = 'note-1';
  const OWNER = 'user-owner';
  const STRANGER = 'user-stranger';

  let note: { id: string; userId: string; state: string } | null;
  let shares: Map<
    string,
    { permission: 'viewer' | 'editor'; isDeleted: boolean }
  >;

  const prisma = {
    note: {
      findUnique: jest.fn(() => Promise.resolve(note)),
    },
    noteShare: {
      findUnique: jest.fn(
        ({
          where,
        }: {
          where: {
            noteId_sharedWithUserId: {
              noteId: string;
              sharedWithUserId: string;
            };
          };
        }) =>
          Promise.resolve(
            shares.get(where.noteId_sharedWithUserId.sharedWithUserId) ?? null,
          ),
      ),
    },
  } as unknown as PrismaService;

  const service = new NoteAccessService(prisma);

  beforeEach(() => {
    note = { id: NOTE_ID, userId: OWNER, state: 'active' };
    shares = new Map();
    jest.clearAllMocks();
  });

  describe('hasNoteAccess', () => {
    it('denies access to a missing note', async () => {
      note = null;
      const access = await service.hasNoteAccess(OWNER, NOTE_ID);
      expect(access).toEqual({ hasAccess: false, isOwner: false });
    });

    it('grants the owner full access', async () => {
      const access = await service.hasNoteAccess(OWNER, NOTE_ID);
      expect(access).toEqual({
        hasAccess: true,
        isOwner: true,
        permission: 'owner',
      });
    });

    it('denies a user with no share', async () => {
      const access = await service.hasNoteAccess(STRANGER, NOTE_ID);
      expect(access.hasAccess).toBe(false);
    });

    it('denies a user whose share was revoked', async () => {
      shares.set(STRANGER, { permission: 'editor', isDeleted: true });
      const access = await service.hasNoteAccess(STRANGER, NOTE_ID);
      expect(access.hasAccess).toBe(false);
    });

    it('grants a viewer read access', async () => {
      shares.set(STRANGER, { permission: 'viewer', isDeleted: false });
      const access = await service.hasNoteAccess(STRANGER, NOTE_ID);
      expect(access).toEqual({
        hasAccess: true,
        isOwner: false,
        permission: 'viewer',
      });
    });

    it('denies a viewer when editor permission is required', async () => {
      shares.set(STRANGER, { permission: 'viewer', isDeleted: false });
      const access = await service.hasNoteAccess(STRANGER, NOTE_ID, 'editor');
      expect(access).toEqual({
        hasAccess: false,
        isOwner: false,
        permission: 'viewer',
      });
    });

    it('grants an editor when editor permission is required', async () => {
      shares.set(STRANGER, { permission: 'editor', isDeleted: false });
      const access = await service.hasNoteAccess(STRANGER, NOTE_ID, 'editor');
      expect(access).toEqual({
        hasAccess: true,
        isOwner: false,
        permission: 'editor',
      });
    });
  });

  describe('verifyNoteOwnership', () => {
    it('throws NotFound for a missing note', async () => {
      note = null;
      await expect(service.verifyNoteOwnership(OWNER, NOTE_ID)).rejects.toThrow(
        NotFoundException,
      );
    });

    it('throws Forbidden for a non-owner, even with an editor share', async () => {
      shares.set(STRANGER, { permission: 'editor', isDeleted: false });
      await expect(
        service.verifyNoteOwnership(STRANGER, NOTE_ID),
      ).rejects.toThrow(ForbiddenException);
    });

    it('passes for the owner', async () => {
      await expect(
        service.verifyNoteOwnership(OWNER, NOTE_ID),
      ).resolves.toBeUndefined();
    });
  });

  describe('ensureNoteAccess', () => {
    it('throws Forbidden (not NotFound) when a viewer tries to edit', async () => {
      shares.set(STRANGER, { permission: 'viewer', isDeleted: false });
      await expect(
        service.ensureNoteAccess(STRANGER, NOTE_ID, 'editor'),
      ).rejects.toThrow(ForbiddenException);
    });

    it('throws NotFound for a user with no access, hiding note existence', async () => {
      await expect(service.ensureNoteAccess(STRANGER, NOTE_ID)).rejects.toThrow(
        NotFoundException,
      );
    });

    it('returns the access result when allowed', async () => {
      shares.set(STRANGER, { permission: 'editor', isDeleted: false });
      const access = await service.ensureNoteAccess(
        STRANGER,
        NOTE_ID,
        'editor',
      );
      expect(access.hasAccess).toBe(true);
    });
  });

  describe('ensureNoteIsActive', () => {
    it.each(['trashed', 'deleted'])('rejects a %s note', async (state) => {
      note = { id: NOTE_ID, userId: OWNER, state };
      await expect(service.ensureNoteIsActive(NOTE_ID)).rejects.toThrow(
        BadRequestException,
      );
    });

    it('rejects a missing note', async () => {
      note = null;
      await expect(service.ensureNoteIsActive(NOTE_ID)).rejects.toThrow(
        BadRequestException,
      );
    });

    it('passes for an active note', async () => {
      await expect(
        service.ensureNoteIsActive(NOTE_ID),
      ).resolves.toBeUndefined();
    });
  });
});
