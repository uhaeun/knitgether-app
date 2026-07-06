# Pattern File Upload Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the server-backed pattern library slice so iOS can upload PDF patterns, list metadata, download PDFs, cache files locally, and delete server-backed patterns.

**Architecture:** Add `StoredFile` and `PatternDocument` persistence to Prisma, then add a NestJS `patterns` module and a focused local storage service rooted at `FILE_STORAGE_ROOT`. On iOS, extend `APIClient` with multipart upload and binary download helpers, then implement `RemotePatternRepository` behind the existing `PatternRepository` protocol while leaving local repository behavior unchanged.

**Tech Stack:** NestJS, Prisma, PostgreSQL, Supertest, Swift, Swift Testing, URLSession, existing `LocalPatternFileStore`

---

## Scope

This plan implements:

- server local PDF storage
- pattern metadata CRUD
- PDF upload via `POST /api/v1/patterns`
- PDF download via `GET /api/v1/patterns/:id/file`
- Swift `RemotePatternRepository`
- remote repository wiring in `AppRepositoryContainer`

This plan does not implement project pattern copy persistence in the server project API, drawing data upload/download, S3/MinIO, production auth, offline queueing, or sync conflict handling.

## File Structure

Server files:

- Modify `server/prisma/schema.prisma`: add `StoredFile` and `PatternDocument`; add relations to `UserProfile`.
- Create `server/prisma/migrations/20260706000000_add_pattern_files/migration.sql`: SQL migration for the new tables and indexes.
- Modify `server/.env.example`: add `FILE_STORAGE_ROOT` and `PATTERN_UPLOAD_MAX_BYTES`.
- Modify `.gitignore`: ignore `server/storage/`.
- Create `server/src/storage/local-file-storage.service.ts`: local disk storage boundary for PDF files.
- Create `server/src/storage/storage.module.ts`: exports `LocalFileStorageService`.
- Create `server/src/patterns/uploaded-pattern-file.ts`: small local type for Multer file shape without depending on `Express.Multer`.
- Create `server/src/patterns/pattern-response.dto.ts`: Swift-compatible pattern response mapper shape.
- Create `server/src/patterns/pattern-update.dto.ts`: PATCH validation DTO.
- Create `server/src/patterns/pattern-create-fields.dto.ts`: multipart field validation DTO for non-file fields.
- Create `server/src/patterns/patterns.service.ts`: owner-scoped pattern persistence and file association.
- Create `server/src/patterns/patterns.controller.ts`: authenticated REST routes and file streaming.
- Create `server/src/patterns/patterns.module.ts`: module wiring.
- Modify `server/src/app.module.ts`: import `PatternsModule`.
- Create `server/test/patterns.e2e-spec.ts`: server route tests using the existing mock-Prisma style plus a temporary storage root.

iOS files:

- Modify `KnitGether/Networking/APIClient.swift`: add multipart upload and binary download helpers.
- Create `KnitGether/Repositories/Remote/RemotePatternRepository.swift`: remote implementation of `PatternRepository`.
- Modify `KnitGether/Repositories/AppRepositoryContainer.swift`: wire remote pattern repository when API base URL is configured.
- Modify `KnitGether/Repositories/Local/LocalPatternFileStore.swift`: add testable root directory injection plus helpers for caching downloaded library PDFs and copying cached PDFs into project pattern copies.
- Modify `KnitGetherTests/APIClientTests.swift`: request tests for multipart upload and binary download.
- Create `KnitGetherTests/RemotePatternRepositoryTests.swift`: repository request/cache behavior tests.
- Modify `KnitGetherTests/AppRepositoryContainerTests.swift`: assert remote pattern repository wiring.

## Task 1: Prisma Pattern/File Schema

**Files:**

- Modify: `server/prisma/schema.prisma`
- Create: `server/prisma/migrations/20260706000000_add_pattern_files/migration.sql`
- Modify: `server/.env.example`
- Modify: `.gitignore`

- [ ] **Step 1: Update Prisma schema**

Add `storedFiles` and `patternDocuments` relations to `UserProfile`, then add these models:

```prisma
model UserProfile {
  id             String    @id
  displayName    String
  preferredUnits String    @default("metric")
  createdAt      DateTime  @default(now())
  updatedAt      DateTime  @updatedAt
  deletedAt      DateTime?

  projects         Project[]
  rowCounters      RowCounter[]
  workSessions     WorkSession[]
  storedFiles      StoredFile[]
  patternDocuments PatternDocument[]
}

model StoredFile {
  id               String    @id @db.Uuid
  ownerId          String
  kind             String
  originalFileName String
  contentType      String
  byteSize         Int
  storageKey       String
  createdAt        DateTime  @default(now())
  updatedAt        DateTime  @updatedAt
  deletedAt        DateTime?

  owner            UserProfile       @relation(fields: [ownerId], references: [id], onDelete: Cascade)
  patternDocuments PatternDocument[]

  @@index([ownerId, kind, deletedAt])
  @@unique([storageKey])
}

model PatternDocument {
  id           String    @id @db.Uuid
  ownerId      String
  title        String
  designer     String?
  fileName     String?
  pageCount    Int?
  notes        String    @default("")
  storedFileId String?   @db.Uuid
  createdAt    DateTime  @default(now())
  updatedAt    DateTime  @updatedAt
  deletedAt    DateTime?

  owner      UserProfile @relation(fields: [ownerId], references: [id], onDelete: Cascade)
  storedFile StoredFile? @relation(fields: [storedFileId], references: [id], onDelete: SetNull)

  @@index([ownerId, deletedAt])
  @@index([storedFileId])
}
```

- [ ] **Step 2: Add SQL migration**

Create `server/prisma/migrations/20260706000000_add_pattern_files/migration.sql`:

```sql
-- CreateTable
CREATE TABLE "StoredFile" (
    "id" UUID NOT NULL,
    "ownerId" TEXT NOT NULL,
    "kind" TEXT NOT NULL,
    "originalFileName" TEXT NOT NULL,
    "contentType" TEXT NOT NULL,
    "byteSize" INTEGER NOT NULL,
    "storageKey" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "deletedAt" TIMESTAMP(3),

    CONSTRAINT "StoredFile_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "PatternDocument" (
    "id" UUID NOT NULL,
    "ownerId" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "designer" TEXT,
    "fileName" TEXT,
    "pageCount" INTEGER,
    "notes" TEXT NOT NULL DEFAULT '',
    "storedFileId" UUID,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "deletedAt" TIMESTAMP(3),

    CONSTRAINT "PatternDocument_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "StoredFile_ownerId_kind_deletedAt_idx" ON "StoredFile"("ownerId", "kind", "deletedAt");

-- CreateIndex
CREATE UNIQUE INDEX "StoredFile_storageKey_key" ON "StoredFile"("storageKey");

-- CreateIndex
CREATE INDEX "PatternDocument_ownerId_deletedAt_idx" ON "PatternDocument"("ownerId", "deletedAt");

-- CreateIndex
CREATE INDEX "PatternDocument_storedFileId_idx" ON "PatternDocument"("storedFileId");

-- AddForeignKey
ALTER TABLE "StoredFile" ADD CONSTRAINT "StoredFile_ownerId_fkey" FOREIGN KEY ("ownerId") REFERENCES "UserProfile"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PatternDocument" ADD CONSTRAINT "PatternDocument_ownerId_fkey" FOREIGN KEY ("ownerId") REFERENCES "UserProfile"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PatternDocument" ADD CONSTRAINT "PatternDocument_storedFileId_fkey" FOREIGN KEY ("storedFileId") REFERENCES "StoredFile"("id") ON DELETE SET NULL ON UPDATE CASCADE;
```

- [ ] **Step 3: Add file storage environment defaults**

Append to `server/.env.example`:

```dotenv
FILE_STORAGE_ROOT=./storage
PATTERN_UPLOAD_MAX_BYTES=52428800
```

- [ ] **Step 4: Ignore local storage files**

Append to `.gitignore`:

```gitignore
server/storage/
```

- [ ] **Step 5: Generate Prisma client and compile schema**

Run:

```bash
npx prisma generate
```

Expected: Prisma client generation succeeds without schema validation errors.

- [ ] **Step 6: Commit**

```bash
git add .gitignore server/.env.example server/prisma/schema.prisma server/prisma/migrations/20260706000000_add_pattern_files/migration.sql
git commit -m "feat: add pattern file schema"
```

