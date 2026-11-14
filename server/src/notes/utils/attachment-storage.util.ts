import { BadRequestException, Logger } from '@nestjs/common';
import * as crypto from 'crypto';
import * as fs from 'fs/promises';
import * as path from 'path';
import { AttachmentType } from 'src/generated/prisma/enums';
import {
  ATTACHMENT_ALLOWED_MIME_TYPES,
  ATTACHMENT_MAX_FILE_SIZE,
} from '../constants/notes.constants';

const NOTE_FOLDER_NAME = /^[\w-]+$/;

/** Throws for an id that could point outside the attachments folder. */
export function noteAttachmentDir(
  attachmentsDir: string,
  noteId: string,
): string {
  if (!NOTE_FOLDER_NAME.test(noteId)) {
    throw new BadRequestException('Invalid note id');
  }
  return path.join(attachmentsDir, noteId);
}

/** Never throws; a failure is logged. */
export async function removeNoteAttachmentDir(
  attachmentsDir: string,
  noteId: string,
  logger: Logger,
): Promise<void> {
  try {
    await fs.rm(noteAttachmentDir(attachmentsDir, noteId), {
      recursive: true,
      force: true,
    });
  } catch (error) {
    logger.error(
      `Failed to delete the attachments of note ${noteId}: ${String(error)}`,
    );
  }
}

export function assertValidAttachmentFile(file?: Express.Multer.File): void {
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
}

export function attachmentTypeForMime(mimeType: string): AttachmentType {
  return mimeType.startsWith('image/')
    ? AttachmentType.image
    : AttachmentType.audio;
}

export async function writeAttachmentFile(
  noteDir: string,
  originalName: string,
  data: Buffer,
): Promise<{ storedFilename: string; filePath: string }> {
  await fs.mkdir(noteDir, { recursive: true });

  const ext = path.extname(originalName).toLowerCase();
  const storedFilename = `${crypto.randomUUID()}-${Date.now()}${ext}`;
  const filePath = path.join(noteDir, storedFilename);

  await fs.writeFile(filePath, data);
  return { storedFilename, filePath };
}
