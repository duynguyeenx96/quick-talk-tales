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
import { ClassroomSession } from './classroom-session.entity';

@Entity('classroom_participants')
@Unique(['sessionId', 'userId'])
export class ClassroomParticipant {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'session_id' })
  sessionId: string;

  @ManyToOne(() => ClassroomSession, s => s.participants, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'session_id' })
  session: ClassroomSession;

  @Column({ name: 'user_id' })
  userId: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user: User;

  // Set after story submission
  @Column({ name: 'submission_id', nullable: true })
  submissionId: string;

  // Denormalized for fast leaderboard queries
  @Column({ name: 'score_overall', type: 'int', nullable: true })
  scoreOverall: number;

  @CreateDateColumn({ name: 'joined_at' })
  joinedAt: Date;
}
