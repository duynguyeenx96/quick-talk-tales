import { IsEnum, IsOptional } from 'class-validator';
import { Transform } from 'class-transformer';
import { WordCategory, WordDifficulty } from '../../database/entities';

export class GetRandomWordsDto {
  @Transform(({ value }) => parseInt(value))
  @IsOptional()
  count?: 3 | 5 | 7 = 5;

  @IsEnum(WordDifficulty)
  @IsOptional()
  difficulty?: WordDifficulty;

  @IsEnum(WordCategory)
  @IsOptional()
  category?: WordCategory;
}
