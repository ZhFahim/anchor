import { Module } from '@nestjs/common';
import { NoteLockModule } from 'src/notes/note-lock.module';
import { PrismaModule } from 'src/prisma/prisma.module';
import { HomarrIntegrationController } from './homarr-integration.controller';
import { HomarrIntegrationGuard } from './homarr-integration.guard';
import { HomarrIntegrationService } from './homarr-integration.service';

@Module({
  imports: [PrismaModule, NoteLockModule],
  controllers: [HomarrIntegrationController],
  providers: [HomarrIntegrationService, HomarrIntegrationGuard],
})
export class HomarrIntegrationModule {}
