import {
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Post,
  UseGuards,
} from '@nestjs/common';
import { NoteLinksService } from '../services/note-links.service';
import { CurrentUser } from '../../auth/decorators/current-user.decorator';
import { AuthGuard } from '../../auth/auth.guard';

/** The owner's side of a note's public link. */
@Controller('api/notes/:id/link')
@UseGuards(AuthGuard)
export class NoteLinksController {
  constructor(private readonly noteLinksService: NoteLinksService) {}

  @Get()
  getLink(@CurrentUser('id') userId: string, @Param('id') noteId: string) {
    return this.noteLinksService.getLink(userId, noteId);
  }

  @Post()
  createLink(@CurrentUser('id') userId: string, @Param('id') noteId: string) {
    return this.noteLinksService.createLink(userId, noteId);
  }

  @Delete()
  @HttpCode(HttpStatus.OK)
  deleteLink(@CurrentUser('id') userId: string, @Param('id') noteId: string) {
    return this.noteLinksService.deleteLink(userId, noteId);
  }
}
