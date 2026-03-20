import { Injectable, Logger, BadGatewayException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Between } from 'typeorm';
import { HttpService } from '@nestjs/axios';
import { firstValueFrom } from 'rxjs';
import { ConfigService } from '@nestjs/config';
import { StorySubmission, User } from '../database/entities';
import { SubmitStoryDto } from './dto/submit-story.dto';
import { WordsService } from '../words/words.service';

interface EvaluationResult {
  scores: {
    grammar: number;
    creativity: number;
    coherence: number;
    word_usage: number;
    overall: number;
  };
  words_used: string[];
  words_missing: string[];
  feedback: string;
  encouragement: string;
}

@Injectable()
export class EvaluationService {
  private readonly logger = new Logger(EvaluationService.name);
  private readonly aiServiceUrl: string;

  constructor(
    @InjectRepository(StorySubmission)
    private readonly submissionRepository: Repository<StorySubmission>,
    @InjectRepository(User)
    private readonly usersRepository: Repository<User>,
    private readonly httpService: HttpService,
    private readonly configService: ConfigService,
    private readonly wordsService: WordsService,
  ) {
    this.aiServiceUrl = this.configService.get<string>('AI_SERVICE_URL', 'http://localhost:5000');
  }

  async submitStory(dto: SubmitStoryDto, userId: string): Promise<any> {
    // Call FastAPI evaluation endpoint
    let evalResult: EvaluationResult;
    try {
      const response = await firstValueFrom(
        this.httpService.post(`${this.aiServiceUrl}/api/v1/evaluate-story`, {
          story_text: dto.storyText,
          target_words: dto.targetWords,
          word_count: dto.targetWords.length,
        }),
      );
      evalResult = response.data as EvaluationResult;
    } catch (error) {
      this.logger.error(`Story evaluation failed: ${error.message}`);
      throw new BadGatewayException('Story evaluation service unavailable. Please try again later.');
    }

    // Save submission to database
    const submission = this.submissionRepository.create({
      userId,
      storyText: dto.storyText,
      targetWords: dto.targetWords,
      wordsUsed: evalResult.words_used,
      wordsMissing: evalResult.words_missing,
      scoreGrammar: evalResult.scores.grammar,
      scoreCreativity: evalResult.scores.creativity,
      scoreCoherence: evalResult.scores.coherence,
      scoreWordUsage: evalResult.scores.word_usage,
      scoreOverall: evalResult.scores.overall,
      feedback: evalResult.feedback,
      encouragement: evalResult.encouragement,
    });

    const saved = await this.submissionRepository.save(submission);

    // Record word history for adaptive selection (fire-and-forget — non-blocking)
    this.wordsService
      .recordWordHistory(userId, dto.targetWords, evalResult.words_missing ?? [])
      .catch(err => this.logger.warn(`recordWordHistory failed: ${err.message}`));

    // Count streak on first story submission of the day, regardless of score
    await this.updateStreak(userId);

    const challengeRewardGranted = await this.checkAndGrantChallengeReward(userId);

    return { ...saved, challengeRewardGranted };
  }

