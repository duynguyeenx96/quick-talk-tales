import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  OneToMany,
  ManyToMany,
  JoinTable,
  JoinColumn,
} from 'typeorm';
import { User } from './user.entity';
import { Category } from './category.entity';
import { Tag } from './tag.entity';
import { Chapter } from './chapter.entity';
import { UserStoryProgress } from './user-story-progress.entity';
import { UserRating } from './user-rating.entity';
import { Comment } from './comment.entity';

export enum StoryStatus {
  DRAFT = 'draft',
  PUBLISHED = 'published',
  ARCHIVED = 'archived',
}

export enum DifficultyLevel {
  BEGINNER = 'beginner',
  INTERMEDIATE = 'intermediate',
  ADVANCED = 'advanced',
}

@Entity('stories')
export class Story {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ length: 200 })
  title: string;

  @Column({ unique: true, length: 200 })
  slug: string;

  @Column({ type: 'text', nullable: true })
  description: string;

  @Column({ name: 'cover_image_url', length: 500, nullable: true })
  coverImageUrl: string;

  @Column({ name: 'author_id' })
  authorId: string;

  @ManyToOne(() => User, user => user.stories, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'author_id' })
  author: User;

  @Column({ name: 'category_id', nullable: true })
  categoryId: string;

  @ManyToOne(() => Category, category => category.stories, { onDelete: 'SET NULL' })
  @JoinColumn({ name: 'category_id' })
  category: Category;

  @Column({ type: 'enum', enum: StoryStatus, default: StoryStatus.DRAFT })
  status: StoryStatus;

  @Column({ type: 'enum', enum: DifficultyLevel, default: DifficultyLevel.BEGINNER })
  difficulty: DifficultyLevel;

  @Column({ name: 'estimated_reading_time', nullable: true })
  estimatedReadingTime: number;

  @Column({ name: 'is_featured', default: false })
  isFeatured: boolean;

  @Column({ name: 'is_interactive', default: false })
  isInteractive: boolean;

  @Column({ name: 'view_count', default: 0 })
  viewCount: number;

  @Column({ type: 'decimal', precision: 3, scale: 2, default: 0.00 })
  rating: number;

  @Column({ name: 'rating_count', default: 0 })
  ratingCount: number;

  @Column({ name: 'published_at', nullable: true })
  publishedAt: Date;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;

  @OneToMany(() => Chapter, chapter => chapter.story)
  chapters: Chapter[];

  @OneToMany(() => UserStoryProgress, progress => progress.story)
  userProgress: UserStoryProgress[];

  @OneToMany(() => UserRating, rating => rating.story)
  ratings: UserRating[];

  @OneToMany(() => Comment, comment => comment.story)
  comments: Comment[];

  @ManyToMany(() => Tag, tag => tag.stories)
  @JoinTable({
    name: 'story_tags',
    joinColumn: { name: 'story_id', referencedColumnName: 'id' },
    inverseJoinColumn: { name: 'tag_id', referencedColumnName: 'id' },
  })
  tags: Tag[];
}