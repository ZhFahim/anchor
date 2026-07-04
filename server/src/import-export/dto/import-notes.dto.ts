import {
  ArrayMaxSize,
  ArrayMinSize,
  IsArray,
  IsBoolean,
  IsDateString,
  IsNotEmpty,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
  ValidateNested,
} from 'class-validator';
import { Type } from 'class-transformer';
import {
  IMPORT_MAX_CONTENT_LENGTH,
  IMPORT_MAX_NOTES_PER_BATCH,
  IMPORT_MAX_TAG_NAME_LENGTH,
  IMPORT_MAX_TAGS_PER_BATCH,
  IMPORT_MAX_TAGS_PER_NOTE,
  IMPORT_MAX_TITLE_LENGTH,
} from '../constants/import.constants';

export class ImportNoteItemDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(256)
  ref: string;

  @IsUUID()
  @IsOptional()
  id?: string;

  @IsString()
  @MaxLength(IMPORT_MAX_TITLE_LENGTH)
  title: string;

  @IsString()
  @MaxLength(IMPORT_MAX_CONTENT_LENGTH)
  @IsOptional()
  content?: string;

  @IsBoolean()
  @IsOptional()
  isPinned?: boolean;

  @IsBoolean()
  @IsOptional()
  isArchived?: boolean;

  @IsBoolean()
  @IsOptional()
  isTrashed?: boolean;

  @IsString()
  @MaxLength(64)
  @IsOptional()
  background?: string;

  @IsArray()
  @ArrayMaxSize(IMPORT_MAX_TAGS_PER_NOTE)
  @IsString({ each: true })
  @MaxLength(IMPORT_MAX_TAG_NAME_LENGTH, { each: true })
  @IsOptional()
  tagNames?: string[];

  @IsDateString()
  @IsOptional()
  createdAt?: string;

  @IsDateString()
  @IsOptional()
  updatedAt?: string;
}

export class ImportTagDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(IMPORT_MAX_TAG_NAME_LENGTH)
  name: string;

  @IsString()
  @MaxLength(32)
  @IsOptional()
  color?: string;
}

export class ImportNotesDto {
  @IsArray()
  @ArrayMinSize(1)
  @ArrayMaxSize(IMPORT_MAX_NOTES_PER_BATCH)
  @ValidateNested({ each: true })
  @Type(() => ImportNoteItemDto)
  notes: ImportNoteItemDto[];

  @IsArray()
  @ArrayMaxSize(IMPORT_MAX_TAGS_PER_BATCH)
  @ValidateNested({ each: true })
  @Type(() => ImportTagDto)
  @IsOptional()
  tags?: ImportTagDto[];

  @IsBoolean()
  @IsOptional()
  skipExisting?: boolean;
}

export type ImportNoteStatus = 'created' | 'skipped' | 'remapped' | 'failed';

export interface ImportNoteResult {
  ref: string;
  status: ImportNoteStatus;
  noteId?: string;
  warning?: string;
  error?: string;
}

export interface ImportNotesResponse {
  results: ImportNoteResult[];
  tags: { created: number; reused: number };
}
