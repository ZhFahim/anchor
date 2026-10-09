import { describe, expect, it } from 'vitest';
import { BadRequestException, type ArgumentMetadata } from '@nestjs/common';
import { AppValidationPipe } from '../../common/pipes/app-validation.pipe';
import { UpdateUserDto } from './update-user.dto';

const pipe = new AppValidationPipe();
const body = { type: 'body', metatype: UpdateUserDto } as ArgumentMetadata;

const messagesFor = async (value: unknown): Promise<string[]> => {
  try {
    await pipe.transform(value, body);
  } catch (error) {
    const response = (error as BadRequestException).getResponse();
    return (response as { message: string[] }).message;
  }
  return [];
};

describe('UpdateUserDto', () => {
  it('refuses a blank name, or one of only spaces', async () => {
    expect(await messagesFor({ name: '' })).toContain(
      'name should not be empty',
    );
    expect(await messagesFor({ name: '   ' })).toContain(
      'name should not be empty',
    );
  });

  it('refuses a name longer than 100 characters', async () => {
    expect(await messagesFor({ name: 'a'.repeat(101) })).toContain(
      'name must be shorter than or equal to 100 characters',
    );
  });

  it('trims the name it keeps', async () => {
    await expect(
      pipe.transform({ name: '  Sam Lee  ' }, body),
    ).resolves.toEqual({ name: 'Sam Lee' });
  });

  it('leaves the name alone when only other fields change', async () => {
    await expect(pipe.transform({ isAdmin: true }, body)).resolves.toEqual({
      isAdmin: true,
    });
  });
});
