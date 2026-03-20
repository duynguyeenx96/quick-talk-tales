import { Injectable, NotFoundException, BadRequestException, ConflictException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Friendship, FriendshipStatus } from '../database/entities/friendship.entity';
import { User } from '../database/entities';
import { Notification } from '../database/entities/notification.entity';

@Injectable()
export class FriendsService {
  constructor(
    @InjectRepository(Friendship)
    private readonly friendshipRepo: Repository<Friendship>,
    @InjectRepository(User)
    private readonly usersRepo: Repository<User>,
    @InjectRepository(Notification)
    private readonly notifRepo: Repository<Notification>,
  ) {}

  private isUuid(s: string) {
    return /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(s);
  }

  async sendRequest(requesterId: string, usernameOrId: string) {
    const where: any[] = [{ username: usernameOrId }];
    if (this.isUuid(usernameOrId)) where.push({ id: usernameOrId });
    const target = await this.usersRepo.findOne({ where });
    if (!target) throw new NotFoundException('User not found');
    if (target.id === requesterId) throw new BadRequestException('Cannot add yourself');

    const existing = await this.friendshipRepo.findOne({
      where: [
        { requesterId, receiverId: target.id },
        { requesterId: target.id, receiverId: requesterId },
      ],
    });
    if (existing) throw new ConflictException('Friend request already exists');

    const friendship = this.friendshipRepo.create({
      requesterId,
      receiverId: target.id,
      status: FriendshipStatus.PENDING,
    });
    const saved = await this.friendshipRepo.save(friendship);

    // Notify receiver
    const requester = await this.usersRepo.findOne({ where: { id: requesterId } });
    await this.notifRepo.save(this.notifRepo.create({
      userId: target.id,
      type: 'friend_request',
      title: 'Friend Request 👥',
      message: `${requester?.username ?? 'Someone'} wants to be your friend`,
      data: { friendshipId: saved.id },
      isRead: false,
    }));

    return saved;
  }

  async acceptRequest(userId: string, friendshipId: string) {
    const friendship = await this.friendshipRepo.findOne({ where: { id: friendshipId, receiverId: userId } });
    if (!friendship) throw new NotFoundException('Friend request not found');
    friendship.status = FriendshipStatus.ACCEPTED;
    return this.friendshipRepo.save(friendship);
  }

  async declineOrRemove(userId: string, friendshipId: string) {
    const friendship = await this.friendshipRepo.findOne({
      where: [
        { id: friendshipId, receiverId: userId },
        { id: friendshipId, requesterId: userId },
      ],
    });
    if (!friendship) throw new NotFoundException('Friendship not found');
    await this.friendshipRepo.remove(friendship);
    return { success: true };
  }

  async getFriends(userId: string) {
    const friendships = await this.friendshipRepo.find({
      where: [
        { requesterId: userId, status: FriendshipStatus.ACCEPTED },
        { receiverId: userId, status: FriendshipStatus.ACCEPTED },
      ],
      relations: ['requester', 'receiver'],
    });

    return friendships.map(f => {
      const friend = f.requesterId === userId ? f.receiver : f.requester;
      return {
        friendshipId: f.id,
        id: friend.id,
        username: friend.username,
        fullName: friend.fullName,
        avatarUrl: friend.avatarUrl,
        subscriptionPlan: friend.subscriptionPlan,
      };
    });
  }

  async getPendingRequests(userId: string) {
    return this.friendshipRepo.find({
      where: { receiverId: userId, status: FriendshipStatus.PENDING },
      relations: ['requester'],
    });
  }

  async searchUsers(query: string, currentUserId: string) {
    const users = await this.usersRepo
      .createQueryBuilder('u')
      .where('(u.username ILIKE :q OR u.id::text ILIKE :q)', { q: `%${query}%` })
      .andWhere('u.id::text != :me', { me: currentUserId })
      .select(['u.id', 'u.username', 'u.fullName', 'u.avatarUrl'])
      .limit(10)
      .getMany();
    return users;
  }
}
