import { Module } from '@nestjs/common';
import { PrismaModule } from '../prisma/prisma.module';
import { SyncModule } from '../sync/sync.module';
import { UserDeletionService } from './user-deletion.service';

@Module({
  imports: [PrismaModule, SyncModule],
  providers: [UserDeletionService],
  exports: [UserDeletionService],
})
export class UserDeletionModule {}
