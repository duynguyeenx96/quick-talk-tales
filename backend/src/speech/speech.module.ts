import { Module } from '@nestjs/common';
import { HttpModule } from '@nestjs/axios';
import { SpeechGateway } from './speech.gateway';
import { SpeechService } from './speech.service';

@Module({
  imports: [
    HttpModule.register({
      timeout: 30000, // 30 seconds timeout for Whisper processing
      maxRedirects: 3,
    }),
  ],
  providers: [SpeechGateway, SpeechService],
  exports: [SpeechService],
})
export class SpeechModule {}