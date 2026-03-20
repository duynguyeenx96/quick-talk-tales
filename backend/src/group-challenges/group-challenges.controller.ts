import { Controller, Get, Post, Param, Body, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { User } from '../database/entities';
import { GroupChallengesService } from './group-challenges.service';

@Controller('group-challenges')
@UseGuards(JwtAuthGuard)
export class GroupChallengesController {
  constructor(private readonly service: GroupChallengesService) {}

  @Post()
  create(
    @CurrentUser() user: User,
    @Body() body: { wordCount: number; difficulty: string; durationDays: number; inviteUserIds: string[]; words: string[] },
  ) {
    return this.service.createChallenge(user.id, body);
  }

  @Get()
  getMine(@CurrentUser() user: User) {
    return this.service.getMyChallenges(user.id);
  }

  @Get(':id')
  getDetail(@Param('id') id: string, @CurrentUser() user: User) {
    return this.service.getChallengeDetail(id, user.id);
  }

  @Post(':id/accept')
  accept(@Param('id') id: string, @CurrentUser() user: User) {
    return this.service.acceptChallenge(id, user.id);
  }

  @Post(':id/decline')
  decline(@Param('id') id: string, @CurrentUser() user: User) {
    return this.service.declineChallenge(id, user.id);
  }

  @Post(':id/submit')
  submit(
    @Param('id') id: string,
    @CurrentUser() user: User,
    @Body('storyText') storyText: string,
  ) {
    return this.service.submitStory(id, user.id, storyText);
  }
}
