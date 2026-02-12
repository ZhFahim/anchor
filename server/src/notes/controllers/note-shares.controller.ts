import {
  Controller,
  Post,
  Get,
  Patch,
  Delete,
  Param,
  Body,
  UseGuards,
} from '@nestjs/common';
import { NoteSharesService } from '../services/note-shares.service';
import { ShareNoteDto } from '../dto/share-note.dto';
import { UpdateNoteSharePermissionDto } from '../dto/update-share-permission.dto';
import { CurrentUser } from '../../auth/decorators/current-user.decorator';
import { NotesAuthGuard } from '../../auth/notes-auth.guard';

@Controller('api/notes')
@UseGuards(NotesAuthGuard)
export class NoteSharesController {
  constructor(private readonly noteSharesService: NoteSharesService) { }

  @Post(':id/shares')
  shareNote(
    @CurrentUser('id') userId: string,
    @Param('id') noteId: string,
    @Body() shareNoteDto: ShareNoteDto,
  ) {
    return this.noteSharesService.shareNote(userId, noteId, shareNoteDto);
  }

  @Get(':id/shares')
  getNoteShares(
    @CurrentUser('id') userId: string,
    @Param('id') noteId: string,
  ) {
    return this.noteSharesService.getNoteShares(noteId, userId);
  }

  @Patch(':id/shares/:shareId')
  updateNoteSharePermission(
    @CurrentUser('id') userId: string,
    @Param('id') noteId: string,
    @Param('shareId') shareId: string,
    @Body() updateDto: UpdateNoteSharePermissionDto,
  ) {
    return this.noteSharesService.updateNoteSharePermission(
      noteId,
      shareId,
      userId,
      updateDto,
    );
  }

  @Delete(':id/shares/:shareId')
  revokeShare(
    @CurrentUser('id') userId: string,
    @Param('id') noteId: string,
    @Param('shareId') shareId: string,
  ) {
    return this.noteSharesService.revokeShare(noteId, shareId, userId);
  }
}
