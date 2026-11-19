import { Controller, Get, Param, Res, StreamableFile } from '@nestjs/common';
import type { Response } from 'express';
import { NoteLinksService } from '../services/note-links.service';

/**
 * What anyone holding a note's link can read, without an account. Read only:
 * nothing here writes.
 */
@Controller('api/public/notes/:token')
export class PublicNotesController {
  constructor(private readonly noteLinksService: NoteLinksService) {}

  @Get()
  getNote(
    @Param('token') token: string,
    @Res({ passthrough: true }) res: Response,
  ) {
    // The link may be turned off at any time, so nothing keeps a copy.
    res.set('Cache-Control', 'no-store');
    return this.noteLinksService.getPublicNote(token);
  }

  @Get('attachments/:id')
  async getAttachment(
    @Param('token') token: string,
    @Param('id') attachmentId: string,
    @Res({ passthrough: true }) res: Response,
  ) {
    const { stream, attachment } =
      await this.noteLinksService.openPublicAttachment(token, attachmentId);

    res.set({
      'Content-Type': attachment.mimeType,
      'Content-Disposition': `inline; filename="${encodeURIComponent(attachment.originalFilename)}"`,
      'Content-Length': attachment.fileSize.toString(),
      'Cache-Control': 'no-store',
      'X-Content-Type-Options': 'nosniff',
    });

    return new StreamableFile(stream);
  }
}
