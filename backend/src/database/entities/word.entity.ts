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

  @Column({ name: 'is_active', default: true })
  isActive: boolean;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;
}
