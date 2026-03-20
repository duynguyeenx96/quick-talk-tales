import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
  Unique,
} from 'typeorm';
import { User } from './user.entity';
import { Word } from './word.entity';

@Entity('user_word_history')
@Unique(['userId', 'wordId'])
export class UserWordHistory {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'user_id' })
  userId: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user: User;

  @Column({ name: 'word_id' })
  wordId: string;

  @ManyToOne(() => Word, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'word_id' })
  word: Word;

  @Column({ name: 'times_seen', default: 1 })
  timesSeen: number;

  @Column({ name: 'times_missed', default: 0 })
  timesMissed: number;

  @UpdateDateColumn({ name: 'last_seen_at' })
  lastSeenAt: Date;
}
