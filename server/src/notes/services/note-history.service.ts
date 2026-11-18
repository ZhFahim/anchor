import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { NoteSharePermission, NoteState } from 'src/generated/prisma/enums';
import { NoteAccessService } from './note-access.service';
import { transformNote } from '../utils/note-transformer.util';
import { noteContentChanged } from '../utils/note-versioning.util';
import {
  SyncEmitterService,
  noteEmissions,
} from '../../sync/sync-emitter.service';
import { NoteRevisionsService } from '../../sync/note-revisions.service';
import { ListNoteRevisionsDto } from '../dto/list-note-revisions.dto';
import {
  NoteRevisionDto,
  NoteRevisionPageDto,
  toRevision,
  toRevisionSummary,
} from '../dto/note-revision-response.dto';
import {
  DEFAULT_REVISION_PAGE_SIZE,
  ERROR_MESSAGES,
  NOTE_INCLUDE_TAGS,
  USER_SELECT_FIELDS,
  noteArchiveInclude,
  notePinInclude,
  notePositionInclude,
} from '../constants/notes.constants';

const REVISION_ORDER = [
  { createdAt: 'desc' as const },
  { id: 'desc' as const },
];

const REVISION_INCLUDE_AUTHOR = {
  author: { select: USER_SELECT_FIELDS },
} as const;

@Injectable()
export class NoteHistoryService {
  constructor(
    private prisma: PrismaService,
    private noteAccessService: NoteAccessService,
    private syncEmitter: SyncEmitterService,
    private noteRevisions: NoteRevisionsService,
  ) {}

  async list(
    userId: string,
    noteId: string,
    query: ListNoteRevisionsDto,
  ): Promise<NoteRevisionPageDto> {
    await this.ensureHistoryReadable(userId, noteId);

    const limit = query.limit ?? DEFAULT_REVISION_PAGE_SIZE;
    const rows = await this.prisma.noteRevision.findMany({
      where: { noteId },
      include: REVISION_INCLUDE_AUTHOR,
      orderBy: REVISION_ORDER,
      take: limit + 1,
      ...(query.cursor ? { cursor: { id: query.cursor }, skip: 1 } : {}),
    });

    const page = rows.slice(0, limit);
    return {
      revisions: page.map(query.withContent ? toRevision : toRevisionSummary),
      nextCursor: rows.length > limit ? page[page.length - 1].id : null,
    };
  }

  async findOne(
    userId: string,
    noteId: string,
    revisionId: string,
  ): Promise<NoteRevisionDto> {
    await this.ensureHistoryReadable(userId, noteId);

    const revision = await this.prisma.noteRevision.findFirst({
      where: { id: revisionId, noteId },
      include: REVISION_INCLUDE_AUTHOR,
    });

    if (!revision) {
      throw new NotFoundException(ERROR_MESSAGES.REVISION_NOT_FOUND);
    }

    return toRevision(revision);
  }

  async restore(userId: string, noteId: string, revisionId: string) {
    await this.noteAccessService.ensureNoteAccess(
      userId,
      noteId,
      NoteSharePermission.editor,
    );
    await this.noteAccessService.ensureNoteIsActive(noteId);

    const include = {
      ...NOTE_INCLUDE_TAGS,
      ...notePinInclude(userId),
      ...notePositionInclude(userId),
      ...noteArchiveInclude(userId),
    };
    const note = await this.prisma.$transaction(async (tx) => {
      const revision = await tx.noteRevision.findFirst({
        where: { id: revisionId, noteId },
      });
      if (!revision) {
        throw new NotFoundException(ERROR_MESSAGES.REVISION_NOT_FOUND);
      }

      const prior = await tx.note.findUniqueOrThrow({ where: { id: noteId } });
      const restored = { title: revision.title, content: revision.content };

      if (!noteContentChanged(prior, restored)) {
        return tx.note.findUniqueOrThrow({
          where: { id: noteId },
          include,
        });
      }

      await this.noteRevisions.recordRestore(tx, prior, userId);
      const updated = await tx.note.update({
        where: { id: noteId },
        data: { ...restored, version: { increment: 1 } },
        include,
      });

      const recipients = await this.syncEmitter.noteRecipients(tx, noteId);
      await this.syncEmitter.emit(tx, noteEmissions(recipients, noteId));

      return updated;
    });

    return transformNote(note, userId);
  }

  private async ensureHistoryReadable(userId: string, noteId: string) {
    const access = await this.noteAccessService.ensureNoteAccess(
      userId,
      noteId,
      NoteSharePermission.editor,
    );
    if (access.state === NoteState.deleted) {
      throw new NotFoundException(ERROR_MESSAGES.NOTE_NOT_FOUND);
    }
  }
}
