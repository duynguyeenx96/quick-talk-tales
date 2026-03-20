import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  OneToMany,
} from 'typeorm';
import { ClassroomParticipant } from './classroom-participant.entity';

@Entity('classroom_sessions')
export class ClassroomSession {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  // Words assigned to this session
  @Column({ name: 'word_set', type: 'simple-array' })
  wordSet: string[];

  @Column({ name: 'word_count', type: 'int' })
  wordCount: number;

  @Column({ name: 'start_time' })
  startTime: Date;

  // Submission window closes at endTime
  @Column({ name: 'end_time' })
  endTime: Date;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @OneToMany(() => ClassroomParticipant, p => p.session)
  participants: ClassroomParticipant[];

  // Computed — not stored
  get status(): 'upcoming' | 'active' | 'ended' {
    const now = new Date();
    if (now < this.startTime) return 'upcoming';
    if (now <= this.endTime) return 'active';
    return 'ended';
  }
}
