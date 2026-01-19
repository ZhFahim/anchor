import {
  Body,
  ConflictException,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { NotesService } from './notes.service';
import { CreateNoteDto } from './dto/create-note.dto';
import { UpdateNoteDto } from './dto/update-note.dto';
import { SyncNotesDto } from './dto/sync-notes.dto';
import { BulkActionDto } from './dto/bulk-action.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { NoteLockService } from './note-lock.service';

@Controller('api/notes')
@UseGuards(JwtAuthGuard)
export class NotesController {
  constructor(
    private readonly notesService: NotesService,
    private readonly noteLockService: NoteLockService,
  ) {}

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
  ) {
    return this.notesService.findAll(userId, search, tagId);
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

  @Post(':id/lock')
  async lock(
    @CurrentUser('id') userId: string,
    @Param('id') id: string,
  ) {
    await this.notesService.findOne(userId, id, true);
    const result = this.noteLockService.acquire(id, 'anchor', userId);
    if (result.status === 'locked') {
      throw new ConflictException({
        message: 'Note is locked',
        lockedBy: result.lockedBy,
        expiresAt: result.expiresAt,
        status: result.status,
      });
    }
    return result;
  }

  @Delete(':id/lock')
  async unlock(
    @CurrentUser('id') userId: string,
    @Param('id') id: string,
  ) {
    await this.notesService.findOne(userId, id, true);
    this.noteLockService.release(id, 'anchor', userId);
    return { status: 'released' };
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
  permanentDelete(
    @CurrentUser('id') userId: string,
    @Param('id') id: string,
  ) {
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