## Task 2: Server Local File Storage Boundary

**Files:**

- Create: `server/src/storage/local-file-storage.service.ts`
- Create: `server/src/storage/storage.module.ts`
- Test indirectly in: `server/test/patterns.e2e-spec.ts`

- [ ] **Step 1: Create storage service**

Create `server/src/storage/local-file-storage.service.ts`:

```ts
import { Injectable, NotFoundException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createReadStream, promises as fs } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { ReadStream } from 'node:fs';

export type StoredPatternPdf = {
  storageKey: string;
  byteSize: number;
};

@Injectable()
export class LocalFileStorageService {
  private readonly rootDirectory: string;

  constructor(configService: ConfigService) {
    const configuredRoot = configService.get<string>('FILE_STORAGE_ROOT')?.trim();
    this.rootDirectory = resolve(process.cwd(), configuredRoot || './storage');
  }

  async savePatternPdf(params: {
    ownerId: string;
    patternId: string;
    fileId: string;
    buffer: Buffer;
  }): Promise<StoredPatternPdf> {
    const storageKey = join('patterns', params.ownerId, params.patternId, `${params.fileId}.pdf`);
    const absolutePath = this.absolutePath(storageKey);
    await fs.mkdir(dirname(absolutePath), { recursive: true });
    await fs.writeFile(absolutePath, params.buffer);
    return {
      storageKey,
      byteSize: params.buffer.byteLength,
    };
  }

  openReadStream(storageKey: string): ReadStream {
    return createReadStream(this.absolutePath(storageKey));
  }

  async assertExists(storageKey: string): Promise<void> {
    try {
      await fs.access(this.absolutePath(storageKey));
    } catch {
      throw new NotFoundException({
        code: 'PATTERN_FILE_NOT_FOUND',
        message: 'Pattern file not found.',
      });
    }
  }

  async remove(storageKey: string | null | undefined): Promise<void> {
    if (!storageKey) {
      return;
    }

    try {
      await fs.unlink(this.absolutePath(storageKey));
    } catch (error) {
      const nodeError = error as NodeJS.ErrnoException;
      if (nodeError.code !== 'ENOENT') {
        throw error;
      }
    }
  }

  private absolutePath(storageKey: string): string {
    const absolutePath = resolve(this.rootDirectory, storageKey);

    if (!absolutePath.startsWith(`${this.rootDirectory}/`) && absolutePath !== this.rootDirectory) {
      throw new Error('Invalid storage key.');
    }

    return absolutePath;
  }
}
```

- [ ] **Step 2: Create storage module**

Create `server/src/storage/storage.module.ts`:

```ts
import { Module } from '@nestjs/common';
import { LocalFileStorageService } from './local-file-storage.service';

@Module({
  providers: [LocalFileStorageService],
  exports: [LocalFileStorageService],
})
export class StorageModule {}
```

- [ ] **Step 3: Run TypeScript build**

Run:

```bash
npm run build
```

Expected: build succeeds.

- [ ] **Step 4: Commit**

```bash
git add server/src/storage/local-file-storage.service.ts server/src/storage/storage.module.ts
git commit -m "feat: add local file storage service"
```

## Task 3: Server Pattern API Tests

**Files:**

- Create: `server/test/patterns.e2e-spec.ts`

- [ ] **Step 1: Write failing e2e tests**

Create `server/test/patterns.e2e-spec.ts`:

