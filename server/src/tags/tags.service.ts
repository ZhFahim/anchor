import {
  Injectable,
  NotFoundException,
  ConflictException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateTagDto } from './dto/create-tag.dto';
import { UpdateTagDto } from './dto/update-tag.dto';
import { SyncEmitterService, tagEmission } from '../sync/sync-emitter.service';
import { NoteState, SyncOp } from 'src/generated/prisma/enums';
import { RETENTION_CHUNK_SIZE } from '../common/retention.constants';
import {
  ERROR_MESSAGES,
  TAG_INCLUDE_NOTE_COUNT,
} from './constants/tags.constants';

@Injectable()
export class TagsService {
  constructor(
    private prisma: PrismaService,
    private syncEmitter: SyncEmitterService,
  ) {}

  async create(userId: string, createTagDto: CreateTagDto) {
    await this.assertNameFree(userId, createTagDto.name);

    return this.prisma.$transaction(async (tx) => {
      const tag = await tx.tag.create({
        data: {
          ...createTagDto,
          userId,
        },
        include: TAG_INCLUDE_NOTE_COUNT,
      });
      await this.syncEmitter.emit(tx, [tagEmission(userId, tag.id)]);
      return tag;
    });
  }

  async findAll(userId: string) {
    return this.prisma.tag.findMany({
      where: {
        userId,
        isDeleted: false,
      },
      orderBy: { name: 'asc' },
      include: TAG_INCLUDE_NOTE_COUNT,
    });
  }

  async findOne(userId: string, id: string) {
    const tag = await this.prisma.tag.findUnique({
      where: { id },
      include: TAG_INCLUDE_NOTE_COUNT,
    });

    if (!tag || tag.userId !== userId || tag.isDeleted) {
      throw new NotFoundException(ERROR_MESSAGES.TAG_NOT_FOUND);
    }

    return tag;
  }

  async update(userId: string, id: string, updateTagDto: UpdateTagDto) {
    const prior = await this.findOne(userId, id);
    const { baseVersion, ...tagData } = updateTagDto;

    if (tagData.name) {
      await this.assertNameFree(userId, tagData.name, id);
    }

    const changed =
      (tagData.name !== undefined && tagData.name !== prior.name) ||
      (tagData.color !== undefined && tagData.color !== prior.color);

    const result = await this.prisma.$transaction(async (tx) => {
      const current = await tx.tag.findUniqueOrThrow({ where: { id } });
      if (baseVersion !== undefined && baseVersion !== current.version) {
        return { conflict: true as const };
      }

      const tag = await tx.tag.update({
        where: { id },
        data: {
          ...tagData,
          ...(changed ? { version: { increment: 1 } } : {}),
        },
        include: TAG_INCLUDE_NOTE_COUNT,
      });
      await this.syncEmitter.emit(tx, [tagEmission(userId, id)]);
      return { conflict: false as const, tag };
    });

    if (result.conflict) {
      throw new ConflictException({
        message: ERROR_MESSAGES.TAG_CHANGED,
        serverTag: await this.findOne(userId, id),
      });
    }

    return result.tag;
  }

  async remove(userId: string, id: string) {
    await this.findOne(userId, id);

    return this.prisma.$transaction(async (tx) => {
      const tag = await tx.tag.update({
        where: { id },
        data: {
          isDeleted: true,
          version: { increment: 1 },
        },
      });
      await this.syncEmitter.emit(tx, [tagEmission(userId, id, SyncOp.remove)]);
      return tag;
    });
  }

  async getNotesByTag(userId: string, tagId: string) {
    await this.findOne(userId, tagId);

    const notes = await this.prisma.note.findMany({
      where: {
        userId,
        state: NoteState.active,
        tags: {
          some: {
            id: tagId,
          },
        },
      },
      orderBy: { updatedAt: 'desc' },
      include: {
        tags: true,
      },
    });

    return notes.map((note) => ({
      ...note,
      tagIds: note.tags.map((t) => t.id),
    }));
  }

  async purgeTombstones(retentionDays = 30) {
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - retentionDays);

    let purgedTagsCount = 0;

    for (;;) {
      const doomed = await this.prisma.tag.findMany({
        where: {
          isDeleted: true,
          updatedAt: { lt: cutoffDate },
        },
        select: { id: true, userId: true },
        take: RETENTION_CHUNK_SIZE,
      });
      if (doomed.length === 0) {
        break;
      }

      const purged = await this.prisma.$transaction(async (tx) => {
        const result = await tx.tag.deleteMany({
          where: { id: { in: doomed.map((tag) => tag.id) } },
        });

        await this.syncEmitter.emit(
          tx,
          doomed.map((tag) => tagEmission(tag.userId, tag.id, SyncOp.remove)),
        );

        return result.count;
      });

      purgedTagsCount += purged;
      if (purged === 0 || doomed.length < RETENTION_CHUNK_SIZE) {
        break;
      }
    }

    return { purgedTagsCount };
  }

  private async assertNameFree(
    userId: string,
    name: string,
    exceptId?: string,
  ) {
    const existing = await this.prisma.tag.findFirst({
      where: {
        userId,
        name,
        isDeleted: false,
        ...(exceptId ? { id: { not: exceptId } } : {}),
      },
    });

    if (existing) {
      throw new ConflictException(ERROR_MESSAGES.TAG_NAME_EXISTS);
    }
  }
}
