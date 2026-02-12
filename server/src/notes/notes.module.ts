import { Module } from '@nestjs/common';
import { NotesService } from './services/notes.service';
import { NotesController } from './controllers/notes.controller';
import { NoteSharesService } from './services/note-shares.service';
import { NoteSharesController } from './controllers/note-shares.controller';
import { NoteAccessService } from './services/note-access.service';
import { UsersModule } from '../users/users.module';
import { AuthModule } from '../auth/auth.module';
import { NotesAuthGuard } from '../auth/notes-auth.guard';

@Module({
  imports: [UsersModule, AuthModule],
  controllers: [NotesController, NoteSharesController],
  providers: [
    NotesService,
    NoteSharesService,
    NoteAccessService,
    NotesAuthGuard,
  ],
  exports: [NotesService, NoteSharesService, NoteAccessService],
})
export class NotesModule {}
