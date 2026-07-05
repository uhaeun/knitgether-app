# iOS Sync API Project List Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the first server-backed vertical slice: the iOS app can fetch authenticated project data from a NestJS API while the existing local app behavior remains the default.

**Architecture:** Add a NestJS server under `server/` with PostgreSQL/Prisma, a development auth guard, and `GET /api/v1/projects`. Add a Swift `APIClient` and `RemoteProjectRepository` that conform to the existing repository boundary. Keep `LocalProjectRepository` as the default unless a server base URL is explicitly configured.

**Tech Stack:** NestJS, TypeScript, Prisma, PostgreSQL, Jest, Supertest, Swift, Swift Testing, URLSession.

---

## Scope

This plan implements one complete vertical slice:

```text
SwiftUI ViewModel
  -> ProjectRepository protocol
  -> RemoteProjectRepository
  -> APIClient
  -> NestJS GET /api/v1/projects
  -> Prisma
  -> PostgreSQL
```

This plan does not implement pattern document APIs, file upload URLs, full sync push/pull, profile APIs, Apple sign-in, or gauge APIs. Those are separate follow-up plans after this slice proves the server-client boundary.

## File Structure

Create server files:

- `server/package.json`: scripts and dependencies for the NestJS API.
- `server/tsconfig.json`: TypeScript compiler settings.
- `server/tsconfig.build.json`: production build settings.
- `server/nest-cli.json`: Nest CLI source root.
- `server/.env.example`: development database and auth environment.
- `server/docker-compose.yml`: local PostgreSQL service.
- `server/prisma/schema.prisma`: database schema for users, projects, row counters, and work sessions.
- `server/src/main.ts`: HTTP server entrypoint.
- `server/src/app.setup.ts`: shared global prefix and validation setup.
- `server/src/app.module.ts`: root Nest module.
- `server/src/health/health.controller.ts`: health check endpoint.
- `server/src/health/health.module.ts`: health module.
- `server/src/database/prisma.service.ts`: Prisma client lifecycle wrapper.
- `server/src/database/database.module.ts`: Prisma provider module.
- `server/src/auth/current-user.decorator.ts`: extracts authenticated user from request.
- `server/src/auth/dev-auth.guard.ts`: development Bearer token auth guard.
- `server/src/auth/auth.module.ts`: auth module.
- `server/src/projects/project-response.dto.ts`: response DTO matching Swift `KnittingProject`.
- `server/src/projects/projects.service.ts`: project query and DTO mapping.
- `server/src/projects/projects.controller.ts`: project routes.
- `server/src/projects/projects.module.ts`: project module.
- `server/test/jest-e2e.json`: e2e test config.
- `server/test/health.e2e-spec.ts`: health route e2e test.
- `server/test/projects.e2e-spec.ts`: authenticated project list e2e test.

Create iOS files:

- `KnitGether/Networking/APIConfiguration.swift`: API base URL and auth token provider.
- `KnitGether/Networking/APIError.swift`: HTTP and decoding error type.
- `KnitGether/Networking/APIClient.swift`: typed URLSession wrapper.
- `KnitGether/Repositories/Remote/RemoteProjectRepository.swift`: remote implementation of `ProjectRepository`.
- `KnitGetherTests/MockURLProtocol.swift`: URLProtocol test helper.
- `KnitGetherTests/APIClientTests.swift`: request, auth, and decoding tests.
- `KnitGetherTests/RemoteProjectRepositoryTests.swift`: project repository mapping tests.
- `KnitGetherTests/AppRepositoryContainerTests.swift`: local default and remote opt-in tests.

Modify iOS files:

- `KnitGether/Repositories/AppRepositoryContainer.swift`: add a factory that selects local or remote repositories based on environment.

The Xcode project uses file system synchronized groups, so new Swift files under `KnitGether/` and `KnitGetherTests/` should be included without manual `.pbxproj` source phase edits.

---

### Task 1: Add NestJS Server Skeleton and Health Route

**Files:**

- Create: `server/package.json`
- Create: `server/tsconfig.json`
- Create: `server/tsconfig.build.json`
- Create: `server/nest-cli.json`
- Create: `server/.env.example`
- Create: `server/src/main.ts`
- Create: `server/src/app.setup.ts`
- Create: `server/src/app.module.ts`
- Create: `server/src/health/health.controller.ts`
- Create: `server/src/health/health.module.ts`
- Create: `server/test/jest-e2e.json`
- Create: `server/test/health.e2e-spec.ts`

- [ ] **Step 1: Write the failing health e2e test**

Create `server/test/health.e2e-spec.ts`:

```ts
import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { setupApp } from '../src/app.setup';

describe('Health route', () => {
  let app: INestApplication;

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleRef.createNestApplication();
    setupApp(app);
    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  it('returns API health status', async () => {
    await request(app.getHttpServer())
      .get('/api/v1/health')
      .expect(200)
      .expect({
        status: 'ok',
        service: 'knitgether-api',
      });
  });
});
```

- [ ] **Step 2: Create server package and TypeScript config**

Create `server/package.json`:

```json
{
  "name": "knitgether-api",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "build": "nest build",
    "start": "node dist/main.js",
    "start:dev": "nest start --watch",
    "test": "jest --runInBand",
    "test:e2e": "jest --config ./test/jest-e2e.json --runInBand"
  },
  "dependencies": {
    "@nestjs/common": "^11.0.0",
    "@nestjs/config": "^4.0.0",
    "@nestjs/core": "^11.0.0",
    "@nestjs/platform-express": "^11.0.0",
    "class-transformer": "^0.5.1",
    "class-validator": "^0.14.1",
    "reflect-metadata": "^0.2.2",
    "rxjs": "^7.8.1"
  },
  "devDependencies": {
    "@nestjs/cli": "^11.0.0",
    "@nestjs/testing": "^11.0.0",
    "@types/jest": "^29.5.14",
    "@types/node": "^22.0.0",
    "@types/supertest": "^6.0.2",
    "jest": "^29.7.0",
    "source-map-support": "^0.5.21",
    "supertest": "^7.0.0",
    "ts-jest": "^29.2.5",
    "ts-loader": "^9.5.1",
    "ts-node": "^10.9.2",
    "typescript": "^5.7.0"
  }
}
```

Create `server/tsconfig.json`:

