import { Module } from '@nestjs/common';
import { AdminController } from './admin.controller';
import { AdminService } from './admin.service';
import { PrismaModule } from '../prisma/prisma.module';
import { SettingsModule } from '../settings/settings.module';
import { AuthModule } from '../auth/auth.module';
import { UserDeletionModule } from '../users/user-deletion.module';

@Module({
  imports: [PrismaModule, SettingsModule, AuthModule, UserDeletionModule],
  controllers: [AdminController],
  providers: [AdminService],
})
export class AdminModule {}
