import {
  Injectable,
  Logger,
  OnModuleInit,
  NotFoundException,
  ForbiddenException,
  ConflictException,
  BadGatewayException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Cron } from '@nestjs/schedule';
import { HttpService } from '@nestjs/axios';
import { ConfigService } from '@nestjs/config';
import { firstValueFrom } from 'rxjs';
import {
  ClassroomSession,
  ClassroomParticipant,
  User,
  Word,
  Notification,
} from '../database/entities';
import { SubmitClassroomStoryDto } from './dto/submit-classroom-story.dto';

// Session is active for 10 minutes after startTime
const SESSION_DURATION_MS = 10 * 60 * 1000;
// Default word count per session
const SESSION_WORD_COUNT = 5;
// Free users can join at most this many sessions per UTC day
const FREE_DAILY_LIMIT = 1;

interface AiEvalResult {
  scores: { grammar: number; creativity: number; coherence: number; word_usage: number; overall: number };
  words_used: string[];
  words_missing: string[];
  feedback: string;
  encouragement: string;
}

@Injectable()
export class ClassroomService implements OnModuleInit {
  private readonly logger = new Logger(ClassroomService.name);
  private readonly aiServiceUrl: string;

  constructor(
    @InjectRepository(ClassroomSession)
    private readonly sessionRepo: Repository<ClassroomSession>,
    @InjectRepository(ClassroomParticipant)
    private readonly participantRepo: Repository<ClassroomParticipant>,
    @InjectRepository(User)
    private readonly userRepo: Repository<User>,
    @InjectRepository(Word)
    private readonly wordRepo: Repository<Word>,
    @InjectRepository(Notification)
    private readonly notifRepo: Repository<Notification>,
    private readonly httpService: HttpService,
    private readonly configService: ConfigService,
  ) {
    this.aiServiceUrl = this.configService.get<string>('AI_SERVICE_URL', 'http://localhost:5000');
  }

  // ─── On startup: ensure there's always an active or upcoming session ─────

  async onModuleInit() {
    await this.ensureActiveSession();
  }

  private async ensureActiveSession() {
    const now = new Date();
    const existing = await this.sessionRepo
      .createQueryBuilder('s')
      .where('s.end_time >= :now', { now })
      .getOne();

    if (!existing) {
      const startTime = new Date();
      const endTime = new Date(startTime.getTime() + SESSION_DURATION_MS);
      const words = await this.getRandomWordTexts(SESSION_WORD_COUNT);
      const session = await this.sessionRepo.save(
        this.sessionRepo.create({ wordSet: words, wordCount: SESSION_WORD_COUNT, startTime, endTime }),
      );
      this.logger.log(`Created startup classroom session: ${session.id}`);
    }
  }

  // ─── Cron: create upcoming session at :55 of every hour ──────────────────

  @Cron('55 * * * *')
  async scheduleNextSession() {
    const startTime = this.nextHourTop();
    const endTime = new Date(startTime.getTime() + SESSION_DURATION_MS);

    // Avoid duplicate sessions for the same startTime
    const exists = await this.sessionRepo.findOne({ where: { startTime } });
    if (exists) return;

    const words = await this.getRandomWordTexts(SESSION_WORD_COUNT);
    const session = await this.sessionRepo.save(
      this.sessionRepo.create({ wordSet: words, wordCount: SESSION_WORD_COUNT, startTime, endTime }),
    );

    this.logger.log(`Classroom session scheduled: ${session.id} at ${startTime.toISOString()}`);

    // Schedule in-app notifications via setTimeout
    const msUntilFiveMin = startTime.getTime() - Date.now() - 5 * 60 * 1000;
    const msUntilOneMin  = startTime.getTime() - Date.now() - 1 * 60 * 1000;

    if (msUntilFiveMin > 0) {
      setTimeout(() => this.broadcastNotification(session.id, 5), msUntilFiveMin);
    }
    if (msUntilOneMin > 0) {
      setTimeout(() => this.broadcastNotification(session.id, 1), msUntilOneMin);
    }
  }

  // ─── Cron: create new active session every hour at :00 ───────────────────

