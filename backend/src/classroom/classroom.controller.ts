import {
  Controller,
  Get,
  Post,
  Param,
  Body,
  UseGuards,
  ParseUUIDPipe,
} from '@nestjs/common';
import { ClassroomService } from './classroom.service';
import { SubmitClassroomStoryDto } from './dto/submit-classroom-story.dto';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { User } from '../database/entities';

@Controller('classroom')
@UseGuards(JwtAuthGuard)
export class ClassroomController {
  constructor(private readonly classroomService: ClassroomService) {}

  /** Returns the active or upcoming session (used by in-app overlay polling). */
  @Get('current')
  getCurrent(@CurrentUser() user: User) {
    return this.classroomService.getCurrentSession(user.id);
  }

  @Get('sessions')
  getSessions() {
    return this.classroomService.getRecentSessions();
  }

  @Get('my-history')
  getMyHistory(@CurrentUser() user: User) {
    return this.classroomService.getMyHistory(user.id);
  }

  @Get('leaderboard/all-time')
  getAllTimeLeaderboard() {
    return this.classroomService.getAllTimeLeaderboard();
  }

  @Get(':id/leaderboard')
  getLeaderboard(@Param('id', ParseUUIDPipe) id: string) {
    return this.classroomService.getLeaderboard(id);
  }

  @Post(':id/join')
  join(@Param('id', ParseUUIDPipe) id: string, @CurrentUser() user: User) {
    return this.classroomService.joinSession(id, user);
  }

  @Post(':id/submit')
  submit(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: SubmitClassroomStoryDto,
    @CurrentUser() user: User,
  ) {
    return this.classroomService.submitClassroomStory(id, user.id, dto);
  }
}
