import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { StorySubmission, User } from '../database/entities';
import { ChallengesService } from './challenges.service';
import { ChallengesController } from './challenges.controller';

@Module({
  imports: [TypeOrmModule.forFeature([StorySubmission, User])],
  controllers: [ChallengesController],
  providers: [ChallengesService],
})
export class ChallengesModule {}
