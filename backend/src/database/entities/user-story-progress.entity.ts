import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
  Unique,
} from 'typeorm';
import { User } from './user.entity';
import { Story } from './story.entity';
import { Chapter } from './chapter.entity';

@Entity('user_story_progress')
@Unique(['userId', 'storyId'])
export class UserStoryProgress {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'user_id' })
  userId: string;

  @ManyToOne(() => User, user => user.storyProgress, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user: User;

  @Column({ name: 'story_id' })
  storyId: string;

  @ManyToOne(() => Story, story => story.userProgress, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'story_id' })
  story: Story;

  @Column({ name: 'current_chapter_id', nullable: true })
  currentChapterId: string;

  @ManyToOne(() => Chapter, chapter => chapter.currentForUsers, { onDelete: 'SET NULL' })
  @JoinColumn({ name: 'current_chapter_id' })
  currentChapter: Chapter;

  @Column({ name: 'progress_percentage', type: 'decimal', precision: 5, scale: 2, default: 0.00 })
  progressPercentage: number;

  @Column({ name: 'reading_time', default: 0 })
  readingTime: number;

  @Column({ default: false })
  bookmarked: boolean;

  @Column({ default: false })
  favorite: boolean;

  @CreateDateColumn({ name: 'started_at' })
  startedAt: Date;

  @UpdateDateColumn({ name: 'last_read_at' })
  lastReadAt: Date;

  @Column({ name: 'completed_at', nullable: true })
  completedAt: Date;
}