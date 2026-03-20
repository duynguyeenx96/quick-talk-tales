import { Controller, Get, Patch, Param, Query, UseGuards, ParseIntPipe, DefaultValuePipe } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { User } from '../database/entities';
import { Notification } from '../database/entities/notification.entity';

@Controller('notifications')
@UseGuards(JwtAuthGuard)
export class NotificationsController {
  constructor(
    @InjectRepository(Notification)
    private readonly notifRepo: Repository<Notification>,
  ) {}

  @Get()
  async getNotifications(
    @CurrentUser() user: User,
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number,
    @Query('limit', new DefaultValuePipe(12), ParseIntPipe) limit: number,
  ) {
    const take = Math.min(limit, 50);
    const skip = (page - 1) * take;

    const [notifications, total] = await this.notifRepo.findAndCount({
      where: { userId: user.id },
      order: { createdAt: 'DESC' },
      take,
      skip,
    });

    const unreadCount = await this.notifRepo.count({
      where: { userId: user.id, isRead: false },
    });

    return { notifications, total, page, limit: take, unreadCount };
  }

  @Patch(':id/read')
  async markRead(@CurrentUser() user: User, @Param('id') id: string) {
    await this.notifRepo.update({ id, userId: user.id }, { isRead: true });
    return { success: true };
  }

  @Patch('read-all/all')
  async markAllRead(@CurrentUser() user: User) {
    await this.notifRepo.update({ userId: user.id, isRead: false }, { isRead: true });
    return { success: true };
  }
}
