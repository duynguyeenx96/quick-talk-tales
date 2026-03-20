import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  Query,
  UseGuards,
  ParseUUIDPipe,
} from '@nestjs/common';
import { StoriesService } from './stories.service';
import { CreateStoryDto } from './dto/create-story.dto';
import { UpdateStoryDto } from './dto/update-story.dto';
import { RateStoryDto } from './dto/rate-story.dto';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { User, UserRole, StoryStatus, DifficultyLevel } from '../database/entities';
import { PaginationDto } from '../common/dto/pagination.dto';

@Controller('stories')
export class StoriesController {
  constructor(private readonly storiesService: StoriesService) {}

  @Post()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.AUTHOR, UserRole.ADMIN)
  create(@Body() createStoryDto: CreateStoryDto, @CurrentUser() user: User) {
    return this.storiesService.create(createStoryDto, user.id);
  }

  @Get()
  findAll(
    @Query() pagination: PaginationDto,
    @Query('status') status?: StoryStatus,
    @Query('categoryId') categoryId?: string,
    @Query('difficulty') difficulty?: DifficultyLevel,
    @Query('isFeatured') isFeatured?: boolean,
    @Query('isInteractive') isInteractive?: boolean,
    @Query('authorId') authorId?: string,
  ) {
    const filters = {
      status: status || StoryStatus.PUBLISHED,
      categoryId,
      difficulty,
      isFeatured,
      isInteractive,
      authorId,
    };

    return this.storiesService.findAll(pagination, filters);
  }

  @Get('featured')
  getFeaturedStories() {
    return this.storiesService.getFeaturedStories();
  }

  @Get('popular')
  getPopularStories() {
    return this.storiesService.getPopularStories();
  }

  @Get('recent')
  getRecentStories() {
    return this.storiesService.getRecentStories();
  }

  @Get('my-stories')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.AUTHOR, UserRole.ADMIN)
  getMyStories(@CurrentUser() user: User, @Query() pagination: PaginationDto) {
    return this.storiesService.findAll(pagination, { authorId: user.id });
  }

  @Get(':id')
  findOne(@Param('id', ParseUUIDPipe) id: string) {
    return this.storiesService.findOne(id);
  }

  @Get('slug/:slug')
  findBySlug(@Param('slug') slug: string) {
    this.storiesService.incrementViewCount; // Note: This should be properly implemented with the story ID
    return this.storiesService.findBySlug(slug);
  }

  @Patch(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.AUTHOR, UserRole.ADMIN)
  update(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() updateStoryDto: UpdateStoryDto,
    @CurrentUser() user: User,
  ) {
    return this.storiesService.update(id, updateStoryDto, user.id, user.role);
  }

  @Delete(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.AUTHOR, UserRole.ADMIN)
  remove(@Param('id', ParseUUIDPipe) id: string, @CurrentUser() user: User) {
    return this.storiesService.remove(id, user.id, user.role);
  }

  @Post(':id/rate')
  @UseGuards(JwtAuthGuard)
  rateStory(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() rateStoryDto: RateStoryDto,
    @CurrentUser() user: User,
  ) {
    return this.storiesService.rateStory(id, user.id, rateStoryDto);
  }

  @Get(':id/ratings')
  getStoryRatings(
    @Param('id', ParseUUIDPipe) id: string,
    @Query() pagination: PaginationDto,
  ) {
    return this.storiesService.getStoryRatings(id, pagination);
  }

  @Get(':id/progress')
  @UseGuards(JwtAuthGuard)
  getUserProgress(@Param('id', ParseUUIDPipe) id: string, @CurrentUser() user: User) {
    return this.storiesService.getUserProgress(id, user.id);
  }

  @Post(':id/progress')
  @UseGuards(JwtAuthGuard)
  updateUserProgress(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() progressData: any,
    @CurrentUser() user: User,
  ) {
    return this.storiesService.updateUserProgress(id, user.id, progressData);
  }
}