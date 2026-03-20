import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Word } from '../database/entities';
import { WordsService } from './words.service';
import { WordsController } from './words.controller';

@Module({
  imports: [TypeOrmModule.forFeature([Word])],
  controllers: [WordsController],
  providers: [WordsService],
  exports: [WordsService],
})
export class WordsModule {}
