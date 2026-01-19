import { Module } from '@nestjs/common';
import { NoteLockService } from './note-lock.service';

@Module({
  providers: [NoteLockService],
  exports: [NoteLockService],
})
export class NoteLockModule {}
