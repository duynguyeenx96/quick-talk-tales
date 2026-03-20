import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { StoriesController } from './stories.controller';
import { StoriesService } from './stories.service';
import { Story, Category, Tag, UserStoryProgress, UserRating } from '../database/entities';

@Module({
  imports: [TypeOrmModule.forFeature([Story, Category, Tag, UserStoryProgress, UserRating])],
  controllers: [StoriesController],
  providers: [StoriesService],
  exports: [StoriesService],
})
export class StoriesModule {}