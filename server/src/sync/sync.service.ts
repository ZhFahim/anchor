import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { NoteSharePermission, NoteState } from '../generated/prisma/enums';
import { Prisma } from '../generated/prisma/client';
import { NoteAccessService } from '../notes/services/note-access.service';
import { transformNote } from '../notes/utils/note-transformer.util';
import {
  NOTE_INCLUDE_TAGS,
  NOTE_INCLUDE_SHARES,
} from '../notes/constants/notes.constants';
import { bumpSyncVersion } from './sync-version';
import {
  SyncOpDto,
  SyncOpResult,
  SyncRequestDto,
  SyncResponse,
  SyncServerChange,
} from './dto/sync.dto';

const NOTE_INCLUDE_ATTACHMENTS_FULL = {
  attachments: {
    where: { isDeleted: false },
    orderBy: { position: 'asc' as const },
  },
} satisfies Prisma.NoteInclude;

const SOFT_PAGE_LIMIT = 1000;

@Injectable()
export class SyncService {
  constructor(
    private prisma: PrismaService,
    private noteAccessService: NoteAccessService,
  ) {}

  async sync(userId: string, dto: SyncRequestDto): Promise<SyncResponse> {
    const cursor = parseCursor(dto.cursor);

    const results: SyncOpResult[] = [];
    for (const op of dto.ops || []) {
      results.push(await this.applyOpWithIdempotency(userId, op));
    }

    const { serverChanges, revokedSharedNoteIds, newCursor, hasMore } =
      await this.pullChanges(userId, cursor);

    return {
      results,
      serverChanges,
      revokedSharedNoteIds,
      newCursor: newCursor.toString(),
      hasMore,
    };
  }

  private async applyOpWithIdempotency(
    userId: string,
    op: SyncOpDto,
  ): Promise<SyncOpResult> {
    return this.prisma.$transaction(async (tx) => {
      const existing = await tx.syncOpLog.findUnique({
        where: { userId_clientOpId: { userId, clientOpId: op.clientOpId } },
      });

      if (existing) {
        const stored = JSON.parse(existing.resultJson) as SyncOpResult;
        return { ...stored, status: 'noop' as const };
      }

      const result = await this.dispatchOp(tx, userId, op);

      await tx.syncOpLog.create({
        data: {
          userId,
          clientOpId: op.clientOpId,
          entityType: op.entityType,
          entityId: op.entityId,
          resultJson: JSON.stringify(result),
        },
      });

      return result;
    });
  }

  private async dispatchOp(
    tx: Prisma.TransactionClient,
    userId: string,
    op: SyncOpDto,
  ): Promise<SyncOpResult> {
    switch (op.entityType) {
      case 'note':
        return this.applyNoteOp(tx, userId, op);
      case 'tag':
        return this.applyTagOp(tx, userId, op);
      case 'note_attachment':
        return this.applyAttachmentOp(tx, userId, op);
      default:
        return rejected(op, 'unknown_entity_type');
    }
  }

