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
  clientAttachmentId,
  isStorableNoteId,
  noteAttachmentDir,
  writeAttachmentFile,
} from '../utils/attachment-storage.util';
import { toAttachmentResponse } from '../dto/attachment-response.dto';
import {
  type AttachmentRowInput,
  createAttachmentRow,
  createAttachmentRows,
  deleteAttachmentRow,
  findAttachmentRow,
  findAttachmentRows,
  setAttachmentPosition,
  shiftAttachmentRows,
} from '../utils/attachment-rows.util';
import { PictureTextService } from './picture-text.service';
import { PictureSearchService } from '../../picture-search/picture-search.service';
import { replaceAttachmentIds } from '../utils/inline-images.util';
import * as crypto from 'crypto';
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
    private pictureText: PictureTextService,
    private pictureSearch: PictureSearchService,
    @Inject(StorageConfig.KEY)
    private storageConfig: ConfigType<typeof StorageConfig>,
  ) {}

  private attachmentDir(noteId: string): string {
    return noteAttachmentDir(this.storageConfig.attachmentsDir, noteId);
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
    return path.join(this.attachmentDir(noteId), storedFilename);
  }

  /**
   * Stores an uploaded file. [clientId] is the id the client gave it while
   * offline (a picture placed in the note's text refers to it); it's kept
   * when free. Sending the same one again, after a reply that got lost,
   * returns the attachment made the first time.
   */
  async upload(
    userId: string,
    noteId: string,
    file: Express.Multer.File,
    clientId?: string,
  ) {
    await this.noteAccessService.ensureNoteAccess(
      userId,
      noteId,
      NoteSharePermission.editor,
    );
    await this.noteAccessService.ensureNoteIsActive(noteId);

    assertValidAttachmentFile(file);

    const id = clientAttachmentId(clientId);
    const taken = id ? await findAttachmentRow(this.prisma, id) : null;
    if (taken && taken.noteId === noteId && taken.uploadedByUserId === userId) {
      return toAttachmentResponse(taken);
    }

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
        await shiftAttachmentRows(tx, noteId);

        const created = await createAttachmentRow(tx, {
          ...(id && !taken ? { id } : {}),
          noteId,
          uploadedByUserId: userId,
          type: attachmentType,
          originalFilename: file.originalname,
          storedFilename,
          mimeType: file.mimetype,
          fileSize: file.size,
          position: 0,
        });

        await this.emitAttachmentChange(tx, noteId);

        return created;
      });

      if (attachmentType === 'image') {
        this.pictureText.kick();
        this.pictureSearch.kick();
      }
      return toAttachmentResponse(attachment);
    } catch {
      if (stored) {
        await deleteFileIfExists(stored.filePath, this.logger);
      }
      throw new BadRequestException('Failed to upload attachment');
    }
  }

  /**
   * Copies every attachment of `fromNoteId` to `toNoteId`, files included,
   * in the same order. Used by "Make a copy". Pictures placed in the copy's
   * text are pointed at their copies.
   */
  async copyAll(userId: string, fromNoteId: string, toNoteId: string) {
    const attachments = await findAttachmentRows(this.prisma, fromNoteId);
    if (attachments.length === 0) return;
    const newIds = new Map<string, string>();

    const written: string[] = [];
    try {
      const copies: AttachmentRowInput[] = [];
      for (const attachment of attachments) {
        const data = await fs.readFile(
          this.attachmentPath(fromNoteId, attachment.storedFilename),
        );
        const stored = await writeAttachmentFile(
          this.attachmentDir(toNoteId),
          attachment.originalFilename,
          data,
        );
        written.push(stored.filePath);
        const copyId = crypto.randomUUID();
        newIds.set(attachment.id, copyId);
        copies.push({
          id: copyId,
          noteId: toNoteId,
          uploadedByUserId: userId,
          type: attachment.type,
          originalFilename: attachment.originalFilename,
          storedFilename: stored.storedFilename,
          mimeType: attachment.mimeType,
          fileSize: attachment.fileSize,
          position: attachment.position,
          // Same picture, same text: no need to read it again.
          text: attachment.text,
          textReadAt: attachment.textReadAt,
        });
      }
      await this.prisma.$transaction(async (tx) => {
        await createAttachmentRows(tx, copies);
        const copy = await tx.note.findUnique({
          where: { id: toNoteId },
          select: { content: true },
        });
        const content = copy?.content
          ? replaceAttachmentIds(copy.content, newIds)
          : null;
        if (content !== null && content !== copy?.content) {
          await tx.note.update({ where: { id: toNoteId }, data: { content } });
        }
        await this.emitAttachmentChange(tx, toNoteId);
      });
    } catch (error) {
      for (const filePath of written)
        await deleteFileIfExists(filePath, this.logger);
      throw error;
    }
  }

  async findAll(userId: string, noteId: string) {
    const access = await this.noteAccessService.hasNoteAccess(userId, noteId);
    if (!access.hasAccess) {
      throw new NotFoundException('Note not found');
    }

    const attachments = await findAttachmentRows(this.prisma, noteId);

    return attachments.map(toAttachmentResponse);
  }

  async serveFile(userId: string, noteId: string, attachmentId: string) {
    const { attachment, filePath } = await this.findFile(
      userId,
      noteId,
      attachmentId,
    );
    const stream = createReadStream(filePath);
    return { stream, attachment };
  }

  /** An attachment's bytes, read whole; for files small enough to hold. */
  async readFile(userId: string, noteId: string, attachmentId: string) {
    const { attachment, filePath } = await this.findFile(
      userId,
      noteId,
      attachmentId,
    );
    return { data: await fs.readFile(filePath), attachment };
  }

  /** For a share link: the caller has already checked the link opens it. */
  async listForLink(noteId: string) {
    const attachments = await findAttachmentRows(this.prisma, noteId);
    return attachments.map(toAttachmentResponse);
  }

  /** For a share link: the caller has already checked the link opens it. */
  async serveFileForLink(noteId: string, attachmentId: string) {
    const { attachment, filePath } = await this.findNoteFile(
      noteId,
      attachmentId,
    );
    return { stream: createReadStream(filePath), attachment };
  }

  private async findFile(userId: string, noteId: string, attachmentId: string) {
    const access = await this.noteAccessService.hasNoteAccess(userId, noteId);
    if (!access.hasAccess) {
      throw new NotFoundException('Note not found');
    }
    return this.findNoteFile(noteId, attachmentId);
  }

  private async findNoteFile(noteId: string, attachmentId: string) {
    const attachment = await findAttachmentRow(
      this.prisma,
      attachmentId,
      noteId,
    );

    if (!attachment) {
      throw new NotFoundException('Attachment not found');
    }

    const filePath = this.attachmentPath(noteId, attachment.storedFilename);
    if (!existsSync(filePath)) {
      throw new NotFoundException('Attachment file not found');
    }

    return { attachment, filePath };
  }

  async remove(userId: string, noteId: string, attachmentId: string) {
    await this.noteAccessService.ensureNoteIsActive(noteId);

    const attachment = await findAttachmentRow(
      this.prisma,
      attachmentId,
      noteId,
    );

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
      await deleteAttachmentRow(tx, attachment);

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

    const attachments = await findAttachmentRows(this.prisma, noteId);

    const byId = new Map(attachments.map((a) => [a.id, a]));
    if (orderedIds.length !== attachments.length) {
      throw new BadRequestException(
        'Reorder must include exactly all attachment IDs for the note',
      );
    }
    for (const id of orderedIds) {
      if (!byId.has(id)) {
        throw new BadRequestException(`Attachment ${id} not found in note`);
      }
    }

    await this.prisma.$transaction(async (tx) => {
      for (const [index, id] of orderedIds.entries()) {
        await setAttachmentPosition(tx, byId.get(id)!, index);
      }

      await this.emitAttachmentChange(tx, noteId);
    });

    return this.findAll(userId, noteId);
  }

  async deleteAllForNote(noteId: string) {
    // A note saved with a non-UUID id (before ids were checked) has no
    // folder of its own; removing its "folder" could reach outside.
    if (!isStorableNoteId(noteId)) {
      this.logger.warn(`Not deleting files for note with bad id ${noteId}`);
      return;
    }
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
