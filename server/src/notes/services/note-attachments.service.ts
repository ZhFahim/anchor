import {
  Inject,
  Injectable,
  NotFoundException,
  BadRequestException,
  Logger,
} from '@nestjs/common';
import type { ConfigType } from '@nestjs/config';
import type { Prisma } from 'src/generated/prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { NoteAccessService } from './note-access.service';
import {
  SyncEmitterService,
  attachmentsEmissions,
  noteEmissions,
} from '../../sync/sync-emitter.service';
import { NoteSharePermission } from 'src/generated/prisma/enums';
import { StorageConfig } from '../../config/configuration';
import { deleteFileIfExists } from '../../common/utils/file-system.util';
import {
  assertValidAttachmentFile,
  attachmentTypeForMime,
  writeAttachmentFile,
} from '../utils/attachment-storage.util';
import { toAttachmentResponse } from '../dto/attachment-response.dto';
import * as fs from 'fs/promises';
import * as path from 'path';
import { createReadStream, existsSync } from 'fs';

@Injectable()
export class NoteAttachmentsService {
  private readonly logger = new Logger(NoteAttachmentsService.name);

  constructor(
    private prisma: PrismaService,
    private noteAccessService: NoteAccessService,
    private syncEmitter: SyncEmitterService,
    @Inject(StorageConfig.KEY)
    private storageConfig: ConfigType<typeof StorageConfig>,
  ) {}

  private attachmentDir(noteId: string): string {
    return path.join(this.storageConfig.attachmentsDir, noteId);
  }

  private async emitAttachmentChange(
    tx: Prisma.TransactionClient,
    noteId: string,
  ): Promise<void> {
    await tx.note.update({
      where: { id: noteId },
      data: { updatedAt: new Date() },
    });
    const recipients = await this.syncEmitter.noteRecipients(tx, noteId);
    await this.syncEmitter.emit(tx, [
      ...noteEmissions(recipients, noteId),
      ...attachmentsEmissions(recipients, noteId),
    ]);
  }

  private attachmentPath(noteId: string, storedFilename: string): string {
    return path.join(this.storageConfig.attachmentsDir, noteId, storedFilename);
  }

  async upload(userId: string, noteId: string, file: Express.Multer.File) {
    await this.noteAccessService.ensureNoteAccess(
      userId,
      noteId,
      NoteSharePermission.editor,
    );
    await this.noteAccessService.ensureNoteIsActive(noteId);

    assertValidAttachmentFile(file);

    const attachmentType = attachmentTypeForMime(file.mimetype);

    let stored: { storedFilename: string; filePath: string } | null = null;
    try {
      stored = await writeAttachmentFile(
        this.attachmentDir(noteId),
        file.originalname,
        file.buffer,
      );
      const { storedFilename } = stored;

      const attachment = await this.prisma.$transaction(async (tx) => {
        // Shift all existing attachments down to make room at position 0
        await tx.noteAttachment.updateMany({
          where: { noteId },
          data: { position: { increment: 1 } },
        });

        const created = await tx.noteAttachment.create({
          data: {
            noteId,
            uploadedByUserId: userId,
            type: attachmentType,
            originalFilename: file.originalname,
            storedFilename,
            mimeType: file.mimetype,
            fileSize: file.size,
            position: 0,
          },
        });

        await this.emitAttachmentChange(tx, noteId);

        return created;
      });

      return toAttachmentResponse(attachment);
    } catch {
      if (stored) {
        await deleteFileIfExists(stored.filePath, this.logger);
      }
      throw new BadRequestException('Failed to upload attachment');
    }
  }

  async findAll(userId: string, noteId: string) {
    const access = await this.noteAccessService.hasNoteAccess(userId, noteId);
    if (!access.hasAccess) {
      throw new NotFoundException('Note not found');
    }

    const attachments = await this.prisma.noteAttachment.findMany({
      where: { noteId },
      orderBy: { position: 'asc' },
    });

    return attachments.map(toAttachmentResponse);
  }

  async serveFile(userId: string, noteId: string, attachmentId: string) {
    const access = await this.noteAccessService.hasNoteAccess(userId, noteId);
    if (!access.hasAccess) {
      throw new NotFoundException('Note not found');
    }

    const attachment = await this.prisma.noteAttachment.findFirst({
      where: { id: attachmentId, noteId },
    });

    if (!attachment) {
      throw new NotFoundException('Attachment not found');
    }

    const filePath = this.attachmentPath(noteId, attachment.storedFilename);
    if (!existsSync(filePath)) {
      throw new NotFoundException('Attachment file not found');
    }

    const stream = createReadStream(filePath);
    return { stream, attachment };
  }

  async remove(userId: string, noteId: string, attachmentId: string) {
    await this.noteAccessService.ensureNoteIsActive(noteId);

    const attachment = await this.prisma.noteAttachment.findFirst({
      where: { id: attachmentId, noteId },
    });

    if (!attachment) {
      throw new NotFoundException('Attachment not found');
    }

    // Owner can delete any attachment; editors can delete their own uploads
    const access = await this.noteAccessService.hasNoteAccess(
      userId,
      noteId,
      NoteSharePermission.editor,
    );
    if (!access.hasAccess) {
      throw new NotFoundException('Note not found');
    }
    if (!access.isOwner && attachment.uploadedByUserId !== userId) {
      throw new BadRequestException(
        'You can only delete attachments you uploaded',
      );
    }

    await this.prisma.$transaction(async (tx) => {
      await tx.noteAttachment.delete({ where: { id: attachmentId } });

      await this.emitAttachmentChange(tx, noteId);
    });

    const filePath = this.attachmentPath(noteId, attachment.storedFilename);
    await deleteFileIfExists(filePath, this.logger);

    return { success: true };
  }

  async reorder(userId: string, noteId: string, orderedIds: string[]) {
    await this.noteAccessService.ensureNoteAccess(
      userId,
      noteId,
      NoteSharePermission.editor,
    );
    await this.noteAccessService.ensureNoteIsActive(noteId);

    const attachments = await this.prisma.noteAttachment.findMany({
      where: { noteId },
    });

    const attachmentIds = new Set(attachments.map((a) => a.id));
    if (orderedIds.length !== attachments.length) {
      throw new BadRequestException(
        'Reorder must include exactly all attachment IDs for the note',
      );
    }
    for (const id of orderedIds) {
      if (!attachmentIds.has(id)) {
        throw new BadRequestException(`Attachment ${id} not found in note`);
      }
    }

    await this.prisma.$transaction(async (tx) => {
      for (const [index, id] of orderedIds.entries()) {
        await tx.noteAttachment.update({
          where: { id },
          data: { position: index },
        });
      }

      await this.emitAttachmentChange(tx, noteId);
    });

    return this.findAll(userId, noteId);
  }

  async deleteAllForNote(noteId: string) {
    const noteDir = this.attachmentDir(noteId);
    try {
      await fs.rm(noteDir, { recursive: true, force: true });
    } catch (error) {
      // Directory may not exist, log only if it's not ENOENT
      if ((error as NodeJS.ErrnoException).code !== 'ENOENT') {
        this.logger.error(
          `Failed to delete attachments directory for note ${noteId}: ${String(error)}`,
        );
      }
    }
  }
}
