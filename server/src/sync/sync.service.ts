import { Injectable } from '@nestjs/common';
import { SyncApplyService } from './sync-apply.service';
import { SyncFeedService } from './sync-feed.service';
import { DEFAULT_SYNC_LIMIT } from './sync.constants';
import { ANCHOR_PROTOCOL } from '../common/protocol/protocol.constants';
import type { SyncRequestDto } from './dto/sync-request.dto';
import type { SyncResponse } from './dto/sync-response.dto';

// Push before pull, so the same response's feed already reflects the results.
@Injectable()
export class SyncService {
  constructor(
    private applyService: SyncApplyService,
    private feedService: SyncFeedService,
  ) {}

  async sync(
    userId: string,
    dto: SyncRequestDto,
    clientProtocol?: number,
  ): Promise<SyncResponse> {
    const results = dto.changes?.length
      ? await this.applyService.apply(userId, dto.changes)
      : [];
    const feed = await this.feedService.pull(
      userId,
      dto.cursor,
      dto.limit ?? DEFAULT_SYNC_LIMIT,
    );
    // Answer in the protocol the caller speaks.
    const protocol = Math.min(
      clientProtocol ?? ANCHOR_PROTOCOL,
      ANCHOR_PROTOCOL,
    );
    return { protocol, results, ...feed };
  }
}
