import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Between } from 'typeorm';
import { StorySubmission } from '../database/entities';
import { User } from '../database/entities';

export const DAILY_CHALLENGES = [
  {
    id: 'warm_up',
    title: 'Warm Up',
    description: 'Complete 1 challenge today',
    icon: '🎯',
    target: 1,
    type: 'count',
  },
  {
    id: 'triple_play',
    title: 'Triple Play',
    description: 'Complete 3 challenges today',
    icon: '🔥',
    target: 3,
    type: 'count',
  },
  {
    id: 'high_scorer',
    title: 'High Scorer',
    description: 'Average score ≥ 75 today',
    icon: '📊',
    target: 75,
    type: 'avg_score',
  },
  {
    id: 'perfect_round',
    title: 'Perfect Round',
    description: 'Score 100 in one challenge',
    icon: '⭐',
    target: 100,
    type: 'max_score',
  },
  {
    id: 'word_master',
    title: 'Word Master',
    description: 'Use all target words correctly at least once',
    icon: '📖',
    target: 1,
    type: 'no_missing_words',
  },
];

@Injectable()
export class ChallengesService {
  constructor(
    @InjectRepository(StorySubmission)
    private readonly submissionRepository: Repository<StorySubmission>,
    @InjectRepository(User)
    private readonly usersRepository: Repository<User>,
  ) {}

  async getDailyChallenges(userId: string) {
    const now = new Date();
    const startOfDay = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));
    const endOfDay = new Date(startOfDay.getTime() + 24 * 60 * 60 * 1000);

    const todaySubmissions = await this.submissionRepository.find({
      where: {
        userId,
        createdAt: Between(startOfDay, endOfDay),
      },
    });

    const user = await this.usersRepository.findOne({
      where: { id: userId },
      select: ['currentStreak', 'longestStreak'] as any,
    });

    const count = todaySubmissions.length;
    const avgScore = count > 0
      ? Math.round(todaySubmissions.reduce((s, r) => s + r.scoreOverall, 0) / count)
      : 0;
    const maxScore = count > 0
      ? Math.max(...todaySubmissions.map(r => r.scoreOverall))
      : 0;
    const hasNoMissingWords = todaySubmissions.some(r => r.wordsMissing?.length === 0);

    const challenges = DAILY_CHALLENGES.map(c => {
      let progress = 0;
      let completed = false;

      switch (c.type) {
        case 'count':
          progress = Math.min(count, c.target);
          completed = count >= c.target;
          break;
        case 'avg_score':
          progress = avgScore;
          completed = count > 0 && avgScore >= c.target;
          break;
        case 'max_score':
          progress = maxScore;
          completed = maxScore >= c.target;
          break;
        case 'no_missing_words':
          progress = hasNoMissingWords ? 1 : 0;
          completed = hasNoMissingWords;
          break;
      }

      return {
        ...c,
        progress,
        completed,
      };
    });

    return {
      date: startOfDay.toISOString().split('T')[0],
      challenges,
      completedCount: challenges.filter(c => c.completed).length,
      totalCount: challenges.length,
      currentStreak: user?.currentStreak ?? 0,
      longestStreak: user?.longestStreak ?? 0,
      submissionsToday: count,
    };
  }
}
