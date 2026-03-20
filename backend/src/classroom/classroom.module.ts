import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { HttpModule } from '@nestjs/axios';
import { ClassroomSession, ClassroomParticipant, User, Word, Notification } from '../database/entities';
import { ClassroomService } from './classroom.service';
import { ClassroomController } from './classroom.controller';

@Module({
  imports: [
    TypeOrmModule.forFeature([ClassroomSession, ClassroomParticipant, User, Word, Notification]),
    HttpModule.register({ timeout: 60000 }),
  ],
  controllers: [ClassroomController],
  providers: [ClassroomService],
})
export class ClassroomModule {}
