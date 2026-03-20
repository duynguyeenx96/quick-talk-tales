import { Injectable, Logger } from '@nestjs/common';
import { HttpService } from '@nestjs/axios';
import { firstValueFrom } from 'rxjs';

@Injectable()
export class SpeechService {
  private readonly logger = new Logger(SpeechService.name);

  constructor(private readonly httpService: HttpService) {}

  async processAudioWithWhisper(
    audioData: string,
    sessionId: string,
    challengeId: string,
  ): Promise<{ text: string; confidence: number }> {
    try {
      const response = await firstValueFrom(
        this.httpService.post('http://localhost:5000/process-audio', {
          audioData,
          sessionId,
          challengeId,
          timestamp: Date.now(),
        }),
      );

      return {
        text: response.data.text,
        confidence: response.data.confidence || 0.9,
      };
    } catch (error) {
      this.logger.error(`Failed to process audio with Whisper: ${error.message}`);
      throw new Error('Speech processing failed');
    }
  }

  async processFinalAudio(
    audioData: string,
    sessionId: string,
    challengeId: string,
  ): Promise<{ text: string; confidence: number; wordCount: number }> {
    try {
      const response = await firstValueFrom(
        this.httpService.post('http://localhost:5000/process-final-audio', {
          audioData,
          sessionId,
          challengeId,
          timestamp: Date.now(),
        }),
      );

      return {
        text: response.data.text,
        confidence: response.data.confidence || 0.9,
        wordCount: response.data.wordCount || 0,
      };
    } catch (error) {
      this.logger.error(`Failed to process final audio: ${error.message}`);
      throw new Error('Final speech processing failed');
    }
  }

  async getAiServerHealth(): Promise<boolean> {
    try {
      const response = await firstValueFrom(
        this.httpService.get('http://localhost:5000/health'),
      );
      return response.data.status === 'healthy';
    } catch (error) {
      this.logger.warn(`AI server health check failed: ${error.message}`);
      return false;
    }
  }
}