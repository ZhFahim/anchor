import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { NotesService } from '../notes/services/notes.service';
import { TagsService } from '../tags/tags.service';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class TasksService {
  private readonly logger = new Logger(TasksService.name);

  constructor(
    private readonly notesService: NotesService,
    private readonly tagsService: TagsService,
    private readonly prisma: PrismaService,
  ) { }

  // Run daily at 2:00 AM to clean up expired refresh tokens
  @Cron(CronExpression.EVERY_DAY_AT_2AM)
  async handleExpiredTokenCleanup() {
    this.logger.log('Starting scheduled expired refresh token cleanup...');

    try {
      const result = await this.prisma.refreshToken.deleteMany({
        where: {
          expiresAt: {
            lt: new Date(),
          },
        },
      });

      this.logger.log(
        `Expired token cleanup completed. Deleted ${result.count} expired refresh tokens.`,
      );
    } catch (error) {
      this.logger.error('Expired token cleanup failed:', error);
    }
  }

  // Run daily at 3:00 AM to purge tombstones older than 30 days
  @Cron(CronExpression.EVERY_DAY_AT_3AM)
  async handleTombstonePurge() {
    this.logger.log('Starting scheduled tombstone purge...');

    try {
      const notesResult = await this.notesService.purgeTombstones(30);
      const tagsResult = await this.tagsService.purgeTombstones(30);

      this.logger.log(
        `Tombstone purge completed. Purged ${notesResult.purgedNotesCount} notes, ${notesResult.purgedSharesCount} shares, and ${tagsResult.purgedTagsCount} tags.`,
      );
    } catch (error) {
      this.logger.error('Tombstone purge failed:', error);
    }
  }
}