```json
{
  "compilerOptions": {
    "module": "commonjs",
    "declaration": true,
    "removeComments": true,
    "emitDecoratorMetadata": true,
    "experimentalDecorators": true,
    "allowSyntheticDefaultImports": true,
    "target": "ES2022",
    "sourceMap": true,
    "outDir": "./dist",
    "baseUrl": "./",
    "incremental": true,
    "strict": true,
    "skipLibCheck": true
  }
}
```

Create `server/tsconfig.build.json`:

```json
{
  "extends": "./tsconfig.json",
  "exclude": ["node_modules", "test", "dist", "**/*spec.ts"]
}
```

Create `server/nest-cli.json`:

```json
{
  "$schema": "https://json.schemastore.org/nest-cli",
  "collection": "@nestjs/schematics",
  "sourceRoot": "src"
}
```

Create `server/.env.example`:

```dotenv
PORT=3000
DEV_AUTH_TOKEN=dev-token
DEV_AUTH_USER_ID=dev-user
DATABASE_URL=postgresql://knitgether:knitgether@localhost:5432/knitgether_dev?schema=public
```

- [ ] **Step 3: Create app setup and health implementation**

Create `server/src/app.setup.ts`:

```ts
import { INestApplication, ValidationPipe } from '@nestjs/common';

export function setupApp(app: INestApplication): void {
  app.setGlobalPrefix('api/v1');
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
      forbidNonWhitelisted: true,
    }),
  );
}
```

Create `server/src/main.ts`:

```ts
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { setupApp } from './app.setup';

async function bootstrap(): Promise<void> {
  const app = await NestFactory.create(AppModule);
  setupApp(app);

  const port = Number(process.env.PORT ?? 3000);
  await app.listen(port);
}

void bootstrap();
```

Create `server/src/app.module.ts`:

```ts
import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { HealthModule } from './health/health.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
    }),
    HealthModule,
  ],
})
export class AppModule {}
```

Create `server/src/health/health.controller.ts`:

```ts
import { Controller, Get } from '@nestjs/common';

type HealthResponse = {
  status: 'ok';
  service: 'knitgether-api';
};

@Controller('health')
export class HealthController {
  @Get()
  getHealth(): HealthResponse {
    return {
      status: 'ok',
      service: 'knitgether-api',
    };
  }
}
```

Create `server/src/health/health.module.ts`:

```ts
import { Module } from '@nestjs/common';
import { HealthController } from './health.controller';

@Module({
  controllers: [HealthController],
})
export class HealthModule {}
```

Create `server/test/jest-e2e.json`:

```json
{
  "moduleFileExtensions": ["js", "json", "ts"],
  "rootDir": "..",
  "testEnvironment": "node",
  "testRegex": ".e2e-spec.ts$",
  "transform": {
    "^.+\\.(t|j)s$": "ts-jest"
  }
}
```

- [ ] **Step 4: Install dependencies and verify the health test passes**

Run:

```bash
cd server
npm install
npm run test:e2e -- health.e2e-spec.ts
```

Expected: `PASS test/health.e2e-spec.ts`.

- [ ] **Step 5: Commit the server skeleton**

Run:

```bash
git add server/package.json server/package-lock.json server/tsconfig.json server/tsconfig.build.json server/nest-cli.json server/.env.example server/src server/test
git commit -m "feat: add NestJS API health check"
```

---

### Task 2: Add Prisma and PostgreSQL Project Schema

**Files:**

- Modify: `server/package.json`
- Create: `server/docker-compose.yml`
- Create: `server/prisma/schema.prisma`
- Create: `server/src/database/prisma.service.ts`
- Create: `server/src/database/database.module.ts`
- Modify: `server/src/app.module.ts`

- [ ] **Step 1: Add Prisma dependencies and scripts**

Modify the relevant sections in `server/package.json`:

```json
{
  "scripts": {
    "build": "nest build",
    "start": "node dist/main.js",
    "start:dev": "nest start --watch",
    "test": "jest --runInBand",
    "test:e2e": "jest --config ./test/jest-e2e.json --runInBand",
    "prisma:generate": "prisma generate",
    "prisma:migrate": "prisma migrate dev",
    "prisma:studio": "prisma studio"
  },
  "dependencies": {
    "@nestjs/common": "^11.0.0",
    "@nestjs/config": "^4.0.0",
    "@nestjs/core": "^11.0.0",
    "@nestjs/platform-express": "^11.0.0",
    "@prisma/client": "^6.0.0",
    "class-transformer": "^0.5.1",
    "class-validator": "^0.14.1",
    "reflect-metadata": "^0.2.2",
    "rxjs": "^7.8.1"
  },
  "devDependencies": {
    "@nestjs/cli": "^11.0.0",
    "@nestjs/testing": "^11.0.0",
    "@types/jest": "^29.5.14",
    "@types/node": "^22.0.0",
    "@types/supertest": "^6.0.2",
    "jest": "^29.7.0",
    "prisma": "^6.0.0",
    "source-map-support": "^0.5.21",
    "supertest": "^7.0.0",
    "ts-jest": "^29.2.5",
    "ts-loader": "^9.5.1",
    "ts-node": "^10.9.2",
    "typescript": "^5.7.0"
  }
}
```

- [ ] **Step 2: Add local PostgreSQL service**

Create `server/docker-compose.yml`:

```yaml
services:
  postgres:
    image: postgres:16
    container_name: knitgether-postgres
    restart: unless-stopped
    environment:
      POSTGRES_USER: knitgether
      POSTGRES_PASSWORD: knitgether
      POSTGRES_DB: knitgether_dev
    ports:
      - "5432:5432"
    volumes:
      - knitgether-postgres-data:/var/lib/postgresql/data

volumes:
  knitgether-postgres-data:
```

- [ ] **Step 3: Add Prisma schema**

Create `server/prisma/schema.prisma`:

```prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model UserProfile {
  id             String    @id
  displayName    String
  preferredUnits String    @default("metric")
  createdAt      DateTime  @default(now())
  updatedAt      DateTime  @updatedAt
  deletedAt      DateTime?

  projects      Project[]
  rowCounters   RowCounter[]
  workSessions  WorkSession[]
}

model Project {
  id                     String        @id @db.Uuid
  ownerId                String
  name                   String
  status                 String
  isFavorite             Boolean       @default(false)
  memo                   String        @default("")
  startDate              DateTime
  lastWorkedAt           DateTime?
  workspaceDisplayMode   String?
  workspaceSheetPosition String?
  relatedSkillIds        String[]      @default([])
  createdAt              DateTime      @default(now())
  updatedAt              DateTime      @updatedAt
  deletedAt              DateTime?

  owner        UserProfile  @relation(fields: [ownerId], references: [id], onDelete: Cascade)
  rowCounter   RowCounter?
  workSessions WorkSession[]

  @@index([ownerId, deletedAt])
}

model RowCounter {
  id         String    @id @db.Uuid
  ownerId    String
  projectId  String    @unique @db.Uuid
  name       String    @default("Main Counter")
  currentRow Int
  targetRow  Int?
  createdAt  DateTime  @default(now())
  updatedAt  DateTime  @updatedAt
  deletedAt  DateTime?

  owner   UserProfile @relation(fields: [ownerId], references: [id], onDelete: Cascade)
  project Project     @relation(fields: [projectId], references: [id], onDelete: Cascade)

  @@index([ownerId, deletedAt])
}

model WorkSession {
  id        String    @id @db.Uuid
  ownerId   String
  projectId String    @db.Uuid
  startedAt DateTime
  endedAt   DateTime?
  memo      String?
  createdAt DateTime  @default(now())
  updatedAt DateTime  @updatedAt
  deletedAt DateTime?

  owner   UserProfile @relation(fields: [ownerId], references: [id], onDelete: Cascade)
  project Project     @relation(fields: [projectId], references: [id], onDelete: Cascade)

  @@index([ownerId, projectId, deletedAt])
}
```

- [ ] **Step 4: Add Prisma service**

Create `server/src/database/prisma.service.ts`:

```ts
import { Injectable, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';

@Injectable()
export class PrismaService
  extends PrismaClient
  implements OnModuleInit, OnModuleDestroy
{
  async onModuleInit(): Promise<void> {
    await this.$connect();
  }

  async onModuleDestroy(): Promise<void> {
    await this.$disconnect();
  }
}
```

Create `server/src/database/database.module.ts`:

```ts
import { Global, Module } from '@nestjs/common';
import { PrismaService } from './prisma.service';

@Global()
@Module({
  providers: [PrismaService],
  exports: [PrismaService],
})
export class DatabaseModule {}
```

Modify `server/src/app.module.ts`:

```ts
import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { DatabaseModule } from './database/database.module';
import { HealthModule } from './health/health.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
    }),
    DatabaseModule,
    HealthModule,
  ],
})
export class AppModule {}
```

- [ ] **Step 5: Generate Prisma client and migration**

Run:

```bash
cd server
npm install
cp .env.example .env
docker compose up -d postgres
npx prisma generate
npx prisma migrate dev --name init_project_list
```

Expected:

- Prisma Client generated successfully.
- A migration directory is created under `server/prisma/migrations/`.
- PostgreSQL has `UserProfile`, `Project`, `RowCounter`, and `WorkSession` tables.

- [ ] **Step 6: Verify health test still passes**

Run:

```bash
cd server
npm run test:e2e -- health.e2e-spec.ts
```

Expected: `PASS test/health.e2e-spec.ts`.

- [ ] **Step 7: Commit the database foundation**

Run:

```bash
git add server/package.json server/package-lock.json server/docker-compose.yml server/prisma server/src/database server/src/app.module.ts
git commit -m "feat: add project database schema"
```

---

### Task 3: Add Development Auth Guard

**Files:**

- Create: `server/src/auth/current-user.decorator.ts`
- Create: `server/src/auth/dev-auth.guard.ts`
- Create: `server/src/auth/auth.module.ts`
- Modify: `server/src/app.module.ts`

- [ ] **Step 1: Create current user decorator**

Create `server/src/auth/current-user.decorator.ts`:

```ts
import { createParamDecorator, ExecutionContext } from '@nestjs/common';
import { Request } from 'express';

export type CurrentUserPayload = {
  id: string;
};

export type AuthenticatedRequest = Request & {
  user: CurrentUserPayload;
};

export const CurrentUser = createParamDecorator(
  (_data: unknown, context: ExecutionContext): CurrentUserPayload => {
    const request = context.switchToHttp().getRequest<AuthenticatedRequest>();
    return request.user;
  },
);
```

- [ ] **Step 2: Create development auth guard**

Create `server/src/auth/dev-auth.guard.ts`:

```ts
import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AuthenticatedRequest } from './current-user.decorator';

@Injectable()
export class DevAuthGuard implements CanActivate {
  constructor(private readonly configService: ConfigService) {}

  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest<AuthenticatedRequest>();
    const authorization = request.header('authorization');
    const token = this.extractBearerToken(authorization);
    const expectedToken = this.configService.get<string>('DEV_AUTH_TOKEN') ?? 'dev-token';

    if (token !== expectedToken) {
      throw new UnauthorizedException({
        code: 'UNAUTHENTICATED',
        message: 'Missing or invalid bearer token.',
        details: {},
      });
    }

    request.user = {
      id: this.configService.get<string>('DEV_AUTH_USER_ID') ?? 'dev-user',
    };

    return true;
  }

  private extractBearerToken(authorization: string | undefined): string | null {
    if (!authorization) {
      return null;
    }

    const match = authorization.match(/^Bearer (.+)$/);
    return match?.[1] ?? null;
  }
}
```

- [ ] **Step 3: Create auth module and register it**

Create `server/src/auth/auth.module.ts`:

```ts
import { Module } from '@nestjs/common';
import { DevAuthGuard } from './dev-auth.guard';

@Module({
  providers: [DevAuthGuard],
  exports: [DevAuthGuard],
})
export class AuthModule {}
```

Modify `server/src/app.module.ts`:

```ts
import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AuthModule } from './auth/auth.module';
import { DatabaseModule } from './database/database.module';
import { HealthModule } from './health/health.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
    }),
    AuthModule,
    DatabaseModule,
    HealthModule,
  ],
})
export class AppModule {}
```

- [ ] **Step 4: Verify TypeScript build**

Run:

```bash
cd server
npm run build
```

Expected: build completes with no TypeScript errors.

- [ ] **Step 5: Commit the auth boundary**

Run:

```bash
git add server/src/auth server/src/app.module.ts
git commit -m "feat: add development auth guard"
```

---

### Task 4: Add Authenticated Projects List Endpoint

**Files:**

- Create: `server/src/projects/project-response.dto.ts`
- Create: `server/src/projects/projects.service.ts`
- Create: `server/src/projects/projects.controller.ts`
- Create: `server/src/projects/projects.module.ts`
- Modify: `server/src/app.module.ts`
- Create: `server/test/projects.e2e-spec.ts`

- [ ] **Step 1: Write failing e2e tests for authenticated project list**

Create `server/test/projects.e2e-spec.ts`:

