import {
  Inject,
  BadRequestException,
  Injectable,
  Logger,
} from '@nestjs/common';
import type { ConfigType } from '@nestjs/config';
import { PrismaService } from '../prisma/prisma.service';
import { NoteAccessService } from '../notes/services/note-access.service';
import { NoteState } from 'src/generated/prisma/enums';
import { StorageConfig } from '../config/configuration';
import { deleteFileIfExists } from '../common/utils/file-system.util';
import {
  assertValidAttachmentFile,
  attachmentTypeForMime,
  writeAttachmentFile,
} from '../notes/utils/attachment-storage.util';
import { toAttachmentResponse } from '../notes/dto/attachment-response.dto';
import {
  SyncEmitterService,
  SyncEmission,
  noteEmissions,
  pinEmission,
  reminderEmission,
  tagEmission,
  attachmentsEmissions,
} from '../sync/sync-emitter.service';
import { IMPORT_ALLOWED_BACKGROUNDS } from './constants/import.constants';
import { SyncReminderRecurrence } from '../sync/dto/sync-request.dto';
import {
  ImportNoteItemDto,
  ImportNoteResult,
  ImportNotesDto,
  ImportNotesResponse,
} from './dto/import-notes.dto';
import * as path from 'path';

/**
 * Truncate to whole seconds: mobile sync clients store timestamps with
 * second precision, and sub-second drift between client and server is a
 * known source of false conflict warnings.
 */
const truncateToSeconds = (iso: string): Date =>
  new Date(Math.floor(new Date(iso).getTime() / 1000) * 1000);

@Injectable()
export class ImportService {
  private readonly logger = new Logger(ImportService.name);

  constructor(
    private prisma: PrismaService,
    private noteAccessService: NoteAccessService,
    private syncEmitter: SyncEmitterService,
    @Inject(StorageConfig.KEY)
    private storageConfig: ConfigType<typeof StorageConfig>,
  ) {}

  async importNotes(
    userId: string,
    dto: ImportNotesDto,
  ): Promise<ImportNotesResponse> {
    const tagResolution = await this.resolveTags(
      userId,
      dto.notes.flatMap((note) => note.tagNames ?? []),
      dto.tags ?? [],
    );

    const skipExisting = dto.skipExisting === true;
    const incomingIds = skipExisting
      ? dto.notes
          .map((note) => note.id)
          .filter((id): id is string => Boolean(id))
      : [];
    const existingNotes = incomingIds.length
      ? await this.prisma.note.findMany({
          where: { id: { in: incomingIds } },
          select: { id: true, userId: true, state: true },
        })
      : [];
    const existingById = new Map(existingNotes.map((note) => [note.id, note]));

    const results: ImportNoteResult[] = [];
    for (const item of dto.notes) {
      results.push(
        await this.importSingleNote(
          userId,
          item,
          skipExisting,
          existingById,
          tagResolution.idByName,
        ),
      );
    }

    // Notes are committed one by one above, so their index rows land together
    // in a single trailing transaction.
    const emissions: SyncEmission[] = tagResolution.createdIds.map((tagId) =>
      tagEmission(userId, tagId),
    );
    results.forEach((result, index) => {
      if (
        result.status === 'failed' ||
        result.status === 'skipped' ||
        !result.noteId
      ) {
        return;
      }
      emissions.push(...noteEmissions([userId], result.noteId));
      if (dto.notes[index].isPinned === true) {
        emissions.push(pinEmission(userId, result.noteId, true));
      }
      if (dto.notes[index].reminder) {
        emissions.push(reminderEmission(userId, result.noteId, true));
      }
    });
    if (emissions.length) {
      await this.prisma.$transaction(async (tx) => {
        await this.syncEmitter.emit(tx, emissions);
      });
    }

    return {
      results,
      tags: { created: tagResolution.created, reused: tagResolution.reused },
    };
  }

  private async importSingleNote(
    userId: string,
    item: ImportNoteItemDto,
    skipExisting: boolean,
    existingById: Map<string, { userId: string; state: string }>,
    tagIdByName: Map<string, string>,
  ): Promise<ImportNoteResult> {
    let status: ImportNoteResult['status'] = 'created';
    let noteId: string | undefined;

    if (skipExisting && item.id) {
      const existing = existingById.get(item.id);
      if (!existing) {
        // Keep the backup's identity so a later skip-existing import
        // recognizes this note.
        noteId = item.id;
      } else if (
        existing.userId === userId &&
        existing.state !== NoteState.deleted
      ) {
        return { ref: item.ref, status: 'skipped', noteId: item.id };
      } else {
        // Foreign-owned ID, or the user's own permanently deleted note:
        // permanently deleted means gone, so the backup comes in as a
        // fresh copy rather than resurrecting the old identity.
        status = 'remapped';
      }
    }

    const prepared = this.prepareNote(item);
    const tagIds = (item.tagNames ?? [])
      .map((name) => tagIdByName.get(name))
      .filter((id): id is string => Boolean(id));

    const isTrashed = item.isTrashed === true;
    // Timestamps come from the backup; stateChangedAt starts fresh.
    const createdAt = item.createdAt
      ? truncateToSeconds(item.createdAt)
      : undefined;
    const updatedAt = item.updatedAt
      ? truncateToSeconds(item.updatedAt)
      : undefined;

    try {
      const created = await this.prisma.$transaction(async (tx) => {
        const note = await tx.note.create({
          data: {
            ...(noteId ? { id: noteId } : {}),
            title: item.title,
            content: prepared.content,
            isArchived: item.isArchived === true,
            background: prepared.background,
            state: isTrashed ? NoteState.trashed : NoteState.active,
            userId,
            ...(createdAt ? { createdAt } : {}),
            ...(updatedAt ? { updatedAt } : {}),
            ...(tagIds.length
              ? { tags: { connect: tagIds.map((id) => ({ id })) } }
              : {}),
          },
          select: { id: true },
        });

        if (item.isPinned === true) {
          await tx.notePin.create({
            data: { userId, noteId: note.id },
          });
        }

        if (item.reminder) {
          await tx.noteReminder.create({
            data: {
              userId,
              noteId: note.id,
              remindAt: item.reminder.remindAt,
              recurrence:
                item.reminder.recurrence ?? SyncReminderRecurrence.none,
            },
          });
        }

        return note;
      });

      return {
        ref: item.ref,
        status,
        noteId: created.id,
        ...(prepared.warning ? { warning: prepared.warning } : {}),
      };
    } catch (error) {
      this.logger.error(
        `Failed to import note (ref ${item.ref}): ${String(error)}`,
      );
      return {
        ref: item.ref,
        status: 'failed',
        error: 'Failed to create note',
      };
    }
  }

