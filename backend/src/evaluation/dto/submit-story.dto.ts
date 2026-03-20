import { IsString, IsArray, IsNotEmpty, MinLength, ArrayMinSize, ArrayMaxSize } from 'class-validator';

export class SubmitStoryDto {
  @IsString()
  @IsNotEmpty()
  @MinLength(20, { message: 'Story must be at least 20 characters long' })
  storyText: string;

  @IsArray()
  @ArrayMinSize(3)
  @ArrayMaxSize(7)
  @IsString({ each: true })
  targetWords: string[];
}
