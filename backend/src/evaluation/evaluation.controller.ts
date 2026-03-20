import {
  Controller,
  Post,
  Get,
  Body,
  Param,
  UseGuards,
  NotFoundException,
  ParseUUIDPipe,
} from '@nestjs/common';
import { EvaluationService } from './evaluation.service';
import { SubmitStoryDto } from './dto/submit-story.dto';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { User } from '../database/entities';

@Controller('evaluation')
@UseGuards(JwtAuthGuard)
export class EvaluationController {
  constructor(private readonly evaluationService: EvaluationService) {}

  @Post('submit')
  submitStory(@Body() dto: SubmitStoryDto, @CurrentUser() user: User) {
    return this.evaluationService.submitStory(dto, user.id);
  }

  @Get('history')
  getHistory(@CurrentUser() user: User) {
    return this.evaluationService.getHistory(user.id);
  }

  @Get('leaderboard')
  getLeaderboard() {
    return this.evaluationService.getLeaderboard();
  }

  @Get('my-stats')
  getMyStats(@CurrentUser() user: User) {
    return this.evaluationService.getMyStats(user.id);
  }

  @Get(':id')
  async getSubmission(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUser() user: User,
  ) {
    const submission = await this.evaluationService.getSubmission(id, user.id);
    if (!submission) throw new NotFoundException('Submission not found');
    return submission;
  }
}