  private async applyNoteOp(
    tx: Prisma.TransactionClient,
    userId: string,
    op: SyncOpDto,
  ): Promise<SyncOpResult> {
    const existing = await tx.note.findUnique({
      where: { id: op.entityId },
      include: {
        ...NOTE_INCLUDE_TAGS,
        ...NOTE_INCLUDE_SHARES,
        ...NOTE_INCLUDE_ATTACHMENTS_FULL,
      },
    });

    if (op.op === 'delete') {
      if (!existing) {
        return {
          clientOpId: op.clientOpId,
          status: 'applied',
          entityId: op.entityId,
        };
      }
      if (existing.userId !== userId) {
        return rejected(op, 'permission_denied');
      }
      const syncVersion = await bumpSyncVersion(tx);
      const updated = await tx.note.update({
        where: { id: op.entityId },
        data: { state: NoteState.deleted, syncVersion },
        include: {
          ...NOTE_INCLUDE_TAGS,
          ...NOTE_INCLUDE_SHARES,
          ...NOTE_INCLUDE_ATTACHMENTS_FULL,
        },
      });
      return applied(op, syncVersion, transformNoteForSync(updated, userId));
    }

    const payload = op.payload ?? {};

    if (!existing) {
      const syncVersion = await bumpSyncVersion(tx);
      const created = await tx.note.create({
        data: {
          id: op.entityId,
          title: stringField(payload, 'title') ?? '',
          content: stringField(payload, 'content'),
          isPinned: boolField(payload, 'isPinned') ?? false,
          isArchived: boolField(payload, 'isArchived') ?? false,
          background: stringField(payload, 'background'),
          state: stateField(payload) ?? NoteState.active,
          userId,
          syncVersion,
          tags: tagIdsField(payload)?.length
            ? { connect: tagIdsField(payload)!.map((id) => ({ id })) }
            : undefined,
        },
        include: {
          ...NOTE_INCLUDE_TAGS,
          ...NOTE_INCLUDE_SHARES,
          ...NOTE_INCLUDE_ATTACHMENTS_FULL,
        },
      });
      return applied(op, syncVersion, transformNoteForSync(created, userId));
    }

    const access = await this.noteAccessService.hasNoteAccess(
      userId,
      op.entityId,
      NoteSharePermission.editor,
    );
    if (!access.hasAccess) {
      return rejected(op, 'permission_denied');
    }

    const baseSyncVersion = parseBaseSyncVersion(op.baseSyncVersion);
    if (baseSyncVersion !== null && existing.syncVersion > baseSyncVersion) {
      // Server is ahead — server wins. Client decides whether to overwrite local.
      return {
        clientOpId: op.clientOpId,
        status: 'applied',
        entityId: op.entityId,
        syncVersion: existing.syncVersion.toString(),
        serverRow: transformNoteForSync(existing, userId),
        serverWon: true,
      };
    }

    const syncVersion = await bumpSyncVersion(tx);
    const data: Prisma.NoteUpdateInput = {
      title: stringField(payload, 'title') ?? existing.title,
      content:
        payload.content === undefined
          ? existing.content
          : stringField(payload, 'content'),
      isPinned: boolField(payload, 'isPinned') ?? existing.isPinned,
      background:
        payload.background === undefined
          ? existing.background
          : stringField(payload, 'background'),
      syncVersion,
    };
    if (access.isOwner) {
      const isArchived = boolField(payload, 'isArchived');
      if (isArchived !== undefined) data.isArchived = isArchived;
      const state = stateField(payload);
      if (state !== undefined) data.state = state;
    }
    const tagIds = tagIdsField(payload);
    if (tagIds !== undefined) {
      data.tags = { set: tagIds.map((id) => ({ id })) };
    }

    const updated = await tx.note.update({
      where: { id: op.entityId },
      data,
      include: {
        ...NOTE_INCLUDE_TAGS,
        ...NOTE_INCLUDE_SHARES,
        ...NOTE_INCLUDE_ATTACHMENTS_FULL,
      },
    });

    return applied(op, syncVersion, transformNoteForSync(updated, userId));
  }

  private async applyTagOp(
    tx: Prisma.TransactionClient,
    userId: string,
    op: SyncOpDto,
  ): Promise<SyncOpResult> {
    const existing = await tx.tag.findUnique({ where: { id: op.entityId } });

    if (op.op === 'delete') {
      if (!existing) {
        return {
          clientOpId: op.clientOpId,
          status: 'applied',
          entityId: op.entityId,
        };
      }
      if (existing.userId !== userId) {
        return rejected(op, 'permission_denied');
      }
      const syncVersion = await bumpSyncVersion(tx);
      const updated = await tx.tag.update({
        where: { id: op.entityId },
        data: { isDeleted: true, syncVersion },
      });
      return applied(op, syncVersion, transformTagForSync(updated));
    }

    const payload = op.payload ?? {};
    const name = stringField(payload, 'name');
    if (!name) {
      return rejected(op, 'name_required');
    }
    const color = stringField(payload, 'color');

    if (!existing) {
      const syncVersion = await bumpSyncVersion(tx);
      try {
        const created = await tx.tag.create({
          data: { id: op.entityId, name, color, userId, syncVersion },
        });
        return applied(op, syncVersion, transformTagForSync(created));
      } catch (err) {
        if (
          err instanceof Prisma.PrismaClientKnownRequestError &&
          err.code === 'P2002'
        ) {
          return rejected(op, 'tag_name_conflict');
        }
        throw err;
      }
    }

    if (existing.userId !== userId) {
      return rejected(op, 'permission_denied');
    }

    const baseSyncVersion = parseBaseSyncVersion(op.baseSyncVersion);
    if (baseSyncVersion !== null && existing.syncVersion > baseSyncVersion) {
      return {
        clientOpId: op.clientOpId,
        status: 'applied',
        entityId: op.entityId,
        syncVersion: existing.syncVersion.toString(),
        serverRow: transformTagForSync(existing),
        serverWon: true,
      };
    }

    const syncVersion = await bumpSyncVersion(tx);
    try {
      const updated = await tx.tag.update({
        where: { id: op.entityId },
        data: { name, color, syncVersion, isDeleted: false },
      });
      return applied(op, syncVersion, transformTagForSync(updated));
    } catch (err) {
      if (
        err instanceof Prisma.PrismaClientKnownRequestError &&
        err.code === 'P2002'
      ) {
        return rejected(op, 'tag_name_conflict');
      }
      throw err;
    }
  }

