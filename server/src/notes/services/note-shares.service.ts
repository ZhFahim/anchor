import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { ShareNoteDto } from '../dto/share-note.dto';
import { UpdateNoteSharePermissionDto } from '../dto/update-share-permission.dto';
import { NoteAccessService } from './note-access.service';
import {
  SHARED_WITH_USER_SELECT,
  ERROR_MESSAGES,
} from '../constants/notes.constants';

@Injectable()
export class NoteSharesService {
  constructor(
    private prisma: PrismaService,
    private noteAccessService: NoteAccessService,
  ) { }

  async shareNote(ownerId: string, noteId: string, shareNoteDto: ShareNoteDto) {
    const { sharedWithUserId, permission } = shareNoteDto;

    await this.noteAccessService.verifyNoteOwnership(ownerId, noteId);

    if (sharedWithUserId === ownerId) {
      throw new BadRequestException(ERROR_MESSAGES.CANNOT_SHARE_WITH_SELF);
    }

    const user = await this.prisma.user.findUnique({
      where: { id: sharedWithUserId },
    });

    if (!user) {
      throw new NotFoundException(ERROR_MESSAGES.USER_NOT_FOUND);
    }

    const existingShare = await this.prisma.noteShare.findUnique({
      where: {
        noteId_sharedWithUserId: {
          noteId,
          sharedWithUserId,
        },
      },
    });

    if (existingShare) {
      const updated = await this.prisma.noteShare.update({
        where: { id: existingShare.id },
        data: {
          permission,
          isDeleted: false, // Reactivate if it was soft-deleted
        },
        include: {
          sharedWithUser: {
            select: SHARED_WITH_USER_SELECT,
          },
        },
      });

      return {
        id: updated.id,
        sharedWithUser: updated.sharedWithUser,
        permission: updated.permission,
        createdAt: updated.createdAt.toISOString(),
        updatedAt: updated.updatedAt.toISOString(),
      };
    }

    const created = await this.prisma.noteShare.create({
      data: {
        noteId,
        sharedWithUserId,
        permission,
        sharedByUserId: ownerId,
      },
      include: {
        sharedWithUser: {
          select: SHARED_WITH_USER_SELECT,
        },
      },
    });

    return {
      id: created.id,
      sharedWithUser: created.sharedWithUser,
      permission: created.permission,
      createdAt: created.createdAt.toISOString(),
      updatedAt: created.updatedAt.toISOString(),
    };
  }

  async getNoteShares(noteId: string, ownerId: string) {
    await this.noteAccessService.verifyNoteOwnership(ownerId, noteId);

    const shares = await this.prisma.noteShare.findMany({
      where: {
        noteId,
        isDeleted: false,
      },
      include: {
        sharedWithUser: {
          select: SHARED_WITH_USER_SELECT,
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    // Transform to simplified format (remove noteId, sharedByUser)
    return shares.map((share) => ({
      id: share.id,
      sharedWithUser: share.sharedWithUser,
      permission: share.permission,
      createdAt: share.createdAt.toISOString(),
      updatedAt: share.updatedAt.toISOString(),
    }));
  }

  async updateNoteSharePermission(
    noteId: string,
    shareId: string,
    ownerId: string,
    updateDto: UpdateNoteSharePermissionDto,
  ) {
    await this.noteAccessService.verifyNoteOwnership(ownerId, noteId);

    const share = await this.prisma.noteShare.findUnique({
      where: { id: shareId },
    });

    if (!share || share.isDeleted) {
      throw new NotFoundException(ERROR_MESSAGES.SHARE_NOT_FOUND);
    }

    if (share.noteId !== noteId) {
      throw new NotFoundException(ERROR_MESSAGES.SHARE_NOT_FOUND);
    }

    const updated = await this.prisma.noteShare.update({
      where: { id: shareId },
      data: { permission: updateDto.permission },
      include: {
        sharedWithUser: {
          select: SHARED_WITH_USER_SELECT,
        },
      },
    });

    return {
      id: updated.id,
      sharedWithUser: updated.sharedWithUser,
      permission: updated.permission,
      createdAt: updated.createdAt.toISOString(),
      updatedAt: updated.updatedAt.toISOString(),
    };
  }

  async revokeShare(noteId: string, shareId: string, ownerId: string) {
    await this.noteAccessService.verifyNoteOwnership(ownerId, noteId);

    const share = await this.prisma.noteShare.findUnique({
      where: { id: shareId },
    });

    if (!share || share.isDeleted) {
      throw new NotFoundException(ERROR_MESSAGES.SHARE_NOT_FOUND);
    }

    if (share.noteId !== noteId) {
      throw new NotFoundException(ERROR_MESSAGES.SHARE_NOT_FOUND);
    }

    await this.prisma.noteShare.update({
      where: { id: shareId },
      data: { isDeleted: true },
    });

    return { success: true };
  }
}
