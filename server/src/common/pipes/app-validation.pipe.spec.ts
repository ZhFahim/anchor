import { describe, expect, it } from 'vitest';
import { IsOptional, IsString } from 'class-validator';
import { BadRequestException, type ArgumentMetadata } from '@nestjs/common';
import { AppValidationPipe } from './app-validation.pipe';
import { RejectUnknownFields } from '../decorators/reject-unknown-fields.decorator';

@RejectUnknownFields()
class StrictDto {
  @IsString()
  name: string;
}

class TolerantDto {
  @IsString()
  name: string;

  @IsString()
  @IsOptional()
  note?: string;
}

const bodyOf = (metatype: unknown): ArgumentMetadata =>
  ({ type: 'body', metatype }) as ArgumentMetadata;

/** The validation messages, which ride on the response, not the error. */
const messagesFrom = async (result: Promise<unknown>): Promise<string[]> => {
  try {
    await result;
  } catch (error) {
    const response = (error as BadRequestException).getResponse();
    return (response as { message: string[] }).message;
  }
  throw new Error('expected the pipe to reject');
};

describe('AppValidationPipe', () => {
  const pipe = new AppValidationPipe();

  it('rejects an unknown field on a DTO that opts into strictness', async () => {
    const messages = await messagesFrom(
      pipe.transform({ name: 'a', surprise: 1 }, bodyOf(StrictDto)),
    );

    expect(messages).toContain('property surprise should not exist');
  });

  it('drops an unknown field by default', async () => {
    await expect(
      pipe.transform({ name: 'a', surprise: 1 }, bodyOf(TolerantDto)),
    ).resolves.toEqual({ name: 'a' });
  });

  it('still enforces the fields a tolerant DTO does declare', async () => {
    const messages = await messagesFrom(
      pipe.transform({ name: 42 }, bodyOf(TolerantDto)),
    );

    expect(messages).toContain('name must be a string');
  });

  it('keeps the declared optional fields it understands', async () => {
    await expect(
      pipe.transform(
        { name: 'a', note: 'b', surprise: 1 },
        bodyOf(TolerantDto),
      ),
    ).resolves.toEqual({ name: 'a', note: 'b' });
  });

  it('adds a code and each field with the rules it broke', async () => {
    try {
      await pipe.transform({ name: 42 }, bodyOf(TolerantDto));
    } catch (error) {
      const response = (error as BadRequestException).getResponse();
      expect(response).toMatchObject({
        statusCode: 400,
        error: 'Bad Request',
        message: ['name must be a string'],
        code: 'VALIDATION_FAILED',
        fields: [{ field: 'name', rules: ['isString'] }],
      });
      return;
    }
    throw new Error('expected the pipe to reject');
  });
});
