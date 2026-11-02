import { describe, expect, it } from 'vitest';
import { BadRequestException } from '@nestjs/common';
import { AttachmentType } from 'src/generated/prisma/enums';
import { ATTACHMENT_MAX_FILE_SIZE } from '../constants/notes.constants';
import {
  assertValidAttachmentFile,
  attachmentTypeForMime,
  clientAttachmentId,
  servedMimeType,
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

  it('accepts any kind of file', () => {
    expect(() =>
      assertValidAttachmentFile(fileOf({ mimetype: 'application/pdf' })),
    ).not.toThrow();
  });

  it('rejects a file over the size limit', () => {
    expect(() =>
      assertValidAttachmentFile(fileOf({ size: ATTACHMENT_MAX_FILE_SIZE + 1 })),
    ).toThrow(/exceeds/);
  });
});

describe('attachmentTypeForMime', () => {
  it('maps image types to image', () => {
    expect(attachmentTypeForMime('image/jpeg')).toBe(AttachmentType.image);
  });

  it('maps audio types to audio', () => {
    expect(attachmentTypeForMime('audio/mpeg')).toBe(AttachmentType.audio);
  });

  it('maps anything else to file', () => {
    expect(attachmentTypeForMime('application/zip')).toBe('file');
    expect(attachmentTypeForMime('image/svg+xml')).toBe('file');
    expect(attachmentTypeForMime('text/html')).toBe('file');
  });
});

describe('servedMimeType', () => {
  it('serves files as bytes to download', () => {
    expect(servedMimeType('file', 'text/html')).toBe(
      'application/octet-stream',
    );
  });

  it('keeps the type of pictures and recordings', () => {
    expect(servedMimeType(AttachmentType.image, 'image/png')).toBe('image/png');
  });
});

describe('clientAttachmentId', () => {
  it('keeps a UUID', () => {
    const id = '3f2a8c4e-9b1d-4e6f-a2c3-1b2c3d4e5f60';
    expect(clientAttachmentId(id)).toBe(id);
  });

  it('drops anything else', () => {
    expect(clientAttachmentId('../etc')).toBeUndefined();
    expect(clientAttachmentId(undefined)).toBeUndefined();
    expect(clientAttachmentId(42)).toBeUndefined();
  });
});