```ts
import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { promises as fs } from 'node:fs';
import { join } from 'node:path';
import { tmpdir } from 'node:os';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { setupApp } from '../src/app.setup';
import { PrismaService } from '../src/database/prisma.service';

type MockPrismaService = {
  userProfile: {
    upsert: jest.Mock;
  };
  patternDocument: {
    findMany: jest.Mock;
    findFirst: jest.Mock;
    findFirstOrThrow: jest.Mock;
    create: jest.Mock;
    update: jest.Mock;
  };
  storedFile: {
    update: jest.Mock;
  };
  $transaction: jest.Mock;
};

describe('Patterns route', () => {
  let app: INestApplication;
  let prisma: MockPrismaService;
  let storageRoot: string;

  const patternId = '44444444-4444-4444-8444-444444444444';
  const fileId = '55555555-5555-4555-8555-555555555555';
  const pdfBytes = Buffer.from('%PDF-1.4\n% KnitGether test PDF\n');
  const activePattern = {
    id: patternId,
    ownerId: 'user-a',
    title: 'Cozy Shawl',
    designer: 'Yu',
    fileName: 'cozy-shawl.pdf',
    pageCount: 12,
    notes: 'Use lace markers.',
    storedFileId: fileId,
    createdAt: new Date('2026-07-04T00:00:00.000Z'),
    updatedAt: new Date('2026-07-05T00:00:00.000Z'),
    deletedAt: null,
    storedFile: {
      id: fileId,
      ownerId: 'user-a',
      kind: 'patternPdf',
      originalFileName: 'cozy-shawl.pdf',
      contentType: 'application/pdf',
      byteSize: pdfBytes.byteLength,
      storageKey: `patterns/user-a/${patternId}/${fileId}.pdf`,
      createdAt: new Date('2026-07-04T00:00:00.000Z'),
      updatedAt: new Date('2026-07-04T00:00:00.000Z'),
      deletedAt: null,
    },
  };

  beforeAll(async () => {
    process.env.DEV_AUTH_TOKEN = 'dev-token';
    process.env.DEV_AUTH_USER_ID = 'user-a';
    storageRoot = await fs.mkdtemp(join(tmpdir(), 'knitgether-patterns-'));
    process.env.FILE_STORAGE_ROOT = storageRoot;
    process.env.PATTERN_UPLOAD_MAX_BYTES = '52428800';

    prisma = {
      userProfile: {
        upsert: jest.fn(),
      },
      patternDocument: {
        findMany: jest.fn(),
        findFirst: jest.fn(),
        findFirstOrThrow: jest.fn(),
        create: jest.fn(),
        update: jest.fn(),
      },
      storedFile: {
        update: jest.fn(),
      },
      $transaction: jest.fn(async (callback) => callback(prisma)),
    };

    const moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    })
      .overrideProvider(PrismaService)
      .useValue(prisma)
      .compile();

    app = moduleRef.createNestApplication();
    setupApp(app);
    await app.init();
  });

  beforeEach(async () => {
    await fs.rm(storageRoot, { recursive: true, force: true });
    await fs.mkdir(storageRoot, { recursive: true });
    prisma.userProfile.upsert.mockReset();
    prisma.patternDocument.findMany.mockReset();
    prisma.patternDocument.findFirst.mockReset();
    prisma.patternDocument.findFirstOrThrow.mockReset();
    prisma.patternDocument.create.mockReset();
    prisma.patternDocument.update.mockReset();
    prisma.storedFile.update.mockReset();
    prisma.$transaction.mockReset();
    prisma.$transaction.mockImplementation(async (callback) => callback(prisma));
    prisma.userProfile.upsert.mockResolvedValue(undefined);
    prisma.patternDocument.findMany.mockResolvedValue([activePattern]);
    prisma.patternDocument.findFirst.mockResolvedValue(activePattern);
    prisma.patternDocument.findFirstOrThrow.mockResolvedValue(activePattern);
    prisma.patternDocument.create.mockResolvedValue(activePattern);
    prisma.patternDocument.update.mockResolvedValue(activePattern);
    prisma.storedFile.update.mockResolvedValue(activePattern.storedFile);
  });

  afterAll(async () => {
    delete process.env.DEV_AUTH_TOKEN;
    delete process.env.DEV_AUTH_USER_ID;
    delete process.env.FILE_STORAGE_ROOT;
    delete process.env.PATTERN_UPLOAD_MAX_BYTES;
    await app.close();
    await fs.rm(storageRoot, { recursive: true, force: true });
  });

  it('rejects unauthenticated requests', async () => {
    await request(app.getHttpServer())
      .get('/api/v1/patterns')
      .expect(401)
      .expect(({ body }) => {
        expect(body.code).toBe('UNAUTHENTICATED');
      });
  });

  it('uploads a PDF pattern and returns metadata', async () => {
    const response = await request(app.getHttpServer())
      .post('/api/v1/patterns')
      .set('Authorization', 'Bearer dev-token')
      .field('id', patternId)
      .field('title', 'Cozy Shawl')
      .field('designer', 'Yu')
      .field('pageCount', '12')
      .field('notes', 'Use lace markers.')
      .attach('file', pdfBytes, {
        filename: 'cozy-shawl.pdf',
        contentType: 'application/pdf',
      })
      .expect(201);

    expect(prisma.userProfile.upsert).toHaveBeenCalledWith({
      where: { id: 'user-a' },
      create: {
        id: 'user-a',
        displayName: 'user-a',
      },
      update: {},
    });
    expect(prisma.patternDocument.create).toHaveBeenCalledWith({
      data: expect.objectContaining({
        id: patternId,
        ownerId: 'user-a',
        title: 'Cozy Shawl',
        designer: 'Yu',
        fileName: 'cozy-shawl.pdf',
        pageCount: 12,
        notes: 'Use lace markers.',
        deletedAt: null,
        storedFile: {
          create: expect.objectContaining({
            ownerId: 'user-a',
            kind: 'patternPdf',
            originalFileName: 'cozy-shawl.pdf',
            contentType: 'application/pdf',
            byteSize: pdfBytes.byteLength,
          }),
        },
      }),
      include: {
        storedFile: true,
      },
    });
    expect(response.body).toEqual({
      id: patternId,
      ownerId: 'user-a',
      title: 'Cozy Shawl',
      designer: 'Yu',
      fileName: 'cozy-shawl.pdf',
      localFilePath: null,
      pageCount: 12,
      notes: 'Use lace markers.',
      createdAt: '2026-07-04T00:00:00.000Z',
      updatedAt: '2026-07-05T00:00:00.000Z',
      deletedAt: null,
      syncStatus: 'Synced',
    });
  });

  it('rejects non-PDF uploads', async () => {
    await request(app.getHttpServer())
      .post('/api/v1/patterns')
      .set('Authorization', 'Bearer dev-token')
      .field('title', 'Not PDF')
      .attach('file', Buffer.from('plain text'), {
        filename: 'notes.txt',
        contentType: 'text/plain',
      })
      .expect(400)
      .expect(({ body }) => {
        expect(body.code).toBe('VALIDATION_FAILED');
      });
  });

  it('returns only active patterns owned by the current user', async () => {
    const response = await request(app.getHttpServer())
      .get('/api/v1/patterns')
      .set('Authorization', 'Bearer dev-token')
      .expect(200);

    expect(prisma.patternDocument.findMany).toHaveBeenCalledWith({
      where: {
        ownerId: 'user-a',
        deletedAt: null,
      },
      include: {
        storedFile: true,
      },
      orderBy: {
        createdAt: 'desc',
      },
    });
    expect(response.body).toHaveLength(1);
    expect(response.body[0].id).toBe(patternId);
    expect(response.body[0].syncStatus).toBe('Synced');
  });

  it('returns one active pattern owned by the current user', async () => {
    const response = await request(app.getHttpServer())
      .get(`/api/v1/patterns/${patternId}`)
      .set('Authorization', 'Bearer dev-token')
      .expect(200);

    expect(prisma.patternDocument.findFirst).toHaveBeenCalledWith({
      where: {
        id: patternId,
        ownerId: 'user-a',
        deletedAt: null,
      },
      include: {
        storedFile: true,
      },
    });
    expect(response.body.id).toBe(patternId);
  });

  it('updates owner-scoped pattern metadata', async () => {
    await request(app.getHttpServer())
      .patch(`/api/v1/patterns/${patternId}`)
      .set('Authorization', 'Bearer dev-token')
      .send({
        title: 'Updated Shawl',
        designer: 'Yu H',
        pageCount: 14,
        notes: 'Updated notes.',
      })
      .expect(200);

    expect(prisma.patternDocument.update).toHaveBeenCalledWith({
      where: { id: patternId },
      data: {
        title: 'Updated Shawl',
        designer: 'Yu H',
        pageCount: 14,
        notes: 'Updated notes.',
      },
      include: {
        storedFile: true,
      },
    });
  });

  it('downloads the owner-scoped PDF', async () => {
    const absoluteFilePath = join(storageRoot, activePattern.storedFile.storageKey);
    await fs.mkdir(join(storageRoot, 'patterns', 'user-a', patternId), { recursive: true });
    await fs.writeFile(absoluteFilePath, pdfBytes);

    const response = await request(app.getHttpServer())
      .get(`/api/v1/patterns/${patternId}/file`)
      .set('Authorization', 'Bearer dev-token')
      .expect(200)
      .expect('Content-Type', /application\/pdf/);

    expect(Buffer.from(response.body)).toEqual(pdfBytes);
    expect(response.header['content-disposition']).toContain('cozy-shawl.pdf');
  });

  it('soft-deletes metadata and removes the disk file', async () => {
    const absoluteFilePath = join(storageRoot, activePattern.storedFile.storageKey);
    await fs.mkdir(join(storageRoot, 'patterns', 'user-a', patternId), { recursive: true });
    await fs.writeFile(absoluteFilePath, pdfBytes);

    await request(app.getHttpServer())
      .delete(`/api/v1/patterns/${patternId}`)
      .set('Authorization', 'Bearer dev-token')
      .expect(204);

    expect(prisma.patternDocument.update).toHaveBeenCalledWith({
      where: { id: patternId },
      data: {
        deletedAt: expect.any(Date),
        storedFile: {
          update: {
            deletedAt: expect.any(Date),
          },
        },
      },
    });
    await expect(fs.access(absoluteFilePath)).rejects.toMatchObject({ code: 'ENOENT' });
  });
});
```

- [ ] **Step 2: Run tests to verify failure**

Run:

```bash
npm test -- --runTestsByPath test/patterns.e2e-spec.ts
```

Expected: FAIL because `PatternsModule` and route files do not exist.

- [ ] **Step 3: Commit the failing tests**

```bash
git add server/test/patterns.e2e-spec.ts
git commit -m "test: cover pattern file API"
```

## Task 4: Server Pattern API Implementation

**Files:**

- Create: `server/src/patterns/uploaded-pattern-file.ts`
- Create: `server/src/patterns/pattern-response.dto.ts`
- Create: `server/src/patterns/pattern-create-fields.dto.ts`
- Create: `server/src/patterns/pattern-update.dto.ts`
- Create: `server/src/patterns/patterns.service.ts`
- Create: `server/src/patterns/patterns.controller.ts`
- Create: `server/src/patterns/patterns.module.ts`
- Modify: `server/src/app.module.ts`
- Test: `server/test/patterns.e2e-spec.ts`

- [ ] **Step 1: Create uploaded file type**

Create `server/src/patterns/uploaded-pattern-file.ts`:

```ts
export type UploadedPatternFile = {
  originalname: string;
  mimetype: string;
  size: number;
  buffer: Buffer;
};
```

- [ ] **Step 2: Create response DTO**

Create `server/src/patterns/pattern-response.dto.ts`:

```ts
import { PatternDocument, StoredFile } from '@prisma/client';

export type PatternWithFile = PatternDocument & {
  storedFile: StoredFile | null;
};

export class PatternResponseDto {
  id!: string;
  ownerId!: string;
  title!: string;
  designer!: string | null;
  fileName!: string | null;
  localFilePath!: string | null;
  pageCount!: number | null;
  notes!: string;
  createdAt!: string;
  updatedAt!: string;
  deletedAt!: string | null;
  syncStatus!: 'Synced';

  static fromModel(pattern: PatternWithFile): PatternResponseDto {
    return {
      id: pattern.id,
      ownerId: pattern.ownerId,
      title: pattern.title,
      designer: pattern.designer,
      fileName: pattern.fileName,
      localFilePath: null,
      pageCount: pattern.pageCount,
      notes: pattern.notes,
      createdAt: pattern.createdAt.toISOString(),
      updatedAt: pattern.updatedAt.toISOString(),
      deletedAt: pattern.deletedAt?.toISOString() ?? null,
      syncStatus: 'Synced',
    };
  }
}
```

- [ ] **Step 3: Create multipart field DTO**

Create `server/src/patterns/pattern-create-fields.dto.ts`:

