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
  SyncEmitterService,
  noteEmissions,
  attachmentsEmissions,
} from '../../sync/sync-emitter.service';
import {
  SHARED_WITH_USER_SELECT,
  ERROR_MESSAGES,
} from '../constants/notes.constants';

@Injectable()
export class NoteSharesService {
  constructor(
    private prisma: PrismaService,
    private noteAccessService: NoteAccessService,
    private syncEmitter: SyncEmitterService,
  ) {}

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

    const share = await this.prisma.$transaction(async (tx) => {
      const written = existingShare
        ? await tx.noteShare.update({
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
          })
        : await tx.noteShare.create({
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

      // Resolved after the write so the new sharee is included; they also get
      // the attachments index for their first pull.
      const recipients = await this.syncEmitter.noteRecipients(tx, noteId);
      await this.syncEmitter.emit(tx, [
        ...noteEmissions(recipients, noteId),
        ...attachmentsEmissions([sharedWithUserId], noteId),
      ]);

      return written;
    });

    return {
      id: share.id,
      sharedWithUser: share.sharedWithUser,
      permission: share.permission,
      createdAt: share.createdAt.toISOString(),
      updatedAt: share.updatedAt.toISOString(),
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

    const updated = await this.prisma.$transaction(async (tx) => {
      const written = await tx.noteShare.update({
        where: { id: shareId },
        data: { permission: updateDto.permission },
        include: {
          sharedWithUser: {
            select: SHARED_WITH_USER_SELECT,
          },
        },
      });
      const recipients = await this.syncEmitter.noteRecipients(tx, noteId);
      await this.syncEmitter.emit(tx, noteEmissions(recipients, noteId));
      return written;
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

    await this.prisma.$transaction(async (tx) => {
      await tx.noteShare.update({
        where: { id: shareId },
        data: { isDeleted: true },
      });

      await tx.notePin.deleteMany({
        where: { noteId, userId: share.sharedWithUserId },
      });

      // Their reminder goes too, or it comes back on a re-share.
      await tx.noteReminder.deleteMany({
        where: { noteId, userId: share.sharedWithUserId },
      });

      // The revoked sharee gets a note remove; the rest re-pull so their share
      // lists stay fresh.
      const remaining = await this.syncEmitter.noteRecipients(tx, noteId);
      await this.syncEmitter.removeNote(
        tx,
        [share.sharedWithUserId],
        noteId,
        noteEmissions(remaining, noteId),
      );
    });

    return { success: true };
  }
}
