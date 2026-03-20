import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { WordsService } from './words.service';
import { GetRandomWordsDto } from './dto/get-random-words.dto';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';

@Controller('words')
@UseGuards(JwtAuthGuard)
export class WordsController {
  constructor(private readonly wordsService: WordsService) {}

  @Get('random')
  getRandomWords(@Query() dto: GetRandomWordsDto) {
    return this.wordsService.getRandomWords(dto);
  }

  @Get()
  findAll() {
    return this.wordsService.findAll();
  }
}
