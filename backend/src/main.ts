import { NestFactory } from '@nestjs/core';
import { NestExpressApplication } from '@nestjs/platform-express';
import { ValidationPipe } from '@nestjs/common';
import { join } from 'path';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create<NestExpressApplication>(AppModule);
  app.enableCors({
    origin: true, // allow all origins in dev; lock down in prod
    credentials: true,
  });
  app.useGlobalPipes(new ValidationPipe({ transform: true, whitelist: true }));
  // Serve uploaded avatar images at /uploads/avatars/<filename>
  app.useStaticAssets(join(process.cwd(), 'uploads'), { prefix: '/uploads' });
  // Serve Flutter web build
  app.useStaticAssets(join(process.cwd(), 'public'));
  await app.listen(3000);
}
bootstrap();
