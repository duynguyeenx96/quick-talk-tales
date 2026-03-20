import {
  Controller,
  Post,
  Get,
  Body,
  Query,
  UseGuards,
  Request,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { AuthService } from './auth.service';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { LocalAuthGuard } from '../common/guards/local-auth.guard';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { User } from '../database/entities';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('register')
  async register(@Body() registerDto: RegisterDto) {
    return this.authService.register(registerDto);
  }

  @UseGuards(LocalAuthGuard)
  @Post('login')
  @HttpCode(HttpStatus.OK)
  async login(@Request() req, @Body() loginDto: LoginDto) {
    const deviceInfo = {
      userAgent: req.headers['user-agent'],
      platform: req.headers['sec-ch-ua-platform'],
    };
    const ipAddress = req.ip || req.connection.remoteAddress;
    return this.authService.login(req.user, deviceInfo, ipAddress);
  }

  @Post('google')
  @HttpCode(HttpStatus.OK)
  async googleAuth(@Body('idToken') idToken: string) {
    return this.authService.googleAuth(idToken);
  }

  @Get('verify-email')
  async verifyEmail(@Query('token') token: string) {
    return this.authService.verifyEmail(token);
  }

  @UseGuards(JwtAuthGuard)
  @Post('resend-verification')
  @HttpCode(HttpStatus.OK)
  async resendVerification(@CurrentUser() user: User) {
    return this.authService.resendVerification(user.id);
  }

  @Post('refresh')
  @HttpCode(HttpStatus.OK)
  async refresh(@Body('refreshToken') refreshToken: string) {
    return this.authService.refreshTokens(refreshToken);
  }

  @UseGuards(JwtAuthGuard)
  @Post('logout')
  @HttpCode(HttpStatus.OK)
  async logout(
    @CurrentUser() user: User,
    @Body('refreshToken') refreshToken?: string,
  ) {
    return this.authService.logout(user.id, refreshToken);
  }

  @UseGuards(JwtAuthGuard)
  @Post('profile')
  getProfile(@CurrentUser() user: User) {
    return user;
  }
}
