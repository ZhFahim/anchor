import { Inject, Injectable, Logger } from '@nestjs/common';
import type { ConfigType } from '@nestjs/config';
import * as path from 'path';
import { deleteFileIfExists } from '../common/utils/file-system.util';
import { StorageConfig } from '../config/configuration';
import { removeNoteAttachmentDir } from '../notes/utils/attachment-storage.util';
import { PrismaService } from '../prisma/prisma.service';
import {
  noteEmissions,
  SyncEmitterService,
} from '../sync/sync-emitter.service';
import { SyncEventsService } from '../sync/sync-events.service';

const DELETION_TIMEOUT_MS = 60_000;

@Injectable()
export class UserDeletionService {
  private readonly logger = new Logger(UserDeletionService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly syncEmitter: SyncEmitterService,
    private readonly syncEvents: SyncEventsService,
    @Inject(StorageConfig.KEY)
    private readonly storageConfig: ConfigType<typeof StorageConfig>,
  ) {}

  // The database cascade removes the user's own rows.
  async deleteUser(userId: string): Promise<void> {
    const { profileImage, ownedNoteIds } = await this.prisma.$transaction(
      async (tx) => {
        const { profileImage } = await tx.user.findUniqueOrThrow({
          where: { id: userId },
          select: { profileImage: true },
        });
        const ownedNotes = await tx.note.findMany({
          where: { userId },
          select: {
            id: true,
            sharedWith: {
              where: { isDeleted: false },
              select: { sharedWithUserId: true },
            },
          },
        });
        const sharesWithUser = await tx.noteShare.findMany({
          where: { sharedWithUserId: userId, isDeleted: false },
          select: { noteId: true },
        });
        const recipientsOfSharedNotes = await this.syncEmitter.notesRecipients(
          tx,
          sharesWithUser.map((share) => share.noteId),
        );

        await this.syncEmitter.removeNotes(
          tx,
          new Map(
            ownedNotes
              .filter((note) => note.sharedWith.length > 0)
              .map((note) => [
                note.id,
                note.sharedWith.map((share) => share.sharedWithUserId),
              ]),
          ),
          [...recipientsOfSharedNotes].flatMap(([noteId, recipients]) =>
            noteEmissions(
              recipients.filter((recipient) => recipient !== userId),
              noteId,
            ),
          ),
        );

        const attachmentsOnOtherNotes = await tx.noteAttachment.findMany({
          where: {
            uploadedByUserId: userId,
            note: { userId: { not: userId } },
          },
          select: { id: true, note: { select: { userId: true } } },
        });
        for (const attachment of attachmentsOnOtherNotes) {
          await tx.noteAttachment.update({
            where: { id: attachment.id },
            data: { uploadedByUserId: attachment.note.userId },
          });
        }

        await tx.user.delete({ where: { id: userId } });

        return {
          profileImage,
          ownedNoteIds: ownedNotes.map((note) => note.id),
        };
      },
      { timeout: DELETION_TIMEOUT_MS },
    );

    this.syncEvents.disconnect(userId);

    // Must never throw: nothing awaits it.
    void this.removeFiles(ownedNoteIds, profileImage);
  }

  private async removeFiles(
    noteIds: string[],
    profileImage: string | null,
  ): Promise<void> {
    for (const noteId of noteIds) {
      await removeNoteAttachmentDir(
        this.storageConfig.attachmentsDir,
        noteId,
        this.logger,
      );
    }
    if (profileImage) {
      await deleteFileIfExists(
        path.join(this.storageConfig.root, profileImage),
        this.logger,
      );
    }
  }
}
