import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../database/entities';
import { PaginationDto, PaginatedResult } from '../common/dto/pagination.dto';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private usersRepository: Repository<User>,
  ) {}

  async findAll(pagination: PaginationDto): Promise<PaginatedResult<User>> {
    const { page, limit, search, sortBy, sortOrder } = pagination;
    const skip = (page - 1) * limit;

    const queryBuilder = this.usersRepository.createQueryBuilder('user');

    if (search) {
      queryBuilder.where(
        'user.username ILIKE :search OR user.email ILIKE :search OR user.fullName ILIKE :search',
        { search: `%${search}%` },
      );
    }

    if (sortBy) {
      queryBuilder.orderBy(`user.${sortBy}`, sortOrder);
    } else {
      queryBuilder.orderBy('user.createdAt', sortOrder);
    }

    const [data, total] = await queryBuilder
      .skip(skip)
      .take(limit)
      .getManyAndCount();

    return {
      data,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  async findById(id: string): Promise<User> {
    const user = await this.usersRepository.findOne({
      where: { id },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    return user;
  }

  async findByEmail(email: string): Promise<User | null> {
    return this.usersRepository.findOne({
      where: { email },
    });
  }

  async findByUsername(username: string): Promise<User | null> {
    return this.usersRepository.findOne({
      where: { username },
    });
  }

  async findByEmailOrUsername(email: string, username: string): Promise<User | null> {
    return this.usersRepository.findOne({
      where: [{ email }, { username }],
    });
  }

  async findByReferralCode(code: string): Promise<User | null> {
    return this.usersRepository.findOne({ where: { referralCode: code } });
  }

  async updateProfile(id: string, updateData: Partial<User>): Promise<User> {
    await this.usersRepository.update(id, updateData);
    return this.findById(id);
  }

  async deactivateUser(id: string): Promise<User> {
    await this.usersRepository.update(id, { isActive: false });
    return this.findById(id);
  }

  async activateUser(id: string): Promise<User> {
    await this.usersRepository.update(id, { isActive: true });
    return this.findById(id);
  }

}