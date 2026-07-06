import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { promises as fs } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
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
    await fs.mkdir(join(storageRoot, 'patterns', 'user-a', patternId), {
      recursive: true,
    });
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
    await fs.mkdir(join(storageRoot, 'patterns', 'user-a', patternId), {
      recursive: true,
    });
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
    await expect(fs.access(absoluteFilePath)).rejects.toMatchObject({
      code: 'ENOENT',
    });
  });
});
