import { Injectable, OnModuleInit, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, FindOptionsWhere } from 'typeorm';
import { Word, WordCategory, WordDifficulty } from '../database/entities';
import { GetRandomWordsDto } from './dto/get-random-words.dto';

const SEED_WORDS: { text: string; category: WordCategory; difficulty: WordDifficulty }[] = [
  // Easy - Animals
  { text: 'cat', category: WordCategory.ANIMAL, difficulty: WordDifficulty.EASY },
  { text: 'dog', category: WordCategory.ANIMAL, difficulty: WordDifficulty.EASY },
  { text: 'bird', category: WordCategory.ANIMAL, difficulty: WordDifficulty.EASY },
  { text: 'fish', category: WordCategory.ANIMAL, difficulty: WordDifficulty.EASY },
  { text: 'rabbit', category: WordCategory.ANIMAL, difficulty: WordDifficulty.EASY },
  { text: 'horse', category: WordCategory.ANIMAL, difficulty: WordDifficulty.EASY },
  { text: 'lion', category: WordCategory.ANIMAL, difficulty: WordDifficulty.EASY },
  { text: 'elephant', category: WordCategory.ANIMAL, difficulty: WordDifficulty.MEDIUM },
  { text: 'butterfly', category: WordCategory.ANIMAL, difficulty: WordDifficulty.MEDIUM },
  { text: 'dolphin', category: WordCategory.ANIMAL, difficulty: WordDifficulty.MEDIUM },
  // Easy - Food
  { text: 'apple', category: WordCategory.FOOD, difficulty: WordDifficulty.EASY },
  { text: 'cake', category: WordCategory.FOOD, difficulty: WordDifficulty.EASY },
  { text: 'bread', category: WordCategory.FOOD, difficulty: WordDifficulty.EASY },
  { text: 'pizza', category: WordCategory.FOOD, difficulty: WordDifficulty.EASY },
  { text: 'cookie', category: WordCategory.FOOD, difficulty: WordDifficulty.EASY },
  { text: 'banana', category: WordCategory.FOOD, difficulty: WordDifficulty.EASY },
  { text: 'ice cream', category: WordCategory.FOOD, difficulty: WordDifficulty.EASY },
  { text: 'sandwich', category: WordCategory.FOOD, difficulty: WordDifficulty.MEDIUM },
  { text: 'chocolate', category: WordCategory.FOOD, difficulty: WordDifficulty.MEDIUM },
  { text: 'strawberry', category: WordCategory.FOOD, difficulty: WordDifficulty.MEDIUM },
  // Easy - Nature
  { text: 'sun', category: WordCategory.NATURE, difficulty: WordDifficulty.EASY },
  { text: 'moon', category: WordCategory.NATURE, difficulty: WordDifficulty.EASY },
  { text: 'star', category: WordCategory.NATURE, difficulty: WordDifficulty.EASY },
  { text: 'tree', category: WordCategory.NATURE, difficulty: WordDifficulty.EASY },
  { text: 'flower', category: WordCategory.NATURE, difficulty: WordDifficulty.EASY },
  { text: 'rain', category: WordCategory.NATURE, difficulty: WordDifficulty.EASY },
  { text: 'ocean', category: WordCategory.NATURE, difficulty: WordDifficulty.EASY },
  { text: 'mountain', category: WordCategory.NATURE, difficulty: WordDifficulty.MEDIUM },
  { text: 'rainbow', category: WordCategory.NATURE, difficulty: WordDifficulty.EASY },
  { text: 'waterfall', category: WordCategory.NATURE, difficulty: WordDifficulty.MEDIUM },
  // Easy - Objects
  { text: 'book', category: WordCategory.OBJECT, difficulty: WordDifficulty.EASY },
  { text: 'ball', category: WordCategory.OBJECT, difficulty: WordDifficulty.EASY },
  { text: 'hat', category: WordCategory.OBJECT, difficulty: WordDifficulty.EASY },
  { text: 'key', category: WordCategory.OBJECT, difficulty: WordDifficulty.EASY },
  { text: 'lamp', category: WordCategory.OBJECT, difficulty: WordDifficulty.EASY },
  { text: 'mirror', category: WordCategory.OBJECT, difficulty: WordDifficulty.EASY },
  { text: 'umbrella', category: WordCategory.OBJECT, difficulty: WordDifficulty.MEDIUM },
  { text: 'telescope', category: WordCategory.OBJECT, difficulty: WordDifficulty.MEDIUM },
  { text: 'treasure', category: WordCategory.OBJECT, difficulty: WordDifficulty.MEDIUM },
  { text: 'compass', category: WordCategory.OBJECT, difficulty: WordDifficulty.MEDIUM },
  // Easy - Actions
  { text: 'jump', category: WordCategory.ACTION, difficulty: WordDifficulty.EASY },
  { text: 'run', category: WordCategory.ACTION, difficulty: WordDifficulty.EASY },
  { text: 'fly', category: WordCategory.ACTION, difficulty: WordDifficulty.EASY },
  { text: 'swim', category: WordCategory.ACTION, difficulty: WordDifficulty.EASY },
  { text: 'dance', category: WordCategory.ACTION, difficulty: WordDifficulty.EASY },
  { text: 'sing', category: WordCategory.ACTION, difficulty: WordDifficulty.EASY },
  { text: 'climb', category: WordCategory.ACTION, difficulty: WordDifficulty.EASY },
  { text: 'discover', category: WordCategory.ACTION, difficulty: WordDifficulty.MEDIUM },
  { text: 'whisper', category: WordCategory.ACTION, difficulty: WordDifficulty.MEDIUM },
  { text: 'adventure', category: WordCategory.ACTION, difficulty: WordDifficulty.MEDIUM },
  // Easy - Adjectives
  { text: 'big', category: WordCategory.ADJECTIVE, difficulty: WordDifficulty.EASY },
  { text: 'small', category: WordCategory.ADJECTIVE, difficulty: WordDifficulty.EASY },
  { text: 'happy', category: WordCategory.ADJECTIVE, difficulty: WordDifficulty.EASY },
  { text: 'scary', category: WordCategory.ADJECTIVE, difficulty: WordDifficulty.EASY },
  { text: 'magical', category: WordCategory.ADJECTIVE, difficulty: WordDifficulty.EASY },
  { text: 'giant', category: WordCategory.ADJECTIVE, difficulty: WordDifficulty.EASY },
  { text: 'colorful', category: WordCategory.ADJECTIVE, difficulty: WordDifficulty.MEDIUM },
  { text: 'mysterious', category: WordCategory.ADJECTIVE, difficulty: WordDifficulty.MEDIUM },
  { text: 'invisible', category: WordCategory.ADJECTIVE, difficulty: WordDifficulty.MEDIUM },
  { text: 'ancient', category: WordCategory.ADJECTIVE, difficulty: WordDifficulty.HARD },
  // Places
  { text: 'castle', category: WordCategory.PLACE, difficulty: WordDifficulty.EASY },
  { text: 'forest', category: WordCategory.PLACE, difficulty: WordDifficulty.EASY },
  { text: 'island', category: WordCategory.PLACE, difficulty: WordDifficulty.EASY },
  { text: 'cave', category: WordCategory.PLACE, difficulty: WordDifficulty.EASY },
  { text: 'village', category: WordCategory.PLACE, difficulty: WordDifficulty.MEDIUM },
  { text: 'dungeon', category: WordCategory.PLACE, difficulty: WordDifficulty.MEDIUM },
  { text: 'kingdom', category: WordCategory.PLACE, difficulty: WordDifficulty.MEDIUM },
  { text: 'volcano', category: WordCategory.PLACE, difficulty: WordDifficulty.MEDIUM },
  { text: 'labyrinth', category: WordCategory.PLACE, difficulty: WordDifficulty.HARD },
  { text: 'sanctuary', category: WordCategory.PLACE, difficulty: WordDifficulty.HARD },
  // Person
  { text: 'princess', category: WordCategory.PERSON, difficulty: WordDifficulty.EASY },
  { text: 'wizard', category: WordCategory.PERSON, difficulty: WordDifficulty.EASY },
  { text: 'knight', category: WordCategory.PERSON, difficulty: WordDifficulty.EASY },
  { text: 'pirate', category: WordCategory.PERSON, difficulty: WordDifficulty.EASY },
  { text: 'dragon', category: WordCategory.PERSON, difficulty: WordDifficulty.EASY },
  { text: 'fairy', category: WordCategory.PERSON, difficulty: WordDifficulty.EASY },
  { text: 'mermaid', category: WordCategory.PERSON, difficulty: WordDifficulty.MEDIUM },
  { text: 'explorer', category: WordCategory.PERSON, difficulty: WordDifficulty.MEDIUM },
  { text: 'inventor', category: WordCategory.PERSON, difficulty: WordDifficulty.MEDIUM },
  { text: 'sorcerer', category: WordCategory.PERSON, difficulty: WordDifficulty.HARD },
];

