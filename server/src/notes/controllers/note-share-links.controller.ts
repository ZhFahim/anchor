import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Put,
  Res,
  StreamableFile,
  UseGuards,
} from '@nestjs/common';
import type { Response } from 'express';
import { NoteShareLinksService } from '../services/note-share-links.service';
import {
  SetNoteShareLinkDto,
  UpdateLinkedNoteDto,
} from '../dto/note-share-link.dto';
import { servedMimeType } from '../utils/attachment-storage.util';
import { CurrentUser } from '../../auth/decorators/current-user.decorator';
import { contentDisposition } from '../../common/utils/content-disposition.util';
import { AuthGuard } from '../../auth/auth.guard';

/** The owner's side: making, changing and taking away a note's link. */
@Controller('api/notes')
@UseGuards(AuthGuard)
export class NoteShareLinksController {
  constructor(private readonly noteShareLinksService: NoteShareLinksService) {}

  @Get(':id/link')
  getLink(@CurrentUser('id') userId: string, @Param('id') noteId: string) {
    return this.noteShareLinksService.getLink(userId, noteId);
  }

  @Put(':id/link')
  setLink(
    @CurrentUser('id') userId: string,
    @Param('id') noteId: string,
    @Body() dto: SetNoteShareLinkDto,
  ) {
    return this.noteShareLinksService.setLink(userId, noteId, dto.permission);
  }

  @Delete(':id/link')
  removeLink(@CurrentUser('id') userId: string, @Param('id') noteId: string) {
    return this.noteShareLinksService.removeLink(userId, noteId);
  }
}

/** The link's side: no account, only the token in the link. */
@Controller('api/shared')
export class SharedNotesController {
  constructor(private readonly noteShareLinksService: NoteShareLinksService) {}

  @Get(':token')
  open(@Param('token') token: string) {
    return this.noteShareLinksService.openLink(token);
  }

  @Patch(':token')
  update(@Param('token') token: string, @Body() dto: UpdateLinkedNoteDto) {
    return this.noteShareLinksService.updateLinkedNote(token, dto);
  }

  @Get(':token/attachments/:id')
  async serveFile(
    @Param('token') token: string,
    @Param('id') attachmentId: string,
    @Res({ passthrough: true }) res: Response,
  ) {
    const { stream, attachment } =
      await this.noteShareLinksService.serveLinkedFile(token, attachmentId);

    const isFile = attachment.type === 'file';
    res.set({
      'Content-Type': servedMimeType(attachment.type, attachment.mimeType),
      'Content-Disposition': contentDisposition(
        isFile ? 'attachment' : 'inline',
        attachment.originalFilename,
      ),
      'Content-Length': attachment.fileSize.toString(),
      // Not immutable like the owner's: taking the link away should stop it.
      'Cache-Control': 'private, no-cache',
      'X-Content-Type-Options': 'nosniff',
    });

    return new StreamableFile(stream);
  }
}
