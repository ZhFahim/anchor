import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { NoteSharePermission } from 'src/generated/prisma/enums';

export interface NoteAccessResult {
  hasAccess: boolean;
  isOwner: boolean;
  permission?: NoteSharePermission | 'owner';
}

@Injectable()
export class NoteAccessService {
  constructor(private prisma: PrismaService) { }

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
      return { hasAccess: true, isOwner: true, permission: 'owner' };
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
          };
        }
      }
      // Viewer permission is sufficient for read access
    }

    return {
      hasAccess: true,
      isOwner: false,
      permission: share.permission,
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
      throw new NotFoundException('Note not found');
    }

    if (note.userId !== userId) {
      throw new ForbiddenException('Only note owner can perform this action');
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
        throw new ForbiddenException('Viewers cannot edit notes');
      }
      throw new NotFoundException('Note not found');
    }

    return access;
  }
}
