import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ScheduleModule } from '@nestjs/schedule';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { databaseConfig } from './config/database.config';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { StoriesModule } from './stories/stories.module';
import { ChaptersModule } from './chapters/chapters.module';
import { SpeechModule } from './speech/speech.module';
import { WordsModule } from './words/words.module';
import { EvaluationModule } from './evaluation/evaluation.module';
import { PaymentsModule } from './payments/payments.module';
import { AdminModule } from './admin/admin.module';
import { ChallengesModule } from './challenges/challenges.module';
import { FriendsModule } from './friends/friends.module';
import { GroupChallengesModule } from './group-challenges/group-challenges.module';
import { NotificationsModule } from './notifications/notifications.module';
import { ClassroomModule } from './classroom/classroom.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: '.env',
    }),
    TypeOrmModule.forRootAsync({
      inject: [ConfigService],
      useFactory: databaseConfig,
    }),
    ScheduleModule.forRoot(),
    AuthModule,
    UsersModule,
    StoriesModule,
    ChaptersModule,
    SpeechModule,
    WordsModule,
    EvaluationModule,
    PaymentsModule,
    AdminModule,
    ChallengesModule,
    FriendsModule,
    GroupChallengesModule,
    NotificationsModule,
    ClassroomModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
