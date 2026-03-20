import {
  Injectable,
  Logger,
  BadRequestException,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ConfigService } from '@nestjs/config';
import * as crypto from 'crypto';
import { PaymentOrder } from '../database/entities/payment-order.entity';
import { User } from '../database/entities';
import { UsersService } from '../users/users.service';

export const PLANS = {
  premium_monthly: { label: 'Premium Monthly', amount: 59000, durationDays: 30 },
  premium_yearly:  { label: 'Premium Yearly',  amount: 499000, durationDays: 365 },
};

@Injectable()
export class PaymentsService {
  private readonly logger = new Logger(PaymentsService.name);

  constructor(
    @InjectRepository(PaymentOrder)
    private ordersRepo: Repository<PaymentOrder>,
    @InjectRepository(User)
    private usersRepo: Repository<User>,
    private usersService: UsersService,
    private config: ConfigService,
  ) {}

  async createOrder(userId: string, planId: string): Promise<any> {
    const plan = PLANS[planId];
    if (!plan) throw new BadRequestException('Invalid plan');

    // Cancel any existing pending order for this user+plan
    await this.ordersRepo.update(
      { userId, planId, status: 'pending' },
      { status: 'expired' },
    );

    const transferContent = this._genTransferContent();
    const expiresAt = new Date(Date.now() + 30 * 60 * 1000); // 30 min

    const order = await this.ordersRepo.save(
      this.ordersRepo.create({
        userId,
        planId,
        amount: plan.amount,
        transferContent,
        expiresAt,
      }),
    );

    return {
      orderId: order.id,
      planLabel: plan.label,
      amount: plan.amount,
      transferContent,
      expiresAt,
      ...this._bankInfo(),
      qrUrl: this._qrUrl(plan.amount, transferContent),
    };
  }

  async getStatus(orderId: string, userId: string): Promise<any> {
    const order = await this.ordersRepo.findOne({ where: { id: orderId, userId } });
    if (!order) throw new NotFoundException('Order not found');

    // Auto-expire
    if (order.status === 'pending' && order.expiresAt < new Date()) {
      await this.ordersRepo.update(orderId, { status: 'expired' });
      order.status = 'expired';
    }

    return {
      orderId: order.id,
      status: order.status,
      amount: order.amount,
      transferContent: order.transferContent,
      expiresAt: order.expiresAt,
      paidAt: order.paidAt,
    };
  }

  /** Called by Sepay webhook POST /payments/webhook/sepay */
  async handleSepayWebhook(payload: any, apiKey: string): Promise<{ success: boolean }> {
    const expectedKey = this.config.get<string>('SEPAY_API_KEY', '');
    if (expectedKey && apiKey !== expectedKey) {
      throw new UnauthorizedException('Invalid Sepay API key');
    }

    this.logger.log(`Sepay webhook: ${JSON.stringify(payload)}`);

    const { code, transferAmount, transferType, id: sepayTxId } = payload;

    // Only process incoming transfers
    if (transferType !== 'in') return { success: false };

    // Find pending order whose transferContent is contained in the description
    const orders = await this.ordersRepo.find({ where: { status: 'pending' } });
    const matched = orders.find(
      (o) => code && code.toString().includes(o.transferContent) && transferAmount >= o.amount,
    );

    if (!matched) {
      this.logger.warn(`No matching order for content: ${code}`);
      return { success: false };
    }

    // Mark order completed
    await this.ordersRepo.update(matched.id, {
      status: 'completed',
      paidAt: new Date(),
      sepayTransactionId: String(sepayTxId ?? ''),
    });

    // Upgrade user subscription
    const plan = PLANS[matched.planId];
    if (plan) {
      const expiresAt = new Date(Date.now() + plan.durationDays * 24 * 60 * 60 * 1000);
      await this.usersRepo.update(matched.userId, {
        subscriptionPlan: 'premium',
        subscriptionExpiresAt: expiresAt,
      });
      this.logger.log(`User ${matched.userId} upgraded to premium via Sepay`);
    }

    return { success: true };
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  private _genTransferContent(): string {
    const prefix = this.config.get<string>('TRANSFER_PREFIX', 'QTTALES');
    const suffix = crypto.randomBytes(3).toString('hex').toUpperCase(); // 6 chars
    return `${prefix} ${suffix}`;
  }

  private _bankInfo() {
    return {
      bankCode: this.config.get<string>('BANK_CODE', 'MB'),
      accountNumber: this.config.get<string>('BANK_ACCOUNT', ''),
      accountName: this.config.get<string>('BANK_ACCOUNT_NAME', ''),
    };
  }

  private _qrUrl(amount: number, content: string): string {
    const bank = this.config.get<string>('BANK_CODE', 'MB');
    const acc  = this.config.get<string>('BANK_ACCOUNT', '');
    const name = encodeURIComponent(this.config.get<string>('BANK_ACCOUNT_NAME', ''));
    const des  = encodeURIComponent(content);
    // VietQR public image API — no API key needed
    return `https://img.vietqr.io/image/${bank}-${acc}-compact.jpg?amount=${amount}&addInfo=${des}&accountName=${name}`;
  }
}
