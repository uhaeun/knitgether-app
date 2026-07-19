import { INestApplication, ValidationPipe } from '@nestjs/common';
import type { NextFunction, Request, Response } from 'express';

export function setupApp(app: INestApplication): void {
  if (process.env.NODE_ENV === 'development') {
    app.use((request: Request, response: Response, next: NextFunction) => {
      const startedAt = Date.now();

      response.on('finish', () => {
        const durationMs = Date.now() - startedAt;
        console.log(
          `[KnitGether API] ${request.method} ${request.originalUrl} ${response.statusCode} ${durationMs}ms`,
        );
      });

      next();
    });
  }

  app.setGlobalPrefix('api/v1');
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
      forbidNonWhitelisted: true,
    }),
  );
}
