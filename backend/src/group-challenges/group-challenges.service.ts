import { Injectable, NotFoundException, ForbiddenException, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { GroupChallenge, ChallengeStatus } from '../database/entities/group-challenge.entity';
import { ChallengeParticipant, ParticipantStatus } from '../database/entities/challenge-participant.entity';
import { User } from '../database/entities';
import { StorySubmission } from '../database/entities';
import { Notification } from '../database/entities/notification.entity';
import { HttpService } from '@nestjs/axios';
import { firstValueFrom } from 'rxjs';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class GroupChallengesService {
  constructor(
    @InjectRepository(GroupChallenge)
    private readonly challengeRepo: Repository<GroupChallenge>,
    @InjectRepository(ChallengeParticipant)
    private readonly participantRepo: Repository<ChallengeParticipant>,
    @InjectRepository(User)
    private readonly usersRepo: Repository<User>,
    @InjectRepository(StorySubmission)
    private readonly submissionRepo: Repository<StorySubmission>,
    @InjectRepository(Notification)
    private readonly notifRepo: Repository<Notification>,
    private readonly httpService: HttpService,
    private readonly configService: ConfigService,
  ) {}

  async createChallenge(hostId: string, dto: {
    wordCount: number;
    difficulty: string;
    durationDays: number;
    inviteUserIds: string[];
    words: string[];
  }) {
    const host = await this.usersRepo.findOne({ where: { id: hostId } });
    if (!host || host.subscriptionPlan !== 'premium') {
      throw new ForbiddenException('Creating group challenges requires a Premium account');
    }

    if (![1, 2, 3, 5, 7].includes(dto.durationDays)) {
      throw new BadRequestException('Duration must be 1, 2, 3, 5, or 7 days');
    }
    if (dto.inviteUserIds.length > 4) {
      throw new BadRequestException('Maximum 4 invitees (5 total including host)');
    }

    const challenge = this.challengeRepo.create({
      hostId,
      wordCount: dto.wordCount,
      difficulty: dto.difficulty,
      words: dto.words,
      durationDays: dto.durationDays,
      status: ChallengeStatus.PENDING,
    });
    const saved = await this.challengeRepo.save(challenge);

    // Host is automatically accepted
    const hostParticipant = this.participantRepo.create({
      challengeId: saved.id,
      userId: hostId,
      status: ParticipantStatus.ACCEPTED,
      acceptedAt: new Date(),
    });
    await this.participantRepo.save(hostParticipant);

    // Invite others
    const isUuid = (s: string) => /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(s);
    for (const userId of dto.inviteUserIds) {
      const where: any[] = [{ username: userId }];
      if (isUuid(userId)) where.push({ id: userId });
      const user = await this.usersRepo.findOne({ where });
      if (!user || user.id === hostId) continue;
      const p = this.participantRepo.create({
        challengeId: saved.id,
        userId: user.id,
        status: ParticipantStatus.INVITED,
      });
      await this.participantRepo.save(p);

      // Create notification for invitee
      await this.notifRepo.save(this.notifRepo.create({
        userId: user.id,
        type: 'challenge_invite',
        title: 'Challenge Invite ⚔️',
        message: `${host.username} challenged you! ${dto.wordCount} words · ${dto.difficulty} · ${dto.durationDays} days`,
        data: { challengeId: saved.id },
        isRead: false,
      }));
    }

    return this.getChallengeDetail(saved.id, hostId);
  }

  async getMyChallenges(userId: string) {
    const participations = await this.participantRepo.find({
      where: { userId },
      relations: ['challenge', 'challenge.host', 'challenge.participants', 'challenge.participants.user'],
    });

    return participations.map(p => ({
      ...p.challenge,
      myStatus: p.status,
      participants: p.challenge.participants.map(cp => ({
        userId: cp.userId,
        username: cp.user?.username,
        avatarUrl: cp.user?.avatarUrl,
        status: cp.status,
        score: cp.score,
      })),
    }));
  }

  async getChallengeDetail(challengeId: string, userId: string) {
    const challenge = await this.challengeRepo.findOne({
      where: { id: challengeId },
      relations: ['host', 'participants', 'participants.user'],
    });
    if (!challenge) throw new NotFoundException('Challenge not found');

    const myParticipant = challenge.participants.find(p => p.userId === userId);
    if (!myParticipant) throw new ForbiddenException('Not a participant');

    // Auto-finish if past endsAt
    if (challenge.status === ChallengeStatus.ACTIVE && challenge.endsAt && new Date() > challenge.endsAt) {
      await this.challengeRepo.update(challengeId, { status: ChallengeStatus.FINISHED });
      challenge.status = ChallengeStatus.FINISHED;
    }

    return {
      id: challenge.id,
      hostId: challenge.hostId,
      hostUsername: challenge.host?.username,
      wordCount: challenge.wordCount,
      difficulty: challenge.difficulty,
      words: challenge.words,
      durationDays: challenge.durationDays,
      status: challenge.status,
      startedAt: challenge.startedAt,
      endsAt: challenge.endsAt,
      createdAt: challenge.createdAt,
      myStatus: myParticipant.status,
      participants: challenge.participants
        .sort((a, b) => (b.score ?? -1) - (a.score ?? -1))
        .map((p, i) => ({
          rank: p.score != null ? i + 1 : null,
          userId: p.userId,
          username: p.user?.username,
          avatarUrl: p.user?.avatarUrl,
          status: p.status,
          score: p.score,
        })),
    };
  }

  async acceptChallenge(challengeId: string, userId: string) {
    const participant = await this.participantRepo.findOne({
      where: { challengeId, userId, status: ParticipantStatus.INVITED },
    });
    if (!participant) throw new NotFoundException('Invitation not found');

    participant.status = ParticipantStatus.ACCEPTED;
    participant.acceptedAt = new Date();
    await this.participantRepo.save(participant);

    // Start challenge if still pending
    const challenge = await this.challengeRepo.findOne({ where: { id: challengeId } });
    if (challenge && challenge.status === ChallengeStatus.PENDING) {
      const startedAt = new Date();
      const endsAt = new Date(startedAt.getTime() + challenge.durationDays * 24 * 60 * 60 * 1000);
      await this.challengeRepo.update(challengeId, {
        status: ChallengeStatus.ACTIVE,
        startedAt,
        endsAt,
      });
    }

    return { success: true };
  }

  async declineChallenge(challengeId: string, userId: string) {
    const participant = await this.participantRepo.findOne({
      where: { challengeId, userId, status: ParticipantStatus.INVITED },
    });
    if (!participant) throw new NotFoundException('Invitation not found');
    participant.status = ParticipantStatus.DECLINED;
    await this.participantRepo.save(participant);

    const challenge = await this.challengeRepo.findOne({
      where: { id: challengeId },
      relations: ['participants'],
    });

    if (challenge) {
      // Cancel challenge if no non-host participants remain active (invited/accepted)
      const nonHostActive = challenge.participants.filter(
        p => p.userId !== challenge.hostId &&
          (p.status === ParticipantStatus.INVITED || p.status === ParticipantStatus.ACCEPTED),
      );
      if (nonHostActive.length === 0 && challenge.status === ChallengeStatus.PENDING) {
        await this.challengeRepo.update(challengeId, { status: ChallengeStatus.CANCELLED });
      }

      // Notify host
      const decliner = await this.usersRepo.findOne({ where: { id: userId } });
      await this.notifRepo.save(this.notifRepo.create({
        userId: challenge.hostId,
        type: 'challenge_declined',
        title: 'Challenge Declined ❌',
        message: `${decliner?.username ?? 'Someone'} declined your challenge.`,
        data: { challengeId },
        isRead: false,
      }));
    }

    return { success: true };
  }

  async submitStory(challengeId: string, userId: string, storyText: string) {
    const challenge = await this.challengeRepo.findOne({ where: { id: challengeId } });
    if (!challenge) throw new NotFoundException('Challenge not found');
    if (challenge.status !== ChallengeStatus.ACTIVE) throw new BadRequestException('Challenge is not active');
    if (challenge.endsAt && new Date() > challenge.endsAt) throw new BadRequestException('Challenge has ended');

    const participant = await this.participantRepo.findOne({
      where: { challengeId, userId, status: ParticipantStatus.ACCEPTED },
    });
    if (!participant) throw new ForbiddenException('You must accept the challenge before submitting');

    const aiUrl = this.configService.get<string>('AI_SERVICE_URL', 'http://localhost:5001');
    let evalResult: any;
    try {
      const response = await firstValueFrom(
        this.httpService.post(`${aiUrl}/api/v1/evaluate-story`, {
          story_text: storyText,
          target_words: challenge.words,
          word_count: challenge.words.length,
        }),
      );
      evalResult = response.data;
    } catch {
      throw new BadRequestException('Evaluation service unavailable');
    }

    const submission = this.submissionRepo.create({
      userId,
      storyText,
      targetWords: challenge.words,
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
    const savedSub = await this.submissionRepo.save(submission);

    participant.status = ParticipantStatus.SUBMITTED;
    participant.score = evalResult.scores.overall;
    participant.submissionId = savedSub.id;
    await this.participantRepo.save(participant);

    return { score: evalResult.scores.overall, feedback: evalResult.feedback, encouragement: evalResult.encouragement };
  }
}
