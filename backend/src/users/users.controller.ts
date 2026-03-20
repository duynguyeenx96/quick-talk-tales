import {
  Controller,
  Get,
  Post,
  Put,
  Body,
  Param,
  Query,
  UseGuards,
  UseInterceptors,
  UploadedFile,
  ParseUUIDPipe,
  BadRequestException,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import { extname } from 'path';
import { existsSync, mkdirSync } from 'fs';
import { ConfigService } from '@nestjs/config';
import { UsersService } from './users.service';
import { UpdateUserDto } from './dto/update-user.dto';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { User, UserRole } from '../database/entities';
import { PaginationDto } from '../common/dto/pagination.dto';

const SUBSCRIPTION_PLANS = [
  {
    id: 'free',
    name: 'Free',
    price: 0,
    currency: 'USD',
    features: [
      '3 stories per day',
      'Easy & Medium difficulty',
      'Basic AI feedback',
      'Story history (last 20)',
    ],
    limits: { storiesPerDay: 3, difficulties: ['easy', 'medium'] },
  },
  {
    id: 'premium',
    name: 'Premium',
    price: 4.99,
    currency: 'USD',
    billingPeriod: 'month',
    features: [
      'Unlimited stories',
      'All difficulties including Hard ⚡',
      'Detailed AI feedback',
      'Full story history',
      'Leaderboard priority badge',
      'Early access to new features',
    ],
    limits: { storiesPerDay: -1, difficulties: ['easy', 'medium', 'hard'] },
  },
];

@Controller('users')
@UseGuards(JwtAuthGuard)
export class UsersController {
  constructor(
    private readonly usersService: UsersService,
    private readonly configService: ConfigService,
  ) {}

  @Get()
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN)
  async findAll(@Query() pagination: PaginationDto) {
    return this.usersService.findAll(pagination);
  }

  @Get('profile')
  getProfile(@CurrentUser() user: User) {
    return user;
  }

  @Get('referral-code')
  async getReferralCode(@CurrentUser() user: User) {
    if (!user.referralCode) {
      // Generate unique referral code for existing users
      let code: string;
      let exists = true;
      while (exists) {
        code = Math.random().toString(36).substring(2, 10).toUpperCase();
        const existing = await this.usersService.findByReferralCode(code);
        exists = !!existing;
      }
      await this.usersService.updateProfile(user.id, { referralCode: code } as any);
      return { referralCode: code };
    }
    return { referralCode: user.referralCode };
  }

  @Put('profile')
  async updateProfile(@CurrentUser() user: User, @Body() updateUserDto: UpdateUserDto) {
    return this.usersService.updateProfile(user.id, updateUserDto);
  }

  @Post('avatar')
  @UseInterceptors(
    FileInterceptor('file', {
      storage: diskStorage({
        destination: (req, file, cb) => {
          const dest = './uploads/avatars';
          if (!existsSync(dest)) mkdirSync(dest, { recursive: true });
          cb(null, dest);
        },
        filename: (req, file, cb) => {
          const userId = (req as any).user?.id ?? 'unknown';
          const ext = extname(file.originalname).toLowerCase() || '.jpg';
          cb(null, `${userId}-${Date.now()}${ext}`);
        },
      }),
      fileFilter: (req, file, cb) => {
        // Allow by mimetype OR by file extension (macOS sometimes sends
        // 'application/octet-stream' for valid image files picked via NSOpenPanel)
        const allowedMime = /^image\//i.test(file.mimetype);
        const allowedExt = /\.(jpe?g|png|gif|webp|heic|heif)$/i.test(
          file.originalname,
        );
        if (!allowedMime && !allowedExt) {
          return cb(new BadRequestException('Only image files are allowed'), false);
        }
        cb(null, true);
      },
      limits: { fileSize: 5 * 1024 * 1024 }, // 5 MB
    }),
  )
  async uploadAvatar(
    @CurrentUser() user: User,
    @UploadedFile() file: Express.Multer.File,
  ) {
    if (!file) throw new BadRequestException('No file uploaded');
    const baseUrl = this.configService.get<string>('BASE_URL', 'http://localhost:3000');
    const avatarUrl = `${baseUrl}/uploads/avatars/${file.filename}`;
    return this.usersService.updateProfile(user.id, { avatarUrl });
  }

  // ── Subscription ───────────────────────────────────────────────────────────

  @Get('subscription/plans')
  getPlans() {
    return SUBSCRIPTION_PLANS;
  }

  @Post('subscription/mock-upgrade')
  async mockUpgrade(@CurrentUser() user: User, @Body('planId') planId: string) {
    if (!['free', 'premium'].includes(planId)) {
      throw new BadRequestException('Invalid plan');
    }
    const expiresAt =
      planId === 'premium'
        ? new Date(Date.now() + 30 * 24 * 60 * 60 * 1000)
        : null;

    return this.usersService.updateProfile(user.id, {
      subscriptionPlan: planId,
      subscriptionExpiresAt: expiresAt,
    } as any);
  }

  // ── Admin ──────────────────────────────────────────────────────────────────

  @Get(':id')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN)
  async findOne(@Param('id', ParseUUIDPipe) id: string) {
    return this.usersService.findById(id);
  }

  @Put(':id/deactivate')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN)
  async deactivateUser(@Param('id', ParseUUIDPipe) id: string) {
    return this.usersService.deactivateUser(id);
  }

  @Put(':id/activate')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN)
  async activateUser(@Param('id', ParseUUIDPipe) id: string) {
    return this.usersService.activateUser(id);
  }

}
