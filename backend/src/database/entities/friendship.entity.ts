import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, ManyToOne, JoinColumn } from 'typeorm';
import { User } from './user.entity';

export enum FriendshipStatus {
  PENDING = 'pending',
  ACCEPTED = 'accepted',
}

@Entity('friendships')
export class Friendship {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'requester_id' })
  requesterId: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'requester_id' })
  requester: User;

  @Column({ name: 'receiver_id' })
  receiverId: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'receiver_id' })
  receiver: User;

  @Column({ type: 'enum', enum: FriendshipStatus, default: FriendshipStatus.PENDING })
  status: FriendshipStatus;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;
}
