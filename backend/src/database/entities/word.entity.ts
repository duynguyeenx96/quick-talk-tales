import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
} from 'typeorm';

export enum WordCategory {
  ANIMAL = 'animal',
  FOOD = 'food',
  NATURE = 'nature',
  OBJECT = 'object',
  ACTION = 'action',
  ADJECTIVE = 'adjective',
  PLACE = 'place',
  PERSON = 'person',
}

export enum WordDifficulty {
  EASY = 'easy',
  MEDIUM = 'medium',
  HARD = 'hard',
}

export enum WordTopic {
  ADVENTURE = 'adventure',
  FANTASY = 'fantasy',
  SCIENCE = 'science',
  DAILY_LIFE = 'daily_life',
  EMOTION = 'emotion',
  NATURE = 'nature',
  MYSTERY = 'mystery',
  SPORT = 'sport',
}

@Entity('words')
export class Word {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ length: 100, unique: true })
  text: string;

  @Column({ type: 'enum', enum: WordCategory })
  category: WordCategory;

  @Column({ type: 'enum', enum: WordDifficulty, default: WordDifficulty.EASY })
  difficulty: WordDifficulty;

  // Comma-separated list of WordTopic values (e.g. "adventure,fantasy")
  // A word can belong to multiple topics.
  @Column({ type: 'simple-array', nullable: true })
  topics: string[];

  @Column({ name: 'is_active', default: true })
  isActive: boolean;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;
}
