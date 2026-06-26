import {
  Body,
  Controller,
  Param,
  Post,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import type { Express } from 'express';
import { memoryStorage } from 'multer';
import { ImportService } from './import.service';
import { ImportNotesDto } from './dto/import-notes.dto';
import { ImportAttachmentDto } from './dto/import-attachment.dto';
import { ATTACHMENT_MAX_FILE_SIZE } from '../notes/constants/notes.constants';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { AuthGuard } from '../auth/auth.guard';

@Controller('api/import')
@UseGuards(AuthGuard)
export class ImportController {
  constructor(private readonly importService: ImportService) {}

  @Post('notes')
  importNotes(@CurrentUser('id') userId: string, @Body() dto: ImportNotesDto) {
    return this.importService.importNotes(userId, dto);
  }

  @Post('notes/:noteId/attachments')
  @UseInterceptors(
    FileInterceptor('file', {
      storage: memoryStorage(),
      limits: { fileSize: ATTACHMENT_MAX_FILE_SIZE },
    }),
  )
  importAttachment(
    @CurrentUser('id') userId: string,
    @Param('noteId') noteId: string,
    @UploadedFile() file: Express.Multer.File,
    @Body() dto: ImportAttachmentDto,
  ) {
    return this.importService.importAttachment(
      userId,
      noteId,
      file,
      dto.position,
    );
  }
}
