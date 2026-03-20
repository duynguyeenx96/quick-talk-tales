import { Injectable, OnModuleInit, BadRequestException, ForbiddenException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, FindOptionsWhere, In } from 'typeorm';
import { Word, WordCategory, WordDifficulty, WordTopic, UserWordHistory } from '../database/entities';
import { User } from '../database/entities';
import { GetRandomWordsDto } from './dto/get-random-words.dto';

type SeedWord = {
  text: string;
  category: WordCategory;
  difficulty: WordDifficulty;
  topics: WordTopic[];
};

const SEED_WORDS: SeedWord[] = [
  // Animals
  { text: 'cat',       category: WordCategory.ANIMAL,    difficulty: WordDifficulty.EASY,   topics: [WordTopic.DAILY_LIFE, WordTopic.FANTASY] },
  { text: 'dog',       category: WordCategory.ANIMAL,    difficulty: WordDifficulty.EASY,   topics: [WordTopic.DAILY_LIFE] },
  { text: 'bird',      category: WordCategory.ANIMAL,    difficulty: WordDifficulty.EASY,   topics: [WordTopic.NATURE, WordTopic.DAILY_LIFE] },
  { text: 'fish',      category: WordCategory.ANIMAL,    difficulty: WordDifficulty.EASY,   topics: [WordTopic.NATURE, WordTopic.SPORT] },
  { text: 'rabbit',    category: WordCategory.ANIMAL,    difficulty: WordDifficulty.EASY,   topics: [WordTopic.DAILY_LIFE, WordTopic.FANTASY] },
  { text: 'horse',     category: WordCategory.ANIMAL,    difficulty: WordDifficulty.EASY,   topics: [WordTopic.ADVENTURE, WordTopic.SPORT] },
  { text: 'lion',      category: WordCategory.ANIMAL,    difficulty: WordDifficulty.EASY,   topics: [WordTopic.ADVENTURE, WordTopic.NATURE] },
  { text: 'elephant',  category: WordCategory.ANIMAL,    difficulty: WordDifficulty.MEDIUM, topics: [WordTopic.NATURE, WordTopic.ADVENTURE] },
  { text: 'butterfly', category: WordCategory.ANIMAL,    difficulty: WordDifficulty.MEDIUM, topics: [WordTopic.NATURE, WordTopic.SCIENCE] },
  { text: 'dolphin',   category: WordCategory.ANIMAL,    difficulty: WordDifficulty.MEDIUM, topics: [WordTopic.NATURE, WordTopic.SCIENCE, WordTopic.SPORT] },
  // Food
  { text: 'apple',       category: WordCategory.FOOD, difficulty: WordDifficulty.EASY,   topics: [WordTopic.DAILY_LIFE] },
  { text: 'cake',        category: WordCategory.FOOD, difficulty: WordDifficulty.EASY,   topics: [WordTopic.DAILY_LIFE] },
  { text: 'bread',       category: WordCategory.FOOD, difficulty: WordDifficulty.EASY,   topics: [WordTopic.DAILY_LIFE] },
  { text: 'pizza',       category: WordCategory.FOOD, difficulty: WordDifficulty.EASY,   topics: [WordTopic.DAILY_LIFE] },
  { text: 'cookie',      category: WordCategory.FOOD, difficulty: WordDifficulty.EASY,   topics: [WordTopic.DAILY_LIFE] },
  { text: 'banana',      category: WordCategory.FOOD, difficulty: WordDifficulty.EASY,   topics: [WordTopic.DAILY_LIFE, WordTopic.NATURE] },
  { text: 'ice cream',   category: WordCategory.FOOD, difficulty: WordDifficulty.EASY,   topics: [WordTopic.DAILY_LIFE, WordTopic.EMOTION] },
  { text: 'sandwich',    category: WordCategory.FOOD, difficulty: WordDifficulty.MEDIUM, topics: [WordTopic.DAILY_LIFE] },
  { text: 'chocolate',   category: WordCategory.FOOD, difficulty: WordDifficulty.MEDIUM, topics: [WordTopic.DAILY_LIFE, WordTopic.EMOTION] },
  { text: 'strawberry',  category: WordCategory.FOOD, difficulty: WordDifficulty.MEDIUM, topics: [WordTopic.DAILY_LIFE, WordTopic.NATURE] },
  // Nature
  { text: 'sun',       category: WordCategory.NATURE, difficulty: WordDifficulty.EASY,   topics: [WordTopic.NATURE, WordTopic.DAILY_LIFE] },
  { text: 'moon',      category: WordCategory.NATURE, difficulty: WordDifficulty.EASY,   topics: [WordTopic.NATURE, WordTopic.FANTASY, WordTopic.MYSTERY] },
  { text: 'star',      category: WordCategory.NATURE, difficulty: WordDifficulty.EASY,   topics: [WordTopic.NATURE, WordTopic.SCIENCE, WordTopic.FANTASY] },
  { text: 'tree',      category: WordCategory.NATURE, difficulty: WordDifficulty.EASY,   topics: [WordTopic.NATURE, WordTopic.DAILY_LIFE] },
  { text: 'flower',    category: WordCategory.NATURE, difficulty: WordDifficulty.EASY,   topics: [WordTopic.NATURE, WordTopic.DAILY_LIFE, WordTopic.EMOTION] },
  { text: 'rain',      category: WordCategory.NATURE, difficulty: WordDifficulty.EASY,   topics: [WordTopic.NATURE, WordTopic.EMOTION] },
  { text: 'ocean',     category: WordCategory.NATURE, difficulty: WordDifficulty.EASY,   topics: [WordTopic.NATURE, WordTopic.ADVENTURE, WordTopic.SCIENCE] },
  { text: 'mountain',  category: WordCategory.NATURE, difficulty: WordDifficulty.MEDIUM, topics: [WordTopic.NATURE, WordTopic.ADVENTURE, WordTopic.SPORT] },
  { text: 'rainbow',   category: WordCategory.NATURE, difficulty: WordDifficulty.EASY,   topics: [WordTopic.NATURE, WordTopic.FANTASY, WordTopic.EMOTION] },
  { text: 'waterfall', category: WordCategory.NATURE, difficulty: WordDifficulty.MEDIUM, topics: [WordTopic.NATURE, WordTopic.ADVENTURE, WordTopic.SCIENCE] },
  // Objects
  { text: 'book',      category: WordCategory.OBJECT, difficulty: WordDifficulty.EASY,   topics: [WordTopic.DAILY_LIFE, WordTopic.MYSTERY] },
  { text: 'ball',      category: WordCategory.OBJECT, difficulty: WordDifficulty.EASY,   topics: [WordTopic.DAILY_LIFE, WordTopic.SPORT] },
  { text: 'hat',       category: WordCategory.OBJECT, difficulty: WordDifficulty.EASY,   topics: [WordTopic.DAILY_LIFE, WordTopic.FANTASY] },
  { text: 'key',       category: WordCategory.OBJECT, difficulty: WordDifficulty.EASY,   topics: [WordTopic.MYSTERY, WordTopic.ADVENTURE] },
  { text: 'lamp',      category: WordCategory.OBJECT, difficulty: WordDifficulty.EASY,   topics: [WordTopic.DAILY_LIFE, WordTopic.MYSTERY] },
  { text: 'mirror',    category: WordCategory.OBJECT, difficulty: WordDifficulty.EASY,   topics: [WordTopic.MYSTERY, WordTopic.FANTASY] },
  { text: 'umbrella',  category: WordCategory.OBJECT, difficulty: WordDifficulty.MEDIUM, topics: [WordTopic.DAILY_LIFE, WordTopic.NATURE] },
  { text: 'telescope', category: WordCategory.OBJECT, difficulty: WordDifficulty.MEDIUM, topics: [WordTopic.SCIENCE, WordTopic.MYSTERY, WordTopic.ADVENTURE] },
  { text: 'treasure',  category: WordCategory.OBJECT, difficulty: WordDifficulty.MEDIUM, topics: [WordTopic.ADVENTURE, WordTopic.MYSTERY] },
  { text: 'compass',   category: WordCategory.OBJECT, difficulty: WordDifficulty.MEDIUM, topics: [WordTopic.ADVENTURE, WordTopic.SCIENCE] },
  // Actions
  { text: 'jump',      category: WordCategory.ACTION, difficulty: WordDifficulty.EASY,   topics: [WordTopic.SPORT, WordTopic.ADVENTURE] },
  { text: 'run',       category: WordCategory.ACTION, difficulty: WordDifficulty.EASY,   topics: [WordTopic.SPORT, WordTopic.ADVENTURE] },
  { text: 'fly',       category: WordCategory.ACTION, difficulty: WordDifficulty.EASY,   topics: [WordTopic.ADVENTURE, WordTopic.FANTASY] },
  { text: 'swim',      category: WordCategory.ACTION, difficulty: WordDifficulty.EASY,   topics: [WordTopic.SPORT, WordTopic.NATURE] },
  { text: 'dance',     category: WordCategory.ACTION, difficulty: WordDifficulty.EASY,   topics: [WordTopic.EMOTION, WordTopic.DAILY_LIFE] },
  { text: 'sing',      category: WordCategory.ACTION, difficulty: WordDifficulty.EASY,   topics: [WordTopic.EMOTION, WordTopic.DAILY_LIFE] },
  { text: 'climb',     category: WordCategory.ACTION, difficulty: WordDifficulty.EASY,   topics: [WordTopic.SPORT, WordTopic.ADVENTURE] },
  { text: 'discover',  category: WordCategory.ACTION, difficulty: WordDifficulty.MEDIUM, topics: [WordTopic.ADVENTURE, WordTopic.SCIENCE] },
  { text: 'whisper',   category: WordCategory.ACTION, difficulty: WordDifficulty.MEDIUM, topics: [WordTopic.MYSTERY, WordTopic.EMOTION] },
  { text: 'adventure', category: WordCategory.ACTION, difficulty: WordDifficulty.MEDIUM, topics: [WordTopic.ADVENTURE] },
  // Adjectives
  { text: 'big',         category: WordCategory.ADJECTIVE, difficulty: WordDifficulty.EASY,   topics: [WordTopic.DAILY_LIFE] },
  { text: 'small',       category: WordCategory.ADJECTIVE, difficulty: WordDifficulty.EASY,   topics: [WordTopic.DAILY_LIFE] },
  { text: 'happy',       category: WordCategory.ADJECTIVE, difficulty: WordDifficulty.EASY,   topics: [WordTopic.EMOTION, WordTopic.DAILY_LIFE] },
  { text: 'scary',       category: WordCategory.ADJECTIVE, difficulty: WordDifficulty.EASY,   topics: [WordTopic.MYSTERY, WordTopic.EMOTION] },
  { text: 'magical',     category: WordCategory.ADJECTIVE, difficulty: WordDifficulty.EASY,   topics: [WordTopic.FANTASY, WordTopic.EMOTION] },
  { text: 'giant',       category: WordCategory.ADJECTIVE, difficulty: WordDifficulty.EASY,   topics: [WordTopic.ADVENTURE, WordTopic.FANTASY] },
  { text: 'colorful',    category: WordCategory.ADJECTIVE, difficulty: WordDifficulty.MEDIUM, topics: [WordTopic.NATURE, WordTopic.EMOTION] },
  { text: 'mysterious',  category: WordCategory.ADJECTIVE, difficulty: WordDifficulty.MEDIUM, topics: [WordTopic.MYSTERY, WordTopic.FANTASY] },
  { text: 'invisible',   category: WordCategory.ADJECTIVE, difficulty: WordDifficulty.MEDIUM, topics: [WordTopic.MYSTERY, WordTopic.FANTASY, WordTopic.SCIENCE] },
  { text: 'ancient',     category: WordCategory.ADJECTIVE, difficulty: WordDifficulty.HARD,   topics: [WordTopic.MYSTERY, WordTopic.ADVENTURE, WordTopic.FANTASY] },
  // Places
  { text: 'castle',    category: WordCategory.PLACE, difficulty: WordDifficulty.EASY,   topics: [WordTopic.FANTASY, WordTopic.ADVENTURE] },
  { text: 'forest',    category: WordCategory.PLACE, difficulty: WordDifficulty.EASY,   topics: [WordTopic.NATURE, WordTopic.ADVENTURE, WordTopic.MYSTERY] },
  { text: 'island',    category: WordCategory.PLACE, difficulty: WordDifficulty.EASY,   topics: [WordTopic.ADVENTURE, WordTopic.NATURE] },
  { text: 'cave',      category: WordCategory.PLACE, difficulty: WordDifficulty.EASY,   topics: [WordTopic.ADVENTURE, WordTopic.MYSTERY] },
  { text: 'village',   category: WordCategory.PLACE, difficulty: WordDifficulty.MEDIUM, topics: [WordTopic.DAILY_LIFE, WordTopic.ADVENTURE] },
  { text: 'dungeon',   category: WordCategory.PLACE, difficulty: WordDifficulty.MEDIUM, topics: [WordTopic.MYSTERY, WordTopic.FANTASY, WordTopic.ADVENTURE] },
  { text: 'kingdom',   category: WordCategory.PLACE, difficulty: WordDifficulty.MEDIUM, topics: [WordTopic.FANTASY, WordTopic.ADVENTURE] },
  { text: 'volcano',   category: WordCategory.PLACE, difficulty: WordDifficulty.MEDIUM, topics: [WordTopic.NATURE, WordTopic.ADVENTURE, WordTopic.SCIENCE] },
  { text: 'labyrinth', category: WordCategory.PLACE, difficulty: WordDifficulty.HARD,   topics: [WordTopic.MYSTERY, WordTopic.ADVENTURE] },
  { text: 'sanctuary', category: WordCategory.PLACE, difficulty: WordDifficulty.HARD,   topics: [WordTopic.NATURE, WordTopic.MYSTERY] },
  // Person
  { text: 'princess', category: WordCategory.PERSON, difficulty: WordDifficulty.EASY,   topics: [WordTopic.FANTASY] },
  { text: 'wizard',   category: WordCategory.PERSON, difficulty: WordDifficulty.EASY,   topics: [WordTopic.FANTASY, WordTopic.MYSTERY] },
  { text: 'knight',   category: WordCategory.PERSON, difficulty: WordDifficulty.EASY,   topics: [WordTopic.ADVENTURE, WordTopic.FANTASY] },
  { text: 'pirate',   category: WordCategory.PERSON, difficulty: WordDifficulty.EASY,   topics: [WordTopic.ADVENTURE] },
  { text: 'dragon',   category: WordCategory.PERSON, difficulty: WordDifficulty.EASY,   topics: [WordTopic.FANTASY, WordTopic.ADVENTURE] },
  { text: 'fairy',    category: WordCategory.PERSON, difficulty: WordDifficulty.EASY,   topics: [WordTopic.FANTASY, WordTopic.NATURE] },
  { text: 'mermaid',  category: WordCategory.PERSON, difficulty: WordDifficulty.MEDIUM, topics: [WordTopic.FANTASY, WordTopic.NATURE] },
  { text: 'explorer', category: WordCategory.PERSON, difficulty: WordDifficulty.MEDIUM, topics: [WordTopic.ADVENTURE, WordTopic.SCIENCE] },
  { text: 'inventor', category: WordCategory.PERSON, difficulty: WordDifficulty.MEDIUM, topics: [WordTopic.SCIENCE] },
  { text: 'sorcerer', category: WordCategory.PERSON, difficulty: WordDifficulty.HARD,   topics: [WordTopic.MYSTERY, WordTopic.FANTASY] },
];