```ts
import { Transform } from 'class-transformer';
import { IsInt, IsOptional, IsString, IsUUID, Min } from 'class-validator';

export class PatternCreateFieldsDto {
  @IsOptional()
  @IsUUID()
  id?: string;

  @IsOptional()
  @IsString()
  title?: string;

  @IsOptional()
  @IsString()
  designer?: string;

  @IsOptional()
  @Transform(({ value }) => {
    if (value === undefined || value === null || value === '') {
      return undefined;
    }
    return Number(value);
  })
  @IsInt()
  @Min(1)
  pageCount?: number;

  @IsOptional()
  @IsString()
  notes?: string;
}
```

- [ ] **Step 4: Create metadata update DTO**

Create `server/src/patterns/pattern-update.dto.ts`:

```ts
import { IsInt, IsOptional, IsString, Min } from 'class-validator';

export class PatternUpdateDto {
  @IsOptional()
  @IsString()
  title?: string;

  @IsOptional()
  @IsString()
  designer?: string | null;

  @IsOptional()
  @IsInt()
  @Min(1)
  pageCount?: number | null;

  @IsOptional()
  @IsString()
  notes?: string;
}
```

- [ ] **Step 5: Create pattern service**

Create `server/src/patterns/patterns.service.ts`:

```ts
import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../database/prisma.service';
import { LocalFileStorageService } from '../storage/local-file-storage.service';
import { PatternCreateFieldsDto } from './pattern-create-fields.dto';
import { PatternResponseDto, PatternWithFile } from './pattern-response.dto';
import { PatternUpdateDto } from './pattern-update.dto';
import { UploadedPatternFile } from './uploaded-pattern-file';

@Injectable()
export class PatternsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly fileStorage: LocalFileStorageService,
  ) {}

  async listPatterns(ownerId: string): Promise<PatternResponseDto[]> {
    const patterns = await this.prisma.patternDocument.findMany({
      where: {
        ownerId,
        deletedAt: null,
      },
      include: {
        storedFile: true,
      },
      orderBy: {
        createdAt: 'desc',
      },
    });

    return patterns.map(PatternResponseDto.fromModel);
  }

  async createPattern(
    ownerId: string,
    fields: PatternCreateFieldsDto,
    file: UploadedPatternFile | undefined,
  ): Promise<PatternResponseDto> {
    this.assertPdf(file);

    const patternId = fields.id ?? randomUUID();
    const fileId = randomUUID();
    const stored = await this.fileStorage.savePatternPdf({
      ownerId,
      patternId,
      fileId,
      buffer: file.buffer,
    });

    const title = this.trimmedOrDefault(
      fields.title,
      this.titleFromFileName(file.originalname),
    );

    const pattern = await this.prisma.$transaction(async (transaction) => {
      await this.ensureUserProfile(transaction, ownerId);

      return transaction.patternDocument.create({
        data: {
          id: patternId,
          ownerId,
          title,
          designer: this.trimmedOrNull(fields.designer),
          fileName: file.originalname,
          pageCount: fields.pageCount,
          notes: fields.notes ?? '',
          deletedAt: null,
          storedFile: {
            create: {
              id: fileId,
              ownerId,
              kind: 'patternPdf',
              originalFileName: file.originalname,
              contentType: 'application/pdf',
              byteSize: stored.byteSize,
              storageKey: stored.storageKey,
              deletedAt: null,
            },
          },
        },
        include: {
          storedFile: true,
        },
      });
    });

    return PatternResponseDto.fromModel(pattern);
  }

  async getPattern(ownerId: string, id: string): Promise<PatternResponseDto> {
    return PatternResponseDto.fromModel(await this.findActivePattern(ownerId, id));
  }

  async updatePattern(
    ownerId: string,
    id: string,
    body: PatternUpdateDto,
  ): Promise<PatternResponseDto> {
    await this.findActivePattern(ownerId, id);

    const data: Prisma.PatternDocumentUncheckedUpdateInput = {};

    if (body.title !== undefined) {
      data.title = body.title.trim();
    }
    if (body.designer !== undefined) {
      data.designer = this.trimmedOrNull(body.designer);
    }
    if (body.pageCount !== undefined) {
      data.pageCount = body.pageCount;
    }
    if (body.notes !== undefined) {
      data.notes = body.notes;
    }

    const pattern = await this.prisma.patternDocument.update({
      where: { id },
      data,
      include: {
        storedFile: true,
      },
    });

    return PatternResponseDto.fromModel(pattern);
  }

  async getPatternFile(ownerId: string, id: string): Promise<PatternWithFile> {
    const pattern = await this.findActivePattern(ownerId, id);

    if (!pattern.storedFile || pattern.storedFile.deletedAt) {
      throw new NotFoundException({
        code: 'PATTERN_FILE_NOT_FOUND',
        message: 'Pattern file not found.',
      });
    }

    await this.fileStorage.assertExists(pattern.storedFile.storageKey);
    return pattern;
  }

  async deletePattern(ownerId: string, id: string): Promise<void> {
    const pattern = await this.findActivePattern(ownerId, id);
    const deletedAt = new Date();

    await this.prisma.patternDocument.update({
      where: { id },
      data: {
        deletedAt,
        storedFile: pattern.storedFile
          ? {
              update: {
                deletedAt,
              },
            }
          : undefined,
      },
    });

    await this.fileStorage.remove(pattern.storedFile?.storageKey);
  }

  openFileReadStream(storageKey: string) {
    return this.fileStorage.openReadStream(storageKey);
  }

  private async findActivePattern(
    ownerId: string,
    id: string,
  ): Promise<PatternWithFile> {
    const pattern = await this.prisma.patternDocument.findFirst({
      where: {
        id,
        ownerId,
        deletedAt: null,
      },
      include: {
        storedFile: true,
      },
    });

    if (!pattern) {
      throw new NotFoundException({
        code: 'PATTERN_NOT_FOUND',
        message: 'Pattern not found.',
      });
    }

    return pattern;
  }

  private async ensureUserProfile(
    transaction: Prisma.TransactionClient,
    ownerId: string,
  ): Promise<void> {
    await transaction.userProfile.upsert({
      where: { id: ownerId },
      create: {
        id: ownerId,
        displayName: ownerId,
      },
      update: {},
    });
  }

  private assertPdf(file: UploadedPatternFile | undefined): asserts file is UploadedPatternFile {
    if (!file) {
      throw new BadRequestException({
        code: 'VALIDATION_FAILED',
        message: 'Pattern PDF file is required.',
      });
    }

    const extensionIsPdf = file.originalname.toLowerCase().endsWith('.pdf');
    const mimeIsPdf = file.mimetype === 'application/pdf';

    if (!extensionIsPdf || !mimeIsPdf) {
      throw new BadRequestException({
        code: 'VALIDATION_FAILED',
        message: 'Pattern upload must be a PDF file.',
      });
    }
  }

  private titleFromFileName(fileName: string): string {
    const withoutExtension = fileName.replace(/\.pdf$/i, '').trim();
    return withoutExtension || fileName;
  }

  private trimmedOrDefault(value: string | undefined, fallback: string): string {
    const trimmed = value?.trim();
    return trimmed && trimmed.length > 0 ? trimmed : fallback;
  }

  private trimmedOrNull(value: string | null | undefined): string | null {
    const trimmed = value?.trim();
    return trimmed && trimmed.length > 0 ? trimmed : null;
  }
}
```

- [ ] **Step 6: Create pattern controller**

Create `server/src/patterns/patterns.controller.ts`:

