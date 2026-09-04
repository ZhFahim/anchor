import { Injectable } from '@nestjs/common';
import { Prisma } from 'src/generated/prisma/client';
import { SyncEntityType, SyncOp } from 'src/generated/prisma/enums';
import { SyncEventsService } from './sync-events.service';
import { CHANGELOG_UPSERT_CHUNK_SIZE } from './sync.constants';

export interface SyncEmission {
  recipientUserId: string;
  entityType: SyncEntityType;
  entityId: string;
  op: SyncOp;
}

@Injectable()
export class SyncEmitterService {
  constructor(private syncEvents: SyncEventsService) {}

  // Must run inside the caller's mutation transaction: the seq block and the
  // ChangeLog rows commit with the entity write, and the SyncState row lock
  // next_sync_seq takes is what keeps seq commit-ordered per recipient.
  // Returns the distinct recipients, each poked once the transaction commits.
  async emit(
    tx: Prisma.TransactionClient,
    emissions: SyncEmission[],
  ): Promise<string[]> {
    const deduped = new Map<string, SyncEmission>();
    for (const emission of emissions) {
      deduped.set(emissionKey(emission), emission);
    }

    const byRecipient = new Map<string, SyncEmission[]>();
    for (const emission of deduped.values()) {
      const batch = byRecipient.get(emission.recipientUserId) ?? [];
      batch.push(emission);
      byRecipient.set(emission.recipientUserId, batch);
    }

    // Sorted so concurrent writers take SyncState locks in the same order.
    const recipients = [...byRecipient.keys()].sort();

    const lastSeqByRecipient = new Map<string, bigint>();
    const rows: Prisma.Sql[] = [];
    for (const recipientUserId of recipients) {
      const batch = byRecipient.get(recipientUserId)!;
      const allocated = await tx.$queryRaw<
        { seq: bigint }[]
      >`SELECT next_sync_seq(${recipientUserId}::text, ${batch.length}::int) AS seq`;
      lastSeqByRecipient.set(recipientUserId, allocated[0].seq);
      let seq = allocated[0].seq - BigInt(batch.length) + 1n;

      for (const emission of batch) {
        rows.push(changeLogRow(emission, seq));
        seq += 1n;
      }
    }

    for (let i = 0; i < rows.length; i += CHANGELOG_UPSERT_CHUNK_SIZE) {
      await tx.$executeRaw(
        upsertChangeLogRows(rows.slice(i, i + CHANGELOG_UPSERT_CHUNK_SIZE)),
      );
    }

    this.syncEvents.schedulePoke(lastSeqByRecipient);
    return recipients;
  }

  // Everyone whose feed carries this note: the owner plus active sharees.
  async noteRecipients(
    tx: Prisma.TransactionClient,
    noteId: string,
  ): Promise<string[]> {
    const map = await this.notesRecipients(tx, [noteId]);
    return map.get(noteId) ?? [];
  }

  async notesRecipients(
    tx: Prisma.TransactionClient,
    noteIds: string[],
  ): Promise<Map<string, string[]>> {
    if (noteIds.length === 0) {
      return new Map();
    }
    const notes = await tx.note.findMany({
      where: { id: { in: noteIds } },
      select: {
        id: true,
        userId: true,
        sharedWith: {
          where: { isDeleted: false },
          select: { sharedWithUserId: true },
        },
      },
    });
    return new Map(
      notes.map((note) => [
        note.id,
        [note.userId, ...note.sharedWith.map((s) => s.sharedWithUserId)],
      ]),
    );
  }

