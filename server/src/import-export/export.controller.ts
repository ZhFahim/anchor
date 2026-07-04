import { Controller, Get, Res, UseGuards } from '@nestjs/common';
import type { Response } from 'express';
import { ExportService } from './export.service';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { AuthGuard } from '../auth/auth.guard';

@Controller('api/export')
@UseGuards(AuthGuard)
export class ExportController {
  constructor(private readonly exportService: ExportService) {}

  @Get()
  async export(
    @CurrentUser('id') userId: string,
    @Res() res: Response,
  ): Promise<void> {
    await this.exportService.streamExport(userId, res);
  }
}
