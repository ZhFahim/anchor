import { Module } from '@nestjs/common';
import { NotesService } from './services/notes.service';
import { NotesController } from './controllers/notes.controller';
import { NoteSharesService } from './services/note-shares.service';
import { NoteSharesController } from './controllers/note-shares.controller';
import { NoteAccessService } from './services/note-access.service';
import { UsersModule } from '../users/users.module';

@Module({
  imports: [UsersModule],
  controllers: [NotesController, NoteSharesController],
  providers: [NotesService, NoteSharesService, NoteAccessService],
  exports: [NotesService, NoteSharesService, NoteAccessService],
})
export class NotesModule {}
