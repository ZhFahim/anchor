import 'reflect-metadata';
import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { describe, expect, it } from 'vitest';
import { CreateNoteDto } from './create-note.dto';
import { UpdateNoteDto } from './update-note.dto';

describe('note type validation', () => {
  it('accepts regular and checklist notes and legacy requests', async () => {
    for (const noteType of [undefined, 'note', 'checklist']) {
      expect(
        await validate(plainToInstance(CreateNoteDto, { title: '', noteType })),
      ).toEqual([]);
    }
  });

  it('rejects unknown note types', async () => {
    const errors = await validate(
      plainToInstance(CreateNoteDto, { title: '', noteType: 'unknown' }),
    );
    expect(errors.some((error) => error.property === 'noteType')).toBe(true);
  });

  it('does not let updates convert note types', async () => {
    const errors = await validate(
      plainToInstance(UpdateNoteDto, { noteType: 'note' }),
      { whitelist: true, forbidNonWhitelisted: true },
    );
    expect(errors.some((error) => error.property === 'noteType')).toBe(true);
  });
});
