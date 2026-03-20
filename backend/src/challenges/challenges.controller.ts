import { Controller, Get, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { User } from '../database/entities';
import { ChallengesService } from './challenges.service';

@Controller('challenges')
@UseGuards(JwtAuthGuard)
export class ChallengesController {
  constructor(private readonly challengesService: ChallengesService) {}

  @Get('daily')
  getDailyChallenges(@CurrentUser() user: User) {
    return this.challengesService.getDailyChallenges(user.id);
  }
}
