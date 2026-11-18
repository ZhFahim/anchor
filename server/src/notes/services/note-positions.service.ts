import { Injectable } from '@nestjs/common';
import { NoteState } from 'src/generated/prisma/enums';
import { Prisma } from '../../generated/prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import {
  noteEmissions,
  SyncEmitterService,
} from '../../sync/sync-emitter.service';
import { noteAccessibleBy } from '../constants/notes.constants';

export interface NotePositionChange {
  noteId: string;
  position: string | null;
}

// Positions are per person, like pins: a sharee's order never touches the
// owner's, and neither bumps the note's version or updatedAt.
@Injectable()
export class NotePositionsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly syncEmitter: SyncEmitterService,
  ) {}

  async setPositions(userId: string, changes: NotePositionChange[]) {
    // The last change for a note wins.
    const byNote = new Map(changes.map((c) => [c.noteId, c.position]));
    if (byNote.size === 0) return { updated: [] as string[] };

    const accessible = await this.prisma.note.findMany({
      where: {
        id: { in: [...byNote.keys()] },
        state: { not: NoteState.deleted },
        ...noteAccessibleBy(userId),
      },
      select: {
        id: true,
        positions: { where: { userId }, select: { position: true } },
      },
    });

    const changed = accessible.filter(
      (note) =>
        (note.positions[0]?.position ?? null) !== (byNote.get(note.id) ?? null),
    );
    if (changed.length === 0) return { updated: [] as string[] };

    const placed = changed.filter((note) => byNote.get(note.id) !== null);
    const cleared = changed.filter((note) => byNote.get(note.id) === null);

    await this.prisma.$transaction(async (tx) => {
      if (placed.length > 0) {
        const noteIds = placed.map((note) => note.id);
        const positions = noteIds.map((id) => byNote.get(id) as string);
        await tx.$executeRaw(Prisma.sql`
          INSERT INTO "NotePosition" ("userId", "noteId", "position", "updatedAt")
          SELECT ${userId}, t."noteId", t."position", NOW()
          FROM unnest(${noteIds}::text[], ${positions}::text[]) AS t("noteId", "position")
          ON CONFLICT ("userId", "noteId")
          DO UPDATE SET "position" = EXCLUDED."position", "updatedAt" = NOW()
        `);
      }
      if (cleared.length > 0) {
        await tx.notePosition.deleteMany({
          where: { userId, noteId: { in: cleared.map((note) => note.id) } },
        });
      }
      // Only this person's devices need the new place.
      await this.syncEmitter.emit(
        tx,
        changed.flatMap((note) => noteEmissions([userId], note.id)),
      );
    });

    return { updated: changed.map((note) => note.id) };
  }
}