  private async updateStreak(userId: string): Promise<void> {
    const user = await this.usersRepository.findOne({ where: { id: userId } });
    if (!user) return;

    const now = new Date();
    const todayUTC = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));

    const lastDate = user.lastActivityDate ? new Date(user.lastActivityDate) : null;
    if (lastDate) lastDate.setUTCHours(0, 0, 0, 0);

    let newStreak = user.currentStreak;
    if (!lastDate) {
      newStreak = 1;
    } else {
      const diffDays = Math.round((todayUTC.getTime() - lastDate.getTime()) / (1000 * 60 * 60 * 24));
      if (diffDays === 0) return;
      if (diffDays === 1) newStreak++;
      else newStreak = 1;
    }

    await this.usersRepository.update(userId, {
      currentStreak: newStreak,
      longestStreak: Math.max(newStreak, user.longestStreak),
      lastActivityDate: todayUTC as any,
    });
  }

  private async checkAndGrantChallengeReward(userId: string): Promise<boolean> {
    const user = await this.usersRepository.findOne({ where: { id: userId } });
    if (!user) return false;

    const now = new Date();
    const todayUTC = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));

    // Already rewarded today
    if (user.lastChallengeRewardDate) {
      const lastReward = new Date(user.lastChallengeRewardDate);
      lastReward.setUTCHours(0, 0, 0, 0);
      if (lastReward.getTime() === todayUTC.getTime()) return false;
    }

    // Fetch today's submissions
    const endOfDay = new Date(todayUTC.getTime() + 24 * 60 * 60 * 1000);
    const todaySubs = await this.submissionRepository.find({
      where: { userId, createdAt: Between(todayUTC, endOfDay) },
    });

    const count = todaySubs.length;
    const avgScore = count > 0 ? todaySubs.reduce((s, r) => s + r.scoreOverall, 0) / count : 0;
    const maxScore = count > 0 ? Math.max(...todaySubs.map(r => r.scoreOverall)) : 0;
    const hasNoMissing = todaySubs.some(r => !r.wordsMissing || r.wordsMissing.length === 0);

    const allDone =
      count >= 1 &&           // warm_up
      count >= 3 &&           // triple_play
      avgScore >= 75 &&       // high_scorer
      maxScore >= 100 &&      // perfect_round
      hasNoMissing;           // word_master

    if (!allDone) return false;

    // Grant 1 day premium
    const currentExpiry = user.subscriptionExpiresAt && user.subscriptionExpiresAt > now
      ? user.subscriptionExpiresAt
      : now;
    const newExpiry = new Date(currentExpiry.getTime() + 24 * 60 * 60 * 1000);

    await this.usersRepository.update(userId, {
      subscriptionPlan: 'premium',
      subscriptionExpiresAt: newExpiry,
      lastChallengeRewardDate: todayUTC as any,
    });

    return true;
  }

  async getHistory(userId: string): Promise<StorySubmission[]> {
    return this.submissionRepository.find({
      where: { userId },
      order: { createdAt: 'DESC' },
      take: 20,
    });
  }

  async getSubmission(id: string, userId: string): Promise<StorySubmission | null> {
    return this.submissionRepository.findOne({ where: { id, userId } });
  }

  async getLeaderboard(): Promise<any[]> {
    const rows = await this.submissionRepository
      .createQueryBuilder('s')
      .select('s.userId', 'userId')
      .addSelect('u.username', 'username')
      .addSelect('u.avatarUrl', 'avatarUrl')
      .addSelect('SUM(s.scoreOverall)', 'totalScore')
      .addSelect('COUNT(s.id)', 'totalChallenges')
      .addSelect('ROUND(AVG(s.scoreOverall))', 'avgScore')
      .addSelect('MAX(s.scoreOverall)', 'bestScore')
      .innerJoin('s.user', 'u')
      .groupBy('s.userId')
      .addGroupBy('u.username')
      .addGroupBy('u.avatarUrl')
      .orderBy('SUM(s.scoreOverall)', 'DESC')
      .limit(20)
      .getRawMany();

    return rows.map((r, i) => ({
      rank: i + 1,
      userId: r.userId,
      username: r.username,
      avatarUrl: r.avatarUrl,
      totalScore: Math.round(parseFloat(r.totalScore ?? '0')),
      totalChallenges: parseInt(r.totalChallenges ?? '0', 10),
      avgScore: Math.round(parseFloat(r.avgScore ?? '0')),
      bestScore: parseInt(r.bestScore ?? '0', 10),
    }));
  }

  async getMyStats(userId: string): Promise<any> {
    const [r, user] = await Promise.all([
      this.submissionRepository
        .createQueryBuilder('s')
        .select('COALESCE(SUM(s.scoreOverall), 0)', 'totalScore')
        .addSelect('COUNT(s.id)', 'totalChallenges')
        .addSelect('COALESCE(ROUND(AVG(s.scoreOverall)), 0)', 'avgScore')
        .addSelect('COALESCE(MAX(s.scoreOverall), 0)', 'bestScore')
        .where('s.userId = :userId', { userId })
        .getRawOne(),
      this.usersRepository.findOne({
        where: { id: userId },
        select: ['currentStreak', 'longestStreak'] as any,
      }),
    ]);

    return {
      totalScore: Math.round(parseFloat(r?.totalScore ?? '0')),
      totalChallenges: parseInt(r?.totalChallenges ?? '0', 10),
      avgScore: Math.round(parseFloat(r?.avgScore ?? '0')),
      bestScore: parseInt(r?.bestScore ?? '0', 10),
      currentStreak: user?.currentStreak ?? 0,
      longestStreak: user?.longestStreak ?? 0,
    };
  }
}
