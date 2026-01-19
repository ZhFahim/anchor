import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { HomarrIntegrationGuard } from './homarr-integration.guard';
import { HomarrIntegrationService } from './homarr-integration.service';
import { HomarrIntegrationUserId } from './homarr-integration-user-id.decorator';
import { UpdateHomarrNoteDto } from './dto/update-homarr-note.dto';

@Controller('api/integrations/homarr')
@UseGuards(HomarrIntegrationGuard)
export class HomarrIntegrationController {
  constructor(private readonly homarrIntegrationService: HomarrIntegrationService) {}

  @Get('notes')
  listNotes(
    @HomarrIntegrationUserId() userId: string,
    @Query('search') search?: string,
    @Query('tagId') tagId?: string,
    @Query('limit') limit?: string,
  ) {
    return this.homarrIntegrationService.listNotes({
      userId,
      search,
      tagId,
      limit: parseLimit(limit),
    });
  }

  @Get('notes/:id')
  getNote(
    @HomarrIntegrationUserId() userId: string,
    @Param('id') id: string,
  ) {
    return this.homarrIntegrationService.getNote(userId, id);
  }

  @Post('notes/:id/lock')
  lockNote(
    @HomarrIntegrationUserId() userId: string,
    @Param('id') id: string,
  ) {
    return this.homarrIntegrationService.lockNote(userId, id);
  }

  @Delete('notes/:id/lock')
  unlockNote(
    @HomarrIntegrationUserId() userId: string,
    @Param('id') id: string,
  ) {
    return this.homarrIntegrationService.unlockNote(userId, id);
  }

  @Patch('notes/:id')
  updateNote(
    @HomarrIntegrationUserId() userId: string,
    @Param('id') id: string,
    @Body() updateNoteDto: UpdateHomarrNoteDto,
  ) {
    return this.homarrIntegrationService.updateNote(userId, id, updateNoteDto);
  }
}

const parseLimit = (limit?: string) => {
  if (!limit) return undefined;

  const parsed = Number.parseInt(limit, 10);
  return Number.isNaN(parsed) ? undefined : parsed;
};
