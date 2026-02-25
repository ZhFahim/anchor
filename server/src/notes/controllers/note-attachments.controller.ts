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
import { CurrentUser } from '../../auth/decorators/current-user.decorator';
import { AuthGuard } from '../../auth/auth.guard';

@Controller('api/notes/:noteId/attachments')
@UseGuards(AuthGuard)
export class NoteAttachmentsController {
  constructor(
    private readonly noteAttachmentsService: NoteAttachmentsService,
  ) { }

  @Post()
  @UseInterceptors(
    FileInterceptor('file', {
      storage: memoryStorage(),
      limits: { fileSize: ATTACHMENT_MAX_FILE_SIZE },
    }),
  )
  upload(
    @CurrentUser('id') userId: string,
    @Param('noteId') noteId: string,
    @UploadedFile() file: Express.Multer.File,
  ) {
    return this.noteAttachmentsService.upload(userId, noteId, file);
  }

  @Get()
  findAll(
    @CurrentUser('id') userId: string,
    @Param('noteId') noteId: string,
  ) {
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

    res.set({
      'Content-Type': attachment.mimeType,
      'Content-Disposition': `inline; filename="${encodeURIComponent(attachment.originalFilename)}"`,
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