```ts
import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { setupApp } from '../src/app.setup';
import { PrismaService } from '../src/database/prisma.service';

describe('Projects route', () => {
  let app: INestApplication;
  let prisma: PrismaService;

  beforeAll(async () => {
    process.env.DEV_AUTH_TOKEN = 'dev-token';
    process.env.DEV_AUTH_USER_ID = 'user-a';

    const moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleRef.createNestApplication();
    setupApp(app);
    await app.init();

    prisma = app.get(PrismaService);
  });

  beforeEach(async () => {
    await prisma.workSession.deleteMany();
    await prisma.rowCounter.deleteMany();
    await prisma.project.deleteMany();
    await prisma.userProfile.deleteMany();

    await prisma.userProfile.createMany({
      data: [
        {
          id: 'user-a',
          displayName: 'User A',
          preferredUnits: 'metric',
        },
        {
          id: 'user-b',
          displayName: 'User B',
          preferredUnits: 'metric',
        },
      ],
    });

    await prisma.project.create({
      data: {
        id: '11111111-1111-1111-1111-111111111111',
        ownerId: 'user-a',
        name: 'Favorite Cardigan',
        status: 'WIP',
        isFavorite: true,
        memo: 'Use smaller needles for ribbing.',
        startDate: new Date('2026-07-01T00:00:00.000Z'),
        lastWorkedAt: new Date('2026-07-03T09:00:00.000Z'),
        workspaceDisplayMode: 'patternAndCounter',
        workspaceSheetPosition: 'medium',
        relatedSkillIds: ['aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'],
        createdAt: new Date('2026-07-01T00:00:00.000Z'),
        updatedAt: new Date('2026-07-03T09:00:00.000Z'),
        rowCounter: {
          create: {
            id: '22222222-2222-2222-2222-222222222222',
            ownerId: 'user-a',
            name: 'Main Counter',
            currentRow: 42,
            targetRow: 120,
            createdAt: new Date('2026-07-01T00:00:00.000Z'),
            updatedAt: new Date('2026-07-03T09:00:00.000Z'),
          },
        },
        workSessions: {
          create: [
            {
              id: '33333333-3333-3333-3333-333333333333',
              ownerId: 'user-a',
              startedAt: new Date('2026-07-03T08:00:00.000Z'),
              endedAt: new Date('2026-07-03T09:00:00.000Z'),
              memo: 'Sleeve increases.',
              createdAt: new Date('2026-07-03T09:00:00.000Z'),
              updatedAt: new Date('2026-07-03T09:00:00.000Z'),
            },
          ],
        },
      },
    });

    await prisma.project.create({
      data: {
        id: '44444444-4444-4444-4444-444444444444',
        ownerId: 'user-b',
        name: 'Other User Project',
        status: 'WIP',
        isFavorite: true,
        memo: '',
        startDate: new Date('2026-07-02T00:00:00.000Z'),
        createdAt: new Date('2026-07-02T00:00:00.000Z'),
        updatedAt: new Date('2026-07-02T00:00:00.000Z'),
        rowCounter: {
          create: {
            id: '55555555-5555-5555-5555-555555555555',
            ownerId: 'user-b',
            name: 'Main Counter',
            currentRow: 5,
            targetRow: null,
            createdAt: new Date('2026-07-02T00:00:00.000Z'),
            updatedAt: new Date('2026-07-02T00:00:00.000Z'),
          },
        },
      },
    });
  });

  afterAll(async () => {
    await app.close();
  });

  it('rejects unauthenticated requests', async () => {
    await request(app.getHttpServer()).get('/api/v1/projects').expect(401);
  });

  it('returns only active projects owned by the current user', async () => {
    const response = await request(app.getHttpServer())
      .get('/api/v1/projects')
      .set('Authorization', 'Bearer dev-token')
      .expect(200);

    expect(response.body).toEqual([
      {
        id: '11111111-1111-1111-1111-111111111111',
        ownerId: 'user-a',
        name: 'Favorite Cardigan',
        status: 'WIP',
        isFavorite: true,
        memo: 'Use smaller needles for ribbing.',
        startDate: '2026-07-01T00:00:00.000Z',
        lastWorkedAt: '2026-07-03T09:00:00.000Z',
        patternCopy: null,
        workspaceDisplayMode: 'patternAndCounter',
        workspaceSheetPosition: 'medium',
        rowCounter: {
          id: '22222222-2222-2222-2222-222222222222',
          ownerId: 'user-a',
          projectId: '11111111-1111-1111-1111-111111111111',
          name: 'Main Counter',
          currentRow: 42,
          targetRow: 120,
          createdAt: '2026-07-01T00:00:00.000Z',
          updatedAt: '2026-07-03T09:00:00.000Z',
          deletedAt: null,
          syncStatus: 'Synced',
        },
        workSessions: [
          {
            id: '33333333-3333-3333-3333-333333333333',
            ownerId: 'user-a',
            projectId: '11111111-1111-1111-1111-111111111111',
            startedAt: '2026-07-03T08:00:00.000Z',
            endedAt: '2026-07-03T09:00:00.000Z',
            memo: 'Sleeve increases.',
            createdAt: '2026-07-03T09:00:00.000Z',
            updatedAt: '2026-07-03T09:00:00.000Z',
            deletedAt: null,
            syncStatus: 'Synced',
          },
        ],
        relatedSkillIds: ['aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'],
        createdAt: '2026-07-01T00:00:00.000Z',
        updatedAt: '2026-07-03T09:00:00.000Z',
        deletedAt: null,
        syncStatus: 'Synced',
      },
    ]);
  });
});
```

Run:

```bash
cd server
npm run test:e2e -- projects.e2e-spec.ts
```

Expected: fail because `ProjectsModule` and `/api/v1/projects` do not exist.

- [ ] **Step 2: Add project response DTO**

Create `server/src/projects/project-response.dto.ts`:

```ts
export type SyncStatusDto = 'Synced';

export type RowCounterResponseDto = {
  id: string;
  ownerId: string;
  projectId: string;
  name: string;
  currentRow: number;
  targetRow: number | null;
  createdAt: string;
  updatedAt: string;
  deletedAt: string | null;
  syncStatus: SyncStatusDto;
};

export type WorkSessionResponseDto = {
  id: string;
  ownerId: string;
  projectId: string;
  startedAt: string;
  endedAt: string | null;
  memo: string | null;
  createdAt: string;
  updatedAt: string;
  deletedAt: string | null;
  syncStatus: SyncStatusDto;
};

export type ProjectResponseDto = {
  id: string;
  ownerId: string;
  name: string;
  status: string;
  isFavorite: boolean;
  memo: string;
  startDate: string;
  lastWorkedAt: string | null;
  patternCopy: null;
  workspaceDisplayMode: string | null;
  workspaceSheetPosition: string | null;
  rowCounter: RowCounterResponseDto;
  workSessions: WorkSessionResponseDto[];
  relatedSkillIds: string[];
  createdAt: string;
  updatedAt: string;
  deletedAt: string | null;
  syncStatus: SyncStatusDto;
};
```

