import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import {
  NoteSharePermission,
  NoteState,
  ReminderRecurrence,
  SyncEntityType,
  SyncOp,
} from 'src/generated/prisma/enums';
import { transformNote } from '../notes/utils/note-transformer.util';
import {
  AttachmentResponseDto,
  toAttachmentResponse,
} from '../notes/dto/attachment-response.dto';
import {
  NOTE_INCLUDE_TAGS,
  NOTE_INCLUDE_SHARES,
  NOTE_INCLUDE_ATTACHMENT_COUNT,
  notePinInclude,
  noteReminderInclude,
} from '../notes/constants/notes.constants';
import type { Tag } from 'src/generated/prisma/client';
import { toSyncTagPayload, SyncFeedEntry } from './dto/sync-response.dto';

export interface SyncFeedRow {
  seq: bigint;
  entityType: SyncEntityType;
  entityId: string;
  op: SyncOp;
}

interface NoteRow {
  id: string;
  title: string;
  content: string | null;
  version: number;
  isArchived: boolean;
  background: string | null;
  state: NoteState;
  createdAt: Date;
  updatedAt: Date;
  userId: string;
  pins: Array<{ userId: string }>;
  reminders: Array<{
    remindAt: string;
    recurrence: ReminderRecurrence;
    version: number;
  }>;
  tags: Array<{ id: string; userId: string }>;
  sharedWith: Array<{
    id: string;
    permission: NoteSharePermission;
    sharedWithUserId: string;
    sharedByUser: {
      id: string;
      name: string;
      email: string;
      profileImage: string | null;
    };
  }>;
  _count: { attachments: number };
  attachments: Array<{ id: string }>;
}

// ChangeLog rows have no FK on entityId, so a row can outlive its entity. Any
// row that can't be hydrated becomes a remove.
@Injectable()
export class SyncHydratorService {
  constructor(private prisma: PrismaService) {}

  async hydrate(userId: string, rows: SyncFeedRow[]): Promise<SyncFeedEntry[]> {
    const noteIds = new Set<string>();
    const tagIds = new Set<string>();
    for (const row of rows) {
      if (row.op !== SyncOp.upsert) {
        continue;
      }
      if (row.entityType === SyncEntityType.tag) {
        tagIds.add(row.entityId);
      } else {
        // note, pin, reminder, and attachments rows all key on a noteId.
        noteIds.add(row.entityId);
      }
    }

    const [notes, tags] = await Promise.all([
      this.fetchNotes(userId, [...noteIds]),
      this.fetchTags(userId, [...tagIds]),
    ]);
    const attachmentsByNote = await this.fetchAttachments(
      rows
        .filter(
          (row) =>
            row.entityType === SyncEntityType.attachments &&
            row.op === SyncOp.upsert &&
            isAccessible(userId, notes.get(row.entityId)),
        )
        .map((row) => row.entityId),
    );

    return rows.map((row) =>
      this.buildEntry(userId, row, notes, tags, attachmentsByNote),
    );
  }

  private buildEntry(
    userId: string,
    row: SyncFeedRow,
    notes: Map<string, NoteRow>,
    tags: Map<string, Tag>,
    attachmentsByNote: Map<string, AttachmentResponseDto[]>,
  ): SyncFeedEntry {
    const base = {
      seq: row.seq.toString(),
      entityType: row.entityType,
      entityId: row.entityId,
    };

    if (row.op === SyncOp.remove) {
      return { ...base, op: 'remove' };
    }

    switch (row.entityType) {
      case SyncEntityType.note: {
        const note = notes.get(row.entityId);
        if (!isAccessible(userId, note)) {
          return { ...base, op: 'remove' };
        }
        return { ...base, op: 'upsert', note: transformNote(note, userId) };
      }
      case SyncEntityType.tag: {
        const tag = tags.get(row.entityId);
        if (!tag || tag.isDeleted) {
          return { ...base, op: 'remove' };
        }
        return { ...base, op: 'upsert', tag: toSyncTagPayload(tag) };
      }
      case SyncEntityType.attachments: {
        if (!isAccessible(userId, notes.get(row.entityId))) {
          return { ...base, op: 'remove' };
        }
        return {
          ...base,
          op: 'upsert',
          attachments: attachmentsByNote.get(row.entityId) ?? [],
        };
      }
      case SyncEntityType.pin: {
        if (!isAccessible(userId, notes.get(row.entityId))) {
          return { ...base, op: 'remove' };
        }
        return { ...base, op: 'upsert' };
      }
      case SyncEntityType.reminder: {
        const note = notes.get(row.entityId);
        if (!isAccessible(userId, note)) {
          return { ...base, op: 'remove' };
        }
        const reminder = note.reminders[0];
        if (!reminder) {
          return { ...base, op: 'remove' };
        }
        return { ...base, op: 'upsert', reminder };
      }
    }
  }

  private async fetchNotes(
    userId: string,
    ids: string[],
  ): Promise<Map<string, NoteRow>> {
    if (ids.length === 0) {
      return new Map();
    }
    const notes = await this.prisma.note.findMany({
      where: { id: { in: ids } },
      include: {
        ...NOTE_INCLUDE_TAGS,
        ...NOTE_INCLUDE_SHARES,
        ...NOTE_INCLUDE_ATTACHMENT_COUNT,
        ...notePinInclude(userId),
        ...noteReminderInclude(userId),
      },
    });
    return new Map(notes.map((note) => [note.id, note]));
  }

  private async fetchTags(
    userId: string,
    ids: string[],
  ): Promise<Map<string, Tag>> {
    if (ids.length === 0) {
      return new Map();
    }
    const tags = await this.prisma.tag.findMany({
      where: { id: { in: ids }, userId },
    });
    return new Map(tags.map((tag) => [tag.id, tag]));
  }

  private async fetchAttachments(
    noteIds: string[],
  ): Promise<Map<string, AttachmentResponseDto[]>> {
    const grouped = new Map<string, AttachmentResponseDto[]>();
    if (noteIds.length === 0) {
      return grouped;
    }
    const attachments = await this.prisma.noteAttachment.findMany({
      where: { noteId: { in: noteIds } },
      orderBy: [{ position: 'asc' }, { createdAt: 'asc' }],
    });
    for (const attachment of attachments) {
      const list = grouped.get(attachment.noteId) ?? [];
      list.push(toAttachmentResponse(attachment));
      grouped.set(attachment.noteId, list);
    }
    return grouped;
  }
}

// Tombstoned notes count as inaccessible, so they hydrate as removes.
function isAccessible(
  userId: string,
  note: NoteRow | undefined,
): note is NoteRow {
  if (!note || note.state === NoteState.deleted) {
    return false;
  }
  return (
    note.userId === userId ||
    note.sharedWith.some((share) => share.sharedWithUserId === userId)
  );
}
