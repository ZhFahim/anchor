import {
  Injectable,
  NotFoundException,
  ConflictException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateTagDto } from './dto/create-tag.dto';
import { UpdateTagDto } from './dto/update-tag.dto';
import { SyncTagsDto } from './dto/sync-tags.dto';

@Injectable()
export class TagsService {
  constructor(private prisma: PrismaService) {}

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
    const processedIds: string[] = [];

    // Process incoming changes from client
    for (const change of changes || []) {
      if (change.isDeleted) {
        // Soft delete tag
        try {
          await this.prisma.tag.update({
            where: { id: change.id },
            data: { isDeleted: true },
          });
        } catch {
          // Tag might not exist, ignore
        }
        processedIds.push(change.id);
        continue;
      }

      const existingTag = await this.prisma.tag.findUnique({
        where: { id: change.id },
      });

      if (!existingTag) {
        // Tag doesn't exist on server - create it
        try {
          await this.prisma.tag.create({
            data: {
              id: change.id,
              name: change.name,
              color: change.color,
              userId,
            },
          });
        } catch {
          // Might conflict with name, ignore
        }
        processedIds.push(change.id);
      } else if (existingTag.userId === userId) {
        // Tag exists - compare timestamps
        const clientUpdatedAt = new Date(change.updatedAt || 0);
        const serverUpdatedAt = existingTag.updatedAt;

        if (clientUpdatedAt > serverUpdatedAt) {
          // Client wins - update server
          try {
            await this.prisma.tag.update({
              where: { id: change.id },
              data: {
                name: change.name,
                color: change.color,
              },
            });
          } catch {
            // Might conflict with name, ignore
          }
        }
        processedIds.push(change.id);
      }
    }

    // Get all tags modified after lastSyncedAt
    const serverChanges = await this.prisma.tag.findMany({
      where: {
        userId,
        updatedAt: lastSyncedAt ? { gt: new Date(lastSyncedAt) } : undefined,
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
      processedIds,
      syncedAt: new Date().toISOString(),
    };
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
