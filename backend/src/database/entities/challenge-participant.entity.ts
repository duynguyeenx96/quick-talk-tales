import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, ManyToOne, JoinColumn } from 'typeorm';
import { User } from './user.entity';
import { GroupChallenge } from './group-challenge.entity';

export enum ParticipantStatus {
  INVITED = 'invited',
  ACCEPTED = 'accepted',
  DECLINED = 'declined',
  SUBMITTED = 'submitted',
}

@Entity('challenge_participants')
export class ChallengeParticipant {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'challenge_id' })
  challengeId: string;

  @ManyToOne(() => GroupChallenge, c => c.participants)
  @JoinColumn({ name: 'challenge_id' })
  challenge: GroupChallenge;

  @Column({ name: 'user_id' })
  userId: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'user_id' })
  user: User;

  @Column({ type: 'enum', enum: ParticipantStatus, default: ParticipantStatus.INVITED })
  status: ParticipantStatus;

  @Column({ name: 'score', nullable: true, type: 'int' })
  score: number;

  @Column({ name: 'submission_id', nullable: true })
  submissionId: string;

  @Column({ name: 'accepted_at', nullable: true })
  acceptedAt: Date;

  @CreateDateColumn({ name: 'invited_at' })
  invitedAt: Date;
}