@Injectable()
export class WordsService implements OnModuleInit {
  constructor(
    @InjectRepository(Word)
    private readonly wordRepository: Repository<Word>,
    @InjectRepository(UserWordHistory)
    private readonly historyRepository: Repository<UserWordHistory>,
  ) {}

  async onModuleInit() {
    await this.seedWords();
    await this.ensureTopicsSeeded();
  }

  private async seedWords() {
    const count = await this.wordRepository.count();
    if (count > 0) return;

    const words = SEED_WORDS.map(w => this.wordRepository.create(w));
    await this.wordRepository.save(words);
  }

  /**
   * Idempotent: assigns topics to any word that has an empty topics array.
   * Safe to run on every startup — skips words that already have topics.
   */
  private async ensureTopicsSeeded() {
    const allWords = await this.wordRepository.find();
    const needsTopics = allWords.filter(w => !w.topics || w.topics.length === 0);
    if (!needsTopics.length) return;

    const topicMap = new Map(SEED_WORDS.map(s => [s.text, s.topics]));
    for (const word of needsTopics) {
      const topics = topicMap.get(word.text);
      if (topics) {
        word.topics = topics;
        await this.wordRepository.save(word);
      }
    }
  }

  private isPremium(user: User): boolean {
    return (
      user.subscriptionPlan === 'premium' &&
      (!user.subscriptionExpiresAt || user.subscriptionExpiresAt > new Date())
    );
  }