- [ ] **Step 3: Add project service**

Create `server/src/projects/projects.service.ts`:

```ts
import { Injectable, InternalServerErrorException } from '@nestjs/common';
import { Prisma, RowCounter, WorkSession } from '@prisma/client';
import { PrismaService } from '../database/prisma.service';
import {
  ProjectResponseDto,
  RowCounterResponseDto,
  WorkSessionResponseDto,
} from './project-response.dto';

type ProjectWithChildren = Prisma.ProjectGetPayload<{
  include: {
    rowCounter: true;
    workSessions: true;
  };
}>;

@Injectable()
export class ProjectsService {
  constructor(private readonly prisma: PrismaService) {}

  async listProjects(ownerId: string): Promise<ProjectResponseDto[]> {
    const projects = await this.prisma.project.findMany({
      where: {
        ownerId,
        deletedAt: null,
      },
      include: {
        rowCounter: true,
        workSessions: {
          where: {
            deletedAt: null,
          },
          orderBy: {
            startedAt: 'asc',
          },
        },
      },
    });

    return projects
      .sort((first, second) => this.compareProjects(first, second))
      .map((project) => this.toResponse(project));
  }

  private compareProjects(first: ProjectWithChildren, second: ProjectWithChildren): number {
    if (first.isFavorite !== second.isFavorite) {
      return first.isFavorite ? -1 : 1;
    }

    const firstActivity = first.lastWorkedAt ?? first.startDate;
    const secondActivity = second.lastWorkedAt ?? second.startDate;
    return secondActivity.getTime() - firstActivity.getTime();
  }

  private toResponse(project: ProjectWithChildren): ProjectResponseDto {
    if (!project.rowCounter) {
      throw new InternalServerErrorException({
        code: 'PROJECT_ROW_COUNTER_MISSING',
        message: 'Project is missing its row counter.',
        details: {
          projectId: project.id,
        },
      });
    }

    return {
      id: project.id,
      ownerId: project.ownerId,
      name: project.name,
      status: project.status,
      isFavorite: project.isFavorite,
      memo: project.memo,
      startDate: project.startDate.toISOString(),
      lastWorkedAt: project.lastWorkedAt?.toISOString() ?? null,
      patternCopy: null,
      workspaceDisplayMode: project.workspaceDisplayMode,
      workspaceSheetPosition: project.workspaceSheetPosition,
      rowCounter: this.toRowCounterResponse(project.rowCounter),
      workSessions: project.workSessions.map((session) =>
        this.toWorkSessionResponse(session),
      ),
      relatedSkillIds: project.relatedSkillIds,
      createdAt: project.createdAt.toISOString(),
      updatedAt: project.updatedAt.toISOString(),
      deletedAt: project.deletedAt?.toISOString() ?? null,
      syncStatus: 'Synced',
    };
  }

  private toRowCounterResponse(rowCounter: RowCounter): RowCounterResponseDto {
    return {
      id: rowCounter.id,
      ownerId: rowCounter.ownerId,
      projectId: rowCounter.projectId,
      name: rowCounter.name,
      currentRow: rowCounter.currentRow,
      targetRow: rowCounter.targetRow,
      createdAt: rowCounter.createdAt.toISOString(),
      updatedAt: rowCounter.updatedAt.toISOString(),
      deletedAt: rowCounter.deletedAt?.toISOString() ?? null,
      syncStatus: 'Synced',
    };
  }

  private toWorkSessionResponse(session: WorkSession): WorkSessionResponseDto {
    return {
      id: session.id,
      ownerId: session.ownerId,
      projectId: session.projectId,
      startedAt: session.startedAt.toISOString(),
      endedAt: session.endedAt?.toISOString() ?? null,
      memo: session.memo,
      createdAt: session.createdAt.toISOString(),
      updatedAt: session.updatedAt.toISOString(),
      deletedAt: session.deletedAt?.toISOString() ?? null,
      syncStatus: 'Synced',
    };
  }
}
```

- [ ] **Step 4: Add project controller and module**

Create `server/src/projects/projects.controller.ts`:

```ts
import { Controller, Get, UseGuards } from '@nestjs/common';
import {
  CurrentUser,
  CurrentUserPayload,
} from '../auth/current-user.decorator';
import { DevAuthGuard } from '../auth/dev-auth.guard';
import { ProjectResponseDto } from './project-response.dto';
import { ProjectsService } from './projects.service';

@UseGuards(DevAuthGuard)
@Controller('projects')
export class ProjectsController {
  constructor(private readonly projectsService: ProjectsService) {}

  @Get()
  listProjects(
    @CurrentUser() currentUser: CurrentUserPayload,
  ): Promise<ProjectResponseDto[]> {
    return this.projectsService.listProjects(currentUser.id);
  }
}
```

Create `server/src/projects/projects.module.ts`:

```ts
import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { ProjectsController } from './projects.controller';
import { ProjectsService } from './projects.service';

@Module({
  imports: [AuthModule],
  controllers: [ProjectsController],
  providers: [ProjectsService],
})
export class ProjectsModule {}
```

Modify `server/src/app.module.ts`:

```ts
import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AuthModule } from './auth/auth.module';
import { DatabaseModule } from './database/database.module';
import { HealthModule } from './health/health.module';
import { ProjectsModule } from './projects/projects.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
    }),
    AuthModule,
    DatabaseModule,
    HealthModule,
    ProjectsModule,
  ],
})
export class AppModule {}
```

- [ ] **Step 5: Run project e2e test**

Run:

```bash
cd server
npm run test:e2e -- projects.e2e-spec.ts
```

Expected: `PASS test/projects.e2e-spec.ts`.

- [ ] **Step 6: Run full server tests and build**

Run:

```bash
cd server
npm run test:e2e
npm run build
```

Expected:

- `PASS test/health.e2e-spec.ts`
- `PASS test/projects.e2e-spec.ts`
- Nest build completes with no TypeScript errors.

