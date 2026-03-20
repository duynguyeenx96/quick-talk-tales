import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  MessageBody,
  ConnectedSocket,
  OnGatewayConnection,
  OnGatewayDisconnect,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { Injectable, Logger } from '@nestjs/common';
import { HttpService } from '@nestjs/axios';
import { firstValueFrom } from 'rxjs';
import { AudioChunkDto, TranscriptionResponseDto } from './dto/audio-chunk.dto';
import * as FormData from 'form-data';

@Injectable()
@WebSocketGateway({
  cors: {
    origin: '*',
  },
  namespace: '/speech',
})
export class SpeechGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  private readonly logger = new Logger(SpeechGateway.name);
  private activeSessions = new Map<string, string>(); // socketId -> sessionId

  constructor(private readonly httpService: HttpService) {}

  handleConnection(client: Socket) {
    this.logger.log(`Client connected: ${client.id}`);
  }

  handleDisconnect(client: Socket) {
    this.logger.log(`Client disconnected: ${client.id}`);
    this.activeSessions.delete(client.id);
  }

  @SubscribeMessage('start_session')
  handleStartSession(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: { challengeId: string; userId: string },
  ) {
    const sessionId = `${payload.userId}-${payload.challengeId}-${Date.now()}`;
    this.activeSessions.set(client.id, sessionId);
    
    this.logger.log(`Started session: ${sessionId} for client: ${client.id}`);
    
    client.emit('session_started', {
      sessionId,
      challengeId: payload.challengeId,
      status: 'ready',
    });
  }

  @SubscribeMessage('audio_chunk_binary')
  async handleAudioChunkBinary(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: { 
      audioBuffer: Buffer; 
      challengeId: string; 
      timestamp?: number;
      metadata?: any;
    },
  ) {
    try {
      const sessionId = this.activeSessions.get(client.id);
      
      if (!sessionId) {
        client.emit('error', { message: 'Session not started' });
        return;
      }

      this.logger.log(`Processing binary audio chunk for session: ${sessionId}`);

      // Create FormData for binary upload
      const formData = new FormData();
      formData.append('audio', payload.audioBuffer, {
        filename: `audio_${Date.now()}.wav`,
        contentType: 'audio/wav',
      });
      formData.append('sessionId', sessionId);
      formData.append('challengeId', payload.challengeId);
      formData.append('timestamp', (payload.timestamp || Date.now()).toString());

      // Forward binary audio to FastAPI server
      const response = await firstValueFrom(
        this.httpService.post('http://localhost:5000/api/v1/process-audio-binary', formData, {
          headers: {
            ...formData.getHeaders(),
            'Content-Type': 'multipart/form-data',
          },
          maxContentLength: 25 * 1024 * 1024, // 25MB limit
        }),
      );

      // Send transcribed text back to client
      const transcriptionResponse: TranscriptionResponseDto = {
        text: response.data.text,
        timestamp: payload.timestamp || Date.now(),
        confidence: response.data.confidence,
        sessionId: sessionId,
      };

      client.emit('transcription', transcriptionResponse);

      this.logger.log(`Sent transcription for session: ${sessionId}, text: "${response.data.text}"`);

    } catch (error) {
      this.logger.error(`Error processing audio chunk: ${error.message}`, error.stack);
      
      client.emit('error', {
        message: 'Failed to process audio chunk',
        error: error.message,
      });
    }
  }

  @SubscribeMessage('end_session')
  handleEndSession(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: { finalText?: string },
  ) {
    const sessionId = this.activeSessions.get(client.id);
    
    if (sessionId) {
      this.logger.log(`Ending session: ${sessionId}`);
      this.activeSessions.delete(client.id);
      
      client.emit('session_ended', {
        sessionId,
        finalText: payload.finalText,
        status: 'completed',
      });
    }
  }

  // Method to get active session count
  getActiveSessionsCount(): number {
    return this.activeSessions.size;
  }
}