  // Binary upload still goes through the multipart endpoint; this handles
  // reorder/delete/position ops only.
  private async applyAttachmentOp(
    tx: Prisma.TransactionClient,
    userId: string,
    op: SyncOpDto,
  ): Promise<SyncOpResult> {
    const existing = await tx.noteAttachment.findUnique({
      where: { id: op.entityId },
    });

    if (op.op === 'delete') {
      if (!existing) {
        return {
          clientOpId: op.clientOpId,
          status: 'applied',
          entityId: op.entityId,
        };
      }
      const access = await this.noteAccessService.hasNoteAccess(
        userId,
        existing.noteId,
        NoteSharePermission.editor,
      );
      if (!access.hasAccess) {
        return rejected(op, 'permission_denied');
      }
      if (!access.isOwner && existing.uploadedByUserId !== userId) {
        return rejected(op, 'only_uploader_can_delete');
      }

      const syncVersion = await bumpSyncVersion(tx);
      const updated = await tx.noteAttachment.update({
        where: { id: op.entityId },
        data: { isDeleted: true, syncVersion },
      });

      const noteSyncVersion = await bumpSyncVersion(tx);
      await tx.note.update({
        where: { id: existing.noteId },
        data: { syncVersion: noteSyncVersion },
      });

      return applied(op, syncVersion, updated);
    }

    if (!existing) {
      return rejected(op, 'attachment_must_be_uploaded_first');
    }

    const access = await this.noteAccessService.hasNoteAccess(
      userId,
      existing.noteId,
      NoteSharePermission.editor,
    );
    if (!access.hasAccess) {
      return rejected(op, 'permission_denied');
    }

    const baseSyncVersion = parseBaseSyncVersion(op.baseSyncVersion);
    if (baseSyncVersion !== null && existing.syncVersion > baseSyncVersion) {
      return {
        clientOpId: op.clientOpId,
        status: 'applied',
        entityId: op.entityId,
        syncVersion: existing.syncVersion.toString(),
        serverRow: existing,
        serverWon: true,
      };
    }

    const payload = op.payload ?? {};
    const position = numberField(payload, 'position');
    const syncVersion = await bumpSyncVersion(tx);
    const updated = await tx.noteAttachment.update({
      where: { id: op.entityId },
      data: {
        position: position ?? existing.position,
        syncVersion,
      },
    });

    const noteSyncVersion = await bumpSyncVersion(tx);
    await tx.note.update({
      where: { id: existing.noteId },
      data: { syncVersion: noteSyncVersion },
    });

    return applied(op, syncVersion, updated);
  }

  private async pullChanges(userId: string, cursor: bigint) {
    const ownNotes = await this.prisma.note.findMany({
      where: { userId, syncVersion: { gt: cursor } },
      orderBy: { syncVersion: 'asc' },
      take: SOFT_PAGE_LIMIT,
      include: {
        ...NOTE_INCLUDE_TAGS,
        ...NOTE_INCLUDE_SHARES,
        ...NOTE_INCLUDE_ATTACHMENTS_FULL,
      },
    });

    // Match either a share-level change (revoked, permission flipped) or a
    // content change on the shared note.
    const sharedShares = await this.prisma.noteShare.findMany({
      where: {
        sharedWithUserId: userId,
        OR: [
          { syncVersion: { gt: cursor } },
          {
            isDeleted: false,
            note: { syncVersion: { gt: cursor } },
          },
        ],
      },
      orderBy: { syncVersion: 'asc' },
      take: SOFT_PAGE_LIMIT,
      include: {
        note: {
          include: {
            ...NOTE_INCLUDE_TAGS,
            ...NOTE_INCLUDE_SHARES,
            ...NOTE_INCLUDE_ATTACHMENTS_FULL,
          },
        },
      },
    });

    const tags = await this.prisma.tag.findMany({
      where: { userId, syncVersion: { gt: cursor } },
      orderBy: { syncVersion: 'asc' },
      take: SOFT_PAGE_LIMIT,
    });

    const revokedSharedNoteIds = sharedShares
      .filter((s) => s.isDeleted)
      .map((s) => s.noteId);

    const sharedNoteChanges: SyncServerChange[] = sharedShares
      .filter((s) => !s.isDeleted)
      .map((s) => ({
        entityType: 'note' as const,
        syncVersion: maxBigInt(s.note.syncVersion, s.syncVersion).toString(),
        data: transformNoteForSync(s.note, userId),
      }));

    const ownNoteChanges: SyncServerChange[] = ownNotes.map((n) => ({
      entityType: 'note' as const,
      syncVersion: n.syncVersion.toString(),
      data: transformNoteForSync(n, userId),
      isDeleted: n.state === NoteState.deleted,
    }));

    const tagChanges: SyncServerChange[] = tags.map((t) => ({
      entityType: 'tag' as const,
      syncVersion: t.syncVersion.toString(),
      data: transformTagForSync(t),
      isDeleted: t.isDeleted,
    }));

    const all: SyncServerChange[] = [
      ...ownNoteChanges,
      ...sharedNoteChanges,
      ...tagChanges,
    ];

    all.sort((a, b) => {
      const av = BigInt(a.syncVersion);
      const bv = BigInt(b.syncVersion);
      return av < bv ? -1 : av > bv ? 1 : 0;
    });

    const newCursor =
      all.length === 0 ? cursor : BigInt(all[all.length - 1].syncVersion);

    const hasMore =
      ownNotes.length === SOFT_PAGE_LIMIT ||
      sharedShares.length === SOFT_PAGE_LIMIT ||
      tags.length === SOFT_PAGE_LIMIT;

    return {
      serverChanges: all,
      revokedSharedNoteIds,
      newCursor,
      hasMore,
    };
  }
}