- [ ] **Step 7: Commit the projects endpoint**

Run:

```bash
git add server/src/projects server/src/app.module.ts server/test/projects.e2e-spec.ts
git commit -m "feat: add authenticated project list API"
```

---

### Task 5: Add Swift API Client

**Files:**

- Create: `KnitGether/Networking/APIConfiguration.swift`
- Create: `KnitGether/Networking/APIError.swift`
- Create: `KnitGether/Networking/APIClient.swift`
- Create: `KnitGetherTests/MockURLProtocol.swift`
- Create: `KnitGetherTests/APIClientTests.swift`

- [ ] **Step 1: Write failing API client tests**

Create `KnitGetherTests/MockURLProtocol.swift`:

```swift
import Foundation

final class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let requestHandler = Self.requestHandler else {
            client?.urlProtocol(
                self,
                didFailWithError: URLError(.badServerResponse)
            )
            return
        }

        do {
            let (response, data) = try requestHandler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {
    }
}
```

Create `KnitGetherTests/APIClientTests.swift`:

```swift
import Foundation
import Testing
@testable import KnitGether

struct APIClientTests {
    @Test func getAddsAuthorizationHeaderAndDecodesResponse() async throws {
        struct ResponseBody: Decodable, Equatable {
            let value: String
        }

        let session = Self.makeMockSession()
        MockURLProtocol.requestHandler = { request in
            #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/projects")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer dev-token")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data(#"{"value":"ok"}"#.utf8))
        }

        let client = APIClient(
            configuration: APIConfiguration(
                baseURL: URL(string: "http://127.0.0.1:3000/api/v1")!,
                authTokenProvider: { "dev-token" }
            ),
            session: session
        )

        let body: ResponseBody = try await client.get("projects")
        #expect(body == ResponseBody(value: "ok"))
    }

    @Test func getThrowsStructuredErrorForHTTPFailure() async throws {
        let session = Self.makeMockSession()
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 401,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (
                response,
                Data(#"{"code":"UNAUTHENTICATED","message":"Missing or invalid bearer token.","details":{}}"#.utf8)
            )
        }

        let client = APIClient(
            configuration: APIConfiguration(
                baseURL: URL(string: "http://127.0.0.1:3000/api/v1")!,
                authTokenProvider: { nil }
            ),
            session: session
        )

        do {
            let _: [String] = try await client.get("projects")
            Issue.record("Expected APIError.requestFailed")
        } catch let error as APIError {
            #expect(error.statusCode == 401)
            #expect(error.code == "UNAUTHENTICATED")
        }
    }

    private static func makeMockSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: configuration)
    }
}
```

Run:

```bash
xcodebuild -project KnitGether.xcodeproj -scheme KnitGether -destination generic/platform=iOS build-for-testing CODE_SIGNING_ALLOWED=NO
```

Expected: fail because `APIClient`, `APIConfiguration`, and `APIError` do not exist.

- [ ] **Step 2: Add API configuration and error types**

Create `KnitGether/Networking/APIConfiguration.swift`:

```swift
import Foundation

struct APIConfiguration {
    let baseURL: URL
    let authTokenProvider: @Sendable () async throws -> String?
}
```

Create `KnitGether/Networking/APIError.swift`:

```swift
import Foundation

struct APIErrorEnvelope: Decodable {
    let code: String?
    let message: String?
}

enum APIError: Error, Equatable {
    case invalidResponse
    case requestFailed(statusCode: Int, code: String?, message: String?)
    case decodingFailed
    case unsupportedOperation(String)

    var statusCode: Int? {
        if case let .requestFailed(statusCode, _, _) = self {
            return statusCode
        }
        return nil
    }

    var code: String? {
        if case let .requestFailed(_, code, _) = self {
            return code
        }
        return nil
    }

    var message: String? {
        if case let .requestFailed(_, _, message) = self {
            return message
        }
        return nil
    }
}
```

- [ ] **Step 3: Add API client implementation**

Create `KnitGether/Networking/APIClient.swift`:

```swift
import Foundation

final class APIClient {
    private let configuration: APIConfiguration
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(
        configuration: APIConfiguration,
        session: URLSession = .shared
    ) {
        self.configuration = configuration
        self.session = session

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)

            if let date = Self.fractionalISO8601Formatter.date(from: value) {
                return date
            }

            if let date = Self.iso8601Formatter.date(from: value) {
                return date
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid ISO-8601 date: \(value)"
            )
        }
        self.decoder = decoder

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder
    }

    func get<Response: Decodable>(_ path: String) async throws -> Response {
        try await request(path, method: "GET", body: Optional<Data>.none)
    }

    func send<RequestBody: Encodable, Response: Decodable>(
        _ path: String,
        method: String,
        body: RequestBody
    ) async throws -> Response {
        let data = try encoder.encode(body)
        return try await request(path, method: method, body: data)
    }

    private func request<Response: Decodable>(
        _ path: String,
        method: String,
        body: Data?
    ) async throws -> Response {
        let url = configuration.baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        if let token = try await configuration.authTokenProvider() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            let envelope = try? decoder.decode(APIErrorEnvelope.self, from: data)
            throw APIError.requestFailed(
                statusCode: httpResponse.statusCode,
                code: envelope?.code,
                message: envelope?.message
            )
        }

        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw APIError.decodingFailed
        }
    }

    private static let fractionalISO8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
}
```

- [ ] **Step 4: Verify iOS compile**

Run:

```bash
xcodebuild -project KnitGether.xcodeproj -scheme KnitGether -destination generic/platform=iOS build-for-testing CODE_SIGNING_ALLOWED=NO
```

Expected: build-for-testing completes with no Swift compile errors.

- [ ] **Step 5: Commit the API client**

Run:

```bash
git add KnitGether/Networking KnitGetherTests/MockURLProtocol.swift KnitGetherTests/APIClientTests.swift
git commit -m "feat: add iOS API client"
```

---

### Task 6: Add RemoteProjectRepository

**Files:**

- Create: `KnitGether/Repositories/Remote/RemoteProjectRepository.swift`
- Create: `KnitGetherTests/RemoteProjectRepositoryTests.swift`

- [ ] **Step 1: Write failing remote repository test**

Create `KnitGetherTests/RemoteProjectRepositoryTests.swift`:

