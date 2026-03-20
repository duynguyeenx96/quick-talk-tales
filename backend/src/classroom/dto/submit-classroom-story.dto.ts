import { IsString, MinLength } from 'class-validator';

export class SubmitClassroomStoryDto {
  @IsString()
  @MinLength(10)
  storyText: string;
}
