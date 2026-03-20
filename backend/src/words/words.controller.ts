import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { WordsService } from './words.service';
import { GetRandomWordsDto } from './dto/get-random-words.dto';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { User } from '../database/entities';

@Controller('words')
@UseGuards(JwtAuthGuard)
export class WordsController {
  constructor(private readonly wordsService: WordsService) {}

  @Get('random')
  getRandomWords(@Query() dto: GetRandomWordsDto, @CurrentUser() user: User) {
    return this.wordsService.getRandomWords(dto, user);
  }

  @Get()
  findAll() {
    return this.wordsService.findAll();
  }
}
