import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { User } from './user.entity';

@Entity('story_submissions')
export class StorySubmission {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => User, { nullable: false, onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user: User;

  @Column({ name: 'user_id' })
  userId: string;

  @Column({ name: 'story_text', type: 'text' })
  storyText: string;

  @Column({ name: 'target_words', type: 'simple-array' })
  targetWords: string[];

  @Column({ name: 'words_used', type: 'simple-array', nullable: true })
  wordsUsed: string[];

  @Column({ name: 'words_missing', type: 'simple-array', nullable: true })
  wordsMissing: string[];

  @Column({ name: 'score_grammar', type: 'int', default: 0 })
  scoreGrammar: number;

  @Column({ name: 'score_creativity', type: 'int', default: 0 })
  scoreCreativity: number;

  @Column({ name: 'score_coherence', type: 'int', default: 0 })
  scoreCoherence: number;

  @Column({ name: 'score_word_usage', type: 'int', default: 0 })
  scoreWordUsage: number;

  @Column({ name: 'score_overall', type: 'int', default: 0 })
  scoreOverall: number;

  @Column({ type: 'text', nullable: true })
  feedback: string;

  @Column({ type: 'text', nullable: true })
  encouragement: string;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;
}
