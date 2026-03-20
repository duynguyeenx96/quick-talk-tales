import {
  IsString,
  IsOptional,
  IsEnum,
  IsNumber,
  IsBoolean,
  MinLength,
  MaxLength,
  Min,
} from 'class-validator';
import { ChapterType } from '../../database/entities';

export class CreateChapterDto {
  @IsString()
  @MinLength(1)
  @MaxLength(200)
  title: string;

  @IsString()
  @MinLength(1)
  content: string;

  @IsOptional()
  @IsEnum(ChapterType)
  chapterType?: ChapterType;

  @IsNumber()
  @Min(1)
  orderIndex: number;

  @IsOptional()
  @IsBoolean()
  isPublished?: boolean;

  @IsOptional()
  metadata?: Record<string, any>;
}