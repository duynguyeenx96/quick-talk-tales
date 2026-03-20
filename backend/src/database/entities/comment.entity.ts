import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  OneToMany,
  JoinColumn,
} from 'typeorm';
import { User } from './user.entity';
import { Story } from './story.entity';
import { Chapter } from './chapter.entity';

@Entity('comments')
export class Comment {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'user_id' })
  userId: string;

  @ManyToOne(() => User, user => user.comments, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user: User;

  @Column({ name: 'story_id', nullable: true })
  storyId: string;

  @ManyToOne(() => Story, story => story.comments, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'story_id' })
  story: Story;

  @Column({ name: 'chapter_id', nullable: true })
  chapterId: string;

  @ManyToOne(() => Chapter, chapter => chapter.comments, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'chapter_id' })
  chapter: Chapter;

  @Column({ name: 'parent_comment_id', nullable: true })
  parentCommentId: string;

  @ManyToOne(() => Comment, comment => comment.replies, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'parent_comment_id' })
  parentComment: Comment;

  @OneToMany(() => Comment, comment => comment.parentComment)
  replies: Comment[];

  @Column({ type: 'text' })
  content: string;

  @Column({ name: 'is_approved', default: true })
  isApproved: boolean;

  @Column({ name: 'like_count', default: 0 })
  likeCount: number;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}