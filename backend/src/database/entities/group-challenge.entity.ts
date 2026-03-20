import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, ManyToOne, OneToMany, JoinColumn } from 'typeorm';
import { User } from './user.entity';
import { ChallengeParticipant } from './challenge-participant.entity';

export enum ChallengeStatus {
  PENDING = 'pending',
  ACTIVE = 'active',
  FINISHED = 'finished',
  CANCELLED = 'cancelled',
}

@Entity('group_challenges')
export class GroupChallenge {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'host_id' })
  hostId: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'host_id' })
  host: User;

  @Column({ name: 'word_count' })
  wordCount: number;

  @Column({ length: 20 })
  difficulty: string;

  @Column({ type: 'text', array: true })
  words: string[];

  @Column({ name: 'duration_days' })
  durationDays: number;

  @Column({ type: 'enum', enum: ChallengeStatus, default: ChallengeStatus.PENDING })
  status: ChallengeStatus;

  @Column({ name: 'started_at', nullable: true })
  startedAt: Date;

  @Column({ name: 'ends_at', nullable: true })
  endsAt: Date;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @OneToMany(() => ChallengeParticipant, p => p.challenge)
  participants: ChallengeParticipant[];
}
