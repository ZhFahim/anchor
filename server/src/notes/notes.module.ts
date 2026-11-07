import { Module } from '@nestjs/common';
import { MulterModule } from '@nestjs/platform-express';
import { NotesService } from './services/notes.service';
import { NotesController } from './controllers/notes.controller';
import { NoteSharesService } from './services/note-shares.service';
import { NoteSharesController } from './controllers/note-shares.controller';
import { NoteAccessService } from './services/note-access.service';
import { NoteAttachmentsService } from './services/note-attachments.service';
import { NoteAttachmentsController } from './controllers/note-attachments.controller';
import { NoteHistoryService } from './services/note-history.service';
import { NoteRevisionsController } from './controllers/note-revisions.controller';
import { NoteLinksService } from './services/note-links.service';
import { NoteLinksController } from './controllers/note-links.controller';
import { PublicNotesController } from './controllers/public-notes.controller';
import { UsersModule } from '../users/users.module';
import { AuthModule } from '../auth/auth.module';
import { SyncModule } from '../sync/sync.module';

@Module({
  imports: [
    UsersModule,
    AuthModule,
    MulterModule.register({ dest: '/tmp' }),
    SyncModule,
  ],
  controllers: [
    NotesController,
    NoteSharesController,
    NoteAttachmentsController,
    NoteRevisionsController,
    NoteLinksController,
    PublicNotesController,
  ],
  providers: [
    NotesService,
    NoteSharesService,
    NoteAccessService,
    NoteAttachmentsService,
    NoteHistoryService,
    NoteLinksService,
  ],
  exports: [
    NotesService,
    NoteSharesService,
    NoteAccessService,
    NoteAttachmentsService,
    NoteHistoryService,
  ],
})
export class NotesModule {}
