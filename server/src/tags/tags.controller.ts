import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Put,
  Param,
  Delete,
  UseGuards,
} from '@nestjs/common';
import { TagsService } from './tags.service';
import { CreateTagDto } from './dto/create-tag.dto';
import { UpdateTagDto } from './dto/update-tag.dto';
import { SetTagPositionsDto } from './dto/set-tag-positions.dto';
import { AuthGuard } from '../auth/auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';

@Controller('api/tags')
@UseGuards(AuthGuard)
export class TagsController {
  constructor(private readonly tagsService: TagsService) {}

  @Post()
  create(
    @CurrentUser('id') userId: string,
    @Body() createTagDto: CreateTagDto,
  ) {
    return this.tagsService.create(userId, createTagDto);
  }

  @Get()
  findAll(@CurrentUser('id') userId: string) {
    return this.tagsService.findAll(userId);
  }

  // Places tags in the owner's order.
  @Put('positions')
  setPositions(
    @CurrentUser('id') userId: string,
    @Body() dto: SetTagPositionsDto,
  ) {
    return this.tagsService.setPositions(userId, dto.positions);
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
