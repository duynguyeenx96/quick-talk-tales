import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  UseGuards,
  ParseUUIDPipe,
  Query,
} from '@nestjs/common';
import { ChaptersService } from './chapters.service';
import { CreateChapterDto } from './dto/create-chapter.dto';
import { UpdateChapterDto } from './dto/update-chapter.dto';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { User, UserRole } from '../database/entities';

@Controller('stories/:storyId/chapters')
export class ChaptersController {
  constructor(private readonly chaptersService: ChaptersService) {}

  @Post()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.AUTHOR, UserRole.ADMIN)
  create(
    @Param('storyId', ParseUUIDPipe) storyId: string,
    @Body() createChapterDto: CreateChapterDto,
    @CurrentUser() user: User,
  ) {
    return this.chaptersService.create(storyId, createChapterDto, user.id, user.role);
  }

  @Get()
  findAll(
    @Param('storyId', ParseUUIDPipe) storyId: string,
    @Query('includeUnpublished') includeUnpublished?: boolean,
  ) {
    return this.chaptersService.findAllByStory(storyId, includeUnpublished);
  }

  @Get(':id')
  findOne(@Param('id', ParseUUIDPipe) id: string) {
    return this.chaptersService.findOne(id);
  }

  @Get('slug/:slug')
  findBySlug(
    @Param('storyId', ParseUUIDPipe) storyId: string,
    @Param('slug') slug: string,
  ) {
    return this.chaptersService.findBySlug(storyId, slug);
  }

  @Patch(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.AUTHOR, UserRole.ADMIN)
  update(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() updateChapterDto: UpdateChapterDto,
    @CurrentUser() user: User,
  ) {
    return this.chaptersService.update(id, updateChapterDto, user.id, user.role);
  }

  @Delete(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.AUTHOR, UserRole.ADMIN)
  remove(@Param('id', ParseUUIDPipe) id: string, @CurrentUser() user: User) {
    return this.chaptersService.remove(id, user.id, user.role);
  }

  @Post('reorder')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.AUTHOR, UserRole.ADMIN)
  reorderChapters(
    @Param('storyId', ParseUUIDPipe) storyId: string,
    @Body('chapterIds') chapterIds: string[],
    @CurrentUser() user: User,
  ) {
    return this.chaptersService.reorderChapters(storyId, chapterIds, user.id, user.role);
  }

  @Get(':id/next')
  getNextChapter(
    @Param('storyId', ParseUUIDPipe) storyId: string,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    // This would require getting the current chapter's order index first
    // Implementation simplified for demo purposes
    return { message: 'Next chapter endpoint - implementation needed' };
  }

  @Get(':id/previous')
  getPreviousChapter(
    @Param('storyId', ParseUUIDPipe) storyId: string,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    // This would require getting the current chapter's order index first
    // Implementation simplified for demo purposes
    return { message: 'Previous chapter endpoint - implementation needed' };
  }

  @Post(':id/mark-read')
  @UseGuards(JwtAuthGuard)
  markAsRead(
    @Param('id', ParseUUIDPipe) id: string,
    @Body('choicesMade') choicesMade: any[],
    @CurrentUser() user: User,
  ) {
    return this.chaptersService.markChapterAsRead(id, user.id, choicesMade);
  }

  @Get(':id/progress')
  @UseGuards(JwtAuthGuard)
  getProgress(@Param('id', ParseUUIDPipe) id: string, @CurrentUser() user: User) {
    return this.chaptersService.getChapterProgress(id, user.id);
  }
}