import {
  IsBoolean,
  IsOptional,
  IsString,
  IsArray,
  ValidateNested,
} from 'class-validator';
import { Type } from 'class-transformer';
import { NoteReminderDto } from './note-reminder.dto';

export class CreateNoteDto {
  // Blank is allowed and canonical for "no title"; clients render an "Untitled" placeholder.
  @IsString()
  title: string;

  @IsString()
  @IsOptional()
  content?: string;

  @IsBoolean()
  @IsOptional()
  isPinned?: boolean;

  @IsBoolean()
  @IsOptional()
  isArchived?: boolean;

  @IsString()
  @IsOptional()
  background?: string;

  @IsArray()
  @IsString({ each: true })
  @IsOptional()
  tagIds?: string[];

  // null clears the reminder; absent leaves it alone.
  @ValidateNested()
  @Type(() => NoteReminderDto)
  @IsOptional()
  reminder?: NoteReminderDto | null;
}
