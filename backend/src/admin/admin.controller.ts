import {
  Controller,
  Get,
  Patch,
  Param,
  Body,
  Query,
  UseGuards,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Like } from 'typeorm';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { User, UserRole } from '../database/entities';
import { PaymentOrder } from '../database/entities/payment-order.entity';
import { EvaluationService } from '../evaluation/evaluation.service';

@Controller('admin')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.ADMIN)
export class AdminController {
  constructor(
    @InjectRepository(User)
    private usersRepo: Repository<User>,
    @InjectRepository(PaymentOrder)
    private ordersRepo: Repository<PaymentOrder>,
    private evaluationService: EvaluationService,
  ) {}

  @Get('stats')
  async stats() {
    const [totalUsers, premiumUsers, totalOrders, completedOrders] =
      await Promise.all([
        this.usersRepo.count(),
        this.usersRepo.count({ where: { subscriptionPlan: 'premium' } }),
        this.ordersRepo.count(),
        this.ordersRepo.count({ where: { status: 'completed' } }),
      ]);

    return { totalUsers, premiumUsers, totalOrders, completedOrders };
  }

  @Get('users')
  async listUsers(
    @Query('search') search?: string,
    @Query('page') page = '1',
    @Query('limit') limit = '20',
  ) {
    const take = Math.min(Number(limit) || 20, 100);
    const skip = (Math.max(Number(page) || 1, 1) - 1) * take;

    const where = search
      ? [{ username: Like(`%${search}%`) }, { email: Like(`%${search}%`) }]
      : undefined;

    const [users, total] = await this.usersRepo.findAndCount({
      where,
      select: [
        'id', 'username', 'email', 'fullName', 'subscriptionPlan',
        'subscriptionExpiresAt', 'emailVerified', 'authProvider',
        'isActive', 'createdAt',
      ] as any,
      order: { createdAt: 'DESC' },
      take,
      skip,
    });

    return { total, page: Number(page), limit: take, users };
  }

  @Get('users/:id')
  async getUserDetail(@Param('id') id: string) {
    const user = await this.usersRepo.findOne({ where: { id } });
    if (!user) throw new NotFoundException('User not found');

    let referredByUsername: string | null = null;
    if (user.referredByUserId) {
      const referrer = await this.usersRepo.findOne({
        where: { id: user.referredByUserId },
        select: ['username'] as any,
      });
      referredByUsername = referrer?.username ?? null;
    }

    const { passwordHash, verificationToken, verificationTokenExpires, ...safe } = user as any;
    return { ...safe, referredByUsername };
  }

  @Patch('users/:id/subscription')
  async updateSubscription(
    @Param('id') id: string,
    @Body() body: { plan: 'free' | 'premium'; durationDays?: number },
  ) {
    const update: Partial<User> = { subscriptionPlan: body.plan } as any;
    if (body.plan === 'premium') {
      const days = body.durationDays ?? 30;
      (update as any).subscriptionExpiresAt = new Date(Date.now() + days * 24 * 60 * 60 * 1000);
    } else {
      (update as any).subscriptionExpiresAt = null;
    }
    await this.usersRepo.update(id, update);
    return { success: true };
  }

  @Patch('users/:id/active')
  async toggleUserActive(
    @Param('id') id: string,
    @Body() body: { isActive: boolean },
  ) {
    if (typeof body.isActive !== 'boolean') throw new BadRequestException('isActive must be boolean');
    await this.usersRepo.update(id, { isActive: body.isActive });
    const user = await this.usersRepo.findOne({ where: { id } });
    if (!user) throw new NotFoundException('User not found');
    return user;
  }

  @Get('orders')
  async listOrders(
    @Query('page') page = '1',
    @Query('limit') limit = '20',
  ) {
    const take = Math.min(Number(limit) || 20, 100);
    const skip = (Math.max(Number(page) || 1, 1) - 1) * take;

    const [orders, total] = await this.ordersRepo.findAndCount({
      order: { createdAt: 'DESC' },
      take,
      skip,
    });

    return { total, page: Number(page), limit: take, orders };
  }

  @Get('leaderboard')
  async getLeaderboard() {
    return this.evaluationService.getLeaderboard();
  }
}