  // Recipients losing a note (revoke, tombstone) get a note remove, and their
  // pin/reminder/attachments index rows for it go too. extraEmissions ride
  // along so the whole operation still takes its locks in one sorted pass.
  async removeNote(
    tx: Prisma.TransactionClient,
    recipientUserIds: string[],
    noteId: string,
    extraEmissions: SyncEmission[] = [],
  ): Promise<string[]> {
    const recipients = await this.emit(tx, [
      ...noteEmissions(recipientUserIds, noteId, SyncOp.remove),
      ...extraEmissions,
    ]);
    await tx.changeLog.deleteMany({
      where: {
        recipientUserId: { in: recipientUserIds },
        entityId: noteId,
        entityType: {
          in: [
            SyncEntityType.pin,
            SyncEntityType.reminder,
            SyncEntityType.attachments,
          ],
        },
      },
    });
    return recipients;
  }

  // Batch form for the trash-expiry cron. The notes are gone for everyone, so
  // the pin/reminder/attachments cleanup drops rows for every recipient.
  async removeNotes(
    tx: Prisma.TransactionClient,
    recipientsByNote: Map<string, string[]>,
  ): Promise<string[]> {
    const noteIds = [...recipientsByNote.keys()];
    if (noteIds.length === 0) {
      return [];
    }
    const recipients = await this.emit(
      tx,
      noteIds.flatMap((noteId) =>
        noteEmissions(
          recipientsByNote.get(noteId) ?? [],
          noteId,
          SyncOp.remove,
        ),
      ),
    );
    await tx.changeLog.deleteMany({
      where: {
        entityId: { in: noteIds },
        entityType: {
          in: [
            SyncEntityType.pin,
            SyncEntityType.reminder,
            SyncEntityType.attachments,
          ],
        },
      },
    });
    return recipients;
  }
}

const emissionKey = (e: SyncEmission) =>
  `${e.recipientUserId}\0${e.entityType}\0${e.entityId}`;

const changeLogRow = (e: SyncEmission, seq: bigint) =>
  Prisma.sql`(${e.recipientUserId}, ${e.entityType}::"SyncEntityType", ${e.entityId}, ${e.op}::"SyncOp", ${seq.toString()}::bigint, timezone('utc', now()))`;

const upsertChangeLogRows = (rows: Prisma.Sql[]) => Prisma.sql`
  INSERT INTO "ChangeLog" ("recipientUserId", "entityType", "entityId", "op", "seq", "updatedAt")
  VALUES ${Prisma.join(rows)}
  ON CONFLICT ("recipientUserId", "entityType", "entityId") DO UPDATE
  SET "op" = EXCLUDED."op",
      "seq" = EXCLUDED."seq",
      "updatedAt" = EXCLUDED."updatedAt"`;

export const noteEmissions = (
  recipientUserIds: string[],
  noteId: string,
  op: SyncOp = SyncOp.upsert,
): SyncEmission[] =>
  recipientUserIds.map((recipientUserId) => ({
    recipientUserId,
    entityType: SyncEntityType.note,
    entityId: noteId,
    op,
  }));

export const attachmentsEmissions = (
  recipientUserIds: string[],
  noteId: string,
): SyncEmission[] =>
  recipientUserIds.map((recipientUserId) => ({
    recipientUserId,
    entityType: SyncEntityType.attachments,
    entityId: noteId,
    op: SyncOp.upsert,
  }));

// Pins are per-user: the only recipient is the pin's owner.
export const pinEmission = (
  userId: string,
  noteId: string,
  isPinned: boolean,
): SyncEmission => ({
  recipientUserId: userId,
  entityType: SyncEntityType.pin,
  entityId: noteId,
  op: isPinned ? SyncOp.upsert : SyncOp.remove,
});

// Reminders are per-user: the only recipient is the reminder's owner.
export const reminderEmission = (
  userId: string,
  noteId: string,
  hasReminder: boolean,
): SyncEmission => ({
  recipientUserId: userId,
  entityType: SyncEntityType.reminder,
  entityId: noteId,
  op: hasReminder ? SyncOp.upsert : SyncOp.remove,
});

export const tagEmission = (
  userId: string,
  tagId: string,
  op: SyncOp = SyncOp.upsert,
): SyncEmission => ({
  recipientUserId: userId,
  entityType: SyncEntityType.tag,
  entityId: tagId,
  op,
});
