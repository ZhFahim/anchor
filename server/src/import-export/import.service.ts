import { BadRequestException, Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { NoteAccessService } from '../notes/services/note-access.service';
import { AttachmentType, NoteState } from 'src/generated/prisma/enums';
import {
  ATTACHMENT_ALLOWED_MIME_TYPES,
  ATTACHMENT_MAX_FILE_SIZE,
  ATTACHMENTS_BASE_DIR,
} from '../notes/constants/notes.constants';
import { toAttachmentResponse } from '../notes/dto/attachment-response.dto';
import { IMPORT_ALLOWED_BACKGROUNDS } from './constants/import.constants';
import {
  ImportNoteItemDto,
  ImportNoteResult,
  ImportNotesDto,
  ImportNotesResponse,
} from './dto/import-notes.dto';
import * as crypto from 'crypto';
import * as fs from 'fs/promises';
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

    // One lookup for the whole batch to classify incoming IDs
    const incomingIds = dto.notes
      .map((note) => note.id)
      .filter((id): id is string => Boolean(id));
    const existingNotes = incomingIds.length
      ? await this.prisma.note.findMany({
          where: { id: { in: incomingIds } },
          select: { id: true, userId: true },
        })
      : [];
    const existingOwners = new Map(
      existingNotes.map((note) => [note.id, note.userId]),
    );

    const results: ImportNoteResult[] = [];
    for (const item of dto.notes) {
      results.push(
        await this.importSingleNote(
          userId,
          item,
          existingOwners,
          tagResolution.idByName,
        ),
      );
    }

    return {
      results,
      tags: { created: tagResolution.created, reused: tagResolution.reused },
    };
  }

  private async importSingleNote(
    userId: string,
    item: ImportNoteItemDto,
    existingOwners: Map<string, string>,
    tagIdByName: Map<string, string>,
  ): Promise<ImportNoteResult> {
    let status: ImportNoteResult['status'] = 'created';
    let noteId = item.id;

    if (item.id && existingOwners.has(item.id)) {
      if (existingOwners.get(item.id) === userId) {
        return { ref: item.ref, status: 'skipped', noteId: item.id };
      }
      // ID belongs to another user's note (e.g. re-importing a backup that
      // contains shared-with-me notes onto the same server): new identity.
      status = 'remapped';
      noteId = undefined;
    }

    const prepared = this.prepareNote(item);
    const tagIds = (item.tagNames ?? [])
      .map((name) => tagIdByName.get(name))
      .filter((id): id is string => Boolean(id));

    const isTrashed = item.isTrashed === true;
    // Preserve the backup's modified time; the syncedAt trigger handles sync visibility and the trash purge window.
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
      return { idByName: new Map(), created: 0, reused: 0 };
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

    return {
      idByName: new Map(all.map((tag) => [tag.name, tag.id])),
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

    if (!file) {
      throw new BadRequestException('No file provided');
    }
    if (!ATTACHMENT_ALLOWED_MIME_TYPES.has(file.mimetype)) {
      throw new BadRequestException(
        `File type ${file.mimetype} is not allowed`,
      );
    }
    if (file.size > ATTACHMENT_MAX_FILE_SIZE) {
      throw new BadRequestException(
        `File size exceeds ${ATTACHMENT_MAX_FILE_SIZE / 1024 / 1024}MB limit`,
      );
    }

    const noteDir = path.join(ATTACHMENTS_BASE_DIR, noteId);
    await fs.mkdir(noteDir, { recursive: true });

    const ext = path.extname(file.originalname).toLowerCase();
    const storedFilename = `${crypto.randomUUID()}-${Date.now()}${ext}`;
    const filePath = path.join(noteDir, storedFilename);

    const attachmentType: AttachmentType = file.mimetype.startsWith('image/')
      ? AttachmentType.image
      : AttachmentType.audio;

    let fileSaved = false;
    try {
      await fs.writeFile(filePath, file.buffer);
      fileSaved = true;

      const attachment = await this.prisma.noteAttachment.create({
        data: {
          noteId,
          uploadedByUserId: userId,
          type: attachmentType,
          originalFilename: file.originalname,
          storedFilename,
          mimeType: file.mimetype,
          fileSize: file.size,
          position,
        },
      });

      return toAttachmentResponse(attachment);
    } catch {
      if (fileSaved) {
        try {
          await fs.unlink(filePath);
        } catch {
          this.logger.error(
            `Failed to delete file after DB error: ${filePath}`,
          );
        }
      }
      throw new BadRequestException('Failed to import attachment');
    }
  }
}
