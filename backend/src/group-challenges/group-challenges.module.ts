import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { HttpModule } from '@nestjs/axios';
import { GroupChallenge } from '../database/entities/group-challenge.entity';
import { ChallengeParticipant } from '../database/entities/challenge-participant.entity';
import { User, StorySubmission } from '../database/entities';
import { Notification } from '../database/entities/notification.entity';
import { GroupChallengesService } from './group-challenges.service';
import { GroupChallengesController } from './group-challenges.controller';

@Module({
  imports: [
    TypeOrmModule.forFeature([GroupChallenge, ChallengeParticipant, User, StorySubmission, Notification]),
    HttpModule.register({ timeout: 60000 }),
  ],
  controllers: [GroupChallengesController],
  providers: [GroupChallengesService],
})
export class GroupChallengesModule {}