```ts
import {
  Body,
  Controller,
  Delete,
  Get,
  Header,
  HttpCode,
  Param,
  Patch,
  Post,
  Res,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { Response } from 'express';
import {
  CurrentUser,
  CurrentUserPayload,
} from '../auth/current-user.decorator';
import { DevAuthGuard } from '../auth/dev-auth.guard';
import { PatternCreateFieldsDto } from './pattern-create-fields.dto';
import { PatternResponseDto } from './pattern-response.dto';
import { PatternUpdateDto } from './pattern-update.dto';
import { PatternsService } from './patterns.service';
import { UploadedPatternFile } from './uploaded-pattern-file';

@UseGuards(DevAuthGuard)
@Controller('patterns')
export class PatternsController {
  constructor(private readonly patternsService: PatternsService) {}

  @Get()
  listPatterns(
    @CurrentUser() currentUser: CurrentUserPayload,
  ): Promise<PatternResponseDto[]> {
    return this.patternsService.listPatterns(currentUser.id);
  }

  @Post()
  @UseInterceptors(
    FileInterceptor('file', {
      limits: {
        fileSize: Number(process.env.PATTERN_UPLOAD_MAX_BYTES ?? 52_428_800),
      },
    }),
  )
  createPattern(
    @CurrentUser() currentUser: CurrentUserPayload,
    @Body() body: PatternCreateFieldsDto,
    @UploadedFile() file?: UploadedPatternFile,
  ): Promise<PatternResponseDto> {
    return this.patternsService.createPattern(currentUser.id, body, file);
  }

  @Get(':id')
  getPattern(
    @CurrentUser() currentUser: CurrentUserPayload,
    @Param('id') id: string,
  ): Promise<PatternResponseDto> {
    return this.patternsService.getPattern(currentUser.id, id);
  }

  @Patch(':id')
  updatePattern(
    @CurrentUser() currentUser: CurrentUserPayload,
    @Param('id') id: string,
    @Body() body: PatternUpdateDto,
  ): Promise<PatternResponseDto> {
    return this.patternsService.updatePattern(currentUser.id, id, body);
  }

  @Get(':id/file')
  @Header('Content-Type', 'application/pdf')
  async downloadPatternFile(
    @CurrentUser() currentUser: CurrentUserPayload,
    @Param('id') id: string,
    @Res() response: Response,
  ): Promise<void> {
    const pattern = await this.patternsService.getPatternFile(currentUser.id, id);
    const storedFile = pattern.storedFile;

    if (!storedFile) {
      response.status(404).send();
      return;
    }

    response.setHeader('Content-Type', 'application/pdf');
    response.setHeader(
      'Content-Disposition',
      `attachment; filename="${storedFile.originalFileName.replace(/"/g, '')}"`,
    );
    this.patternsService.openFileReadStream(storedFile.storageKey).pipe(response);
  }

  @Delete(':id')
  @HttpCode(204)
  deletePattern(
    @CurrentUser() currentUser: CurrentUserPayload,
    @Param('id') id: string,
  ): Promise<void> {
    return this.patternsService.deletePattern(currentUser.id, id);
  }
}
```

- [ ] **Step 7: Create pattern module and wire app module**

Create `server/src/patterns/patterns.module.ts`:

```ts
import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { DatabaseModule } from '../database/database.module';
import { StorageModule } from '../storage/storage.module';
import { PatternsController } from './patterns.controller';
import { PatternsService } from './patterns.service';

