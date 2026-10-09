import { Injectable } from '@nestjs/common';
import type { Prisma } from 'src/generated/prisma/client';
import { RevisionCause } from 'src/generated/prisma/enums';
import { REVISION_COLLAPSE_WINDOW_MS } from './sync.constants';

export interface PriorNoteContent {
  id: string;
  title: string;
  content: string | null;
  version: number;
}

@Injectable()
export class NoteRevisionsService {
  /** With `collapse`, a run of one person's edits keeps only the text before it. */
  async recordEdit(
    tx: Prisma.TransactionClient,
    prior: PriorNoteContent,
    authorUserId: string,
    { collapse = true }: { collapse?: boolean } = {},
  ): Promise<void> {
    const newest = await tx.noteRevision.findFirst({
      where: { noteId: prior.id },
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
      select: { cause: true, authorUserId: true, createdAt: true },
    });

    if (
      collapse &&
      newest &&
      newest.cause === RevisionCause.edit &&
      newest.authorUserId === authorUserId &&
      Date.now() - newest.createdAt.getTime() < REVISION_COLLAPSE_WINDOW_MS
    ) {
      return;
    }

    await tx.noteRevision.create({
      data: {
        noteId: prior.id,
        version: prior.version,
        title: prior.title,
        content: prior.content,
        authorUserId,
        cause: RevisionCause.edit,
      },
    });
  }

  // Versions the client recorded while it held the note; ids come from the
  // device.
  async recordClient(
    tx: Prisma.TransactionClient,
    noteId: string,
    revisions: ClientRevision[],
    authorUserId: string,
  ): Promise<void> {
    const now = Date.now();

    await tx.noteRevision.createMany({
      data: revisions.map((revision) => {
        const recordedAt = Date.parse(revision.createdAt);
        return {
          id: revision.id,
          noteId,
          version: revision.version ?? 0,
          title: revision.title,
          content: revision.content ?? null,
          authorUserId,
          cause:
            revision.cause === 'restore'
              ? RevisionCause.restore
              : RevisionCause.edit,
          createdAt: new Date(
            Number.isNaN(recordedAt) ? now : Math.min(recordedAt, now),
          ),
        };
      }),
      skipDuplicates: true,
    });
  }

  async recordRestore(
    tx: Prisma.TransactionClient,
    prior: PriorNoteContent,
    authorUserId: string,
  ): Promise<void> {
    await tx.noteRevision.create({
      data: {
        noteId: prior.id,
        version: prior.version,
        title: prior.title,
        content: prior.content,
        authorUserId,
        cause: RevisionCause.restore,
      },
    });
  }

  async recordConflict(
    db: Prisma.TransactionClient,
    rejected: RejectedNoteContent,
    authorUserId: string,
  ): Promise<void> {
    const known = await db.noteRevision.findFirst({
      where: {
        noteId: rejected.noteId,
        title: rejected.title,
        content: rejected.content,
      },
      select: { id: true },
    });
    if (known) {
      return;
    }

    await db.noteRevision.create({
      data: {
        noteId: rejected.noteId,
        version: rejected.baseVersion ?? 0,
        title: rejected.title,
        content: rejected.content,
        authorUserId,
        cause: RevisionCause.conflict,
      },
    });
  }
}

export interface ClientRevision {
  id: string;
  version?: number;
  title: string;
  content?: string;
  cause: 'edit' | 'restore';
  createdAt: string;
}

// Whether one of the client's recorded versions already holds this text.
export const revisionsCover = (
  revisions: ClientRevision[] | undefined,
  prior: PriorNoteContent,
): boolean =>
  !!revisions?.some(
    (revision) =>
      revision.title === prior.title &&
      (revision.content ?? null) === prior.content,
  );

export interface RejectedNoteContent {
  noteId: string;
  title: string;
  content: string | null;
  baseVersion?: number;
}
