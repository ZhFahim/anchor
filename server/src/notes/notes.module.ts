import { Module } from '@nestjs/common';
import { MulterModule } from '@nestjs/platform-express';
import { NotesService } from './services/notes.service';
import { NotesController } from './controllers/notes.controller';
import { NoteSharesService } from './services/note-shares.service';
import { NoteSharesController } from './controllers/note-shares.controller';
import { NoteAccessService } from './services/note-access.service';
import { NoteAttachmentsService } from './services/note-attachments.service';
import { NoteAttachmentsController } from './controllers/note-attachments.controller';
import { UsersModule } from '../users/users.module';
import { AuthModule } from '../auth/auth.module';

@Module({
  imports: [
    UsersModule,
    AuthModule,
    MulterModule.register({ dest: '/tmp' }),
  ],
  controllers: [NotesController, NoteSharesController, NoteAttachmentsController],
  providers: [NotesService, NoteSharesService, NoteAccessService, NoteAttachmentsService],
  exports: [NotesService, NoteSharesService, NoteAccessService, NoteAttachmentsService],
})
export class NotesModule { }
