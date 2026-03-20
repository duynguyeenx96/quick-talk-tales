import {
  Injectable,
  UnauthorizedException,
  ConflictException,
  BadRequestException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import * as bcrypt from 'bcrypt';
import * as crypto from 'crypto';
import { OAuth2Client } from 'google-auth-library';
import { User, UserSession } from '../database/entities';
import { Notification } from '../database/entities/notification.entity';
import { UsersService } from '../users/users.service';
import { EmailService } from '../email/email.service';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';

@Injectable()
export class AuthService {
  private googleClient: OAuth2Client;

  constructor(
    @InjectRepository(User)
    private usersRepository: Repository<User>,
    @InjectRepository(UserSession)
    private userSessionsRepository: Repository<UserSession>,
    @InjectRepository(Notification)
    private notifRepository: Repository<Notification>,
    private usersService: UsersService,
    private jwtService: JwtService,
    private emailService: EmailService,
  ) {
    this.googleClient = new OAuth2Client();
  }

  async validateUser(email: string, password: string): Promise<any> {
    const user = await this.usersService.findByEmail(email);
    if (user && await bcrypt.compare(password, user.passwordHash)) {
      const { passwordHash, ...result } = user;
      return result;
    }
    return null;
  }

  async register(registerDto: RegisterDto) {
    const existingUser = await this.usersService.findByEmailOrUsername(
      registerDto.email,
      registerDto.username,
    );

    if (existingUser) {
      if (existingUser.email === registerDto.email) {
        throw new ConflictException('Email already exists');
      }
      if (existingUser.username === registerDto.username) {
        throw new ConflictException('Username already exists');
      }
    }

    const passwordHash = await bcrypt.hash(registerDto.password, 10);
    const verificationToken = crypto.randomBytes(32).toString('hex');

    // Generate a unique referral code for the new user
    const newReferralCode = Math.random().toString(36).substring(2, 10).toUpperCase();

    const user = this.usersRepository.create({
      username: registerDto.username,
      email: registerDto.email,
      passwordHash,
      fullName: registerDto.fullName,
      authProvider: 'local',
      verificationToken,
      verificationTokenExpires: new Date(Date.now() + 24 * 60 * 60 * 1000),
      referralCode: newReferralCode,
    });

    // Handle referral code provided at registration
    if (registerDto.referralCode) {
      const referrer = await this.usersRepository.findOne({
        where: { referralCode: registerDto.referralCode },
      });

      if (referrer) {
        // Grant referrer +3 days premium (extend from max of now or current expiry)
        const referrerBase =
          referrer.subscriptionExpiresAt && referrer.subscriptionExpiresAt > new Date()
            ? referrer.subscriptionExpiresAt
            : new Date();
        const referrerNewExpiry = new Date(referrerBase.getTime() + 3 * 24 * 60 * 60 * 1000);
        await this.usersRepository.update(referrer.id, {
          subscriptionPlan: 'premium',
          subscriptionExpiresAt: referrerNewExpiry,
        });

        // Grant new user +1 day premium
        user.subscriptionPlan = 'premium';
        user.subscriptionExpiresAt = new Date(Date.now() + 1 * 24 * 60 * 60 * 1000);
        user.referredByUserId = referrer.id;
      }
    }

    const savedUser = await this.usersRepository.save(user);

    // Notify referrer that someone used their code
    if (savedUser.referredByUserId) {
      await this.notifRepository.save(this.notifRepository.create({
        userId: savedUser.referredByUserId,
        type: 'referral_used',
        title: 'Referral Code Used 🎁',
        message: `${savedUser.username} joined using your referral code! You received +3 days Premium.`,
        data: { newUserId: savedUser.id, newUsername: savedUser.username },
        isRead: false,
      }));
    }

    // Send verification email (non-blocking — don't fail registration if email fails)
    this.emailService
      .sendVerificationEmail(savedUser.email, verificationToken, savedUser.username)
      .catch(() => {});

    const { passwordHash: _, ...userResult } = savedUser;
    const tokens = await this.generateTokens(savedUser);
    return { user: userResult, ...tokens };
  }

  async verifyEmail(token: string) {
    const user = await this.usersRepository.findOne({
      where: { verificationToken: token },
    });

    if (!user) {
      throw new BadRequestException('Invalid verification token');
    }
    if (user.verificationTokenExpires < new Date()) {
      throw new BadRequestException('Verification token expired. Request a new one.');
    }

    await this.usersRepository.update(user.id, {
      emailVerified: true,
      verificationToken: null,
      verificationTokenExpires: null,
    });

    return { message: 'Email verified successfully! You can now log in.' };
  }

  async resendVerification(userId: string) {
    const user = await this.usersService.findById(userId);

    if (user.emailVerified) {
      throw new BadRequestException('Email is already verified');
    }

    const token = crypto.randomBytes(32).toString('hex');
    await this.usersRepository.update(userId, {
      verificationToken: token,
      verificationTokenExpires: new Date(Date.now() + 24 * 60 * 60 * 1000),
    });

    await this.emailService.sendVerificationEmail(user.email, token, user.username);
    return { message: 'Verification email sent' };
  }

  async googleAuth(idToken: string) {
    let payload: any;
    try {
      const ticket = await this.googleClient.verifyIdToken({ idToken });
      payload = ticket.getPayload();
    } catch {
      throw new UnauthorizedException('Invalid Google token');
    }

    const { email, name, sub: googleId, picture } = payload;

    // Find by googleId first, then fall back to email
    let user = await this.usersRepository.findOne({
      where: [{ googleId }, { email }],
    });

    if (!user) {
      // New user — create from Google profile
      const baseUsername = (email as string).split('@')[0].replace(/[^a-zA-Z0-9_]/g, '');
      const suffix = Math.floor(Math.random() * 9000) + 1000;
      const username = `${baseUsername}_${suffix}`;

      user = this.usersRepository.create({
        email,
        username,
        fullName: name,
        avatarUrl: picture,
        googleId,
        authProvider: 'google',
        emailVerified: true,
        passwordHash: await bcrypt.hash(crypto.randomBytes(32).toString('hex'), 10),
      });
      user = await this.usersRepository.save(user);
    } else if (!user.googleId) {
      // Existing local account — link Google to it
      await this.usersRepository.update(user.id, {
        googleId,
        emailVerified: true,
        avatarUrl: user.avatarUrl || picture,
      });
      user = await this.usersRepository.findOne({ where: { id: user.id } });
    }

    const { passwordHash: _, ...userResult } = user;
    const tokens = await this.generateTokens(user);

    await this.saveRefreshToken(user.id, tokens.refreshToken);
    return { user: userResult, ...tokens };
  }

  async login(user: any, deviceInfo?: any, ipAddress?: string) {
    const tokens = await this.generateTokens(user);
    await this.saveRefreshToken(user.id, tokens.refreshToken, deviceInfo, ipAddress);
    return { user, ...tokens };
  }

  async generateTokens(user: any) {
    const payload = { email: user.email, sub: user.id, role: user.role };

    const [accessToken, refreshToken] = await Promise.all([
      this.jwtService.signAsync(payload),
      this.jwtService.signAsync(payload, { expiresIn: '7d' }),
    ]);

    return { accessToken, refreshToken };
  }

  async saveRefreshToken(
    userId: string,
    refreshToken: string,
    deviceInfo?: any,
    ipAddress?: string,
  ) {
    const refreshTokenHash = await bcrypt.hash(refreshToken, 10);
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 7);

    const session = this.userSessionsRepository.create({
      userId,
      refreshTokenHash,
      deviceInfo: deviceInfo || {},
      ipAddress,
      expiresAt,
    });

    await this.userSessionsRepository.save(session);
  }

  async refreshTokens(refreshToken: string) {
    try {
      const payload = this.jwtService.verify(refreshToken);
      const sessions = await this.userSessionsRepository.find({
        where: { userId: payload.sub },
      });

      let validSession = null;
      for (const session of sessions) {
        const isValid = await bcrypt.compare(refreshToken, session.refreshTokenHash);
        if (isValid && session.expiresAt > new Date()) {
          validSession = session;
          break;
        }
      }

      if (!validSession) {
        throw new UnauthorizedException('Invalid refresh token');
      }

      const user = await this.usersService.findById(payload.sub);
      if (!user || !user.isActive) {
        throw new UnauthorizedException('User not found or inactive');
      }

      const tokens = await this.generateTokens(user);
      await this.userSessionsRepository.update(validSession.id, {
        refreshTokenHash: await bcrypt.hash(tokens.refreshToken, 10),
        lastUsedAt: new Date(),
      });

      return tokens;
    } catch {
      throw new UnauthorizedException('Invalid refresh token');
    }
  }

  async logout(userId: string, refreshToken?: string) {
    if (refreshToken) {
      const sessions = await this.userSessionsRepository.find({
        where: { userId },
      });
      for (const session of sessions) {
        const isValid = await bcrypt.compare(refreshToken, session.refreshTokenHash);
        if (isValid) {
          await this.userSessionsRepository.remove(session);
          break;
        }
      }
    } else {
      await this.userSessionsRepository.delete({ userId });
    }
    return { message: 'Logged out successfully' };
  }
}
