import {
  IsString,
  IsOptional,
  IsBoolean,
  IsArray,
  ValidateNested,
  IsDateString,
  IsEnum,
} from 'class-validator';
import { Type } from 'class-transformer';

export enum SyncNoteState {
  active = 'active',
  trashed = 'trashed',
  deleted = 'deleted',
}

export class SyncNoteDto {
  @IsString()
  id: string;

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

  @IsEnum(SyncNoteState)
  @IsOptional()
  state?: SyncNoteState;

  @IsArray()
  @IsString({ each: true })
  @IsOptional()
  tagIds?: string[];

  @IsDateString()
  updatedAt: string;
}

export class SyncNotesDto {
  @IsDateString()
  @IsOptional()
  lastSyncedAt?: string;

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => SyncNoteDto)
  @IsOptional()
  changes?: SyncNoteDto[];
}
