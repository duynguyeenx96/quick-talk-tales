import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  OneToMany,
  JoinColumn,
  Unique,
} from 'typeorm';
import { Story } from './story.entity';
import { UserChapterProgress } from './user-chapter-progress.entity';
import { UserStoryProgress } from './user-story-progress.entity';
import { Comment } from './comment.entity';

export enum ChapterType {
  TEXT = 'text',
  INTERACTIVE = 'interactive',
  MULTIMEDIA = 'multimedia',
}

@Entity('chapters')
@Unique(['storyId', 'slug'])
@Unique(['storyId', 'orderIndex'])
export class Chapter {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'story_id' })
  storyId: string;

  @ManyToOne(() => Story, story => story.chapters, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'story_id' })
  story: Story;

  @Column({ length: 200 })
  title: string;

  @Column({ length: 200 })
  slug: string;

  @Column({ type: 'text' })
  content: string;

  @Column({ name: 'chapter_type', type: 'enum', enum: ChapterType, default: ChapterType.TEXT })
  chapterType: ChapterType;

  @Column({ name: 'order_index' })
  orderIndex: number;

  @Column({ name: 'is_published', default: false })
  isPublished: boolean;

  @Column({ name: 'word_count', default: 0 })
  wordCount: number;

  @Column({ name: 'reading_time', default: 0 })
  readingTime: number;

  @Column({ type: 'jsonb', default: {} })
  metadata: Record<string, any>;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;

  @OneToMany(() => UserChapterProgress, progress => progress.chapter)
  userProgress: UserChapterProgress[];

  @OneToMany(() => UserStoryProgress, progress => progress.currentChapter)
  currentForUsers: UserStoryProgress[];

  @OneToMany(() => Comment, comment => comment.chapter)
  comments: Comment[];
}