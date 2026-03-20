import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AdminController } from './admin.controller';
import { User } from '../database/entities';
import { PaymentOrder } from '../database/entities/payment-order.entity';
import { EvaluationModule } from '../evaluation/evaluation.module';

@Module({
  imports: [TypeOrmModule.forFeature([User, PaymentOrder]), EvaluationModule],
  controllers: [AdminController],
})
export class AdminModule {}
