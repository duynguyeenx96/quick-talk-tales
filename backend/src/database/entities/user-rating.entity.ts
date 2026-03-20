import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
  Unique,
  Check,
} from 'typeorm';
import { User } from './user.entity';
import { Story } from './story.entity';

@Entity('user_ratings')
@Unique(['userId', 'storyId'])
@Check('rating >= 1 AND rating <= 5')
export class UserRating {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'user_id' })
  userId: string;

  @ManyToOne(() => User, user => user.ratings, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user: User;

  @Column({ name: 'story_id' })
  storyId: string;

  @ManyToOne(() => Story, story => story.ratings, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'story_id' })
  story: Story;

  @Column()
  rating: number;

  @Column({ type: 'text', nullable: true })
  review: string;

  @Column({ name: 'is_public', default: true })
  isPublic: boolean;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}