```swift
import Foundation
import Testing
@testable import KnitGether

struct RemoteProjectRepositoryTests {
    @Test func fetchProjectsDecodesServerProjectResponse() async throws {
        let session = makeMockSession()
        MockURLProtocol.requestHandler = { request in
            #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/projects")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!

            let body = """
            [
              {
                "id": "11111111-1111-1111-1111-111111111111",
                "ownerId": "user-a",
                "name": "Favorite Cardigan",
                "status": "WIP",
                "isFavorite": true,
                "memo": "Use smaller needles for ribbing.",
                "startDate": "2026-07-01T00:00:00.000Z",
                "lastWorkedAt": "2026-07-03T09:00:00.000Z",
                "patternCopy": null,
                "workspaceDisplayMode": "patternAndCounter",
                "workspaceSheetPosition": "medium",
                "rowCounter": {
                  "id": "22222222-2222-2222-2222-222222222222",
                  "ownerId": "user-a",
                  "projectId": "11111111-1111-1111-1111-111111111111",
                  "name": "Main Counter",
                  "currentRow": 42,
                  "targetRow": 120,
                  "createdAt": "2026-07-01T00:00:00.000Z",
                  "updatedAt": "2026-07-03T09:00:00.000Z",
                  "deletedAt": null,
                  "syncStatus": "Synced"
                },
                "workSessions": [],
                "relatedSkillIds": [],
                "createdAt": "2026-07-01T00:00:00.000Z",
                "updatedAt": "2026-07-03T09:00:00.000Z",
                "deletedAt": null,
                "syncStatus": "Synced"
              }
            ]
            """

            return (response, Data(body.utf8))
        }

        let apiClient = APIClient(
            configuration: APIConfiguration(
                baseURL: URL(string: "http://127.0.0.1:3000/api/v1")!,
                authTokenProvider: { "dev-token" }
            ),
            session: session
        )
        let repository = RemoteProjectRepository(apiClient: apiClient)

        let projects = try await repository.fetchProjects()

        #expect(projects.count == 1)
        #expect(projects[0].id.uuidString.lowercased() == "11111111-1111-1111-1111-111111111111")
        #expect(projects[0].name == "Favorite Cardigan")
        #expect(projects[0].status == .wip)
        #expect(projects[0].rowCounter.currentRow == 42)
        #expect(projects[0].syncStatus == .synced)
    }

    private func makeMockSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: configuration)
    }
}
```

Run:

```bash
xcodebuild -project KnitGether.xcodeproj -scheme KnitGether -destination generic/platform=iOS build-for-testing CODE_SIGNING_ALLOWED=NO
```

Expected: fail because `RemoteProjectRepository` does not exist.

- [ ] **Step 2: Add remote repository implementation**

Create `KnitGether/Repositories/Remote/RemoteProjectRepository.swift`:

```swift
import Foundation

final class RemoteProjectRepository: ProjectRepository {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func fetchProjects() async throws -> [KnittingProject] {
        try await apiClient.get("projects")
    }

    func fetchProject(id: UUID) async throws -> KnittingProject? {
        do {
            return try await apiClient.get("projects/\(id.uuidString)")
        } catch let error as APIError where error.statusCode == 404 {
            return nil
        }
    }

    func saveProject(_ project: KnittingProject) async throws {
        throw APIError.unsupportedOperation(
            "Remote project save is outside the first project-list vertical slice."
        )
    }

    func deleteProject(id: UUID) async throws {
        throw APIError.unsupportedOperation(
            "Remote project delete is outside the first project-list vertical slice."
        )
    }
}
```

- [ ] **Step 3: Verify iOS compile**

Run:

```bash
xcodebuild -project KnitGether.xcodeproj -scheme KnitGether -destination generic/platform=iOS build-for-testing CODE_SIGNING_ALLOWED=NO
```

Expected: build-for-testing completes with no Swift compile errors.

- [ ] **Step 4: Commit remote project repository**

Run:

```bash
git add KnitGether/Repositories/Remote/RemoteProjectRepository.swift KnitGetherTests/RemoteProjectRepositoryTests.swift
git commit -m "feat: add remote project repository"
```

---

### Task 7: Wire Remote Mode Without Changing Default App Behavior

**Files:**

- Modify: `KnitGether/Repositories/AppRepositoryContainer.swift`
- Create: `KnitGetherTests/AppRepositoryContainerTests.swift`

- [ ] **Step 1: Write failing repository container tests**

Create `KnitGetherTests/AppRepositoryContainerTests.swift`:

```swift
import Foundation
import Testing
@testable import KnitGether

struct AppRepositoryContainerTests {
    @Test func makeDefaultUsesLocalRepositoriesWhenServerIsNotConfigured() {
        let container = AppRepositoryContainer.makeDefault(environment: [:])

        #expect(container.projectRepository is LocalProjectRepository)
        #expect(container.patternRepository is LocalPatternRepository)
    }

    @Test func makeDefaultUsesRemoteProjectRepositoryWhenServerIsConfigured() {
        let container = AppRepositoryContainer.makeDefault(
            environment: [
                "KNITGETHER_API_BASE_URL": "http://127.0.0.1:3000/api/v1",
                "KNITGETHER_DEV_AUTH_TOKEN": "dev-token"
            ]
        )

        #expect(container.projectRepository is RemoteProjectRepository)
        #expect(container.patternRepository is LocalPatternRepository)
    }
}
```

Run:

```bash
xcodebuild -project KnitGether.xcodeproj -scheme KnitGether -destination generic/platform=iOS build-for-testing CODE_SIGNING_ALLOWED=NO
```

Expected: fail because `AppRepositoryContainer.makeDefault(environment:)` does not exist.

- [ ] **Step 2: Add remote opt-in factory**

Modify `KnitGether/Repositories/AppRepositoryContainer.swift`:

```swift
//
//  AppRepositoryContainer.swift
//  KnitGether
//
//  Created by yu haeun on 6/4/26.
//

import Foundation

final class AppRepositoryContainer {
    static let shared = AppRepositoryContainer.makeDefault()

    let projectRepository: any ProjectRepository
    let patternRepository: any PatternRepository
    let libraryRepository: any LibraryRepository
    let skillRepository: any SkillRepository
    let profileRepository: any ProfileRepository

    init(
        projectRepository: any ProjectRepository = LocalProjectRepository(),
        patternRepository: any PatternRepository = LocalPatternRepository(),
        libraryRepository: any LibraryRepository = LocalLibraryRepository(),
        skillRepository: any SkillRepository = LocalSkillRepository(),
        profileRepository: any ProfileRepository = LocalProfileRepository()
    ) {
        self.projectRepository = projectRepository
        self.patternRepository = patternRepository
        self.libraryRepository = libraryRepository
        self.skillRepository = skillRepository
        self.profileRepository = profileRepository
    }

    static func makeDefault(
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) -> AppRepositoryContainer {
        guard
            let baseURLString = environment["KNITGETHER_API_BASE_URL"],
            let baseURL = URL(string: baseURLString)
        else {
            return AppRepositoryContainer()
        }

        let apiClient = APIClient(
            configuration: APIConfiguration(
                baseURL: baseURL,
                authTokenProvider: {
                    environment["KNITGETHER_DEV_AUTH_TOKEN"]
                }
            )
        )

        return AppRepositoryContainer(
            projectRepository: RemoteProjectRepository(apiClient: apiClient),
            patternRepository: LocalPatternRepository(),
            libraryRepository: LocalLibraryRepository(),
            skillRepository: LocalSkillRepository(),
            profileRepository: LocalProfileRepository()
        )
    }
}
```