  private prepareNote(item: ImportNoteItemDto): {
    content: string | null;
    background: string | null;
    warning?: string;
  } {
    const warnings: string[] = [];

    let content: string | null = null;
    if (item.content) {
      if (this.isValidDeltaContent(item.content)) {
        content = item.content;
      } else {
        warnings.push('Content was not valid note data and was dropped');
      }
    }

    let background: string | null = null;
    if (item.background) {
      if (IMPORT_ALLOWED_BACKGROUNDS.has(item.background)) {
        background = item.background;
      } else {
        warnings.push(`Unknown background "${item.background}" was ignored`);
      }
    }

    return {
      content,
      background,
      ...(warnings.length ? { warning: warnings.join('; ') } : {}),
    };
  }

  private isValidDeltaContent(content: string): boolean {
    try {
      const parsed: unknown = JSON.parse(content);
      return (
        typeof parsed === 'object' &&
        parsed !== null &&
        Array.isArray((parsed as { ops?: unknown }).ops)
      );
    } catch {
      return false;
    }
  }

  private async resolveTags(
    userId: string,
    tagNames: string[],
    palette: { name: string; color?: string }[],
  ): Promise<{
    idByName: Map<string, string>;
    createdIds: string[];
    created: number;
    reused: number;
  }> {
    const colorByName = new Map(
      palette.filter((tag) => tag.color).map((tag) => [tag.name, tag.color]),
    );
    // Exact case-sensitive matching: the app's partial unique index permits
    // "Tag" and "tag" to coexist, so import must not merge them.
    const names = [...new Set([...tagNames, ...palette.map((t) => t.name)])];
    if (!names.length) {
      return { idByName: new Map(), createdIds: [], created: 0, reused: 0 };
    }

    const existing = await this.prisma.tag.findMany({
      where: { userId, name: { in: names }, isDeleted: false },
      select: { id: true, name: true },
    });
    const existingNames = new Set(existing.map((tag) => tag.name));
    const missing = names.filter((name) => !existingNames.has(name));

    if (missing.length) {
      // Color is only applied to newly created tags; existing tags keep theirs.
      await this.prisma.tag.createMany({
        data: missing.map((name) => ({
          name,
          userId,
          ...(colorByName.has(name) ? { color: colorByName.get(name) } : {}),
        })),
        skipDuplicates: true,
      });
    }

    const all = await this.prisma.tag.findMany({
      where: { userId, name: { in: names }, isDeleted: false },
      select: { id: true, name: true },
    });
    const missingNames = new Set(missing);

    return {
      idByName: new Map(all.map((tag) => [tag.name, tag.id])),
      createdIds: all
        .filter((tag) => missingNames.has(tag.name))
        .map((tag) => tag.id),
      created: missing.length,
      reused: existing.length,
    };
  }

  /**
   * Attachment upload variant for imports. Unlike the regular upload route
   * it is owner-only, accepts trashed/archived notes, honors an explicit
   * position, and does not bump note.updatedAt (which would destroy the
   * timestamps preserved during note import).
   */
  async importAttachment(
    userId: string,
    noteId: string,
    file: Express.Multer.File,
    position: number,
  ) {
    await this.noteAccessService.verifyNoteOwnership(userId, noteId);

    assertValidAttachmentFile(file);

    const noteDir = path.join(this.storageConfig.attachmentsDir, noteId);

    let stored: { storedFilename: string; filePath: string } | null = null;
    try {
      stored = await writeAttachmentFile(
        noteDir,
        file.originalname,
        file.buffer,
      );
      const { storedFilename } = stored;

      const attachment = await this.prisma.$transaction(async (tx) => {
        const created = await tx.noteAttachment.create({
          data: {
            noteId,
            uploadedByUserId: userId,
            type: attachmentTypeForMime(file.mimetype),
            originalFilename: file.originalname,
            storedFilename,
            mimeType: file.mimetype,
            fileSize: file.size,
            position,
          },
        });
        const recipients = await this.syncEmitter.noteRecipients(tx, noteId);
        await this.syncEmitter.emit(
          tx,
          attachmentsEmissions(recipients, noteId),
        );
        return created;
      });

      return toAttachmentResponse(attachment);
    } catch {
      if (stored) {
        await deleteFileIfExists(stored.filePath, this.logger);
      }
      throw new BadRequestException('Failed to import attachment');
    }
  }
}