  @Cron('0 * * * *')
  async createHourlySession() {
    const startTime = new Date();
    const endTime = new Date(startTime.getTime() + SESSION_DURATION_MS);
    const words = await this.getRandomWordTexts(SESSION_WORD_COUNT);
    const session = await this.sessionRepo.save(
      this.sessionRepo.create({ wordSet: words, wordCount: SESSION_WORD_COUNT, startTime, endTime }),
    );
    this.logger.log(`Created hourly classroom session: ${session.id}`);

    // Reschedule next :55 notification (handled separately by scheduleNextSession cron)
  }

  // ─── Cron: daily cleanup — delete old sessions with zero submissions ────────
  // Sessions that had at least one scored participant are kept indefinitely
  // so classroom history and all-time leaderboard remain accurate forever.

  @Cron('0 3 * * *')
  async cleanupOldSessions() {
    const cutoff = new Date(Date.now() - 90 * 24 * 60 * 60 * 1000);

    // Find sessions older than 90 days that have NO scored participants
    const emptySessions = await this.sessionRepo
      .createQueryBuilder('s')
      .leftJoin(
        's.participants',
        'p',
        'p.session_id = s.id AND p.score_overall IS NOT NULL',
      )
      .where('s.created_at < :cutoff', { cutoff })
      .andWhere('p.id IS NULL')
      .select('s.id')
      .getMany();

    if (emptySessions.length === 0) return;

    const ids = emptySessions.map(s => s.id);
    await this.sessionRepo.delete(ids);
    this.logger.log(`Cleaned up ${ids.length} empty sessions older than 90 days`);
  }

  // ─── API ──────────────────────────────────────────────────────────────────

  /**
   * Returns the active session or the next upcoming session (within 30 min).
   * Returns null when there is nothing relevant right now.
   */
  async getCurrentSession(userId: string): Promise<Record<string, any> | null> {
    const now = new Date();
    const windowEnd = new Date(now.getTime() + 30 * 60 * 1000);

    // Prefer active session; fall back to upcoming within 30 min
    const session = await this.sessionRepo
      .createQueryBuilder('s')
      .where('s.end_time >= :now', { now })
      .andWhere('s.start_time <= :windowEnd', { windowEnd })
      .orderBy('s.start_time', 'ASC')
      .getOne();

    if (!session) return null;

    const participantCount = await this.participantRepo.count({ where: { sessionId: session.id } });
    const joined = await this.participantRepo.findOne({ where: { sessionId: session.id, userId } });

    const msUntilStart = Math.max(0, session.startTime.getTime() - now.getTime());

    return {
      id: session.id,
      wordSet: session.wordSet,
      wordCount: session.wordCount,
      startTime: session.startTime,
      endTime: session.endTime,
      status: session.status,
      participantCount,
      hasJoined: !!joined,
      submissionId: joined?.submissionId ?? null,
      minutesUntilStart: Math.ceil(msUntilStart / 60000),
    };
  }

  async joinSession(sessionId: string, user: User): Promise<ClassroomParticipant> {
    const session = await this.sessionRepo.findOne({ where: { id: sessionId } });
    if (!session) throw new NotFoundException('Session not found');

    const status = session.status;
    if (status === 'ended') throw new ForbiddenException('This session has already ended.');
    if (status === 'upcoming') {
      // Allow joining up to 5 min before start for lobby
      const msUntilStart = session.startTime.getTime() - Date.now();
      if (msUntilStart > 5 * 60 * 1000) throw new ForbiddenException('Session has not opened for joining yet.');
    }

    // Check if already joined
    const existing = await this.participantRepo.findOne({ where: { sessionId, userId: user.id } });
    if (existing) throw new ConflictException('Already joined this session.');

    // Daily join limit for free users
    if (!this.isPremium(user)) {
      const todayStart = this.todayUtcMidnight();
      const todayJoins = await this.participantRepo
        .createQueryBuilder('p')
        .where('p.user_id = :userId', { userId: user.id })
        .andWhere('p.joined_at >= :todayStart', { todayStart })
        .getCount();

      if (todayJoins >= FREE_DAILY_LIMIT) {
        throw new ForbiddenException(
          `Free users can join ${FREE_DAILY_LIMIT} classroom session per day. Upgrade to Premium for unlimited access.`,
        );
      }
    }

    return this.participantRepo.save(
      this.participantRepo.create({ sessionId, userId: user.id }),
    );
  }

