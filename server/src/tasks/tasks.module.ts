import { Module } from '@nestjs/common';
import { ScheduleModule } from '@nestjs/schedule';
import { TasksService } from './tasks.service';
import { NotesModule } from '../notes/notes.module';
import { TagsModule } from 'src/tags/tags.module';
import { PrismaModule } from '../prisma/prisma.module';

@Module({
  imports: [ScheduleModule.forRoot(), NotesModule, TagsModule, PrismaModule],
  providers: [TasksService],
})
export class TasksModule {}
