import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as nodemailer from 'nodemailer';

@Injectable()
export class EmailService {
  private readonly logger = new Logger(EmailService.name);
  private transporter: nodemailer.Transporter;

  constructor(private configService: ConfigService) {
    this.transporter = nodemailer.createTransport({
      service: 'gmail',
      auth: {
        user: configService.get<string>('GMAIL_USER'),
        pass: configService.get<string>('GMAIL_APP_PASSWORD'),
      },
    });
  }

  async sendVerificationEmail(
    to: string,
    token: string,
    username: string,
  ): Promise<void> {
    // For mobile apps, deep link format. Adjust APP_SCHEME if needed.
    const appScheme = this.configService.get<string>(
      'APP_SCHEME',
      'quicktalkstories',
    );
    const verifyUrl = `${appScheme}://verify-email?token=${token}`;
    // Fallback web URL
    const webUrl = `${this.configService.get('FRONTEND_URL', 'http://localhost:3000')}/auth/verify-email?token=${token}`;

    try {
      await this.transporter.sendMail({
        from: `"Quick Talk Tales" <${this.configService.get('GMAIL_USER')}>`,
        to,
        subject: '✉️ Verify your Quick Talk Tales account',
        html: `
          <div style="font-family: 'Nunito', Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 32px; background: #f8fbff; border-radius: 16px;">
            <div style="text-align: center; margin-bottom: 24px;">
              <h1 style="color: #58CC02; font-size: 28px; margin: 0;">📖 Quick Talk Tales</h1>
            </div>
            <div style="background: white; border-radius: 16px; padding: 32px; box-shadow: 0 4px 16px rgba(0,0,0,0.08);">
              <h2 style="color: #3C3C3C; margin-top: 0;">Welcome, ${username}! 🎉</h2>
              <p style="color: #777; line-height: 1.6;">
                You're almost ready to start telling amazing stories! Please verify your email address to activate your account.
              </p>
              <div style="text-align: center; margin: 32px 0;">
                <a href="${webUrl}" style="background: #58CC02; color: white; padding: 16px 32px; border-radius: 32px; text-decoration: none; font-weight: bold; font-size: 16px; display: inline-block;">
                  ✅ Verify My Email
                </a>
              </div>
              <p style="color: #aaa; font-size: 12px; text-align: center;">
                This link expires in 24 hours.<br/>
                If you didn't create an account, you can safely ignore this email.
              </p>
            </div>
          </div>
        `,
      });
      this.logger.log(`Verification email sent to ${to}`);
    } catch (error) {
      this.logger.error(
        `Failed to send verification email to ${to}: ${error.message}`,
      );
    }
  }
}
