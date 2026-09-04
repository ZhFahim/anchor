import type {
  TransformedNote,
  TransformedReminder,
} from '../../notes/utils/note-transformer.util';
import type { AttachmentResponseDto } from '../../notes/dto/attachment-response.dto';
import type { NoteReminder, Tag } from 'src/generated/prisma/client';

export interface SyncTagPayload {
  id: string;
  name: string;
  color: string | null;
  version: number;
  createdAt: string;
  updatedAt: string;
}

export const toSyncTagPayload = (tag: Tag): SyncTagPayload => ({
  id: tag.id,
  name: tag.name,
  color: tag.color,
  version: tag.version,
  createdAt: tag.createdAt.toISOString(),
  updatedAt: tag.updatedAt.toISOString(),
});

export type SyncReminderPayload = TransformedReminder;

export const toSyncReminderPayload = (
  reminder: NoteReminder,
): SyncReminderPayload => ({
  remindAt: reminder.remindAt,
  recurrence: reminder.recurrence,
  version: reminder.version,
});

// seq is a string: BigInt doesn't survive JSON. Snapshot entries carry seq "0".
export interface SyncFeedEntry {
  seq: string;
  entityType: 'note' | 'tag' | 'pin' | 'attachments' | 'reminder';
  entityId: string;
  op: 'upsert' | 'remove';
  note?: TransformedNote;
  tag?: SyncTagPayload;
  attachments?: AttachmentResponseDto[];
  reminder?: SyncReminderPayload;
}

// `denied` is final and the client drops the change; `failed` is transient and
// the client keeps it queued.
export type SyncApplyStatus = 'applied' | 'conflict' | 'denied' | 'failed';

export interface SyncApplyResult {
  type: 'note' | 'tag' | 'pin' | 'reminder';
  id: string;
  status: SyncApplyStatus;
  version?: number;
  // The copy the client must adopt. For a tag name collision it carries a
  // different id: a merge instruction. A reminder conflict carries null when
  // the winning state is "no reminder".
  serverCopy?: TransformedNote | SyncTagPayload | SyncReminderPayload | null;
}

export interface SyncFeedPage {
  entries: SyncFeedEntry[];
  nextCursor: string | null;
  hasMore: boolean;
  resetRequired?: boolean;
}

export interface SyncResponse extends SyncFeedPage {
  protocol: number;
  results: SyncApplyResult[];
}
