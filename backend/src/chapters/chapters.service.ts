import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Chapter, Story, UserChapterProgress, UserRole } from '../database/entities';
import { CreateChapterDto } from './dto/create-chapter.dto';
import { UpdateChapterDto } from './dto/update-chapter.dto';
import { StoriesService } from '../stories/stories.service';

@Injectable()
export class ChaptersService {
  constructor(
    @InjectRepository(Chapter)
    private chaptersRepository: Repository<Chapter>,
    @InjectRepository(Story)
    private storiesRepository: Repository<Story>,
    @InjectRepository(UserChapterProgress)
    private userChapterProgressRepository: Repository<UserChapterProgress>,
    private storiesService: StoriesService,
  ) {}

  private generateSlug(title: string): string {
    return title
      .toLowerCase()
      .replace(/[^\w\s-]/g, '')
      .replace(/\s+/g, '-')
      .replace(/-+/g, '-')
      .trim();
  }

  private calculateReadingStats(content: string) {
    const wordCount = content.split(/\s+/).length;
    const readingTime = Math.ceil(wordCount / 200); // Average reading speed: 200 words per minute
    return { wordCount, readingTime };
  }

  async create(storyId: string, createChapterDto: CreateChapterDto, userId: string, userRole: UserRole): Promise<Chapter> {
    const story = await this.storiesService.findOne(storyId);
    
    if (story.authorId !== userId && userRole !== UserRole.ADMIN) {
      throw new ForbiddenException('You can only add chapters to your own stories');
    }

    const slug = this.generateSlug(createChapterDto.title);
    const { wordCount, readingTime } = this.calculateReadingStats(createChapterDto.content);

    const chapter = this.chaptersRepository.create({
      ...createChapterDto,
      slug,
      storyId,
      wordCount,
      readingTime,
    });

    return this.chaptersRepository.save(chapter);
  }

  async findAllByStory(storyId: string, includeUnpublished: boolean = false): Promise<Chapter[]> {
    const whereConditions: any = { storyId };
    
    if (!includeUnpublished) {
      whereConditions.isPublished = true;
    }

    return this.chaptersRepository.find({
      where: whereConditions,
      order: { orderIndex: 'ASC' },
    });
  }

  async findOne(id: string): Promise<Chapter> {
    const chapter = await this.chaptersRepository.findOne({
      where: { id },
      relations: ['story', 'story.author'],
    });

    if (!chapter) {
      throw new NotFoundException('Chapter not found');
    }

    return chapter;
  }

  async findBySlug(storyId: string, slug: string): Promise<Chapter> {
    const chapter = await this.chaptersRepository.findOne({
      where: { storyId, slug },
      relations: ['story', 'story.author'],
    });

    if (!chapter) {
      throw new NotFoundException('Chapter not found');
    }

    return chapter;
  }

  async update(id: string, updateChapterDto: UpdateChapterDto, userId: string, userRole: UserRole): Promise<Chapter> {
    const chapter = await this.findOne(id);

    if (chapter.story.authorId !== userId && userRole !== UserRole.ADMIN) {
      throw new ForbiddenException('You can only update chapters in your own stories');
    }

    const updateData: any = { ...updateChapterDto };

    if (updateChapterDto.title && updateChapterDto.title !== chapter.title) {
      updateData.slug = this.generateSlug(updateChapterDto.title);
    }

    if (updateChapterDto.content) {
      const { wordCount, readingTime } = this.calculateReadingStats(updateChapterDto.content);
      updateData.wordCount = wordCount;
      updateData.readingTime = readingTime;
    }

    await this.chaptersRepository.update(id, updateData);
    return this.findOne(id);
  }

  async remove(id: string, userId: string, userRole: UserRole): Promise<void> {
    const chapter = await this.findOne(id);

    if (chapter.story.authorId !== userId && userRole !== UserRole.ADMIN) {
      throw new ForbiddenException('You can only delete chapters from your own stories');
    }

    await this.chaptersRepository.remove(chapter);
  }

  async reorderChapters(storyId: string, chapterIds: string[], userId: string, userRole: UserRole): Promise<Chapter[]> {
    const story = await this.storiesService.findOne(storyId);

    if (story.authorId !== userId && userRole !== UserRole.ADMIN) {
      throw new ForbiddenException('You can only reorder chapters in your own stories');
    }

    const chapters = await this.chaptersRepository.find({
      where: { storyId },
      order: { orderIndex: 'ASC' },
    });

    // Verify all chapter IDs belong to this story
    const storyChapterIds = chapters.map(c => c.id);
    const invalidIds = chapterIds.filter(id => !storyChapterIds.includes(id));
    
    if (invalidIds.length > 0) {
      throw new NotFoundException(`Invalid chapter IDs: ${invalidIds.join(', ')}`);
    }

    // Update order indexes
    const updatePromises = chapterIds.map((chapterId, index) =>
      this.chaptersRepository.update(chapterId, { orderIndex: index + 1 })
    );

    await Promise.all(updatePromises);

    return this.findAllByStory(storyId, true);
  }

  async getNextChapter(storyId: string, currentOrderIndex: number): Promise<Chapter | null> {
    return this.chaptersRepository.findOne({
      where: {
        storyId,
        orderIndex: currentOrderIndex + 1,
        isPublished: true,
      },
    });
  }

  async getPreviousChapter(storyId: string, currentOrderIndex: number): Promise<Chapter | null> {
    return this.chaptersRepository.findOne({
      where: {
        storyId,
        orderIndex: currentOrderIndex - 1,
        isPublished: true,
      },
    });
  }

  async markChapterAsRead(chapterId: string, userId: string, choicesMade?: any[]): Promise<UserChapterProgress> {
    const chapter = await this.findOne(chapterId);

    let progress = await this.userChapterProgressRepository.findOne({
      where: { chapterId, userId },
    });

    if (progress) {
      await this.userChapterProgressRepository.update(progress.id, {
        isCompleted: true,
        completedAt: new Date(),
        choicesMade: choicesMade || progress.choicesMade,
        readingTime: progress.readingTime + chapter.readingTime,
      });
    } else {
      progress = this.userChapterProgressRepository.create({
        chapterId,
        userId,
        storyId: chapter.storyId,
        isCompleted: true,
        completedAt: new Date(),
        choicesMade: choicesMade || [],
        readingTime: chapter.readingTime,
      });
      await this.userChapterProgressRepository.save(progress);
    }

    // Update story progress
    await this.updateStoryProgress(chapter.storyId, userId);

    return progress;
  }

  private async updateStoryProgress(storyId: string, userId: string): Promise<void> {
    const totalChapters = await this.chaptersRepository.count({
      where: { storyId, isPublished: true },
    });

    const completedChapters = await this.userChapterProgressRepository.count({
      where: { storyId, userId, isCompleted: true },
    });

    const progressPercentage = totalChapters > 0 ? (completedChapters / totalChapters) * 100 : 0;

    const progressData: any = {
      progressPercentage,
    };

    if (completedChapters === totalChapters) {
      progressData.completedAt = new Date();
    }

    await this.storiesService.updateUserProgress(storyId, userId, progressData);
  }

  async getChapterProgress(chapterId: string, userId: string): Promise<UserChapterProgress | null> {
    return this.userChapterProgressRepository.findOne({
      where: { chapterId, userId },
    });
  }
}