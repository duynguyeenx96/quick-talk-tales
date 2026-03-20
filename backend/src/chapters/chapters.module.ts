import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ChaptersController } from './chapters.controller';
import { ChaptersService } from './chapters.service';
import { Chapter, Story, UserChapterProgress } from '../database/entities';
import { StoriesModule } from '../stories/stories.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([Chapter, Story, UserChapterProgress]),
    StoriesModule,
  ],
  controllers: [ChaptersController],
  providers: [ChaptersService],
  exports: [ChaptersService],
})
export class ChaptersModule {}