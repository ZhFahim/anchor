import { describe, expect, it } from 'vitest';
import { BadRequestException } from '@nestjs/common';
import { AttachmentType } from 'src/generated/prisma/enums';
import { ATTACHMENT_MAX_FILE_SIZE } from '../constants/notes.constants';
import {
  assertValidAttachmentFile,
  attachmentTypeForMime,
  noteAttachmentDir,
} from './attachment-storage.util';

const fileOf = (overrides: Partial<Express.Multer.File>): Express.Multer.File =>
  ({ mimetype: 'image/png', size: 1024, ...overrides }) as Express.Multer.File;

describe('assertValidAttachmentFile', () => {
  it('accepts an allowed type within the size limit', () => {
    expect(() => assertValidAttachmentFile(fileOf({}))).not.toThrow();
  });

  it('rejects a missing file', () => {
    expect(() => assertValidAttachmentFile(undefined)).toThrow(
      BadRequestException,
    );
  });

  it('rejects a disallowed MIME type', () => {
    expect(() =>
      assertValidAttachmentFile(fileOf({ mimetype: 'application/pdf' })),
    ).toThrow(/not allowed/);
  });

  it('rejects a file over the size limit', () => {
    expect(() =>
      assertValidAttachmentFile(fileOf({ size: ATTACHMENT_MAX_FILE_SIZE + 1 })),
    ).toThrow(/exceeds/);
  });
});

describe('noteAttachmentDir', () => {
  const root = '/data/uploads/attachments';

  it('names a folder inside the attachments folder', () => {
    expect(
      noteAttachmentDir(root, '3b241101-e2bb-4255-8caf-4136c566a962'),
    ).toBe(`${root}/3b241101-e2bb-4255-8caf-4136c566a962`);
  });

  it.each(['..', '.', '', '../profiles', 'a/b', 'a\\b', '/etc', 'a\0b'])(
    'refuses %j, which could point somewhere else',
    (noteId) => {
      expect(() => noteAttachmentDir(root, noteId)).toThrow(
        BadRequestException,
      );
    },
  );
});

describe('attachmentTypeForMime', () => {
  it('maps image types to image', () => {
    expect(attachmentTypeForMime('image/jpeg')).toBe(AttachmentType.image);
  });

  it('maps non-image types to audio', () => {
    expect(attachmentTypeForMime('audio/mpeg')).toBe(AttachmentType.audio);
  });
});
