import {
  Body,
  Controller,
  HttpCode,
  HttpStatus,
  Post,
  UseGuards,
} from '@nestjs/common';
import { SyncService } from './sync.service';
import { SyncRequestDto } from './dto/sync-request.dto';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { AuthGuard } from '../auth/auth.guard';
import { ClientProtocol } from '../common/protocol/client-protocol.decorator';

@Controller('api/sync')
@UseGuards(AuthGuard)
export class SyncController {
  constructor(private readonly syncService: SyncService) {}

  @Post()
  @HttpCode(HttpStatus.OK)
  sync(
    @CurrentUser('id') userId: string,
    @Body() dto: SyncRequestDto,
    @ClientProtocol() protocol?: number,
  ) {
    return this.syncService.sync(userId, dto, protocol);
  }
}
