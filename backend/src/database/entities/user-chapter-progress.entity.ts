import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
  Unique,
} from 'typeorm';
import { User } from './user.entity';
import { Chapter } from './chapter.entity';
import { Story } from './story.entity';

@Entity('user_chapter_progress')
@Unique(['userId', 'chapterId'])
export class UserChapterProgress {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'user_id' })
  userId: string;

  @ManyToOne(() => User, user => user.chapterProgress, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user: User;

  @Column({ name: 'chapter_id' })
  chapterId: string;

  @ManyToOne(() => Chapter, chapter => chapter.userProgress, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'chapter_id' })
  chapter: Chapter;

  @Column({ name: 'story_id' })
  storyId: string;

  @ManyToOne(() => Story, story => story.userProgress, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'story_id' })
  storyRelation: Story;

  @Column({ name: 'is_completed', default: false })
  isCompleted: boolean;

  @Column({ name: 'reading_time', default: 0 })
  readingTime: number;

  @Column({ name: 'choices_made', type: 'jsonb', default: [] })
  choicesMade: any[];

  @Column({ name: 'last_position', default: 0 })
  lastPosition: number;

  @CreateDateColumn({ name: 'read_at' })
  readAt: Date;

  @Column({ name: 'completed_at', nullable: true })
  completedAt: Date;
}