@Module({
  imports: [AuthModule, DatabaseModule, StorageModule],
  controllers: [PatternsController],
  providers: [PatternsService],
})
export class PatternsModule {}
```

Modify `server/src/app.module.ts` to import `PatternsModule`:

```ts
import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AuthModule } from './auth/auth.module';
import { DatabaseModule } from './database/database.module';
import { HealthModule } from './health/health.module';
import { PatternsModule } from './patterns/patterns.module';
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
    PatternsModule,
  ],
})
export class AppModule {}
```

- [ ] **Step 8: Run focused server tests**

Run:

```bash
npm test -- --runTestsByPath test/patterns.e2e-spec.ts
```

Expected: PASS for `Patterns route`.

- [ ] **Step 9: Run server build**

Run:

```bash
npm run build
```

Expected: build succeeds.

- [ ] **Step 10: Commit**

```bash
git add server/src/app.module.ts server/src/patterns server/src/storage server/test/patterns.e2e-spec.ts
git commit -m "feat: add pattern file API"
```

## Task 5: Swift API Client Multipart And Binary Helpers

**Files:**

- Modify: `KnitGether/Networking/APIClient.swift`
- Modify: `KnitGetherTests/APIClientTests.swift`

- [ ] **Step 1: Add failing API client tests**

Append these tests and helper inside `KnitGetherTests/APIClientTests.swift`:

```swift
@Test func uploadMultipartAddsAuthorizationAndDecodesResponse() async throws {
    struct ResponseBody: Decodable, Equatable {
        let id: String
    }

    let session = MockURLProtocol.makeSession { request in
        #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/patterns")
        #expect(request.httpMethod == "POST")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer dev-token")
        let contentType = try #require(request.value(forHTTPHeaderField: "Content-Type"))
        #expect(contentType.hasPrefix("multipart/form-data; boundary="))

        let body = try Self.bodyData(from: request)
        let bodyString = String(decoding: body, as: UTF8.self)
        #expect(bodyString.contains(#"name="title""#))
        #expect(bodyString.contains("Cozy Shawl"))
        #expect(bodyString.contains(#"name="file"; filename="cozy-shawl.pdf""#))
        #expect(bodyString.contains("application/pdf"))
        #expect(bodyString.contains("%PDF-1.4"))

        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!
        return (response, Data(#"{"id":"44444444-4444-4444-8444-444444444444"}"#.utf8))
    }

    let client = APIClient(
        configuration: APIConfiguration(
            baseURL: URL(string: "http://127.0.0.1:3000/api/v1")!,
            authTokenProvider: { "dev-token" }
        ),
        session: session
    )

    let response: ResponseBody = try await client.uploadMultipart(
        "patterns",
        fields: ["title": "Cozy Shawl"],
        file: MultipartFile(
            fieldName: "file",
            fileName: "cozy-shawl.pdf",
            contentType: "application/pdf",
            data: Data("%PDF-1.4".utf8)
        )
    )

    #expect(response == ResponseBody(id: "44444444-4444-4444-8444-444444444444"))
}

@Test func downloadDataReturnsBinaryResponse() async throws {
    let pdfData = Data("%PDF-1.4".utf8)
    let session = MockURLProtocol.makeSession { request in
        #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/patterns/44444444-4444-4444-8444-444444444444/file")
        #expect(request.httpMethod == "GET")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer dev-token")

        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/pdf"]
        )!
        return (response, pdfData)
    }

    let client = APIClient(
        configuration: APIConfiguration(
            baseURL: URL(string: "http://127.0.0.1:3000/api/v1")!,
            authTokenProvider: { "dev-token" }
        ),
        session: session
    )

    let data = try await client.downloadData("patterns/44444444-4444-4444-8444-444444444444/file")
    #expect(data == pdfData)
}

private static func bodyData(from request: URLRequest) throws -> Data {
    if let body = request.httpBody {
        return body
    }

    guard let bodyStream = request.httpBodyStream else {
        Issue.record("Expected request body")
        return Data()
    }

    bodyStream.open()
    defer { bodyStream.close() }

    var data = Data()
    let bufferSize = 1_024
    let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
    defer { buffer.deallocate() }

    while bodyStream.hasBytesAvailable {
        let readCount = bodyStream.read(buffer, maxLength: bufferSize)
        if readCount < 0 {
            throw bodyStream.streamError ?? URLError(.cannotDecodeContentData)
        }
        if readCount == 0 {
            break
        }
        data.append(buffer, count: readCount)
    }

    return data
}
```

- [ ] **Step 2: Run focused tests to verify failure**

Run:

```bash
xcodebuild test -project KnitGether.xcodeproj -scheme KnitGether -destination 'platform=iOS Simulator,id=F882A23F-0389-430D-84F9-9E43E03AD78F' -only-testing:KnitGetherTests/APIClientTests -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO
```

Expected: FAIL because `MultipartFile`, `uploadMultipart`, and `downloadData` do not exist.

- [ ] **Step 3: Implement API client helpers**

Modify `KnitGether/Networking/APIClient.swift` by adding this public file payload type above `final class APIClient`:

```swift
struct MultipartFile {
    let fieldName: String
    let fileName: String
    let contentType: String
    let data: Data
}
```

Add these methods to `APIClient`:

```swift
func uploadMultipart<Response: Decodable>(
    _ path: String,
    fields: [String: String],
    file: MultipartFile
) async throws -> Response {
    let boundary = "Boundary-\(UUID().uuidString)"
    let body = multipartBody(boundary: boundary, fields: fields, file: file)
    return try await request(
        path,
        method: "POST",
        body: body,
        contentType: "multipart/form-data; boundary=\(boundary)"
    )
}

func downloadData(_ path: String) async throws -> Data {
    try await requestData(path, method: "GET", body: Optional<Data>.none, contentType: nil)
}
```

Change the private JSON request signature so callers can pass a content type:

```swift
private func request<Response: Decodable>(
    _ path: String,
    method: String,
    body: Data?,
    contentType: String? = "application/json"
) async throws -> Response {
    let data = try await requestData(path, method: method, body: body, contentType: contentType)

    do {
        return try decoder.decode(Response.self, from: data)
    } catch {
        throw APIError.decodingFailed(message: String(describing: error))
    }
}
```

Add shared data request and multipart body builders:

```swift
private func requestData(
    _ path: String,
    method: String,
    body: Data?,
    contentType: String?
) async throws -> Data {
    let url = configuration.baseURL.appendingPathComponent(path)
    var request = URLRequest(url: url)
    request.httpMethod = method
    request.setValue("application/json", forHTTPHeaderField: "Accept")

    if let body {
        request.httpBody = body
        if let contentType {
            request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        }
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

    return data
}

private func multipartBody(
    boundary: String,
    fields: [String: String],
    file: MultipartFile
) -> Data {
    var data = Data()
    let lineBreak = "\r\n"

    for key in fields.keys.sorted() {
        guard let value = fields[key] else {
            continue
        }
        data.appendString("--\(boundary)\(lineBreak)")
        data.appendString("Content-Disposition: form-data; name=\"\(key)\"\(lineBreak)\(lineBreak)")
        data.appendString("\(value)\(lineBreak)")
    }

    data.appendString("--\(boundary)\(lineBreak)")
    data.appendString("Content-Disposition: form-data; name=\"\(file.fieldName)\"; filename=\"\(file.fileName)\"\(lineBreak)")
    data.appendString("Content-Type: \(file.contentType)\(lineBreak)\(lineBreak)")
    data.append(file.data)
    data.appendString(lineBreak)
    data.appendString("--\(boundary)--\(lineBreak)")

    return data
}
```

Add this private extension at the bottom of the file:

```swift
private extension Data {
    mutating func appendString(_ string: String) {
        append(Data(string.utf8))
    }
}
```

Update `requestWithoutResponse` to call `requestData` instead of duplicating request execution:

```swift
private func requestWithoutResponse(
    _ path: String,
    method: String,
    body: Data?
) async throws {
    _ = try await requestData(path, method: method, body: body, contentType: "application/json")
}
```

- [ ] **Step 4: Run focused tests**

Run:

```bash
xcodebuild test -project KnitGether.xcodeproj -scheme KnitGether -destination 'platform=iOS Simulator,id=F882A23F-0389-430D-84F9-9E43E03AD78F' -only-testing:KnitGetherTests/APIClientTests -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO
```

Expected: `APIClientTests` pass.

- [ ] **Step 5: Commit**

```bash
git add KnitGether/Networking/APIClient.swift KnitGetherTests/APIClientTests.swift
git commit -m "feat: add API multipart and binary helpers"
```

## Task 6: Swift Local Pattern File Store Cache Helpers

**Files:**

- Modify: `KnitGether/Repositories/Local/LocalPatternFileStore.swift`

- [ ] **Step 1: Make the file store root injectable**

Change the initializer and root assignment in `LocalPatternFileStore`:

```swift
init(
    fileManager: FileManager = .default,
    rootDirectoryURL: URL? = nil
) {
    self.fileManager = fileManager
    if let rootDirectoryURL {
        self.rootDirectoryURL = rootDirectoryURL
    } else {
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        self.rootDirectoryURL = documentsURL.appendingPathComponent("KnitGetherFiles", isDirectory: true)
    }
}
```

- [ ] **Step 2: Add cache helper methods**

Modify `LocalPatternFileStore` by adding:

```swift
func storeLibraryPatternData(
    _ data: Data,
    fileName: String,
    patternId: UUID
) throws -> StoredPatternFile {
    try writeFile(
        data,
        fileName: fileName,
        relativeDirectoryPath: "Patterns/\(patternId.uuidString)"
    )
}

func copyLibraryPatternFileToProject(
    _ pattern: PatternDocument,
    projectId: UUID,
    copyId: UUID
) throws -> StoredPatternFile? {
    guard let sourceURL = fileURL(for: pattern.localFilePath) else {
        return nil
    }

    return try storeProjectPatternFile(
        from: sourceURL,
        projectId: projectId,
        copyId: copyId
    )
}
```

Add this private helper next to `copyFile`:

```swift
private func writeFile(
    _ data: Data,
    fileName: String,
    relativeDirectoryPath: String
) throws -> StoredPatternFile {
    let sanitizedName = sanitizedFileName(fileName)
    let relativePath = "\(relativeDirectoryPath)/\(sanitizedName)"
    let destinationURL = rootDirectoryURL.appendingPathComponent(relativePath)
    let destinationDirectoryURL = destinationURL.deletingLastPathComponent()

    try fileManager.createDirectory(at: destinationDirectoryURL, withIntermediateDirectories: true)

    if fileManager.fileExists(atPath: destinationURL.path) {
        try fileManager.removeItem(at: destinationURL)
    }

    try data.write(to: destinationURL, options: [.atomic])

    return StoredPatternFile(fileName: sanitizedName, relativePath: relativePath)
}
```

- [ ] **Step 3: Run iOS build**

Run:

```bash
xcodebuild -project KnitGether.xcodeproj -scheme KnitGether -destination generic/platform=iOS build CODE_SIGNING_ALLOWED=NO
```

Expected: build succeeds.

- [ ] **Step 4: Commit**

```bash
git add KnitGether/Repositories/Local/LocalPatternFileStore.swift
git commit -m "feat: add pattern cache file helpers"
```

## Task 7: Remote Pattern Repository Tests And Implementation

**Files:**

- Create: `KnitGether/Repositories/Remote/RemotePatternRepository.swift`
- Create: `KnitGetherTests/RemotePatternRepositoryTests.swift`

- [ ] **Step 1: Write failing remote repository tests**

Create `KnitGetherTests/RemotePatternRepositoryTests.swift`:

```swift
import Foundation
import Testing
@testable import KnitGether

struct RemotePatternRepositoryTests {
    @Test func fetchPatternsRequestsPatternsEndpointAndDecodesResponse() async throws {
        let session = MockURLProtocol.makeSession { request in
            #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/patterns")
            #expect(request.httpMethod == "GET")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer dev-token")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data(Self.patternsResponseJSON.utf8))
        }

        let repository = Self.makeRepository(session: session)
        let patterns = try await repository.fetchPatterns()

        #expect(patterns.count == 1)
        #expect(patterns.first?.id.uuidString.lowercased() == "44444444-4444-4444-8444-444444444444")
        #expect(patterns.first?.title == "Cozy Shawl")
        #expect(patterns.first?.syncStatus == .synced)
    }

    @Test func createPatternUploadsPdfAndCachesDownload() async throws {
        let tempDirectory = try Self.makeTempDirectory()
        let sourceURL = tempDirectory.appendingPathComponent("cozy-shawl.pdf")
        try Data("%PDF-1.4".utf8).write(to: sourceURL)
        var callCount = 0

        let session = MockURLProtocol.makeSession { request in
            callCount += 1

            if callCount == 1 {
                #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/patterns")
                #expect(request.httpMethod == "POST")
                #expect(request.value(forHTTPHeaderField: "Content-Type")?.hasPrefix("multipart/form-data; boundary=") == true)
                let body = try Self.bodyData(from: request)
                let bodyString = String(decoding: body, as: UTF8.self)
                #expect(bodyString.contains(#"filename="cozy-shawl.pdf""#))
                #expect(bodyString.contains("%PDF-1.4"))

                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 201,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                )!
                return (response, Data(Self.patternResponseJSON.utf8))
            }

            #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/patterns/44444444-4444-4444-8444-444444444444/file")
            #expect(request.httpMethod == "GET")
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/pdf"]
            )!
            return (response, Data("%PDF-1.4".utf8))
        }

        let repository = Self.makeRepository(
            session: session,
            cacheRootURL: tempDirectory.appendingPathComponent("cache", isDirectory: true)
        )
        let pattern = try await repository.createPattern(fromFileAt: sourceURL)

        #expect(callCount == 2)
        #expect(pattern.localFilePath?.contains("Patterns/44444444-4444-4444-8444-444444444444") == true)
        let cachedURL = try #require(repository.fileURL(for: pattern))
        #expect(FileManager.default.fileExists(atPath: cachedURL.path))
        try? FileManager.default.removeItem(at: tempDirectory)
    }

    @Test func fetchPatternDownloadsFileWhenCacheIsMissing() async throws {
        var callCount = 0
        let session = MockURLProtocol.makeSession { request in
            callCount += 1

            if callCount == 1 {
                #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/patterns/44444444-4444-4444-8444-444444444444")
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                )!
                return (response, Data(Self.patternResponseJSON.utf8))
            }

            #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/patterns/44444444-4444-4444-8444-444444444444/file")
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/pdf"]
            )!
            return (response, Data("%PDF-1.4".utf8))
        }

        let repository = Self.makeRepository(session: session)
        let pattern = try #require(
            try await repository.fetchPattern(id: UUID(uuidString: "44444444-4444-4444-8444-444444444444")!)
        )

        #expect(callCount == 2)
        #expect(repository.fileURL(for: pattern) != nil)
    }

    @Test func deletePatternRequestsDeleteEndpoint() async throws {
        let patternID = UUID(uuidString: "44444444-4444-4444-8444-444444444444")!
        let session = MockURLProtocol.makeSession { request in
            #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/patterns/\(patternID.uuidString.lowercased())")
            #expect(request.httpMethod == "DELETE")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 204,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        let repository = Self.makeRepository(session: session)
        try await repository.deletePattern(id: patternID)
    }

    private static func makeRepository(
        session: URLSession,
        cacheRootURL: URL? = nil
    ) -> RemotePatternRepository {
        RemotePatternRepository(
            apiClient: APIClient(
                configuration: APIConfiguration(
                    baseURL: URL(string: "http://127.0.0.1:3000/api/v1")!,
                    authTokenProvider: { "dev-token" }
                ),
                session: session
            ),
            fileStore: LocalPatternFileStore(
                fileManager: .default,
                rootDirectoryURL: cacheRootURL
            )
        )
    }

    private static func makeTempDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("RemotePatternRepositoryTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private static func bodyData(from request: URLRequest) throws -> Data {
        if let body = request.httpBody {
            return body
        }

        guard let bodyStream = request.httpBodyStream else {
            Issue.record("Expected request body")
            return Data()
        }

        bodyStream.open()
        defer { bodyStream.close() }

        var data = Data()
        let bufferSize = 1_024
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }

        while bodyStream.hasBytesAvailable {
            let readCount = bodyStream.read(buffer, maxLength: bufferSize)
            if readCount < 0 {
                throw bodyStream.streamError ?? URLError(.cannotDecodeContentData)
            }
            if readCount == 0 {
                break
            }
            data.append(buffer, count: readCount)
        }

        return data
    }

    private static let patternResponseJSON = """
    {
      "id": "44444444-4444-4444-8444-444444444444",
      "ownerId": "user-a",
      "title": "Cozy Shawl",
      "designer": "Yu",
      "fileName": "cozy-shawl.pdf",
      "localFilePath": null,
      "pageCount": 12,
      "notes": "Use lace markers.",
      "createdAt": "2026-07-04T00:00:00.000Z",
      "updatedAt": "2026-07-05T00:00:00.000Z",
      "deletedAt": null,
      "syncStatus": "Synced"
    }
    """

    private static let patternsResponseJSON = """
    [
      {
        "id": "44444444-4444-4444-8444-444444444444",
        "ownerId": "user-a",
        "title": "Cozy Shawl",
        "designer": "Yu",
        "fileName": "cozy-shawl.pdf",
        "localFilePath": null,
        "pageCount": 12,
        "notes": "Use lace markers.",
        "createdAt": "2026-07-04T00:00:00.000Z",
        "updatedAt": "2026-07-05T00:00:00.000Z",
        "deletedAt": null,
        "syncStatus": "Synced"
      }
    ]
    """
}
```

- [ ] **Step 2: Run focused tests to verify failure**

Run:

```bash
xcodebuild test -project KnitGether.xcodeproj -scheme KnitGether -destination 'platform=iOS Simulator,id=F882A23F-0389-430D-84F9-9E43E03AD78F' -only-testing:KnitGetherTests/RemotePatternRepositoryTests -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO
```

Expected: FAIL because `RemotePatternRepository` does not exist.

- [ ] **Step 3: Implement remote pattern repository**

Create `KnitGether/Repositories/Remote/RemotePatternRepository.swift`:

```swift
import Foundation

