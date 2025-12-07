import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  UseGuards,
} from '@nestjs/common';
import { TagsService } from './tags.service';
import { CreateTagDto } from './dto/create-tag.dto';
import { UpdateTagDto } from './dto/update-tag.dto';
import { SyncTagsDto } from './dto/sync-tags.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';

@Controller('api/tags')
@UseGuards(JwtAuthGuard)
export class TagsController {
  constructor(private readonly tagsService: TagsService) { }

  @Post()
  create(
    @CurrentUser('id') userId: string,
    @Body() createTagDto: CreateTagDto,
  ) {
    return this.tagsService.create(userId, createTagDto);
  }

  @Post('sync')
  sync(@CurrentUser('id') userId: string, @Body() syncDto: SyncTagsDto) {
    return this.tagsService.sync(userId, syncDto);
  }

  @Get()
  findAll(@CurrentUser('id') userId: string) {
    return this.tagsService.findAll(userId);
  }

  @Get(':id')
  findOne(@CurrentUser('id') userId: string, @Param('id') id: string) {
    return this.tagsService.findOne(userId, id);
  }

  @Get(':id/notes')
  getNotesByTag(@CurrentUser('id') userId: string, @Param('id') id: string) {
    return this.tagsService.getNotesByTag(userId, id);
  }

  @Patch(':id')
  update(
    @CurrentUser('id') userId: string,
    @Param('id') id: string,
    @Body() updateTagDto: UpdateTagDto,
  ) {
    return this.tagsService.update(userId, id, updateTagDto);
  }

  @Delete(':id')
  remove(@CurrentUser('id') userId: string, @Param('id') id: string) {
    return this.tagsService.remove(userId, id);
  }
}
