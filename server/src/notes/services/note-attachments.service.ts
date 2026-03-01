import {
  Injectable,
  NotFoundException,
  BadRequestException,
  Logger,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { NoteAccessService } from './note-access.service';
import { NoteSharePermission, AttachmentType } from 'src/generated/prisma/enums';
import {
  ATTACHMENT_MAX_FILE_SIZE,
  ATTACHMENT_ALLOWED_MIME_TYPES,
} from '../constants/notes.constants';
import { toAttachmentResponse } from '../dto/attachment-response.dto';
import * as crypto from 'crypto';
import * as fs from 'fs/promises';
import * as path from 'path';
import { createReadStream, existsSync } from 'fs';

@Injectable()
export class NoteAttachmentsService {
  private readonly logger = new Logger(NoteAttachmentsService.name);
  private readonly baseDir = '/data/uploads/attachments';

  constructor(
    private prisma: PrismaService,
    private noteAccessService: NoteAccessService,
  ) { }

  async upload(userId: string, noteId: string, file: Express.Multer.File) {
    // Require editor or owner access to upload
    await this.noteAccessService.ensureNoteAccess(
      userId,
      noteId,
      NoteSharePermission.editor,
    );

    if (!file) {
      throw new BadRequestException('No file provided');
    }

    if (!ATTACHMENT_ALLOWED_MIME_TYPES.has(file.mimetype)) {
      throw new BadRequestException(`File type ${file.mimetype} is not allowed`);
    }

    if (file.size > ATTACHMENT_MAX_FILE_SIZE) {
      throw new BadRequestException(
        `File size exceeds ${ATTACHMENT_MAX_FILE_SIZE / 1024 / 1024}MB limit`,
      );
    }

    const noteDir = path.join(this.baseDir, noteId);
    await fs.mkdir(noteDir, { recursive: true });

    const ext = path.extname(file.originalname).toLowerCase();
    const storedFilename = `${crypto.randomUUID()}-${Date.now()}${ext}`;
    const filePath = path.join(noteDir, storedFilename);

    const attachmentType: AttachmentType = file.mimetype.startsWith('image/')
      ? AttachmentType.image
      : AttachmentType.audio;

    let fileSaved = false;
    try {
      await fs.writeFile(filePath, file.buffer);
      fileSaved = true;

      const maxPositionResult = await this.prisma.noteAttachment.aggregate({
        where: { noteId },
        _max: { position: true },
      });
      const nextPosition = (maxPositionResult._max.position ?? -1) + 1;

      const attachment = await this.prisma.noteAttachment.create({
        data: {
          noteId,
          uploadedByUserId: userId,
          type: attachmentType,
          originalFilename: file.originalname,
          storedFilename,
          mimeType: file.mimetype,
          fileSize: file.size,
          position: nextPosition,
        },
      });

      return toAttachmentResponse(attachment);
    } catch (error) {
      if (fileSaved) {
        try {
          await fs.unlink(filePath);
        } catch (deleteError) {
          this.logger.error(`Failed to delete file after DB error: ${filePath}`);
        }
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

    const filePath = path.join(this.baseDir, noteId, attachment.storedFilename);
    if (!existsSync(filePath)) {
      throw new NotFoundException('Attachment file not found');
    }

    const stream = createReadStream(filePath);
    return { stream, attachment };
  }

  async remove(userId: string, noteId: string, attachmentId: string) {
    // Owner only can delete attachments
    await this.noteAccessService.verifyNoteOwnership(userId, noteId);

    const attachment = await this.prisma.noteAttachment.findFirst({
      where: { id: attachmentId, noteId },
    });

    if (!attachment) {
      throw new NotFoundException('Attachment not found');
    }

    await this.prisma.noteAttachment.delete({ where: { id: attachmentId } });

    const filePath = path.join(this.baseDir, noteId, attachment.storedFilename);
    try {
      await fs.unlink(filePath);
    } catch (error) {
      // File may not exist, log only if it's not ENOENT
      if ((error as NodeJS.ErrnoException).code !== 'ENOENT') {
        this.logger.error(`Failed to delete attachment file: ${filePath}`);
      }
    }

    return { success: true };
  }

  async reorder(userId: string, noteId: string, orderedIds: string[]) {
    // Editor or owner can reorder
    await this.noteAccessService.ensureNoteAccess(
      userId,
      noteId,
      NoteSharePermission.editor,
    );

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

    await this.prisma.$transaction(
      orderedIds.map((id, index) =>
        this.prisma.noteAttachment.update({
          where: { id },
          data: { position: index },
        }),
      ),
    );

    return this.findAll(userId, noteId);
  }

  async deleteAllForNote(noteId: string) {
    const noteDir = path.join(this.baseDir, noteId);
    try {
      await fs.rm(noteDir, { recursive: true, force: true });
    } catch (error) {
      // Directory may not exist, log only if it's not ENOENT
      if ((error as NodeJS.ErrnoException).code !== 'ENOENT') {
        this.logger.error(
          `Failed to delete attachments directory for note ${noteId}: ${error}`,
        );
      }
    }
  }
}
