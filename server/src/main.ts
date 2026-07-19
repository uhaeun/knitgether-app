import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { setupApp } from './app.setup';
import { resolveListenHost } from './listen-options';

async function bootstrap(): Promise<void> {
  const app = await NestFactory.create(AppModule);
  setupApp(app);

  const port = Number(process.env.PORT ?? 3000);
  await app.listen(port, resolveListenHost(process.env));
}

void bootstrap();