- [ ] **Step 3: Verify iOS compile**

Run:

```bash
xcodebuild -project KnitGether.xcodeproj -scheme KnitGether -destination generic/platform=iOS build-for-testing CODE_SIGNING_ALLOWED=NO
```

Expected: build-for-testing completes with no Swift compile errors.

- [ ] **Step 4: Commit repository mode wiring**

Run:

```bash
git add KnitGether/Repositories/AppRepositoryContainer.swift KnitGetherTests/AppRepositoryContainerTests.swift
git commit -m "feat: wire optional server-backed project repository"
```

---

### Task 8: End-to-End Manual Verification

**Files:**

- Modify only if verification exposes a defect in files created by Tasks 1-7.

- [ ] **Step 1: Start local API dependencies**

Run:

```bash
cd server
docker compose up -d postgres
npx prisma migrate dev
npm run start:dev
```

Expected:

- PostgreSQL container is running.
- Prisma reports the database is in sync.
- Nest server starts on `http://localhost:3000`.

- [ ] **Step 2: Seed one project manually through Prisma Studio or a one-off script**

Create `server/prisma/seed-project-list.ts`:

```ts
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main(): Promise<void> {
  await prisma.userProfile.upsert({
    where: { id: 'dev-user' },
    update: {
      displayName: 'Dev User',
      preferredUnits: 'metric',
    },
    create: {
      id: 'dev-user',
      displayName: 'Dev User',
      preferredUnits: 'metric',
    },
  });

  await prisma.project.upsert({
    where: { id: '11111111-1111-1111-1111-111111111111' },
    update: {
      name: 'Server Cardigan',
      updatedAt: new Date('2026-07-04T00:00:00.000Z'),
    },
    create: {
      id: '11111111-1111-1111-1111-111111111111',
      ownerId: 'dev-user',
      name: 'Server Cardigan',
      status: 'WIP',
      isFavorite: true,
      memo: 'Seeded from local development server.',
      startDate: new Date('2026-07-01T00:00:00.000Z'),
      lastWorkedAt: new Date('2026-07-04T00:00:00.000Z'),
      workspaceDisplayMode: 'patternAndCounter',
      workspaceSheetPosition: 'medium',
      relatedSkillIds: [],
      createdAt: new Date('2026-07-01T00:00:00.000Z'),
      updatedAt: new Date('2026-07-04T00:00:00.000Z'),
      rowCounter: {
        create: {
          id: '22222222-2222-2222-2222-222222222222',
          ownerId: 'dev-user',
          name: 'Main Counter',
          currentRow: 12,
          targetRow: 80,
          createdAt: new Date('2026-07-01T00:00:00.000Z'),
          updatedAt: new Date('2026-07-04T00:00:00.000Z'),
        },
      },
    },
  });
}

main()
  .then(async () => {
    await prisma.$disconnect();
  })
  .catch(async (error) => {
    console.error(error);
    await prisma.$disconnect();
    process.exit(1);
  });
```

Run:

```bash
cd server
npx ts-node prisma/seed-project-list.ts
curl -H "Authorization: Bearer dev-token" http://localhost:3000/api/v1/projects
```

Expected: JSON array contains `"name":"Server Cardigan"` and `"syncStatus":"Synced"`.

- [ ] **Step 3: Build iOS app with local default mode**

Run:

```bash
xcodebuild -project KnitGether.xcodeproj -scheme KnitGether -destination generic/platform=iOS build CODE_SIGNING_ALLOWED=NO
```

Expected: build succeeds. The default app path still uses local repositories because no `KNITGETHER_API_BASE_URL` is configured.

- [ ] **Step 4: Build iOS app with server environment available to tests**

Run:

```bash
KNITGETHER_API_BASE_URL=http://127.0.0.1:3000/api/v1 KNITGETHER_DEV_AUTH_TOKEN=dev-token xcodebuild -project KnitGether.xcodeproj -scheme KnitGether -destination generic/platform=iOS build-for-testing CODE_SIGNING_ALLOWED=NO
```

Expected: build-for-testing succeeds and repository container compile checks pass.

- [ ] **Step 5: Commit verification seed script if it is kept**

If `server/prisma/seed-project-list.ts` is useful for local development, keep it and commit it:

```bash
git add server/prisma/seed-project-list.ts
git commit -m "chore: add project list seed script"
```

If the seed script is not kept, remove it before the final status check:

```bash
rm server/prisma/seed-project-list.ts
git status --short
```

Expected: the final working tree only contains intentional changes from completed tasks.

---

## Final Verification

Run all verification before declaring the implementation complete:

```bash
cd server
npm run test:e2e
npm run build
```

Expected:

- Health e2e test passes.
- Projects e2e test passes.
- Nest build succeeds.

Run iOS verification:

```bash
xcodebuild -project KnitGether.xcodeproj -scheme KnitGether -destination generic/platform=iOS build-for-testing CODE_SIGNING_ALLOWED=NO
xcodebuild -project KnitGether.xcodeproj -scheme KnitGether -destination generic/platform=iOS build CODE_SIGNING_ALLOWED=NO
```

Expected:

- Swift app and test targets compile.
- The app build succeeds without requiring a running server.

## Follow-Up Plans

After this vertical slice is implemented and verified, create separate plans in this order:

1. Project create/update/delete API and `RemoteProjectRepository` write methods.
2. Profile API and `RemoteProfileRepository`.
3. Pattern document metadata API and `RemotePatternRepository`.
4. Signed file upload/download URLs for PDFs and drawing data.
5. Timestamp-based sync endpoint and conflict handling.
6. Gauge module once the product model for swatch and wash comparison is finalized.
