import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  OneToMany,
} from 'typeorm';
import { Exclude } from 'class-transformer';
import { Story } from './story.entity';
import { UserStoryProgress } from './user-story-progress.entity';
import { UserChapterProgress } from './user-chapter-progress.entity';
import { UserRating } from './user-rating.entity';
import { Comment } from './comment.entity';
import { UserSession } from './user-session.entity';
import { Notification } from './notification.entity';

export enum UserRole {
  ADMIN = 'admin',
  AUTHOR = 'author',
  READER = 'reader',
}

@Entity('users')
export class User {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ unique: true, length: 50 })
  username: string;

  @Column({ unique: true, length: 255 })
  email: string;

  @Column({ name: 'password_hash' })
  @Exclude()
  passwordHash: string;

  @Column({ name: 'full_name', length: 100, nullable: true })
  fullName: string;

  @Column({ name: 'avatar_url', length: 500, nullable: true })
  avatarUrl: string;

  @Column({ type: 'enum', enum: UserRole, default: UserRole.READER })
  role: UserRole;

  @Column({ name: 'is_active', default: true })
  isActive: boolean;

  @Column({ name: 'email_verified', default: false })
  emailVerified: boolean;

  @Column({ name: 'auth_provider', default: 'local' })
  authProvider: string; // 'local' | 'google' | 'facebook'

  @Column({ name: 'google_id', nullable: true, unique: true })
  googleId: string;

  @Column({ name: 'facebook_id', nullable: true, unique: true })
  facebookId: string;

  @Column({ name: 'verification_token', nullable: true })
  verificationToken: string;

  @Column({ name: 'verification_token_expires', nullable: true })
  verificationTokenExpires: Date;

  @Column({ name: 'subscription_plan', default: 'free' })
  subscriptionPlan: string; // 'free' | 'premium'

  @Column({ name: 'subscription_expires_at', nullable: true })
  subscriptionExpiresAt: Date;

  @Column({ name: 'current_streak', default: 0 })
  currentStreak: number;

  @Column({ name: 'longest_streak', default: 0 })
  longestStreak: number;

  @Column({ name: 'last_activity_date', nullable: true, type: 'date' })
  lastActivityDate: Date;

  @Column({ name: 'last_challenge_reward_date', nullable: true, type: 'date' })
  lastChallengeRewardDate: Date;

  @Column({ name: 'referral_code', nullable: true, unique: true, length: 10 })
  referralCode: string;

  @Column({ name: 'referred_by_id', nullable: true })
  referredByUserId: string;

  @Column({ type: 'jsonb', default: {} })
  preferences: Record<string, any>;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;

  @OneToMany(() => Story, story => story.author)
  stories: Story[];

  @OneToMany(() => UserStoryProgress, progress => progress.user)
  storyProgress: UserStoryProgress[];

  @OneToMany(() => UserChapterProgress, progress => progress.user)
  chapterProgress: UserChapterProgress[];

  @OneToMany(() => UserRating, rating => rating.user)
  ratings: UserRating[];

  @OneToMany(() => Comment, comment => comment.user)
  comments: Comment[];

  @OneToMany(() => UserSession, session => session.user)
  sessions: UserSession[];

  @OneToMany(() => Notification, notification => notification.user)
  notifications: Notification[];
}