@Injectable()
export class WordsService implements OnModuleInit {
  constructor(
    @InjectRepository(Word)
    private readonly wordRepository: Repository<Word>,
  ) {}

  async onModuleInit() {
    await this.seedWords();
  }

  private async seedWords() {
    const count = await this.wordRepository.count();
    if (count > 0) return;

    const words = SEED_WORDS.map(w => this.wordRepository.create(w));
    await this.wordRepository.save(words);
  }

  async getRandomWords(dto: GetRandomWordsDto): Promise<Word[]> {
    const count = dto.count ?? 5;
    if (![3, 5, 7].includes(count)) {
      throw new BadRequestException('count must be 3, 5, or 7');
    }

    const where: FindOptionsWhere<Word> = { isActive: true };
    if (dto.difficulty) where.difficulty = dto.difficulty;
    if (dto.category) where.category = dto.category;

    const allWords = await this.wordRepository.find({ where });

    if (allWords.length < count) {
      throw new BadRequestException(
        `Not enough words available (need ${count}, have ${allWords.length})`,
      );
    }

    // Fisher-Yates shuffle then pick count
    for (let i = allWords.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [allWords[i], allWords[j]] = [allWords[j], allWords[i]];
    }

    return allWords.slice(0, count);
  }

  async findAll(): Promise<Word[]> {
    return this.wordRepository.find({ where: { isActive: true }, order: { text: 'ASC' } });
  }
}