  async submitClassroomStory(
    sessionId: string,
    userId: string,
    dto: SubmitClassroomStoryDto,
  ): Promise<Record<string, any>> {
    const session = await this.sessionRepo.findOne({ where: { id: sessionId } });
    if (!session) throw new NotFoundException('Session not found');
    if (session.status !== 'active') throw new ForbiddenException('Session is not accepting submissions right now.');

    const participant = await this.participantRepo.findOne({ where: { sessionId, userId } });
    if (!participant) throw new ForbiddenException('You have not joined this session.');
    if (participant.submissionId) throw new ConflictException('You have already submitted for this session.');

    // Evaluate via AI service
    let evalResult: AiEvalResult;
    try {
      const response = await firstValueFrom(
        this.httpService.post(`${this.aiServiceUrl}/api/v1/evaluate-story`, {
          story_text: dto.storyText,
          target_words: session.wordSet,
          word_count: session.wordSet.length,
        }),
      );
      evalResult = response.data as AiEvalResult;
    } catch (error) {
      this.logger.error(`AI evaluation failed: ${error.message}`);
      throw new BadGatewayException('Story evaluation service unavailable. Please try again.');
    }

    // Update participant with score
    participant.scoreOverall = evalResult.scores.overall;
    // Use a generated ID as a placeholder reference (no separate StorySubmission for classroom — score stored on participant)
    participant.submissionId = `classroom-${sessionId}-${userId}`;
    await this.participantRepo.save(participant);

    return {
      sessionId,
      scores: evalResult.scores,
      wordsUsed: evalResult.words_used,
      wordsMissing: evalResult.words_missing,
      feedback: evalResult.feedback,
      encouragement: evalResult.encouragement,
    };
  }

  async getLeaderboard(sessionId: string): Promise<Record<string, any>[]> {
    const participants = await this.participantRepo
      .createQueryBuilder('p')
      .leftJoinAndSelect('p.user', 'u')
      .where('p.session_id = :sessionId', { sessionId })
      .andWhere('p.score_overall IS NOT NULL')
      .orderBy('p.score_overall', 'DESC')
      .limit(20)
      .getMany();

    return participants.map((p, i) => ({
      rank: i + 1,
      userId: p.userId,
      username: p.user?.username ?? 'Unknown',
      avatarUrl: p.user?.avatarUrl ?? null,
      scoreOverall: p.scoreOverall,
      joinedAt: p.joinedAt,
    }));
  }

  /** User's personal classroom participation history with rank per session. */
  async getMyHistory(userId: string): Promise<Record<string, any>[]> {
    const participations = await this.participantRepo
      .createQueryBuilder('p')
      .leftJoinAndSelect('p.session', 's')
      .where('p.user_id = :userId', { userId })
      .orderBy('p.joined_at', 'DESC')
      .limit(50)
      .getMany();

    return Promise.all(
      participations.map(async p => {
        const participantCount = await this.participantRepo.count({ where: { sessionId: p.sessionId } });

        let rank: number | null = null;
        if (p.scoreOverall !== null && p.scoreOverall !== undefined) {
          const higher = await this.participantRepo
            .createQueryBuilder('p2')
            .where('p2.session_id = :sessionId', { sessionId: p.sessionId })
            .andWhere('p2.score_overall > :score', { score: p.scoreOverall })
            .getCount();
          rank = higher + 1;
        }

        return {
          sessionId: p.sessionId,
          wordSet: p.session?.wordSet ?? [],
          wordCount: p.session?.wordCount ?? 0,
          startTime: p.session?.startTime ?? null,
          endTime: p.session?.endTime ?? null,
          scoreOverall: p.scoreOverall ?? null,
          rank,
          participantCount,
          submitted: !!p.submissionId,
          joinedAt: p.joinedAt,
        };
      }),
    );
  }

