import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { NotesModule } from '../notes/notes.module';
import { ExportController } from './export.controller';
import { ExportService } from './export.service';
import { ImportController } from './import.controller';
import { ImportService } from './import.service';

@Module({
  imports: [AuthModule, NotesModule],
  controllers: [ExportController, ImportController],
  providers: [ExportService, ImportService],
})
export class ImportExportModule {}
