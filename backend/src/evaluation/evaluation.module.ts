import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { HttpModule } from '@nestjs/axios';
import { StorySubmission, User } from '../database/entities';
import { EvaluationService } from './evaluation.service';
import { EvaluationController } from './evaluation.controller';

@Module({
  imports: [
    TypeOrmModule.forFeature([StorySubmission, User]),
    HttpModule.register({ timeout: 60000 }), // 60s for LLM evaluation
  ],
  controllers: [EvaluationController],
  providers: [EvaluationService],
  exports: [EvaluationService],
})
export class EvaluationModule {}
