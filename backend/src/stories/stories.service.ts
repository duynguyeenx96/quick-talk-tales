import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import {
  Story,
  Category,
  Tag,
  UserStoryProgress,
  UserRating,
  StoryStatus,
  UserRole,
} from '../database/entities';
import { CreateStoryDto } from './dto/create-story.dto';
import { UpdateStoryDto } from './dto/update-story.dto';
import { RateStoryDto } from './dto/rate-story.dto';
import { PaginationDto, PaginatedResult } from '../common/dto/pagination.dto';

@Injectable()
export class StoriesService {
  constructor(
    @InjectRepository(Story)
    private storiesRepository: Repository<Story>,
    @InjectRepository(Category)
    private categoriesRepository: Repository<Category>,
    @InjectRepository(Tag)
    private tagsRepository: Repository<Tag>,
    @InjectRepository(UserStoryProgress)
    private userStoryProgressRepository: Repository<UserStoryProgress>,
    @InjectRepository(UserRating)
    private userRatingRepository: Repository<UserRating>,
  ) {}

  private generateSlug(title: string): string {
    return title
      .toLowerCase()
      .replace(/[^\w\s-]/g, '')
      .replace(/\s+/g, '-')
      .replace(/-+/g, '-')
      .trim();
  }

  async create(
    createStoryDto: CreateStoryDto,
    authorId: string,
  ): Promise<Story> {
    const slug = this.generateSlug(createStoryDto.title);

    const story = this.storiesRepository.create({
      ...createStoryDto,
      slug,
      authorId,
      publishedAt:
        createStoryDto.status === StoryStatus.PUBLISHED ? new Date() : null,
    });

    const savedStory = await this.storiesRepository.save(story);

    if (createStoryDto.tagIds && createStoryDto.tagIds.length > 0) {
      const tags = await this.tagsRepository.findByIds(createStoryDto.tagIds);
      savedStory.tags = tags;
      await this.storiesRepository.save(savedStory);
    }

    return this.findOne(savedStory.id);
  }