  /** All-time classroom leaderboard: top users by total score across all sessions. */
  async getAllTimeLeaderboard(): Promise<Record<string, any>[]> {
    const rows = await this.participantRepo
      .createQueryBuilder('p')
      .leftJoin('p.user', 'u')
      .select('p.user_id', 'userId')
      .addSelect('u.username', 'username')
      .addSelect('u.avatar_url', 'avatarUrl')
      .addSelect('COUNT(p.id)', 'sessionsJoined')
      .addSelect('COUNT(p.submission_id)', 'sessionsSubmitted')
      .addSelect('COALESCE(SUM(p.score_overall), 0)', 'totalScore')
      .addSelect('MAX(p.score_overall)', 'bestScore')
      .addSelect('ROUND(AVG(p.score_overall)::numeric, 1)', 'avgScore')
      .where('p.score_overall IS NOT NULL')
      .groupBy('p.user_id')
      .addGroupBy('u.username')
      .addGroupBy('u.avatar_url')
      .orderBy('COALESCE(SUM(p.score_overall), 0)', 'DESC')
      .limit(50)
      .getRawMany();

    return rows.map((r, i) => ({
      rank: i + 1,
      userId: r.userId,
      username: r.username ?? 'Unknown',
      avatarUrl: r.avatarUrl ?? null,
      sessionsJoined: parseInt(r.sessionsJoined ?? '0'),
      sessionsSubmitted: parseInt(r.sessionsSubmitted ?? '0'),
      totalScore: parseInt(r.totalScore ?? '0'),
      bestScore: r.bestScore !== null ? parseInt(r.bestScore) : null,
      avgScore: r.avgScore !== null ? parseFloat(r.avgScore) : null,
    }));
  }

  async getRecentSessions(): Promise<Record<string, any>[]> {
    const sessions = await this.sessionRepo
      .createQueryBuilder('s')
      .orderBy('s.start_time', 'DESC')
      .limit(10)
      .getMany();

    return Promise.all(
      sessions.map(async s => ({
        id: s.id,
        wordSet: s.wordSet,
        wordCount: s.wordCount,
        startTime: s.startTime,
        endTime: s.endTime,
        status: s.status,
        participantCount: await this.participantRepo.count({ where: { sessionId: s.id } }),
      })),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  private isPremium(user: User): boolean {
    return (
      user.subscriptionPlan === 'premium' &&
      (!user.subscriptionExpiresAt || user.subscriptionExpiresAt > new Date())
    );
  }

  private todayUtcMidnight(): Date {
    const d = new Date();
    d.setUTCHours(0, 0, 0, 0);
    return d;
  }

  private nextHourTop(): Date {
    const d = new Date();
    d.setUTCMinutes(0, 0, 0);
    d.setUTCHours(d.getUTCHours() + 1);
    return d;
  }

  private async getRandomWordTexts(count: number): Promise<string[]> {
    const words = await this.wordRepo
      .createQueryBuilder('w')
      .where('w.is_active = true')
      .orderBy('RANDOM()')
      .limit(count)
      .getMany();
    return words.map(w => w.text);
  }

  /**
   * Writes an in-app notification to all active users about an upcoming session.
   * minutesBefore: 5 or 1.
   */
  private async broadcastNotification(sessionId: string, minutesBefore: number) {
    const users = await this.userRepo.find({ where: { isActive: true } });
    const title = minutesBefore === 5
      ? 'Classroom session in 5 minutes!'
      : 'Classroom session starting now!';
    const message = minutesBefore === 5
      ? 'A new classroom session starts in 5 minutes. Get ready to write your story!'
      : 'The classroom session starts in 1 minute — join now!';

    const notifications = users.map(u =>
      this.notifRepo.create({
        userId: u.id,
        title,
        message,
        type: 'classroom',
        data: { sessionId, minutesBefore },
      }),
    );

    // Batch insert in chunks to avoid overwhelming the DB
    const chunkSize = 100;
    for (let i = 0; i < notifications.length; i += chunkSize) {
      await this.notifRepo.save(notifications.slice(i, i + chunkSize));
    }

    this.logger.log(`Broadcast classroom notification (${minutesBefore}min) to ${users.length} users`);
  }
}