  private shuffle<T>(arr: T[]): T[] {
    for (let i = arr.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [arr[i], arr[j]] = [arr[j], arr[i]];
    }
    return arr;
  }

  async getRandomWords(dto: GetRandomWordsDto, user: User): Promise<Word[]> {
    const count = dto.count ?? 5;
    if (![3, 5, 7].includes(count)) {
      throw new BadRequestException('count must be 3, 5, or 7');
    }

    const premiumOnlyDifficulties = [WordDifficulty.MEDIUM, WordDifficulty.HARD];
    if (dto.difficulty && premiumOnlyDifficulties.includes(dto.difficulty) && !this.isPremium(user)) {
      throw new ForbiddenException('Intermediate and Advanced difficulty require a Premium subscription.');
    }

    if (dto.topic && !this.isPremium(user)) {
      throw new ForbiddenException('Topic selection requires a Premium subscription.');
    }

    const where: FindOptionsWhere<Word> = { isActive: true };
    if (dto.difficulty) where.difficulty = dto.difficulty;
    if (dto.category) where.category = dto.category;

    let allWords = await this.wordRepository.find({ where });

    // Filter by topic in application code (word set is small, no perf concern)
    if (dto.topic) {
      allWords = allWords.filter(w => w.topics?.includes(dto.topic!));
    }

    if (allWords.length < count) {
      throw new BadRequestException(
        `Not enough words available for the selected filters (need ${count}, have ${allWords.length})`,
      );
    }

    if (this.isPremium(user)) {
      return this.getAdaptiveWords(allWords, count, user.id);
    }

    return this.shuffle(allWords).slice(0, count);
  }