final class RemotePatternRepository: PatternRepository {
    private let apiClient: APIClient
    private let fileStore: LocalPatternFileStore
    private var cachedPatterns: [UUID: PatternDocument] = [:]

    init(
        apiClient: APIClient,
        fileStore: LocalPatternFileStore = LocalPatternFileStore()
    ) {
        self.apiClient = apiClient
        self.fileStore = fileStore
    }

    func fetchPatterns() async throws -> [PatternDocument] {
        let patterns: [PatternDocument] = try await apiClient.get("patterns")
        return patterns.map { mergeCachedPath(into: $0) }
    }

    func fetchPattern(id: UUID) async throws -> PatternDocument? {
        do {
            let pattern: PatternDocument = try await apiClient.get("patterns/\(id.uuidString.lowercased())")
            return try await cacheFileIfNeeded(for: mergeCachedPath(into: pattern))
        } catch let error as APIError where error.statusCode == 404 {
            return nil
        }
    }

    func savePattern(_ pattern: PatternDocument) async throws {
        let body = SavePatternRequest(pattern: pattern)
        let updated: PatternDocument = try await apiClient.send(
            "patterns/\(pattern.id.uuidString.lowercased())",
            method: "PATCH",
            body: body
        )
        cachedPatterns[updated.id] = mergeCachedPath(into: updated)
    }

    func deletePattern(id: UUID) async throws {
        try await apiClient.delete("patterns/\(id.uuidString.lowercased())")
        if let cached = cachedPatterns[id] {
            try fileStore.removeFile(at: cached.localFilePath)
        }
        cachedPatterns[id] = nil
    }

    func createPattern(fromFileAt fileURL: URL) async throws -> PatternDocument {
        let didStartAccessing = fileURL.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                fileURL.stopAccessingSecurityScopedResource()
            }
        }

        let fileData = try Data(contentsOf: fileURL)
        let title = fileURL.deletingPathExtension().lastPathComponent
        let uploaded: PatternDocument = try await apiClient.uploadMultipart(
            "patterns",
            fields: ["title": title],
            file: MultipartFile(
                fieldName: "file",
                fileName: fileURL.lastPathComponent,
                contentType: "application/pdf",
                data: fileData
            )
        )

        return try await cacheFileIfNeeded(for: uploaded)
    }

    func importPattern(_ pattern: PatternDocument, forProjectId projectId: UUID) async throws -> ProjectPatternCopy {
        let cachedPattern = try await cacheFileIfNeeded(for: mergeCachedPath(into: pattern))
        let copyId = UUID()
        let copiedFile = try fileStore.copyLibraryPatternFileToProject(
            cachedPattern,
            projectId: projectId,
            copyId: copyId
        )
        let now = Date()

        return ProjectPatternCopy(
            id: copyId,
            ownerId: cachedPattern.ownerId,
            projectId: projectId,
            sourcePatternDocumentId: cachedPattern.id,
            titleSnapshot: cachedPattern.title,
            designerSnapshot: cachedPattern.designer,
            fileNameSnapshot: copiedFile?.fileName ?? cachedPattern.fileName,
            localCopyPath: copiedFile?.relativePath,
            pageCountSnapshot: cachedPattern.pageCount,
            copiedAt: now,
            createdAt: now,
            updatedAt: now,
            syncStatus: .localOnly
        )
    }

    func createProjectPatternCopy(fromFileAt fileURL: URL, forProjectId projectId: UUID) async throws -> ProjectPatternCopy {
        let localRepository = LocalPatternRepository(fileStore: fileStore)
        return try await localRepository.createProjectPatternCopy(fromFileAt: fileURL, forProjectId: projectId)
    }

    func fileURL(for pattern: PatternDocument) -> URL? {
        fileStore.fileURL(for: pattern.localFilePath ?? cachedPatterns[pattern.id]?.localFilePath)
    }

    func fileURL(for patternCopy: ProjectPatternCopy) -> URL? {
        fileStore.fileURL(for: patternCopy.localCopyPath)
    }

    func drawingData(for patternCopy: ProjectPatternCopy) async throws -> Data? {
        try fileStore.loadData(at: patternCopy.drawingDataPath)
    }

    func saveDrawingData(_ data: Data, for patternCopy: ProjectPatternCopy) async throws -> ProjectPatternCopy {
        let relativePath = try fileStore.storeProjectPatternDrawingData(
            data,
            projectId: patternCopy.projectId,
            copyId: patternCopy.id
        )
        return patternCopy.updatingDrawingDataPath(relativePath)
    }

    func deleteDrawingData(for patternCopy: ProjectPatternCopy) async throws -> ProjectPatternCopy {
        try fileStore.removeFile(at: patternCopy.drawingDataPath)
        return patternCopy.updatingDrawingDataPath(nil)
    }

    private func cacheFileIfNeeded(for pattern: PatternDocument) async throws -> PatternDocument {
        if let localFilePath = pattern.localFilePath,
           fileStore.fileURL(for: localFilePath) != nil {
            cachedPatterns[pattern.id] = pattern
            return pattern
        }

        if let cached = cachedPatterns[pattern.id],
           let cachedPath = cached.localFilePath,
           fileStore.fileURL(for: cachedPath) != nil {
            return cached
        }

        let fileData = try await apiClient.downloadData("patterns/\(pattern.id.uuidString.lowercased())/file")
        let stored = try fileStore.storeLibraryPatternData(
            fileData,
            fileName: pattern.fileName ?? "\(pattern.title).pdf",
            patternId: pattern.id
        )
        let cached = PatternDocument(
            id: pattern.id,
            ownerId: pattern.ownerId,
            title: pattern.title,
            designer: pattern.designer,
            fileName: stored.fileName,
            localFilePath: stored.relativePath,
            pageCount: pattern.pageCount,
            notes: pattern.notes,
            createdAt: pattern.createdAt,
            updatedAt: pattern.updatedAt,
            deletedAt: pattern.deletedAt,
            syncStatus: pattern.syncStatus
        )
        cachedPatterns[pattern.id] = cached
        return cached
    }

    private func mergeCachedPath(into pattern: PatternDocument) -> PatternDocument {
        guard let cached = cachedPatterns[pattern.id],
              let cachedPath = cached.localFilePath
        else {
            return pattern
        }

        return PatternDocument(
            id: pattern.id,
            ownerId: pattern.ownerId,
            title: pattern.title,
            designer: pattern.designer,
            fileName: pattern.fileName,
            localFilePath: cachedPath,
            pageCount: pattern.pageCount,
            notes: pattern.notes,
            createdAt: pattern.createdAt,
            updatedAt: pattern.updatedAt,
            deletedAt: pattern.deletedAt,
            syncStatus: pattern.syncStatus
        )
    }
}

