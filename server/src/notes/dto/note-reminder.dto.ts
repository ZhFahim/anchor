import { IsEnum, IsOptional, Matches } from 'class-validator';
import {
  REMINDER_WALL_CLOCK,
  SyncReminderRecurrence,
} from '../../sync/dto/sync-request.dto';

export class NoteReminderDto {
  @Matches(REMINDER_WALL_CLOCK)
  remindAt: string;

  @IsEnum(SyncReminderRecurrence)
  @IsOptional()
  recurrence?: SyncReminderRecurrence;
}