  async findAll(
    pagination: PaginationDto,
    filters?: {
      status?: StoryStatus;
      categoryId?: string;
      difficulty?: string;
      isFeatured?: boolean;
      isInteractive?: boolean;
      authorId?: string;
    },
  ): Promise<PaginatedResult<Story>> {
    const { page, limit, search, sortBy, sortOrder } = pagination;
    const skip = (page - 1) * limit;

    const queryBuilder = this.storiesRepository
      .createQueryBuilder('story')
      .leftJoinAndSelect('story.author', 'author')
      .leftJoinAndSelect('story.category', 'category')
      .leftJoinAndSelect('story.tags', 'tags');

    if (search) {
      queryBuilder.where(
        'story.title ILIKE :search OR story.description ILIKE :search OR author.username ILIKE :search',
        { search: `%${search}%` },
      );
    }

    if (filters?.status) {
      queryBuilder.andWhere('story.status = :status', {
        status: filters.status,
      });
    }

    if (filters?.categoryId) {
      queryBuilder.andWhere('story.categoryId = :categoryId', {
        categoryId: filters.categoryId,
      });
    }

    if (filters?.difficulty) {
      queryBuilder.andWhere('story.difficulty = :difficulty', {
        difficulty: filters.difficulty,
      });
    }

    if (filters?.isFeatured !== undefined) {
      queryBuilder.andWhere('story.isFeatured = :isFeatured', {
        isFeatured: filters.isFeatured,
      });
    }

    if (filters?.isInteractive !== undefined) {
      queryBuilder.andWhere('story.isInteractive = :isInteractive', {
        isInteractive: filters.isInteractive,
      });
    }

    if (filters?.authorId) {
      queryBuilder.andWhere('story.authorId = :authorId', {
        authorId: filters.authorId,
      });
    }

    if (sortBy) {
      queryBuilder.orderBy(`story.${sortBy}`, sortOrder);
    } else {
      queryBuilder.orderBy('story.createdAt', sortOrder);
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

  async findOne(id: string): Promise<Story> {
    const story = await this.storiesRepository.findOne({
      where: { id },
      relations: ['author', 'category', 'tags', 'chapters'],
      order: { chapters: { orderIndex: 'ASC' } },
    });

    if (!story) {
      throw new NotFoundException('Story not found');
    }

    return story;
  }

  async findBySlug(slug: string): Promise<Story> {
    const story = await this.storiesRepository.findOne({
      where: { slug },
      relations: ['author', 'category', 'tags', 'chapters'],
      order: { chapters: { orderIndex: 'ASC' } },
    });

    if (!story) {
      throw new NotFoundException('Story not found');
    }

    return story;
  }

  async update(
    id: string,
    updateStoryDto: UpdateStoryDto,
    userId: string,
    userRole: UserRole,
  ): Promise<Story> {
    const story = await this.findOne(id);

    if (story.authorId !== userId && userRole !== UserRole.ADMIN) {
      throw new ForbiddenException('You can only update your own stories');
    }

    if (updateStoryDto.title && updateStoryDto.title !== story.title) {
      updateStoryDto['slug'] = this.generateSlug(updateStoryDto.title);
    }

    if (updateStoryDto.status === StoryStatus.PUBLISHED && !story.publishedAt) {
      updateStoryDto['publishedAt'] = new Date();
    }

    await this.storiesRepository.update(id, updateStoryDto);

    if (updateStoryDto.tagIds) {
      const tags = await this.tagsRepository.findByIds(updateStoryDto.tagIds);
      story.tags = tags;
      await this.storiesRepository.save(story);
    }

    return this.findOne(id);
  }

  async remove(id: string, userId: string, userRole: UserRole): Promise<void> {
    const story = await this.findOne(id);

    if (story.authorId !== userId && userRole !== UserRole.ADMIN) {
      throw new ForbiddenException('You can only delete your own stories');
    }

    await this.storiesRepository.remove(story);
  }

  async incrementViewCount(id: string): Promise<void> {
    await this.storiesRepository.increment({ id }, 'viewCount', 1);
  }

  async rateStory(
    storyId: string,
    userId: string,
    rateStoryDto: RateStoryDto,
  ): Promise<UserRating> {
    let rating = await this.userRatingRepository.findOne({
      where: { storyId, userId },
    });

    if (rating) {
      await this.userRatingRepository.update(rating.id, rateStoryDto);
      rating = await this.userRatingRepository.findOne({
        where: { id: rating.id },
      });
    } else {
      rating = this.userRatingRepository.create({
        ...rateStoryDto,
        storyId,
        userId,
      });
      await this.userRatingRepository.save(rating);
    }

    return rating;
  }

  async getStoryRatings(
    storyId: string,
    pagination: PaginationDto,
  ): Promise<PaginatedResult<UserRating>> {
    const { page, limit } = pagination;
    const skip = (page - 1) * limit;

    const [data, total] = await this.userRatingRepository.findAndCount({
      where: { storyId, isPublic: true },
      relations: ['user'],
      skip,
      take: limit,
      order: { createdAt: 'DESC' },
    });

    return {
      data,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  async getUserProgress(
    storyId: string,
    userId: string,
  ): Promise<UserStoryProgress | null> {
    return this.userStoryProgressRepository.findOne({
      where: { storyId, userId },
      relations: ['currentChapter'],
    });
  }

  async updateUserProgress(
    storyId: string,
    userId: string,
    progressData: Partial<UserStoryProgress>,
  ): Promise<UserStoryProgress> {
    let progress = await this.userStoryProgressRepository.findOne({
      where: { storyId, userId },
    });

    if (progress) {
      await this.userStoryProgressRepository.update(progress.id, {
        ...progressData,
        lastReadAt: new Date(),
      });
      progress = await this.userStoryProgressRepository.findOne({
        where: { id: progress.id },
        relations: ['currentChapter'],
      });
    } else {
      progress = this.userStoryProgressRepository.create({
        storyId,
        userId,
        ...progressData,
        startedAt: new Date(),
        lastReadAt: new Date(),
      });
      await this.userStoryProgressRepository.save(progress);
    }

    return progress;
  }

  async getFeaturedStories(): Promise<Story[]> {
    return this.storiesRepository.find({
      where: { isFeatured: true, status: StoryStatus.PUBLISHED },
      relations: ['author', 'category', 'tags'],
      order: { createdAt: 'DESC' },
      take: 10,
    });
  }

  async getPopularStories(): Promise<Story[]> {
    return this.storiesRepository.find({
      where: { status: StoryStatus.PUBLISHED },
      relations: ['author', 'category', 'tags'],
      order: { viewCount: 'DESC', rating: 'DESC' },
      take: 10,
    });
  }

  async getRecentStories(): Promise<Story[]> {
    return this.storiesRepository.find({
      where: { status: StoryStatus.PUBLISHED },
      relations: ['author', 'category', 'tags'],
      order: { publishedAt: 'DESC' },
      take: 10,
    });
  }
}
