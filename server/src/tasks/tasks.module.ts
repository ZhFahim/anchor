import { Module } from '@nestjs/common';
import { ScheduleModule } from '@nestjs/schedule';
import { TasksService } from './tasks.service';
import { NotesModule } from '../notes/notes.module';
import { TagsModule } from 'src/tags/tags.module';

@Module({
  imports: [ScheduleModule.forRoot(), NotesModule, TagsModule],
  providers: [TasksService],
})
export class TasksModule {}