private struct SavePatternRequest: Encodable {
    let title: String
    let designer: String?
    let pageCount: Int?
    let notes: String

    nonisolated init(pattern: PatternDocument) {
        title = pattern.title
        designer = pattern.designer
        pageCount = pattern.pageCount
        notes = pattern.notes
    }
}
```

- [ ] **Step 4: Run focused repository tests**

Run:

```bash
xcodebuild test -project KnitGether.xcodeproj -scheme KnitGether -destination 'platform=iOS Simulator,id=F882A23F-0389-430D-84F9-9E43E03AD78F' -only-testing:KnitGetherTests/RemotePatternRepositoryTests -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO
```

Expected: `RemotePatternRepositoryTests` pass.

- [ ] **Step 5: Commit**

```bash
git add KnitGether/Repositories/Remote/RemotePatternRepository.swift KnitGetherTests/RemotePatternRepositoryTests.swift
git commit -m "feat: add remote pattern repository"
```

## Task 8: Wire Remote Pattern Repository

**Files:**

- Modify: `KnitGether/Repositories/AppRepositoryContainer.swift`
- Modify: `KnitGetherTests/AppRepositoryContainerTests.swift`

- [ ] **Step 1: Update failing container test expectation**

In `KnitGetherTests/AppRepositoryContainerTests.swift`, change the remote-mode expectation to:

```swift
#expect(container.projectRepository is RemoteProjectRepository)
#expect(container.patternRepository is RemotePatternRepository)
#expect(container.libraryRepository is LocalLibraryRepository)
#expect(container.skillRepository is LocalSkillRepository)
#expect(container.profileRepository is LocalProfileRepository)
```

Also extend the mock handler so it can respond to both `/projects` and `/patterns`:

```swift
let session = MockURLProtocol.makeSession { request in
    #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer dev-token")

    let response = HTTPURLResponse(
        url: request.url!,
        statusCode: 200,
        httpVersion: nil,
        headerFields: ["Content-Type": "application/json"]
    )!

    if request.url?.absoluteString == "https://api.knitgether.test/api/v1/projects" {
        return (response, Data("[]".utf8))
    }

    #expect(request.url?.absoluteString == "https://api.knitgether.test/api/v1/patterns")
    return (response, Data("[]".utf8))
}
```

After fetching projects, also fetch patterns:

```swift
let projects = try await container.projectRepository.fetchProjects()
#expect(projects.isEmpty)
let patterns = try await container.patternRepository.fetchPatterns()
#expect(patterns.isEmpty)
```

- [ ] **Step 2: Run focused test to verify failure**

Run:

```bash
xcodebuild test -project KnitGether.xcodeproj -scheme KnitGether -destination 'platform=iOS Simulator,id=F882A23F-0389-430D-84F9-9E43E03AD78F' -only-testing:KnitGetherTests/AppRepositoryContainerTests -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO
```

Expected: FAIL because remote mode still uses `LocalPatternRepository`.

- [ ] **Step 3: Wire remote pattern repository**

Modify `AppRepositoryContainer.makeDefault` to initialize both repositories in the remote branch:

```swift
static func makeDefault(
    environment: [String: String] = ProcessInfo.processInfo.environment,
    session: URLSession = .shared
) -> AppRepositoryContainer {
    let projectRepository: any ProjectRepository
    let patternRepository: any PatternRepository

    if let baseURL = apiBaseURL(from: environment) {
        let token = environment["KNITGETHER_DEV_AUTH_TOKEN"]?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let apiClient = APIClient(
            configuration: APIConfiguration(
                baseURL: baseURL,
                authTokenProvider: {
                    guard let token, !token.isEmpty else {
                        return nil
                    }
                    return token
                }
            ),
            session: session
        )
        projectRepository = RemoteProjectRepository(apiClient: apiClient)
        patternRepository = RemotePatternRepository(apiClient: apiClient)
    } else {
        projectRepository = LocalProjectRepository()
        patternRepository = LocalPatternRepository()
    }

    return AppRepositoryContainer(
        projectRepository: projectRepository,
        patternRepository: patternRepository
    )
}
```

- [ ] **Step 4: Run focused test**

Run:

```bash
xcodebuild test -project KnitGether.xcodeproj -scheme KnitGether -destination 'platform=iOS Simulator,id=F882A23F-0389-430D-84F9-9E43E03AD78F' -only-testing:KnitGetherTests/AppRepositoryContainerTests -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO
```

Expected: `AppRepositoryContainerTests` pass.

- [ ] **Step 5: Commit**

```bash
git add KnitGether/Repositories/AppRepositoryContainer.swift KnitGetherTests/AppRepositoryContainerTests.swift
git commit -m "feat: wire remote pattern repository"
```

## Task 9: Full Verification And Push

**Files:**

- No functional file edits unless verification exposes a bug.

- [ ] **Step 1: Run server tests**

Run:

```bash
npm test
```

Expected: all server e2e suites pass.

- [ ] **Step 2: Run server build**

Run:

```bash
npm run build
```

Expected: Nest build succeeds.

- [ ] **Step 3: Run iOS unit tests**

Run:

```bash
xcodebuild test -project KnitGether.xcodeproj -scheme KnitGether -destination 'platform=iOS Simulator,id=F882A23F-0389-430D-84F9-9E43E03AD78F' -only-testing:KnitGetherTests -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO
```

Expected: all `KnitGetherTests` pass.

- [ ] **Step 4: Run iOS app build**

Run:

```bash
xcodebuild -project KnitGether.xcodeproj -scheme KnitGether -destination generic/platform=iOS build CODE_SIGNING_ALLOWED=NO
```

Expected: build succeeds.

- [ ] **Step 5: Check git state**

Run:

```bash
git status --short --branch
```

Expected: clean working tree on `codex/ios-sync-api-project-list`, ahead of origin by the new commits.

- [ ] **Step 6: Push**

Run:

```bash
git push
```

Expected: branch pushes to `origin/codex/ios-sync-api-project-list`.
