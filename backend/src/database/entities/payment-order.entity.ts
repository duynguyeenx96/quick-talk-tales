import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
  CreateDateColumn,
} from 'typeorm';
import { User } from './user.entity';

export type PaymentStatus = 'pending' | 'completed' | 'expired';

@Entity('payment_orders')
export class PaymentOrder {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'user_id' })
  userId: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user: User;

  @Column({ name: 'plan_id' })
  planId: string; // 'premium_monthly' | 'premium_yearly'

  @Column({ type: 'int' })
  amount: number; // VND

  @Column({ name: 'transfer_content', unique: true, length: 50 })
  transferContent: string; // e.g. "QTTALES A1B2C3"

  @Column({ default: 'pending', length: 20 })
  status: PaymentStatus;

  @Column({ name: 'expires_at' })
  expiresAt: Date;

  @Column({ name: 'paid_at', nullable: true })
  paidAt: Date;

  @Column({ name: 'sepay_transaction_id', nullable: true })
  sepayTransactionId: string;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;
}
