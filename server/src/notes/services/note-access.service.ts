import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { NoteSharePermission, NoteState } from 'src/generated/prisma/enums';
import { coded } from '../../common/errors/coded';
import { ErrorCode } from '../../common/errors/error-code';

export interface NoteAccessResult {
  hasAccess: boolean;
  isOwner: boolean;
  permission?: NoteSharePermission | 'owner';
  state?: NoteState;
}

@Injectable()
export class NoteAccessService {
  constructor(private prisma: PrismaService) {}

  /**
   * Check if user has access to a note and return permission info
   */
  async hasNoteAccess(
    userId: string,
    noteId: string,
    requiredPermission?: NoteSharePermission,
  ): Promise<NoteAccessResult> {
    const note = await this.prisma.note.findUnique({
      where: { id: noteId },
    });

    if (!note) {
      return { hasAccess: false, isOwner: false };
    }

    // Check if user is owner
    if (note.userId === userId) {
      return {
        hasAccess: true,
        isOwner: true,
        permission: 'owner',
        state: note.state,
      };
    }

    // Check if user has share access
    const share = await this.prisma.noteShare.findUnique({
      where: {
        noteId_sharedWithUserId: {
          noteId,
          sharedWithUserId: userId,
        },
      },
    });

    if (!share || share.isDeleted) {
      return { hasAccess: false, isOwner: false };
    }

    // Check if required permission is met
    if (requiredPermission) {
      if (requiredPermission === NoteSharePermission.editor) {
        // Editor permission required
        if (share.permission !== NoteSharePermission.editor) {
          return {
            hasAccess: false,
            isOwner: false,
            permission: share.permission,
            state: note.state,
          };
        }
      }
      // Viewer permission is sufficient for read access
    }

    return {
      hasAccess: true,
      isOwner: false,
      permission: share.permission,
      state: note.state,
    };
  }

  /**
   * Verify that user is the owner of a note, throws if not
   */
  async verifyNoteOwnership(userId: string, noteId: string): Promise<void> {
    const note = await this.prisma.note.findUnique({
      where: { id: noteId },
    });

    if (!note) {
      throw coded(
        new NotFoundException('Note not found'),
        ErrorCode.NOTE_NOT_FOUND,
      );
    }

    if (note.userId !== userId) {
      throw coded(
        new ForbiddenException('Only note owner can perform this action'),
        ErrorCode.NOT_NOTE_OWNER,
      );
    }
  }

  /**
   * Ensure user has access to a note, throws if not
   */
  async ensureNoteAccess(
    userId: string,
    noteId: string,
    requiredPermission?: NoteSharePermission,
  ): Promise<NoteAccessResult> {
    const access = await this.hasNoteAccess(userId, noteId, requiredPermission);

    if (!access.hasAccess) {
      if (
        access.permission === NoteSharePermission.viewer &&
        requiredPermission === NoteSharePermission.editor
      ) {
        throw coded(
          new ForbiddenException('Viewers cannot edit notes'),
          ErrorCode.VIEWER_CANNOT_EDIT,
        );
      }
      throw coded(
        new NotFoundException('Note not found'),
        ErrorCode.NOTE_NOT_FOUND,
      );
    }

    return access;
  }

  /**
   * Ensure the note is in active state (not trashed, deleted, etc.).
   */
  async ensureNoteIsActive(noteId: string): Promise<void> {
    const note = await this.prisma.note.findUnique({
      where: { id: noteId },
      select: { state: true },
    });
    if (!note || note.state !== NoteState.active) {
      throw coded(
        new BadRequestException(
          'Cannot modify this note. Only active notes can be edited.',
        ),
        ErrorCode.NOTE_NOT_ACTIVE,
      );
    }
  }
}
