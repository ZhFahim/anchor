import {
  Controller,
  Get,
  Post,
  Delete,
  Patch,
  Param,
  Body,
  UseGuards,
  UseInterceptors,
  UploadedFile,
  Res,
  StreamableFile,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import type { Express } from 'express';
import type { Response } from 'express';
import { memoryStorage } from 'multer';
import { NoteAttachmentsService } from '../services/note-attachments.service';
import { ReorderAttachmentsDto } from '../dto/reorder-attachments.dto';
import { ATTACHMENT_MAX_FILE_SIZE } from '../constants/notes.constants';
import { servedMimeType } from '../utils/attachment-storage.util';
import { CurrentUser } from '../../auth/decorators/current-user.decorator';
import { contentDisposition } from '../../common/utils/content-disposition.util';
import { AuthGuard } from '../../auth/auth.guard';

@Controller('api/notes/:noteId/attachments')
@UseGuards(AuthGuard)
export class NoteAttachmentsController {
  constructor(
    private readonly noteAttachmentsService: NoteAttachmentsService,
  ) {}

  @Post()
  @UseInterceptors(
    FileInterceptor('file', {
      storage: memoryStorage(),
      limits: { fileSize: ATTACHMENT_MAX_FILE_SIZE },
      // Browsers send file names as UTF-8; multer reads them as Latin-1.
      defParamCharset: 'utf8',
    }),
  )
  upload(
    @CurrentUser('id') userId: string,
    @Param('noteId') noteId: string,
    @UploadedFile() file: Express.Multer.File,
    @Body('id') clientId?: string,
  ) {
    return this.noteAttachmentsService.upload(userId, noteId, file, clientId);
  }

  @Get()
  findAll(@CurrentUser('id') userId: string, @Param('noteId') noteId: string) {
    return this.noteAttachmentsService.findAll(userId, noteId);
  }

  @Get(':id')
  async serveFile(
    @CurrentUser('id') userId: string,
    @Param('noteId') noteId: string,
    @Param('id') attachmentId: string,
    @Res({ passthrough: true }) res: Response,
  ) {
    const { stream, attachment } = await this.noteAttachmentsService.serveFile(
      userId,
      noteId,
      attachmentId,
    );

    const isFile = attachment.type === 'file';
    res.set({
      'Content-Type': servedMimeType(attachment.type, attachment.mimeType),
      'Content-Disposition': contentDisposition(
        isFile ? 'attachment' : 'inline',
        attachment.originalFilename,
      ),
      'Content-Length': attachment.fileSize.toString(),
      'Cache-Control': 'private, max-age=31536000, immutable',
      'X-Content-Type-Options': 'nosniff',
    });

    return new StreamableFile(stream);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.OK)
  remove(
    @CurrentUser('id') userId: string,
    @Param('noteId') noteId: string,
    @Param('id') attachmentId: string,
  ) {
    return this.noteAttachmentsService.remove(userId, noteId, attachmentId);
  }

  @Patch('reorder')
  reorder(
    @CurrentUser('id') userId: string,
    @Param('noteId') noteId: string,
    @Body() dto: ReorderAttachmentsDto,
  ) {
    return this.noteAttachmentsService.reorder(userId, noteId, dto.orderedIds);
  }
}
