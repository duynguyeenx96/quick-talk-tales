import {
  Controller,
  Post,
  Get,
  Param,
  Body,
  UseGuards,
  Request,
  Headers,
} from '@nestjs/common';
import { PaymentsService } from './payments.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';

@Controller('payments')
export class PaymentsController {
  constructor(private readonly paymentsService: PaymentsService) {}

  /** Create a new payment order for the authenticated user */
  @UseGuards(JwtAuthGuard)
  @Post('create-order')
  createOrder(@Request() req, @Body('planId') planId: string) {
    return this.paymentsService.createOrder(req.user.id, planId);
  }

  /** Poll payment status */
  @UseGuards(JwtAuthGuard)
  @Get('status/:orderId')
  getStatus(@Param('orderId') orderId: string, @Request() req) {
    return this.paymentsService.getStatus(orderId, req.user.id);
  }

  /** Sepay webhook — no JWT, authenticated by API key header */
  @Post('webhook/sepay')
  sepayWebhook(
    @Body() payload: any,
    @Headers('Authorization') authHeader: string,
  ) {
    // Sepay sends: Authorization: Apikey <key>
    const apiKey = authHeader?.replace(/^Apikey\s+/i, '') ?? '';
    return this.paymentsService.handleSepayWebhook(payload, apiKey);
  }
}
