import {
  Injectable,
  NotFoundException,
  ConflictException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateTagDto } from './dto/create-tag.dto';
import { UpdateTagDto } from './dto/update-tag.dto';
import { SyncTagsDto } from './dto/sync-tags.dto';
import {
  getSyncUpdatedAtWindow,
  withForcedSyncIds,
} from '../sync/sync-window.util';

@Injectable()
export class TagsService {
  constructor(private prisma: PrismaService) { }

  async create(userId: string, createTagDto: CreateTagDto) {
    // Check if tag with same name already exists for this user (not deleted)
    const existing = await this.prisma.tag.findFirst({
      where: {
        userId,
        name: createTagDto.name,
        isDeleted: false,
      },
    });

    if (existing) {
      throw new ConflictException('A tag with this name already exists');
    }

    return this.prisma.tag.create({
      data: {
        ...createTagDto,
        userId,
      },
      include: {
        _count: {
          select: {
            notes: {
              where: {
                state: 'active',
                isArchived: false,
              },
            },
          },
        },
      },
    });
  }

  async findAll(userId: string) {
    return this.prisma.tag.findMany({
      where: {
        userId,
        isDeleted: false,
      },
      orderBy: { name: 'asc' },
      include: {
        _count: {
          select: {
            notes: {
              where: {
                state: 'active',
                isArchived: false,
              },
            },
          },
        },
      },
    });
  }

  async findOne(userId: string, id: string) {
    const tag = await this.prisma.tag.findUnique({
      where: { id },
      include: {
        _count: {
          select: {
            notes: {
              where: {
                state: 'active',
                isArchived: false,
              },
            },
          },
        },
      },
    });

    if (!tag || tag.userId !== userId || tag.isDeleted) {
      throw new NotFoundException('Tag not found');
    }

    return tag;
  }

  async update(userId: string, id: string, updateTagDto: UpdateTagDto) {
    await this.findOne(userId, id);

    // Check for name conflict if name is being updated
    if (updateTagDto.name) {
      const existing = await this.prisma.tag.findFirst({
        where: {
          userId,
          name: updateTagDto.name,
          isDeleted: false,
          id: { not: id },
        },
      });

      if (existing) {
        throw new ConflictException('A tag with this name already exists');
      }
    }

    return this.prisma.tag.update({
      where: { id },
      data: updateTagDto,
      include: {
        _count: {
          select: {
            notes: {
              where: {
                state: 'active',
                isArchived: false,
              },
            },
          },
        },
      },
    });
  }

  async remove(userId: string, id: string) {
    await this.findOne(userId, id);

    return this.prisma.tag.update({
      where: { id },
      data: {
        isDeleted: true,
      },
    });
  }

  // Get notes by tag
  async getNotesByTag(userId: string, tagId: string) {
    await this.findOne(userId, tagId);

    const notes = await this.prisma.note.findMany({
      where: {
        userId,
        state: 'active',
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

    // Transform to include tagIds array
    return notes.map((note) => ({
      ...note,
      tagIds: note.tags.map((t) => t.id),
    }));
  }

  // Sync endpoint for tags
  async sync(userId: string, syncDto: SyncTagsDto) {
    const { lastSyncedAt, changes } = syncDto;
    const incoming = await this.processIncomingSyncChanges(
      userId,
      changes || [],
    );

    const syncCutoff = new Date();
    const forceServerIds = Array.from(incoming.forceServerTagIds);
    const updatedAtWindow = getSyncUpdatedAtWindow(lastSyncedAt, syncCutoff);

    // Get all tags modified after lastSyncedAt
    const serverChanges = await this.prisma.tag.findMany({
      where: {
        userId,
        ...withForcedSyncIds(updatedAtWindow, forceServerIds),
      },
      orderBy: { updatedAt: 'desc' },
      include: {
        _count: {
          select: {
            notes: {
              where: {
                state: 'active',
                isArchived: false,
              },
            },
          },
        },
      },
    });

    return {
      serverChanges,
      processedIds: incoming.processedIds,
      syncedAt: syncCutoff.toISOString(),
    };
  }

  private async processIncomingSyncChanges(
    userId: string,
    changes: SyncTagDto[],
  ): Promise<IncomingTagSyncResult> {
    const processedIds: string[] = [];
    const forceServerTagIds = new Set<string>();

    for (const change of changes) {
      const existingTag = await this.prisma.tag.findUnique({
        where: { id: change.id },
      });

      if (change.isDeleted) {
        if (!existingTag || existingTag.userId !== userId) {
          continue;
        }

        const result = await this.prisma.tag.updateMany({
          where: { id: change.id, userId, updatedAt: existingTag.updatedAt },
          data: { isDeleted: true },
        });

        if (result.count !== 1) {
          forceServerTagIds.add(change.id);
        }

        processedIds.push(change.id);
        continue;
      }

      if (!existingTag) {
        const created = await this.createMissingSyncTag(userId, change);
        if (created) {
          processedIds.push(change.id);
        }
        continue;
      }

      if (existingTag.userId !== userId) {
        continue;
      }

      const clientUpdatedAt = new Date(change.updatedAt || 0);
      const serverUpdatedAt = existingTag.updatedAt;

      if (clientUpdatedAt <= serverUpdatedAt) {
        forceServerTagIds.add(change.id);
        processedIds.push(change.id);
        continue;
      }

      const didUpdate = await this.updateSyncTagIfUnchanged(
        userId,
        change,
        serverUpdatedAt,
      );

      if (!didUpdate) {
        forceServerTagIds.add(change.id);
      }

      processedIds.push(change.id);
    }

    return { processedIds, forceServerTagIds };
  }

  private async createMissingSyncTag(userId: string, change: SyncTagDto) {
    try {
      await this.prisma.tag.create({
        data: {
          id: change.id,
          name: change.name,
          color: change.color,
          userId,
        },
      });
      return true;
    } catch {
      // Might conflict with an existing tag name.
      return false;
    }
  }

  private async updateSyncTagIfUnchanged(
    userId: string,
    change: SyncTagDto,
    serverUpdatedAt: Date,
  ) {
    try {
      const result = await this.prisma.tag.updateMany({
        where: { id: change.id, userId, updatedAt: serverUpdatedAt },
        data: {
          name: change.name,
          color: change.color,
        },
      });

      return result.count === 1;
    } catch {
      // Might conflict with an existing tag name.
      return false;
    }
  }

  // Purge tombstones older than retention period (30 days)
  async purgeTombstones(retentionDays = 30) {
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - retentionDays);

    const result = await this.prisma.tag.deleteMany({
      where: {
        isDeleted: true,
        updatedAt: { lt: cutoffDate },
      },
    });

    return { purgedTagsCount: result.count };
  }
}

interface IncomingTagSyncResult {
  processedIds: string[];
  forceServerTagIds: Set<string>;
}

type SyncTagDto = NonNullable<SyncTagsDto['changes']>[number];