  private async getAdaptiveWords(
    eligibleWords: Word[],
    count: number,
    userId: string,
  ): Promise<Word[]> {
    const eligibleIds = eligibleWords.map(w => w.id);

    // Get words this user has previously missed, most-missed first
    const missedHistory = await this.historyRepository.find({
      where: { userId, wordId: In(eligibleIds) },
      order: { timesMissed: 'DESC' },
    });

    const missedWordIds = new Set(
      missedHistory.filter(h => h.timesMissed > 0).map(h => h.wordId),
    );

    const missedWords = eligibleWords.filter(w => missedWordIds.has(w.id));
    const otherWords = eligibleWords.filter(w => !missedWordIds.has(w.id));

    // Up to 60% of slots filled with missed words (at least 1 if any missed words exist)
    const missedSlots = Math.min(Math.ceil(count * 0.6), missedWords.length);
    const otherSlots = count - missedSlots;

    const selected = [
      ...this.shuffle(missedWords).slice(0, missedSlots),
      ...this.shuffle(otherWords).slice(0, otherSlots),
    ];

    return this.shuffle(selected);
  }

  /**
   * Called after story submission to track which words were seen and missed.
   */
  async recordWordHistory(
    userId: string,
    targetWordTexts: string[],
    missingWordTexts: string[],
  ): Promise<void> {
    if (!targetWordTexts.length) return;

    const words = await this.wordRepository.find({
      where: { text: In(targetWordTexts) },
    });

    if (!words.length) return;

    const missingSet = new Set(missingWordTexts.map(w => w.toLowerCase()));

    for (const word of words) {
      const isMissed = missingSet.has(word.text.toLowerCase());
      const existing = await this.historyRepository.findOne({
        where: { userId, wordId: word.id },
      });

      if (existing) {
        existing.timesSeen += 1;
        if (isMissed) existing.timesMissed += 1;
        await this.historyRepository.save(existing);
      } else {
        await this.historyRepository.save(
          this.historyRepository.create({
            userId,
            wordId: word.id,
            timesSeen: 1,
            timesMissed: isMissed ? 1 : 0,
          }),
        );
      }
    }
  }

  async findAll(): Promise<Word[]> {
    return this.wordRepository.find({ where: { isActive: true }, order: { text: 'ASC' } });
  }
}