function parseCursor(raw?: string): bigint {
  if (!raw) return 0n;
  try {
    return BigInt(raw);
  } catch {
    return 0n;
  }
}

function parseBaseSyncVersion(raw?: string): bigint | null {
  if (raw === undefined || raw === null || raw === '') return null;
  try {
    return BigInt(raw);
  } catch {
    return null;
  }
}

function maxBigInt(a: bigint, b: bigint): bigint {
  return a > b ? a : b;
}

function applied(
  op: SyncOpDto,
  syncVersion: bigint,
  serverRow: unknown,
): SyncOpResult {
  return {
    clientOpId: op.clientOpId,
    status: 'applied',
    entityId: op.entityId,
    syncVersion: syncVersion.toString(),
    serverRow,
  };
}

function rejected(op: SyncOpDto, reason: string): SyncOpResult {
  return {
    clientOpId: op.clientOpId,
    status: 'rejected',
    entityId: op.entityId,
    reason,
  };
}

function stringField(
  payload: Record<string, unknown>,
  key: string,
): string | undefined {
  const v = payload[key];
  return typeof v === 'string' ? v : undefined;
}

function boolField(
  payload: Record<string, unknown>,
  key: string,
): boolean | undefined {
  const v = payload[key];
  return typeof v === 'boolean' ? v : undefined;
}

function numberField(
  payload: Record<string, unknown>,
  key: string,
): number | undefined {
  const v = payload[key];
  return typeof v === 'number' && Number.isFinite(v) ? v : undefined;
}

function tagIdsField(payload: Record<string, unknown>): string[] | undefined {
  const v = payload.tagIds;
  if (!Array.isArray(v)) return undefined;
  return v.filter((x): x is string => typeof x === 'string');
}

function stateField(payload: Record<string, unknown>): NoteState | undefined {
  const v = payload.state;
  if (v === 'active') return NoteState.active;
  if (v === 'trashed') return NoteState.trashed;
  if (v === 'deleted') return NoteState.deleted;
  return undefined;
}

type NoteWithSyncIncludes = Prisma.NoteGetPayload<{
  include: {
    tags: { select: { id: true; userId: true } };
    sharedWith: {
      where: { isDeleted: false };
      select: {
        id: true;
        permission: true;
        sharedWithUserId: true;
        sharedByUser: {
          select: { id: true; name: true; email: true; profileImage: true };
        };
      };
    };
    attachments: {
      where: { isDeleted: false };
      orderBy: { position: 'asc' };
    };
  };
}>;

type TagRow = Prisma.TagGetPayload<Record<string, never>>;

function transformNoteForSync(
  note: NoteWithSyncIncludes,
  userId: string,
): Record<string, unknown> {
  const base = transformNote(note, userId);
  return {
    ...base,
    syncVersion: note.syncVersion.toString(),
    attachments: note.attachments.map((a) => ({
      id: a.id,
      noteId: a.noteId,
      type: a.type,
      originalFilename: a.originalFilename,
      mimeType: a.mimeType,
      fileSize: a.fileSize,
      position: a.position,
      uploadedByUserId: a.uploadedByUserId,
      syncVersion: a.syncVersion.toString(),
      isDeleted: a.isDeleted,
      createdAt: a.createdAt.toISOString(),
    })),
  };
}

function transformTagForSync(tag: TagRow): Record<string, unknown> {
  return {
    id: tag.id,
    name: tag.name,
    color: tag.color,
    isDeleted: tag.isDeleted,
    syncVersion: tag.syncVersion.toString(),
    updatedAt: tag.updatedAt.toISOString(),
  };
}
