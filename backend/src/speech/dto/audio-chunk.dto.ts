import { IsString, IsNotEmpty, IsOptional, IsNumber } from 'class-validator';

export class AudioChunkDto {
  @IsString()
  @IsNotEmpty()
  type: string;

  @IsString()
  @IsNotEmpty()
  challengeId: string;

  @IsString()
  @IsNotEmpty()
  data: string; // base64 encoded audio data

  @IsNumber()
  @IsOptional()
  timestamp?: number;

  @IsString()
  @IsOptional()
  sessionId?: string;
}

export class TranscriptionResponseDto {
  @IsString()
  text: string;

  @IsNumber()
  timestamp: number;

  @IsNumber()
  @IsOptional()
  confidence?: number;

  @IsString()
  @IsOptional()
  sessionId?: string;
}