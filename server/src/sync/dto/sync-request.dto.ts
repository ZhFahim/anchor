import {
  ArrayMaxSize,
  IsArray,
  IsBoolean,
  IsDateString,
  IsIn,
  IsInt,
  IsOptional,
  IsString,
  IsEnum,
  Matches,
  Max,
  Min,
  ValidateNested,
} from 'class-validator';
import { Type } from 'class-transformer';
import {
  MAX_SYNC_CHANGES,
  MAX_SYNC_LIMIT,
  MAX_SYNC_NOTE_REVISIONS,
  MIN_SYNC_LIMIT,
} from '../sync.constants';

export enum SyncNoteState {
  active = 'active',
  trashed = 'trashed',
  deleted = 'deleted',
}

export enum SyncReminderRecurrence {
  none = 'none',
  daily = 'daily',
  weekly = 'weekly',
  monthly = 'monthly',
  yearly = 'yearly',
}

// For pins and reminders `id` is the noteId; neither has an entity of its own.
export class SyncChangeBaseDto {
  @IsIn(['note', 'tag', 'pin', 'reminder'])
  type: 'note' | 'tag' | 'pin' | 'reminder';

  @IsString()
  id: string;
}

// What the note said before the client changed it, recorded on the device.
export class SyncNoteRevisionDto {
  @IsString()
  id: string;

  @IsInt()
  @Min(0)
  @IsOptional()
  version?: number;

  @IsString()
  title: string;

  @IsString()
  @IsOptional()
  content?: string;

  @IsIn(['edit', 'restore'])
  cause: 'edit' | 'restore';

  @IsDateString()
  createdAt: string;
}

// Pushes carry the client's whole coalesced row; pins travel as their own
// change type.
export class SyncNoteChangeDto extends SyncChangeBaseDto {
  declare type: 'note';

  // Absent on an existing note means the client never reconciled a server
  // version, so it loses: conflict, nothing clobbered.
  @IsInt()
  @Min(1)
  @IsOptional()
  baseVersion?: number;

  @IsString()
  title: string;

  @IsString()
  @IsOptional()
  content?: string;

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

  @IsArray()
  @ArrayMaxSize(MAX_SYNC_NOTE_REVISIONS)
  @ValidateNested({ each: true })
  @Type(() => SyncNoteRevisionDto)
  @IsOptional()
  revisions?: SyncNoteRevisionDto[];

  // The note itself is clean; only the recorded revisions need to land.
  @IsBoolean()
  @IsOptional()
  revisionsOnly?: boolean;
}

export class SyncTagChangeDto extends SyncChangeBaseDto {
  declare type: 'tag';

  @IsInt()
  @Min(1)
  @IsOptional()
  baseVersion?: number;

  @IsString()
  name: string;

  @IsString()
  @IsOptional()
  color?: string;

  @IsBoolean()
  @IsOptional()
  isDeleted?: boolean;
}

export class SyncPinChangeDto extends SyncChangeBaseDto {
  declare type: 'pin';

  @IsBoolean()
  isPinned: boolean;
}

// A local wall clock with no zone and no seconds, e.g. "2026-09-04T09:00".
export const REMINDER_WALL_CLOCK = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}$/;

export class SyncReminderChangeDto extends SyncChangeBaseDto {
  declare type: 'reminder';

  @IsInt()
  @Min(1)
  @IsOptional()
  baseVersion?: number;

  // Null or absent clears the reminder.
  @Matches(REMINDER_WALL_CLOCK)
  @IsOptional()
  remindAt?: string | null;

  @IsEnum(SyncReminderRecurrence)
  @IsOptional()
  recurrence?: SyncReminderRecurrence;
}

export type SyncChange =
  | SyncNoteChangeDto
  | SyncTagChangeDto
  | SyncPinChangeDto
  | SyncReminderChangeDto;

export class SyncRequestDto {
  @IsString()
  @IsOptional()
  cursor?: string;

  @IsInt()
  @Min(MIN_SYNC_LIMIT)
  @Max(MAX_SYNC_LIMIT)
  @IsOptional()
  limit?: number;

  @IsArray()
  @ArrayMaxSize(MAX_SYNC_CHANGES)
  @ValidateNested({ each: true })
  @Type(() => SyncChangeBaseDto, {
    discriminator: {
      property: 'type',
      subTypes: [
        { value: SyncNoteChangeDto, name: 'note' },
        { value: SyncTagChangeDto, name: 'tag' },
        { value: SyncPinChangeDto, name: 'pin' },
        { value: SyncReminderChangeDto, name: 'reminder' },
      ],
    },
    keepDiscriminatorProperty: true,
  })
  @IsOptional()
  changes?: SyncChange[];
}
