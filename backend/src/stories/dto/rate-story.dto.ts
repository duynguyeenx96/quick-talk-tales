import {
  IsNumber,
  IsOptional,
  IsString,
  Min,
  Max,
  MaxLength,
} from 'class-validator';

export class RateStoryDto {
  @IsNumber()
  @Min(1)
  @Max(5)
  rating: number;

  @IsOptional()
  @IsString()
  @MaxLength(1000)
  review?: string;
}
