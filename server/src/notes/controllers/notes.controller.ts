import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  UseGuards,
  Query,
} from '@nestjs/common';
import { NotesService } from '../services/notes.service';
import { CreateNoteDto } from '../dto/create-note.dto';
import { UpdateNoteDto } from '../dto/update-note.dto';
import { SyncNotesDto } from '../dto/sync-notes.dto';
import { BulkActionDto } from '../dto/bulk-action.dto';
import { CurrentUser } from '../../auth/decorators/current-user.decorator';
import { AuthGuard } from '../../auth/auth.guard';

@Controller('api/notes')
@UseGuards(AuthGuard)
export class NotesController {
  constructor(private readonly notesService: NotesService) { }

  @Post()
  create(
    @CurrentUser('id') userId: string,
    @Body() createNoteDto: CreateNoteDto,
  ) {
    return this.notesService.create(userId, createNoteDto);
  }

  @Post('sync')
  sync(@CurrentUser('id') userId: string, @Body() syncDto: SyncNotesDto) {
    return this.notesService.sync(userId, syncDto);
  }

  @Get()
  findAll(
    @CurrentUser('id') userId: string,
    @Query('search') search?: string,
    @Query('tagId') tagId?: string,
    @Query('limit') limit?: string,
  ) {
    return this.notesService.findAll(userId, search, tagId, parseLimit(limit));
  }

  @Get('trash')
  findTrashed(@CurrentUser('id') userId: string) {
    return this.notesService.findTrashed(userId);
  }

  @Get('archive')
  findArchived(@CurrentUser('id') userId: string) {
    return this.notesService.findArchived(userId);
  }

  @Get(':id')
  findOne(@CurrentUser('id') userId: string, @Param('id') id: string) {
    return this.notesService.findOne(userId, id);
  }

  @Patch(':id')
  update(
    @CurrentUser('id') userId: string,
    @Param('id') id: string,
    @Body() updateNoteDto: UpdateNoteDto,
  ) {
    return this.notesService.update(userId, id, updateNoteDto);
  }

  @Patch(':id/restore')
  restore(@CurrentUser('id') userId: string, @Param('id') id: string) {
    return this.notesService.restore(userId, id);
  }

  @Delete(':id')
  remove(@CurrentUser('id') userId: string, @Param('id') id: string) {
    return this.notesService.remove(userId, id);
  }

  @Delete(':id/permanent')
  permanentDelete(@CurrentUser('id') userId: string, @Param('id') id: string) {
    return this.notesService.permanentDelete(userId, id);
  }

  @Post('bulk/delete')
  bulkDelete(
    @CurrentUser('id') userId: string,
    @Body() bulkActionDto: BulkActionDto,
  ) {
    return this.notesService.bulkRemove(userId, bulkActionDto.noteIds);
  }

  @Post('bulk/archive')
  bulkArchive(
    @CurrentUser('id') userId: string,
    @Body() bulkActionDto: BulkActionDto,
  ) {
    return this.notesService.bulkArchive(userId, bulkActionDto.noteIds);
  }
}

const parseLimit = (limit?: string) => {
  if (!limit) {
    return undefined;
  }

  const parsed = Number.parseInt(limit, 10);
  return Number.isNaN(parsed) ? undefined : parsed;
};
