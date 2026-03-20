import { Controller, Get, Post, Delete, Param, Query, Body, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { User } from '../database/entities';
import { FriendsService } from './friends.service';

@Controller('friends')
@UseGuards(JwtAuthGuard)
export class FriendsController {
  constructor(private readonly friendsService: FriendsService) {}

  @Get()
  getFriends(@CurrentUser() user: User) {
    return this.friendsService.getFriends(user.id);
  }

  @Get('pending')
  getPending(@CurrentUser() user: User) {
    return this.friendsService.getPendingRequests(user.id);
  }

  @Get('search')
  search(@Query('q') q: string, @CurrentUser() user: User) {
    return this.friendsService.searchUsers(q ?? '', user.id);
  }

  @Post('request')
  sendRequest(@Body('usernameOrId') usernameOrId: string, @CurrentUser() user: User) {
    return this.friendsService.sendRequest(user.id, usernameOrId);
  }

  @Post(':id/accept')
  accept(@Param('id') id: string, @CurrentUser() user: User) {
    return this.friendsService.acceptRequest(user.id, id);
  }

  @Delete(':id')
  remove(@Param('id') id: string, @CurrentUser() user: User) {
    return this.friendsService.declineOrRemove(user.id, id);
  }
}
