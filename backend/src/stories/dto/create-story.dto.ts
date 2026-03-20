import {
  IsString,
  IsOptional,
  IsUUID,
  IsEnum,
  IsBoolean,
  IsNumber,
  IsArray,
  MaxLength,
  MinLength,
  Min,
} from 'class-validator';
import { DifficultyLevel, StoryStatus } from '../../database/entities';

export class CreateStoryDto {
  @IsString()
  @MinLength(1)
  @MaxLength(200)
  title: string;

  @IsOptional()
  @IsString()
  @MaxLength(2000)
  description?: string;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  coverImageUrl?: string;

  @IsOptional()
  @IsUUID()
  categoryId?: string;

  @IsOptional()
  @IsEnum(DifficultyLevel)
  difficulty?: DifficultyLevel;

  @IsOptional()
  @IsNumber()
  @Min(1)
  estimatedReadingTime?: number;

  @IsOptional()
  @IsBoolean()
  isInteractive?: boolean;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  tagIds?: string[];

  @IsOptional()
  @IsEnum(StoryStatus)
  status?: StoryStatus;
}