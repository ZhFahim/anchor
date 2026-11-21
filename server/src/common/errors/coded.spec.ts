import { describe, expect, it } from 'vitest';
import { BadRequestException, ConflictException } from '@nestjs/common';
import { coded } from './coded';
import { ErrorCode } from './error-code';

describe('coded', () => {
  it('adds the code beside the unchanged message', () => {
    const error = coded(
      new BadRequestException('No file provided'),
      ErrorCode.FILE_MISSING,
    );
    expect(error.getResponse()).toEqual({
      statusCode: 400,
      error: 'Bad Request',
      message: 'No file provided',
      code: 'FILE_MISSING',
    });
  });

  it('adds the values built into the message', () => {
    const error = coded(
      new BadRequestException('File size exceeds 25MB limit'),
      ErrorCode.FILE_TOO_LARGE,
      { limitMb: 25 },
    );
    expect(error.getResponse()).toMatchObject({
      code: 'FILE_TOO_LARGE',
      params: { limitMb: 25 },
    });
  });

  it('keeps the data a conflict carries', () => {
    const error = coded(
      new ConflictException({
        message: 'Tag was changed',
        serverTag: { id: 't' },
      }),
      ErrorCode.TAG_CHANGED,
    );
    expect(error.getResponse()).toEqual({
      message: 'Tag was changed',
      serverTag: { id: 't' },
      code: 'TAG_CHANGED',
    });
  });
});
