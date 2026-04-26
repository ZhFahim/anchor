import { Body, Controller, Post, UseGuards } from '@nestjs/common';
import { AuthGuard } from '../auth/auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { SyncRequestDto } from './dto/sync.dto';
import { SyncService } from './sync.service';

@Controller('api/sync')
@UseGuards(AuthGuard)
export class SyncController {
  constructor(private readonly syncService: SyncService) {}

  @Post()
  sync(@CurrentUser('id') userId: string, @Body() dto: SyncRequestDto) {
    return this.syncService.sync(userId, dto);
  }
}
