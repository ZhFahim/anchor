import { BadRequestException } from '@nestjs/common';
import * as crypto from 'crypto';
import * as fs from 'fs/promises';
import * as path from 'path';
import { AttachmentType } from 'src/generated/prisma/enums';
import {
  ATTACHMENT_AUDIO_MIME_TYPES,
  ATTACHMENT_IMAGE_MIME_TYPES,
  ATTACHMENT_MAX_FILE_SIZE,
} from '../constants/notes.constants';

export function assertValidAttachmentFile(file?: Express.Multer.File): void {
  if (!file) {
    throw new BadRequestException('No file provided');
  }
  if (file.size > ATTACHMENT_MAX_FILE_SIZE) {
    throw new BadRequestException(
      `File size exceeds ${ATTACHMENT_MAX_FILE_SIZE / 1024 / 1024}MB limit`,
    );
  }
}

/**
 * An attachment's type as the apps see it: a picture or recording, or any
 * other file (stored as a NoteFile, not a NoteAttachment).
 */
export type AttachmentKind = AttachmentType | 'file';

/** Pictures and recordings the clients show; anything else is a file. */
export function attachmentTypeForMime(mimeType: string): AttachmentKind {
  if (ATTACHMENT_IMAGE_MIME_TYPES.has(mimeType)) return AttachmentType.image;
  if (ATTACHMENT_AUDIO_MIME_TYPES.has(mimeType)) return AttachmentType.audio;
  return 'file';
}

/**
 * The Content-Type an attachment is served with. A file is sent as bytes to
 * download, never as something the browser would render (HTML, SVG) on the
 * app's own origin.
 */
export function servedMimeType(type: AttachmentKind, mimeType: string) {
  return type === 'file' ? 'application/octet-stream' : mimeType;
}

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/**
 * The folder a note's attachments live in. Note ids become a path segment,
 * so anything but a UUID (`..`, a slash) is refused rather than let out of
 * [attachmentsDir].
 */
export function noteAttachmentDir(attachmentsDir: string, noteId: string) {
  if (!isStorableNoteId(noteId)) {
    throw new BadRequestException('Invalid note id');
  }
  return path.join(attachmentsDir, noteId);
}

export function isStorableNoteId(noteId: string): boolean {
  return UUID.test(noteId);
}

/** An id a client picked for its upload, if it is a usable one. */
export function clientAttachmentId(id: unknown): string | undefined {
  return typeof id === 'string' && UUID.test(id) ? id : undefined;
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
