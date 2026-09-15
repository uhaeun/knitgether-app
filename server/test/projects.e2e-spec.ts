import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { promises as fs } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import request from 'supertest';
import { Prisma } from '@prisma/client';
import { AppModule } from '../src/app.module';
import { setupApp } from '../src/app.setup';
import { PrismaService } from '../src/database/prisma.service';

type MockPrismaService = {
  userProfile: {
    upsert: jest.Mock;
  };
  project: {
    findMany: jest.Mock;
    findFirst: jest.Mock;
    findFirstOrThrow: jest.Mock;
    count: jest.Mock;
    create: jest.Mock;
    update: jest.Mock;
  };
  rowCounter: {
    findFirst: jest.Mock;
    update: jest.Mock;
    upsert: jest.Mock;
  };
  rowInstruction: {
    findFirst: jest.Mock;
    upsert: jest.Mock;
    update: jest.Mock;
    deleteMany: jest.Mock;
    updateMany: jest.Mock;
    createMany: jest.Mock;
  };
  workSession: {
    findMany: jest.Mock;
    findFirst: jest.Mock;
    upsert: jest.Mock;
    update: jest.Mock;
    deleteMany: jest.Mock;
    updateMany: jest.Mock;
    createMany: jest.Mock;
  };
  projectPatternCopy: {
    findUnique: jest.Mock;
    upsert: jest.Mock;
    create: jest.Mock;
    update: jest.Mock;
    delete: jest.Mock;
    deleteMany: jest.Mock;
    updateMany: jest.Mock;
  };
  patternDocument: {
    findFirst: jest.Mock;
  };
  yarn: {
    findFirst: jest.Mock;
    update: jest.Mock;
  };
  projectYarnUsage: {
    findMany: jest.Mock;
    findFirst: jest.Mock;
    create: jest.Mock;
    update: jest.Mock;
  };
  projectProgressPhoto: {
    findMany: jest.Mock;
    findFirst: jest.Mock;
    create: jest.Mock;
    update: jest.Mock;
    updateMany: jest.Mock;
  };
  $transaction: jest.Mock;
};

describe('Projects route', () => {
  let app: INestApplication;
  let prisma: MockPrismaService;
  let storageRoot: string;

  const userAProject = {
    id: '11111111-1111-4111-8111-111111111111',
    ownerId: 'user-a',
    name: 'Favorite Cardigan',
    status: 'WIP',
    isFavorite: true,
    memo: 'Use smaller needles for ribbing.',
    startDate: new Date('2026-07-01T00:00:00.000Z'),
    targetDate: new Date('2026-08-15T00:00:00.000Z'),
    finishedAt: null,
    lastWorkedAt: new Date('2026-07-03T09:00:00.000Z'),
    yarnId: 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
    yarnNameSnapshot: 'Soft Merino DK',
    yarnBrandSnapshot: 'Sample Yarn Co.',
    yarnColorwaySnapshot: 'Cloud Gray',
    yarnWeightSnapshot: 'DK',
    needleId: 'dddddddd-dddd-4ddd-8ddd-dddddddddddd',
    needleNameSnapshot: 'Wood Circular Needle',
    needleTypeSnapshot: 'Circular',
    needleSizeSnapshot: '5.0 mm',
    needleLengthSnapshot: '80 cm',
    workspaceDisplayMode: 'patternAndCounter',
    workspaceSheetPosition: 'medium',
    relatedSkillIds: ['aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'],
    createdAt: new Date('2026-07-01T00:00:00.000Z'),
    updatedAt: new Date('2026-07-03T09:00:00.000Z'),
    deletedAt: null,
    rowCounter: {
      id: '22222222-2222-4222-8222-222222222222',
      ownerId: 'user-a',
      projectId: '11111111-1111-4111-8111-111111111111',
      name: 'Main Counter',
      mode: 'rowGuide',
      sectionName: 'Sleeve',
      memo: 'Check increases.',
      currentRow: 42,
      targetRow: 120,
      rowInstructions: [
        {
          id: '77777777-7777-4777-8777-777777777777',
          ownerId: 'user-a',
          projectId: '11111111-1111-4111-8111-111111111111',
          rowCounterId: '22222222-2222-4222-8222-222222222222',
          rowNumber: 42,
          instructionText: 'K all stitches.',
          skillTags: 'K',
          createdAt: new Date('2026-07-02T00:00:00.000Z'),
          updatedAt: new Date('2026-07-03T09:00:00.000Z'),
          deletedAt: null,
        },
      ],
      createdAt: new Date('2026-07-01T00:00:00.000Z'),
      updatedAt: new Date('2026-07-03T09:00:00.000Z'),
      deletedAt: null,
    },
    workSessions: [
      {
        id: '33333333-3333-4333-8333-333333333333',
        ownerId: 'user-a',
        projectId: '11111111-1111-4111-8111-111111111111',
        startedAt: new Date('2026-07-03T08:00:00.000Z'),
        endedAt: new Date('2026-07-03T09:00:00.000Z'),
        memo: 'Sleeve increases.',
        createdAt: new Date('2026-07-03T09:00:00.000Z'),
        updatedAt: new Date('2026-07-03T09:00:00.000Z'),
        deletedAt: null,
      },
    ],
  };

  const saveProjectBody = {
    id: '11111111-1111-4111-8111-111111111111',
    name: 'Favorite Cardigan',
    status: 'WIP',
    isFavorite: true,
    memo: 'Use smaller needles for ribbing.',
    startDate: '2026-07-01T00:00:00.000Z',
    targetDate: '2026-08-15T00:00:00.000Z',
    finishedAt: null,
    lastWorkedAt: '2026-07-03T09:00:00.000Z',
    yarnId: 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
    yarnNameSnapshot: 'Soft Merino DK',
    yarnBrandSnapshot: 'Sample Yarn Co.',
    yarnColorwaySnapshot: 'Cloud Gray',
    yarnWeightSnapshot: 'DK',
    needleId: 'dddddddd-dddd-4ddd-8ddd-dddddddddddd',
    needleNameSnapshot: 'Wood Circular Needle',
    needleTypeSnapshot: 'Circular',
    needleSizeSnapshot: '5.0 mm',
    needleLengthSnapshot: '80 cm',
    workspaceDisplayMode: 'patternAndCounter',
    workspaceSheetPosition: 'medium',
    relatedSkillIds: ['aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'],
    rowCounter: {
      id: '22222222-2222-4222-8222-222222222222',
      projectId: '11111111-1111-4111-8111-111111111111',
      name: 'Main Counter',
      mode: 'rowGuide',
      sectionName: 'Sleeve',
      memo: 'Check increases.',
      currentRow: 42,
      targetRow: 120,
      rowInstructions: [
        {
          id: '77777777-7777-4777-8777-777777777777',
          rowCounterId: '22222222-2222-4222-8222-222222222222',
          rowNumber: 42,
          instructionText: 'K all stitches.',
          skillTags: 'K',
        },
      ],
    },
    workSessions: [
      {
        id: '33333333-3333-4333-8333-333333333333',
        projectId: '11111111-1111-4111-8111-111111111111',
        startedAt: '2026-07-03T08:00:00.000Z',
        endedAt: '2026-07-03T09:00:00.000Z',
        memo: 'Sleeve increases.',
      },
    ],
  };

  const projectPatternCopy = {
    id: '66666666-6666-4666-8666-666666666666',
    ownerId: 'user-a',
    projectId: '11111111-1111-4111-8111-111111111111',
    sourcePatternDocumentId: '44444444-4444-4444-8444-444444444444',
    titleSnapshot: 'Cozy Shawl',
    designerSnapshot: 'Yu',
    fileNameSnapshot: 'cozy-shawl.pdf',
    pageCountSnapshot: 12,
    fileStorageKey: null,
    fileContentType: null,
    fileByteSize: null,
    drawingUpdatedAt: null,
    drawingStorageKey: null,
    drawingContentType: null,
    drawingByteSize: null,
    copiedAt: new Date('2026-07-04T12:00:00.000Z'),
    createdAt: new Date('2026-07-04T12:00:00.000Z'),
    updatedAt: new Date('2026-07-05T12:00:00.000Z'),
    deletedAt: null,
    sourcePatternDocument: {
      id: '44444444-4444-4444-8444-444444444444',
      ownerId: 'user-a',
      storedFile: {
        id: '55555555-5555-4555-8555-555555555555',
        ownerId: 'user-a',
        kind: 'patternPdf',
        originalFileName: 'cozy-shawl.pdf',
        contentType: 'application/pdf',
        byteSize: 8,
        storageKey: 'patterns/user-a/44444444-4444-4444-8444-444444444444/55555555-5555-4555-8555-555555555555.pdf',
        createdAt: new Date('2026-07-04T12:00:00.000Z'),
        updatedAt: new Date('2026-07-04T12:00:00.000Z'),
        deletedAt: null,
      },
    },
  };

  const projectPatternCopyWithDirectFile = {
    ...projectPatternCopy,
    sourcePatternDocumentId: null,
    sourcePatternDocument: null,
    fileNameSnapshot: 'direct-cardigan.pdf',
    fileStorageKey:
      'projects/user-a/11111111-1111-4111-8111-111111111111/pattern-copies/66666666-6666-4666-8666-666666666666/direct-cardigan.pdf',
    fileContentType: 'application/pdf',
    fileByteSize: 15,
  };

  const userAProjectWithPatternCopy = {
    ...userAProject,
    patternCopy: projectPatternCopy,
  };

  const projectPatternCopyWithDrawing = {
    ...projectPatternCopy,
    drawingUpdatedAt: new Date('2026-07-05T13:00:00.000Z'),
    drawingStorageKey:
      'projects/user-a/11111111-1111-4111-8111-111111111111/pattern-copies/66666666-6666-4666-8666-666666666666/drawing.pkdrawing',
    drawingContentType: 'application/octet-stream',
    drawingByteSize: 9,
  };

  const userAProjectWithPatternCopyDrawing = {
    ...userAProject,
    patternCopy: projectPatternCopyWithDrawing,
  };

  const activeYarn = {
    id: 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
    ownerId: 'user-a',
    name: 'Soft Merino DK',
    brand: 'Sample Yarn Co.',
    colorway: 'Cloud Gray',
    weight: 'DK',
    quantity: 5,
    notes: 'Reserved for cardigan.',
    createdAt: new Date('2026-07-09T01:00:00.000Z'),
    updatedAt: new Date('2026-07-09T01:05:00.000Z'),
    deletedAt: null,
  };

  const projectYarnUsage = {
    id: '99999999-9999-4999-8999-999999999999',
    ownerId: 'user-a',
    projectId: userAProject.id,
    yarnId: activeYarn.id,
    yarnNameSnapshot: activeYarn.name,
    quantityUsed: 2,
    memo: 'Sleeve swatch',
    usedAt: new Date('2026-07-09T02:00:00.000Z'),
    createdAt: new Date('2026-07-09T02:00:00.000Z'),
    updatedAt: new Date('2026-07-09T02:05:00.000Z'),
    deletedAt: null,
  };

  const saveYarnUsageBody = {
    id: projectYarnUsage.id,
    yarnId: activeYarn.id,
    yarnNameSnapshot: activeYarn.name,
    quantityUsed: 2,
    memo: 'Sleeve swatch',
    usedAt: '2026-07-09T02:00:00.000Z',
  };

  const projectProgressPhoto = {
    id: 'abababab-abab-4aba-8aba-abababababab',
    ownerId: 'user-a',
    projectId: userAProject.id,
    fileName: 'progress.jpg',
    contentType: 'image/jpeg',
    byteSize: 4,
    storageKey:
      'projects/user-a/11111111-1111-4111-8111-111111111111/progress-photos/abababab-abab-4aba-8aba-abababababab/progress.jpg',
    caption: 'Body progress',
    takenAt: new Date('2026-07-09T03:00:00.000Z'),
    createdAt: new Date('2026-07-09T03:00:00.000Z'),
    updatedAt: new Date('2026-07-09T03:05:00.000Z'),
    deletedAt: null,
  };

  const saveProjectWithPatternCopyBody = {
    ...saveProjectBody,
    patternCopy: {
      id: projectPatternCopy.id,
      projectId: saveProjectBody.id,
      sourcePatternDocumentId: projectPatternCopy.sourcePatternDocumentId,
      titleSnapshot: projectPatternCopy.titleSnapshot,
      designerSnapshot: projectPatternCopy.designerSnapshot,
      fileNameSnapshot: projectPatternCopy.fileNameSnapshot,
      localCopyPath: 'Projects/11111111-1111-4111-8111-111111111111/Patterns/66666666-6666-4666-8666-666666666666/cozy-shawl.pdf',
      pageCountSnapshot: projectPatternCopy.pageCountSnapshot,
      drawingDataPath: null,
      drawingUpdatedAt: null,
      copiedAt: '2026-07-04T12:00:00.000Z',
    },
  };

  beforeAll(async () => {
    storageRoot = await fs.mkdtemp(join(tmpdir(), 'knitgether-projects-'));
    process.env.DEV_AUTH_TOKEN = 'dev-token';
    process.env.DEV_AUTH_USER_ID = 'user-a';
    process.env.FILE_STORAGE_ROOT = storageRoot;

    prisma = {
      userProfile: {
        upsert: jest.fn(),
      },
      project: {
        findMany: jest.fn(),
        findFirst: jest.fn(),
        findFirstOrThrow: jest.fn(),
        count: jest.fn(),
        create: jest.fn(),
        update: jest.fn(),
      },
      rowCounter: {
        findFirst: jest.fn(),
        update: jest.fn(),
        upsert: jest.fn(),
      },
      rowInstruction: {
        findFirst: jest.fn(),
        upsert: jest.fn(),
        update: jest.fn(),
        deleteMany: jest.fn(),
        updateMany: jest.fn(),
        createMany: jest.fn(),
      },
      workSession: {
        findMany: jest.fn(),
        findFirst: jest.fn(),
        upsert: jest.fn(),
        update: jest.fn(),
        deleteMany: jest.fn(),
        updateMany: jest.fn(),
        createMany: jest.fn(),
      },
      projectPatternCopy: {
        findUnique: jest.fn(),
        upsert: jest.fn(),
        create: jest.fn(),
        update: jest.fn(),
        delete: jest.fn(),
        deleteMany: jest.fn(),
        updateMany: jest.fn(),
      },
      patternDocument: {
        findFirst: jest.fn(),
      },
      yarn: {
        findFirst: jest.fn(),
        update: jest.fn(),
      },
      projectYarnUsage: {
        findMany: jest.fn(),
        findFirst: jest.fn(),
        create: jest.fn(),
        update: jest.fn(),
      },
      projectProgressPhoto: {
        findMany: jest.fn(),
        findFirst: jest.fn(),
        create: jest.fn(),
        update: jest.fn(),
        updateMany: jest.fn(),
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

  beforeEach(() => {
    prisma.userProfile.upsert.mockReset();
    prisma.project.findMany.mockReset();
    prisma.project.findFirst.mockReset();
    prisma.project.findFirstOrThrow.mockReset();
    prisma.project.count.mockReset();
    prisma.project.create.mockReset();
    prisma.project.update.mockReset();
    prisma.rowCounter.findFirst.mockReset();
    prisma.rowCounter.update.mockReset();
    prisma.rowCounter.upsert.mockReset();
    prisma.rowInstruction.findFirst.mockReset();
    prisma.rowInstruction.upsert.mockReset();
    prisma.rowInstruction.update.mockReset();
    prisma.rowInstruction.deleteMany.mockReset();
    prisma.rowInstruction.updateMany.mockReset();
    prisma.rowInstruction.createMany.mockReset();
    prisma.workSession.findMany.mockReset();
    prisma.workSession.findFirst.mockReset();
    prisma.workSession.upsert.mockReset();
    prisma.workSession.update.mockReset();
    prisma.workSession.deleteMany.mockReset();
    prisma.workSession.updateMany.mockReset();
    prisma.workSession.createMany.mockReset();
    prisma.projectPatternCopy.findUnique.mockReset();
    prisma.projectPatternCopy.upsert.mockReset();
    prisma.projectPatternCopy.create.mockReset();
    prisma.projectPatternCopy.update.mockReset();
    prisma.projectPatternCopy.delete.mockReset();
    prisma.projectPatternCopy.deleteMany.mockReset();
    prisma.projectPatternCopy.updateMany.mockReset();
    prisma.patternDocument.findFirst.mockReset();
    prisma.yarn.findFirst.mockReset();
    prisma.yarn.update.mockReset();
    prisma.projectYarnUsage.findMany.mockReset();
    prisma.projectYarnUsage.findFirst.mockReset();
    prisma.projectYarnUsage.create.mockReset();
    prisma.projectYarnUsage.update.mockReset();
    prisma.projectProgressPhoto.findMany.mockReset();
    prisma.projectProgressPhoto.findFirst.mockReset();
    prisma.projectProgressPhoto.create.mockReset();
    prisma.projectProgressPhoto.update.mockReset();
    prisma.projectProgressPhoto.updateMany.mockReset();
    prisma.$transaction.mockReset();
    prisma.$transaction.mockImplementation(async (callback) => callback(prisma));

    prisma.project.findMany.mockImplementation(async ({ where }) => {
      if (where.ownerId === 'user-a') {
        return [userAProject];
      }

      return [];
    });
    prisma.project.findFirst.mockImplementation(async ({ where }) => {
      if (
        where.id === userAProject.id &&
        where.ownerId === 'user-a' &&
        where.deletedAt === null
      ) {
        return userAProject;
      }

      return null;
    });
    prisma.userProfile.upsert.mockResolvedValue(undefined);
    prisma.project.findFirstOrThrow.mockResolvedValue(userAProject);
    prisma.project.count.mockResolvedValue(1);
    prisma.project.create.mockResolvedValue(userAProject);
    prisma.project.update.mockResolvedValue(userAProject);
    prisma.rowCounter.findFirst.mockResolvedValue(userAProject.rowCounter);
    prisma.rowCounter.update.mockResolvedValue({
      ...userAProject.rowCounter,
      currentRow: 43,
      updatedAt: new Date('2026-07-03T10:00:00.000Z'),
    });
    prisma.rowCounter.upsert.mockResolvedValue(userAProject.rowCounter);
    prisma.rowInstruction.findFirst.mockImplementation(async ({ where }) => {
      if (
        where.id === userAProject.rowCounter.rowInstructions[0].id &&
        where.ownerId === 'user-a' &&
        where.projectId === userAProject.id &&
        where.deletedAt === null
      ) {
        return userAProject.rowCounter.rowInstructions[0];
      }

      if (
        where.rowCounterId === userAProject.rowCounter.id &&
        where.rowNumber === 42 &&
        where.deletedAt === null
      ) {
        return userAProject.rowCounter.rowInstructions[0];
      }

      return null;
    });
    prisma.rowInstruction.upsert.mockImplementation(async ({ create, update }) => ({
      ...userAProject.rowCounter.rowInstructions[0],
      ...create,
      ...update,
      createdAt: new Date('2026-07-02T00:00:00.000Z'),
      updatedAt: new Date('2026-07-03T10:00:00.000Z'),
    }));
    prisma.rowInstruction.update.mockImplementation(async ({ data }) => ({
      ...userAProject.rowCounter.rowInstructions[0],
      ...data,
      updatedAt: new Date('2026-07-03T10:00:00.000Z'),
    }));
    prisma.rowInstruction.deleteMany.mockResolvedValue({ count: 0 });
    prisma.rowInstruction.updateMany.mockResolvedValue({ count: 0 });
    prisma.rowInstruction.createMany.mockResolvedValue({ count: 1 });
    prisma.workSession.findMany.mockResolvedValue(userAProject.workSessions);
    prisma.workSession.findFirst.mockImplementation(async ({ where }) => {
      if (
        where.id === userAProject.workSessions[0].id &&
        where.ownerId === 'user-a' &&
        where.projectId === userAProject.id &&
        where.deletedAt === null
      ) {
        return userAProject.workSessions[0];
      }

      return null;
    });
    prisma.workSession.upsert.mockImplementation(async ({ create, update }) => ({
      ...userAProject.workSessions[0],
      ...create,
      ...update,
      createdAt: new Date('2026-07-03T09:00:00.000Z'),
      updatedAt: new Date('2026-07-03T10:00:00.000Z'),
    }));
    prisma.workSession.update.mockImplementation(async ({ data }) => ({
      ...userAProject.workSessions[0],
      ...data,
      updatedAt: new Date('2026-07-03T10:00:00.000Z'),
    }));
    prisma.workSession.deleteMany.mockResolvedValue({ count: 0 });
    prisma.workSession.updateMany.mockResolvedValue({ count: 0 });
    prisma.workSession.createMany.mockResolvedValue({ count: 1 });
    // 기본값: 기존 복사본 없음(교체 분기 미진입) → upsert 경로로 저장된다.
    prisma.projectPatternCopy.findUnique.mockResolvedValue(null);
    prisma.projectPatternCopy.upsert.mockResolvedValue(projectPatternCopy);
    prisma.projectPatternCopy.create.mockResolvedValue(projectPatternCopy);
    prisma.projectPatternCopy.update.mockResolvedValue(projectPatternCopyWithDrawing);
    prisma.projectPatternCopy.delete.mockResolvedValue(projectPatternCopy);
    prisma.projectPatternCopy.deleteMany.mockResolvedValue({ count: 0 });
    prisma.projectPatternCopy.updateMany.mockResolvedValue({ count: 0 });
    prisma.patternDocument.findFirst.mockResolvedValue(
      projectPatternCopy.sourcePatternDocument,
    );
    prisma.yarn.findFirst.mockResolvedValue(activeYarn);
    prisma.yarn.update.mockResolvedValue({
      ...activeYarn,
      quantity: activeYarn.quantity - projectYarnUsage.quantityUsed,
    });
    prisma.projectYarnUsage.findMany.mockResolvedValue([projectYarnUsage]);
    prisma.projectYarnUsage.findFirst.mockResolvedValue(projectYarnUsage);
    prisma.projectYarnUsage.create.mockResolvedValue(projectYarnUsage);
    prisma.projectYarnUsage.update.mockResolvedValue(projectYarnUsage);
    prisma.projectProgressPhoto.findMany.mockResolvedValue([projectProgressPhoto]);
    prisma.projectProgressPhoto.findFirst.mockResolvedValue(projectProgressPhoto);
    prisma.projectProgressPhoto.create.mockImplementation(async ({ data }) => ({
      ...projectProgressPhoto,
      ...data,
      createdAt: new Date('2026-07-09T03:00:00.000Z'),
      updatedAt: new Date('2026-07-09T03:05:00.000Z'),
      deletedAt: null,
    }));
    prisma.projectProgressPhoto.update.mockImplementation(async ({ data }) => ({
      ...projectProgressPhoto,
      ...data,
      updatedAt: new Date('2026-07-09T03:10:00.000Z'),
    }));
    prisma.projectProgressPhoto.updateMany.mockResolvedValue({ count: 0 });
  });

  afterAll(async () => {
    delete process.env.DEV_AUTH_TOKEN;
    delete process.env.DEV_AUTH_USER_ID;
    delete process.env.FILE_STORAGE_ROOT;
    await app.close();
    await fs.rm(storageRoot, { recursive: true, force: true });
  });

  it('rejects unauthenticated requests', async () => {
    await request(app.getHttpServer())
      .get('/api/v1/projects')
      .expect(401)
      .expect(({ body }) => {
        expect(body.code).toBe('UNAUTHENTICATED');
      });
  });

  it('rejects requests with the wrong token', async () => {
    await request(app.getHttpServer())
      .get('/api/v1/projects')
      .set('Authorization', 'Bearer wrong-token')
      .expect(401)
      .expect(({ body }) => {
        expect(body.code).toBe('UNAUTHENTICATED');
      });
  });

  it('authenticates API tokens as their configured user', async () => {
    process.env.KNITGETHER_API_TOKENS = 'user-a:api-token,user-b:other-token';

    try {
      const response = await request(app.getHttpServer())
        .get('/api/v1/projects')
        .set('Authorization', 'Bearer api-token')
        .expect(200);

      expect(prisma.project.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: {
            ownerId: 'user-a',
            deletedAt: null,
          },
        }),
      );
      expect(response.body[0].ownerId).toBe('user-a');
    } finally {
      delete process.env.KNITGETHER_API_TOKENS;
    }
  });

  it('returns only active projects owned by the current user', async () => {
    const response = await request(app.getHttpServer())
      .get('/api/v1/projects')
      .set('Authorization', 'Bearer dev-token')
      .expect(200);

    expect(prisma.project.findMany).toHaveBeenCalledWith({
      where: {
        ownerId: 'user-a',
        deletedAt: null,
      },
      include: {
        rowCounter: {
          include: {
            rowInstructions: {
              where: {
                ownerId: 'user-a',
                deletedAt: null,
              },
              orderBy: {
                rowNumber: 'asc',
              },
            },
          },
        },
        workSessions: {
          where: {
            ownerId: 'user-a',
            deletedAt: null,
          },
          orderBy: {
            startedAt: 'asc',
          },
        },
        patternCopy: {
          include: {
            sourcePatternDocument: {
              include: {
                storedFile: true,
              },
            },
          },
        },
      },
    });

    expect(response.body).toEqual([
      {
        id: '11111111-1111-4111-8111-111111111111',
        ownerId: 'user-a',
        name: 'Favorite Cardigan',
        status: 'WIP',
        isFavorite: true,
        memo: 'Use smaller needles for ribbing.',
        startDate: '2026-07-01T00:00:00.000Z',
        targetDate: '2026-08-15T00:00:00.000Z',
        finishedAt: null,
        lastWorkedAt: '2026-07-03T09:00:00.000Z',
        yarnId: 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
        yarnNameSnapshot: 'Soft Merino DK',
        yarnBrandSnapshot: 'Sample Yarn Co.',
        yarnColorwaySnapshot: 'Cloud Gray',
        yarnWeightSnapshot: 'DK',
        needleId: 'dddddddd-dddd-4ddd-8ddd-dddddddddddd',
        needleNameSnapshot: 'Wood Circular Needle',
        needleTypeSnapshot: 'Circular',
        needleSizeSnapshot: '5.0 mm',
        needleLengthSnapshot: '80 cm',
        patternCopy: null,
        workspaceDisplayMode: 'patternAndCounter',
        workspaceSheetPosition: 'medium',
        rowCounter: {
          id: '22222222-2222-4222-8222-222222222222',
          ownerId: 'user-a',
          projectId: '11111111-1111-4111-8111-111111111111',
          name: 'Main Counter',
          mode: 'rowGuide',
          sectionName: 'Sleeve',
          memo: 'Check increases.',
          currentRow: 42,
          targetRow: 120,
          rowInstructions: [
            {
              id: '77777777-7777-4777-8777-777777777777',
              ownerId: 'user-a',
              projectId: '11111111-1111-4111-8111-111111111111',
              rowCounterId: '22222222-2222-4222-8222-222222222222',
              rowNumber: 42,
              instructionText: 'K all stitches.',
              skillTags: 'K',
              createdAt: '2026-07-02T00:00:00.000Z',
              updatedAt: '2026-07-03T09:00:00.000Z',
              deletedAt: null,
              syncStatus: 'Synced',
            },
          ],
          createdAt: '2026-07-01T00:00:00.000Z',
          updatedAt: '2026-07-03T09:00:00.000Z',
          deletedAt: null,
          syncStatus: 'Synced',
        },
        workSessions: [
          {
            id: '33333333-3333-4333-8333-333333333333',
            ownerId: 'user-a',
            projectId: '11111111-1111-4111-8111-111111111111',
            startedAt: '2026-07-03T08:00:00.000Z',
            endedAt: '2026-07-03T09:00:00.000Z',
            memo: 'Sleeve increases.',
            createdAt: '2026-07-03T09:00:00.000Z',
            updatedAt: '2026-07-03T09:00:00.000Z',
            deletedAt: null,
            syncStatus: 'Synced',
          },
        ],
        relatedSkillIds: ['aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'],
        createdAt: '2026-07-01T00:00:00.000Z',
        updatedAt: '2026-07-03T09:00:00.000Z',
        deletedAt: null,
        syncStatus: 'Synced',
      },
    ]);
  });

  it('returns one active project owned by the current user', async () => {
    const response = await request(app.getHttpServer())
      .get('/api/v1/projects/11111111-1111-4111-8111-111111111111')
      .set('Authorization', 'Bearer dev-token')
      .expect(200);

    expect(prisma.project.findFirst).toHaveBeenCalledWith({
      where: {
        id: '11111111-1111-4111-8111-111111111111',
        ownerId: 'user-a',
        deletedAt: null,
      },
      include: {
        rowCounter: {
          include: {
            rowInstructions: {
              where: {
                ownerId: 'user-a',
                deletedAt: null,
              },
              orderBy: {
                rowNumber: 'asc',
              },
            },
          },
        },
        workSessions: {
          where: {
            ownerId: 'user-a',
            deletedAt: null,
          },
          orderBy: {
            startedAt: 'asc',
          },
        },
        patternCopy: {
          include: {
            sourcePatternDocument: {
              include: {
                storedFile: true,
              },
            },
          },
        },
      },
    });
    expect(response.body.id).toBe('11111111-1111-4111-8111-111111111111');
    expect(response.body.name).toBe('Favorite Cardigan');
    expect(response.body.syncStatus).toBe('Synced');
  });

  it('updates only a project row counter through the partial API', async () => {
    const response = await request(app.getHttpServer())
      .patch(`/api/v1/projects/${userAProject.id}/row-counter`)
      .set('Authorization', 'Bearer dev-token')
      .send({
        ...saveProjectBody.rowCounter,
        currentRow: 43,
      })
      .expect(200);

    expect(prisma.project.findFirst).toHaveBeenCalledWith({
      where: {
        id: userAProject.id,
        ownerId: 'user-a',
        deletedAt: null,
      },
    });
    expect(prisma.rowCounter.update).toHaveBeenCalledWith({
      where: {
        projectId: userAProject.id,
      },
      data: {
        ownerId: 'user-a',
        name: 'Main Counter',
        mode: 'rowGuide',
        sectionName: 'Sleeve',
        memo: 'Check increases.',
        currentRow: 43,
        targetRow: 120,
        deletedAt: null,
      },
      include: {
        rowInstructions: {
          where: {
            ownerId: 'user-a',
            deletedAt: null,
          },
          orderBy: {
            rowNumber: 'asc',
          },
        },
      },
    });
    expect(prisma.rowInstruction.deleteMany).not.toHaveBeenCalled();
    expect(prisma.workSession.deleteMany).not.toHaveBeenCalled();
    expect(response.body.currentRow).toBe(43);
    expect(response.body.rowInstructions).toHaveLength(1);
  });

  it('upserts one row instruction through the partial API', async () => {
    const response = await request(app.getHttpServer())
      .post(`/api/v1/projects/${userAProject.id}/row-instructions`)
      .set('Authorization', 'Bearer dev-token')
      .send({
        id: '88888888-8888-4888-8888-888888888888',
        rowCounterId: userAProject.rowCounter.id,
        rowNumber: 50,
        instructionText: 'P all stitches.',
        skillTags: 'P',
      })
      .expect(201);

    expect(prisma.rowInstruction.upsert).toHaveBeenCalledWith({
      where: {
        id: '88888888-8888-4888-8888-888888888888',
      },
      create: {
        id: '88888888-8888-4888-8888-888888888888',
        ownerId: 'user-a',
        projectId: userAProject.id,
        rowCounterId: userAProject.rowCounter.id,
        rowNumber: 50,
        instructionText: 'P all stitches.',
        skillTags: 'P',
        deletedAt: null,
      },
      update: {
        ownerId: 'user-a',
        projectId: userAProject.id,
        rowCounterId: userAProject.rowCounter.id,
        rowNumber: 50,
        instructionText: 'P all stitches.',
        skillTags: 'P',
        deletedAt: null,
      },
    });
    expect(prisma.rowInstruction.deleteMany).not.toHaveBeenCalled();
    expect(response.body.rowNumber).toBe(50);
    expect(response.body.instructionText).toBe('P all stitches.');
  });

  it('updates one work session through the partial API', async () => {
    const response = await request(app.getHttpServer())
      .patch(
        `/api/v1/projects/${userAProject.id}/work-sessions/${userAProject.workSessions[0].id}`,
      )
      .set('Authorization', 'Bearer dev-token')
      .send({
        ...saveProjectBody.workSessions[0],
        memo: 'Updated sleeve notes.',
      })
      .expect(200);

    expect(prisma.workSession.update).toHaveBeenCalledWith({
      where: {
        id: userAProject.workSessions[0].id,
      },
      data: {
        ownerId: 'user-a',
        projectId: userAProject.id,
        startedAt: new Date('2026-07-03T08:00:00.000Z'),
        endedAt: new Date('2026-07-03T09:00:00.000Z'),
        memo: 'Updated sleeve notes.',
        deletedAt: null,
      },
    });
    expect(prisma.workSession.deleteMany).not.toHaveBeenCalled();
    expect(response.body.memo).toBe('Updated sleeve notes.');
  });

  it('lists yarn usage records for an owned project', async () => {
    const response = await request(app.getHttpServer())
      .get(`/api/v1/projects/${userAProject.id}/yarn-usages`)
      .set('Authorization', 'Bearer dev-token')
      .expect(200);

    expect(prisma.project.findFirst).toHaveBeenCalledWith({
      where: {
        id: userAProject.id,
        ownerId: 'user-a',
        deletedAt: null,
      },
    });
    expect(prisma.projectYarnUsage.findMany).toHaveBeenCalledWith({
      where: {
        ownerId: 'user-a',
        projectId: userAProject.id,
        deletedAt: null,
      },
      orderBy: {
        usedAt: 'desc',
      },
    });
    expect(response.body).toEqual([expectedProjectYarnUsageResponse()]);
  });

  it('records yarn usage and decrements the owned yarn quantity', async () => {
    const response = await request(app.getHttpServer())
      .post(`/api/v1/projects/${userAProject.id}/yarn-usages`)
      .set('Authorization', 'Bearer dev-token')
      .send(saveYarnUsageBody)
      .expect(201);

    expect(prisma.project.findFirst).toHaveBeenCalledWith({
      where: {
        id: userAProject.id,
        ownerId: 'user-a',
        deletedAt: null,
      },
    });
    expect(prisma.yarn.findFirst).toHaveBeenCalledWith({
      where: {
        id: activeYarn.id,
        ownerId: 'user-a',
        deletedAt: null,
      },
    });
    expect(prisma.yarn.update).toHaveBeenCalledWith({
      where: { id: activeYarn.id },
      data: {
        quantity: activeYarn.quantity - saveYarnUsageBody.quantityUsed,
      },
    });
    expect(prisma.projectYarnUsage.create).toHaveBeenCalledWith({
      data: expect.objectContaining({
        id: projectYarnUsage.id,
        ownerId: 'user-a',
        projectId: userAProject.id,
        yarnId: activeYarn.id,
        yarnNameSnapshot: activeYarn.name,
        quantityUsed: 2,
        memo: 'Sleeve swatch',
        usedAt: new Date(saveYarnUsageBody.usedAt),
        deletedAt: null,
      }),
    });
    expect(response.body).toEqual(expectedProjectYarnUsageResponse());
  });

  it('updates yarn usage and adjusts only the quantity delta', async () => {
    const updatedUsage = {
      ...projectYarnUsage,
      quantityUsed: 3,
      memo: 'Body section',
      updatedAt: new Date('2026-07-09T03:00:00.000Z'),
    };
    prisma.projectYarnUsage.update.mockResolvedValueOnce(updatedUsage);

    const response = await request(app.getHttpServer())
      .patch(`/api/v1/projects/${userAProject.id}/yarn-usages/${projectYarnUsage.id}`)
      .set('Authorization', 'Bearer dev-token')
      .send({
        ...saveYarnUsageBody,
        quantityUsed: 3,
        memo: 'Body section',
      })
      .expect(200);

    expect(prisma.projectYarnUsage.findFirst).toHaveBeenCalledWith({
      where: {
        id: projectYarnUsage.id,
        ownerId: 'user-a',
        projectId: userAProject.id,
        deletedAt: null,
      },
    });
    expect(prisma.yarn.update).toHaveBeenCalledWith({
      where: { id: activeYarn.id },
      data: {
        quantity: activeYarn.quantity - 1,
      },
    });
    expect(prisma.projectYarnUsage.update).toHaveBeenCalledWith({
      where: { id: projectYarnUsage.id },
      data: expect.objectContaining({
        yarnId: activeYarn.id,
        yarnNameSnapshot: activeYarn.name,
        quantityUsed: 3,
        memo: 'Body section',
      }),
    });
    expect(response.body.quantityUsed).toBe(3);
    expect(response.body.memo).toBe('Body section');
  });

  it('soft deletes yarn usage and restores the consumed yarn quantity', async () => {
    const deletedUsage = {
      ...projectYarnUsage,
      deletedAt: new Date('2026-07-09T03:00:00.000Z'),
      updatedAt: new Date('2026-07-09T03:00:00.000Z'),
    };
    prisma.projectYarnUsage.update.mockResolvedValueOnce(deletedUsage);

    await request(app.getHttpServer())
      .delete(`/api/v1/projects/${userAProject.id}/yarn-usages/${projectYarnUsage.id}`)
      .set('Authorization', 'Bearer dev-token')
      .expect(204);

    expect(prisma.projectYarnUsage.findFirst).toHaveBeenCalledWith({
      where: {
        id: projectYarnUsage.id,
        ownerId: 'user-a',
        projectId: userAProject.id,
        deletedAt: null,
      },
    });
    expect(prisma.yarn.update).toHaveBeenCalledWith({
      where: { id: activeYarn.id },
      data: {
        quantity: activeYarn.quantity + projectYarnUsage.quantityUsed,
      },
    });
    expect(prisma.projectYarnUsage.update).toHaveBeenCalledWith({
      where: { id: projectYarnUsage.id },
      data: {
        deletedAt: expect.any(Date),
      },
    });
  });

  it('soft deletes yarn usage without restoring quantity when the linked yarn is already deleted', async () => {
    prisma.yarn.findFirst.mockResolvedValueOnce(null);

    await request(app.getHttpServer())
      .delete(`/api/v1/projects/${userAProject.id}/yarn-usages/${projectYarnUsage.id}`)
      .set('Authorization', 'Bearer dev-token')
      .expect(204);

    expect(prisma.yarn.update).not.toHaveBeenCalled();
    expect(prisma.projectYarnUsage.update).toHaveBeenCalledWith({
      where: { id: projectYarnUsage.id },
      data: {
        deletedAt: expect.any(Date),
      },
    });
  });

  it('lists progress photos for an owned project', async () => {
    const response = await request(app.getHttpServer())
      .get(`/api/v1/projects/${userAProject.id}/progress-photos`)
      .set('Authorization', 'Bearer dev-token')
      .expect(200);

    expect(prisma.project.findFirst).toHaveBeenCalledWith({
      where: {
        id: userAProject.id,
        ownerId: 'user-a',
        deletedAt: null,
      },
    });
    expect(prisma.projectProgressPhoto.findMany).toHaveBeenCalledWith({
      where: {
        ownerId: 'user-a',
        projectId: userAProject.id,
        deletedAt: null,
      },
      orderBy: {
        takenAt: 'desc',
      },
    });
    expect(response.body).toEqual([expectedProjectProgressPhotoResponse()]);
  });

  it('uploads a progress photo for an owned project', async () => {
    const response = await request(app.getHttpServer())
      .post(`/api/v1/projects/${userAProject.id}/progress-photos`)
      .set('Authorization', 'Bearer dev-token')
      .field('id', projectProgressPhoto.id)
      .field('caption', '  Body progress  ')
      .field('takenAt', '2026-07-09T03:00:00.000Z')
      .attach('file', Buffer.from([1, 2, 3, 4]), {
        filename: 'progress.jpg',
        contentType: 'image/jpeg',
      })
      .expect(201);

    expect(prisma.projectProgressPhoto.create).toHaveBeenCalledWith({
      data: expect.objectContaining({
        id: projectProgressPhoto.id,
        ownerId: 'user-a',
        projectId: userAProject.id,
        fileName: 'progress.jpg',
        contentType: 'image/jpeg',
        byteSize: 4,
        caption: 'Body progress',
        takenAt: new Date('2026-07-09T03:00:00.000Z'),
        deletedAt: null,
      }),
    });
    expect(response.body).toEqual(expectedProjectProgressPhotoResponse());
  });

  it('rejects non-image progress photo uploads', async () => {
    await request(app.getHttpServer())
      .post(`/api/v1/projects/${userAProject.id}/progress-photos`)
      .set('Authorization', 'Bearer dev-token')
      .attach('file', Buffer.from('not-image'), {
        filename: 'notes.txt',
        contentType: 'text/plain',
      })
      .expect(400)
      .expect(({ body }) => {
        expect(body.code).toBe('PROJECT_PROGRESS_PHOTO_UNSUPPORTED');
      });
  });

  it('updates progress photo metadata', async () => {
    const updatedPhoto = {
      ...projectProgressPhoto,
      caption: 'Blocked body',
      takenAt: new Date('2026-07-10T03:00:00.000Z'),
      updatedAt: new Date('2026-07-10T03:05:00.000Z'),
    };
    prisma.projectProgressPhoto.update.mockResolvedValueOnce(updatedPhoto);

    const response = await request(app.getHttpServer())
      .patch(`/api/v1/projects/${userAProject.id}/progress-photos/${projectProgressPhoto.id}`)
      .set('Authorization', 'Bearer dev-token')
      .send({
        caption: '  Blocked body  ',
        takenAt: '2026-07-10T03:00:00.000Z',
      })
      .expect(200);

    expect(prisma.projectProgressPhoto.findFirst).toHaveBeenCalledWith({
      where: {
        id: projectProgressPhoto.id,
        ownerId: 'user-a',
        projectId: userAProject.id,
        deletedAt: null,
      },
    });
    expect(prisma.projectProgressPhoto.update).toHaveBeenCalledWith({
      where: { id: projectProgressPhoto.id },
      data: {
        caption: 'Blocked body',
        takenAt: new Date('2026-07-10T03:00:00.000Z'),
      },
    });
    expect(response.body.caption).toBe('Blocked body');
    expect(response.body.takenAt).toBe('2026-07-10T03:00:00.000Z');
  });

  it('downloads progress photo bytes', async () => {
    const photoBytes = Buffer.from([8, 6, 7, 5]);
    const filePath = join(storageRoot, projectProgressPhoto.storageKey);
    await fs.mkdir(dirname(filePath), { recursive: true });
    await fs.writeFile(filePath, photoBytes);

    const response = await request(app.getHttpServer())
      .get(`/api/v1/projects/${userAProject.id}/progress-photos/${projectProgressPhoto.id}/file`)
      .set('Authorization', 'Bearer dev-token')
      .expect(200);

    expect(Buffer.from(response.body)).toEqual(photoBytes);
    expect(response.header['content-type']).toContain('image/jpeg');
    expect(response.header['content-disposition']).toContain('progress.jpg');
  });

  it('deletes a progress photo and removes its stored file', async () => {
    const filePath = join(storageRoot, projectProgressPhoto.storageKey);
    await fs.mkdir(dirname(filePath), { recursive: true });
    await fs.writeFile(filePath, Buffer.from([1, 1, 1]));

    await request(app.getHttpServer())
      .delete(`/api/v1/projects/${userAProject.id}/progress-photos/${projectProgressPhoto.id}`)
      .set('Authorization', 'Bearer dev-token')
      .expect(204);

    await expect(fs.access(filePath)).rejects.toThrow();
    expect(prisma.projectProgressPhoto.update).toHaveBeenCalledWith({
      where: { id: projectProgressPhoto.id },
      data: {
        deletedAt: expect.any(Date),
      },
    });
  });

  it('returns project pattern copy metadata with projects', async () => {
    prisma.project.findMany.mockResolvedValueOnce([userAProjectWithPatternCopy]);

    const response = await request(app.getHttpServer())
      .get('/api/v1/projects')
      .set('Authorization', 'Bearer dev-token')
      .expect(200);

    expect(prisma.project.findMany).toHaveBeenCalledWith({
      where: {
        ownerId: 'user-a',
        deletedAt: null,
      },
      include: {
        rowCounter: {
          include: {
            rowInstructions: {
              where: {
                ownerId: 'user-a',
                deletedAt: null,
              },
              orderBy: {
                rowNumber: 'asc',
              },
            },
          },
        },
        workSessions: {
          where: {
            ownerId: 'user-a',
            deletedAt: null,
          },
          orderBy: {
            startedAt: 'asc',
          },
        },
        patternCopy: {
          include: {
            sourcePatternDocument: {
              include: {
                storedFile: true,
              },
            },
          },
        },
      },
    });
    expect(response.body[0].patternCopy).toEqual({
      id: projectPatternCopy.id,
      ownerId: 'user-a',
      projectId: userAProject.id,
      sourcePatternDocumentId: projectPatternCopy.sourcePatternDocumentId,
      titleSnapshot: 'Cozy Shawl',
      designerSnapshot: 'Yu',
      fileNameSnapshot: 'cozy-shawl.pdf',
      localCopyPath: null,
      pageCountSnapshot: 12,
      drawingDataPath: null,
      drawingUpdatedAt: null,
      copiedAt: '2026-07-04T12:00:00.000Z',
      createdAt: '2026-07-04T12:00:00.000Z',
      updatedAt: '2026-07-05T12:00:00.000Z',
      deletedAt: null,
      syncStatus: 'Synced',
    });
  });

  it('downloads the active project pattern copy PDF', async () => {
    const pdfBytes = Buffer.from('%PDF-1.4');
    const filePath = join(
      storageRoot,
      projectPatternCopy.sourcePatternDocument.storedFile.storageKey,
    );
    await fs.mkdir(dirname(filePath), { recursive: true });
    await fs.writeFile(filePath, pdfBytes);
    prisma.project.findFirst.mockResolvedValueOnce(userAProjectWithPatternCopy);

    const response = await request(app.getHttpServer())
      .get(`/api/v1/projects/${userAProject.id}/pattern-copy/file`)
      .set('Authorization', 'Bearer dev-token')
      .expect(200)
      .expect('Content-Type', /application\/pdf/);

    expect(Buffer.from(response.body)).toEqual(pdfBytes);
    expect(response.header['content-disposition']).toContain('cozy-shawl.pdf');
  });

  it('uploads a directly attached project pattern copy PDF', async () => {
    const directPatternCopyWithoutFile = {
      ...projectPatternCopyWithDirectFile,
      fileStorageKey: null,
      fileContentType: null,
      fileByteSize: null,
    };
    prisma.project.findFirst.mockResolvedValueOnce({
      ...userAProject,
      patternCopy: directPatternCopyWithoutFile,
    });
    prisma.projectPatternCopy.update.mockImplementationOnce(({ data }) => ({
      ...directPatternCopyWithoutFile,
      ...data,
      updatedAt: new Date('2026-07-05T13:00:00.000Z'),
    }));

    const response = await request(app.getHttpServer())
      .post(`/api/v1/projects/${userAProject.id}/pattern-copy/file`)
      .set('Authorization', 'Bearer dev-token')
      .attach('file', Buffer.from('%PDF-1.4 direct'), {
        filename: 'direct-cardigan.pdf',
        contentType: 'application/pdf',
      })
      .expect(201);

    expect(response.body.sourcePatternDocumentId).toBeNull();
    expect(response.body.fileNameSnapshot).toBe('direct-cardigan.pdf');
    expect(prisma.projectPatternCopy.update).toHaveBeenCalledWith(
      expect.objectContaining({
        where: {
          id: projectPatternCopy.id,
        },
        data: expect.objectContaining({
          fileNameSnapshot: 'direct-cardigan.pdf',
          fileStorageKey: expect.stringContaining(
            'projects/user-a/11111111-1111-4111-8111-111111111111/pattern-copies/66666666-6666-4666-8666-666666666666/',
          ),
          fileContentType: 'application/pdf',
          fileByteSize: Buffer.byteLength('%PDF-1.4 direct'),
        }),
      }),
    );
    const updateInput = prisma.projectPatternCopy.update.mock.calls[0][0];
    const storedFilePath = join(storageRoot, updateInput.data.fileStorageKey);
    expect(await fs.readFile(storedFilePath)).toEqual(
      Buffer.from('%PDF-1.4 direct'),
    );
  });

  it('downloads a directly attached project pattern copy PDF', async () => {
    const pdfBytes = Buffer.from('%PDF-1.4 direct');
    const filePath = join(
      storageRoot,
      projectPatternCopyWithDirectFile.fileStorageKey,
    );
    await fs.mkdir(dirname(filePath), { recursive: true });
    await fs.writeFile(filePath, pdfBytes);
    prisma.project.findFirst.mockResolvedValueOnce({
      ...userAProject,
      patternCopy: projectPatternCopyWithDirectFile,
    });

    const response = await request(app.getHttpServer())
      .get(`/api/v1/projects/${userAProject.id}/pattern-copy/file`)
      .set('Authorization', 'Bearer dev-token')
      .expect(200)
      .expect('Content-Type', /application\/pdf/);

    expect(Buffer.from(response.body)).toEqual(pdfBytes);
    expect(response.header['content-disposition']).toContain(
      'direct-cardigan.pdf',
    );
  });

  it('uploads drawing data for the active project pattern copy', async () => {
    prisma.project.findFirst.mockResolvedValueOnce(userAProjectWithPatternCopy);
    prisma.projectPatternCopy.update.mockResolvedValueOnce(projectPatternCopyWithDrawing);

    const response = await request(app.getHttpServer())
      .post(`/api/v1/projects/${userAProject.id}/pattern-copy/drawing`)
      .set('Authorization', 'Bearer dev-token')
      .attach('file', Buffer.from('PKDRAWING'), {
        filename: 'drawing.pkdrawing',
        contentType: 'application/octet-stream',
      })
      .expect(201);

    expect(prisma.projectPatternCopy.update).toHaveBeenCalledWith({
      where: {
        id: projectPatternCopy.id,
      },
      data: expect.objectContaining({
        drawingStorageKey:
          'projects/user-a/11111111-1111-4111-8111-111111111111/pattern-copies/66666666-6666-4666-8666-666666666666/drawing.pkdrawing',
        drawingContentType: 'application/octet-stream',
        drawingByteSize: 9,
        drawingUpdatedAt: expect.any(Date),
      }),
      include: expect.any(Object),
    });
    expect(response.body.drawingUpdatedAt).toBe('2026-07-05T13:00:00.000Z');

    const storedDrawing = await fs.readFile(
      join(
        storageRoot,
        'projects/user-a/11111111-1111-4111-8111-111111111111/pattern-copies/66666666-6666-4666-8666-666666666666/drawing.pkdrawing',
      ),
    );
    expect(storedDrawing).toEqual(Buffer.from('PKDRAWING'));
  });

  it('downloads drawing data for the active project pattern copy', async () => {
    const drawingBytes = Buffer.from('PKDRAWING');
    const filePath = join(
      storageRoot,
      projectPatternCopyWithDrawing.drawingStorageKey,
    );
    await fs.mkdir(dirname(filePath), { recursive: true });
    await fs.writeFile(filePath, drawingBytes);
    prisma.project.findFirst.mockResolvedValueOnce(
      userAProjectWithPatternCopyDrawing,
    );

    const response = await request(app.getHttpServer())
      .get(`/api/v1/projects/${userAProject.id}/pattern-copy/drawing`)
      .set('Authorization', 'Bearer dev-token')
      .expect(200)
      .expect('Content-Type', /application\/octet-stream/);

    expect(Buffer.from(response.body)).toEqual(drawingBytes);
    expect(response.header['content-disposition']).toContain('drawing.pkdrawing');
  });

  it('returns 404 when a project is missing or not owned by the current user', async () => {
    await request(app.getHttpServer())
      .get('/api/v1/projects/99999999-9999-9999-9999-999999999999')
      .set('Authorization', 'Bearer dev-token')
      .expect(404)
      .expect(({ body }) => {
        expect(body.code).toBe('PROJECT_NOT_FOUND');
      });
  });

  it('creates a project with row counter and work sessions', async () => {
    const response = await request(app.getHttpServer())
      .post('/api/v1/projects')
      .set('Authorization', 'Bearer dev-token')
      .send(saveProjectBody)
      .expect(201);

    expect(prisma.userProfile.upsert).toHaveBeenCalledWith({
      where: { id: 'user-a' },
      create: {
        id: 'user-a',
        displayName: 'user-a',
      },
      update: {},
    });
    expect(prisma.project.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          id: saveProjectBody.id,
          ownerId: 'user-a',
          name: saveProjectBody.name,
          status: saveProjectBody.status,
          yarnId: saveProjectBody.yarnId,
          yarnNameSnapshot: saveProjectBody.yarnNameSnapshot,
          yarnBrandSnapshot: saveProjectBody.yarnBrandSnapshot,
          yarnColorwaySnapshot: saveProjectBody.yarnColorwaySnapshot,
          yarnWeightSnapshot: saveProjectBody.yarnWeightSnapshot,
          needleId: saveProjectBody.needleId,
          needleNameSnapshot: saveProjectBody.needleNameSnapshot,
          needleTypeSnapshot: saveProjectBody.needleTypeSnapshot,
          needleSizeSnapshot: saveProjectBody.needleSizeSnapshot,
          needleLengthSnapshot: saveProjectBody.needleLengthSnapshot,
          targetDate: new Date(saveProjectBody.targetDate),
          finishedAt: null,
        }),
        include: expect.any(Object),
      }),
    );
    expect(prisma.rowCounter.upsert).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { projectId: saveProjectBody.id },
        create: expect.objectContaining({
          id: saveProjectBody.rowCounter.id,
          ownerId: 'user-a',
          projectId: saveProjectBody.id,
          currentRow: saveProjectBody.rowCounter.currentRow,
        }),
      }),
    );
    expect(prisma.workSession.deleteMany).not.toHaveBeenCalled();
    expect(prisma.workSession.createMany).not.toHaveBeenCalled();
    expect(prisma.workSession.upsert).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: saveProjectBody.workSessions[0].id },
        create: expect.objectContaining({
          id: saveProjectBody.workSessions[0].id,
          ownerId: 'user-a',
          projectId: saveProjectBody.id,
          memo: saveProjectBody.workSessions[0].memo,
        }),
      }),
    );
    expect(response.body.id).toBe(saveProjectBody.id);
  });

  it('rejects a project when the row counter belongs to a different project', async () => {
    await request(app.getHttpServer())
      .post('/api/v1/projects')
      .set('Authorization', 'Bearer dev-token')
      .send({
        ...saveProjectBody,
        rowCounter: {
          ...saveProjectBody.rowCounter,
          projectId: '99999999-9999-4999-8999-999999999999',
        },
      })
      .expect(400)
      .expect(({ body }) => {
        expect(body.code).toBe('VALIDATION_FAILED');
      });

    expect(prisma.project.create).not.toHaveBeenCalled();
    expect(prisma.rowCounter.upsert).not.toHaveBeenCalled();
  });

  it('rejects a project when a work session belongs to a different project', async () => {
    await request(app.getHttpServer())
      .post('/api/v1/projects')
      .set('Authorization', 'Bearer dev-token')
      .send({
        ...saveProjectBody,
        workSessions: [
          {
            ...saveProjectBody.workSessions[0],
            projectId: '99999999-9999-4999-8999-999999999999',
          },
        ],
      })
      .expect(400)
      .expect(({ body }) => {
        expect(body.code).toBe('VALIDATION_FAILED');
      });

    expect(prisma.project.create).not.toHaveBeenCalled();
    expect(prisma.workSession.createMany).not.toHaveBeenCalled();
  });

  it('saves a project pattern copy with the project', async () => {
    prisma.project.findFirstOrThrow.mockResolvedValueOnce(userAProjectWithPatternCopy);

    // 창고 원본의 물리 파일을 준비한다. 저장 시 서버가 이 파일을 복사본으로
    // 물리 복사해 파일 키를 채워야 한다(결함 19/38).
    const sourceStorageKey = projectPatternCopy.sourcePatternDocument.storedFile.storageKey;
    const sourcePdfBytes = Buffer.from('%PDF-1.4\n% source pattern');
    await fs.mkdir(dirname(join(storageRoot, sourceStorageKey)), { recursive: true });
    await fs.writeFile(join(storageRoot, sourceStorageKey), sourcePdfBytes);

    await request(app.getHttpServer())
      .post('/api/v1/projects')
      .set('Authorization', 'Bearer dev-token')
      .send(saveProjectWithPatternCopyBody)
      .expect(201);

    expect(prisma.patternDocument.findFirst).toHaveBeenCalledWith({
      where: {
        id: projectPatternCopy.sourcePatternDocumentId,
        ownerId: 'user-a',
        deletedAt: null,
      },
      include: {
        storedFile: true,
      },
    });
    expect(prisma.projectPatternCopy.upsert).toHaveBeenCalledWith({
      where: {
        projectId: saveProjectBody.id,
      },
      create: expect.objectContaining({
        id: projectPatternCopy.id,
        ownerId: 'user-a',
        projectId: saveProjectBody.id,
        sourcePatternDocumentId: projectPatternCopy.sourcePatternDocumentId,
        titleSnapshot: 'Cozy Shawl',
        fileNameSnapshot: 'cozy-shawl.pdf',
        fileStorageKey: expect.stringContaining('pattern-copies'),
        fileContentType: 'application/pdf',
        fileByteSize: sourcePdfBytes.byteLength,
        deletedAt: null,
      }),
      update: expect.objectContaining({
        ownerId: 'user-a',
        sourcePatternDocumentId: projectPatternCopy.sourcePatternDocumentId,
        titleSnapshot: 'Cozy Shawl',
        fileNameSnapshot: 'cozy-shawl.pdf',
        deletedAt: null,
      }),
    });
  });

  it('updates an active project owned by the current user', async () => {
    const response = await request(app.getHttpServer())
      .patch('/api/v1/projects/11111111-1111-4111-8111-111111111111')
      .set('Authorization', 'Bearer dev-token')
      // 수정에는 낙관적 잠금 기준값이 필수다(GitHub #14).
      .send({ ...saveProjectBody, baseUpdatedAt: userAProject.updatedAt.toISOString() })
      .expect(200);

    expect(prisma.project.findFirst).toHaveBeenCalledWith({
      where: {
        id: saveProjectBody.id,
        ownerId: 'user-a',
        deletedAt: null,
      },
      include: expect.any(Object),
    });
    expect(prisma.project.update).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: saveProjectBody.id },
        data: expect.objectContaining({
          ownerId: 'user-a',
          name: saveProjectBody.name,
          status: saveProjectBody.status,
          isFavorite: saveProjectBody.isFavorite,
          targetDate: new Date(saveProjectBody.targetDate),
          finishedAt: null,
        }),
        include: expect.any(Object),
      }),
    );
    expect(response.body.name).toBe(saveProjectBody.name);
  });

  it('reconciles project children from the full patch payload', async () => {
    await request(app.getHttpServer())
      .patch('/api/v1/projects/11111111-1111-4111-8111-111111111111')
      .set('Authorization', 'Bearer dev-token')
      .send({
        ...saveProjectBody,
        name: 'Favorite Cardigan Offline',
        rowCounter: {
          ...saveProjectBody.rowCounter,
          currentRow: 48,
          targetRow: 140,
          rowInstructions: [],
        },
        workSessions: [],
        baseUpdatedAt: userAProject.updatedAt.toISOString(),
      })
      .expect(200);

    expect(prisma.project.update).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: saveProjectBody.id },
        data: expect.objectContaining({
          name: 'Favorite Cardigan Offline',
        }),
      }),
    );
    expect(prisma.rowCounter.upsert).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { projectId: saveProjectBody.id },
        update: expect.objectContaining({
          currentRow: 48,
          targetRow: 140,
        }),
      }),
    );
    expect(prisma.rowInstruction.deleteMany).toHaveBeenCalledWith({
      where: {
        ownerId: 'user-a',
        projectId: saveProjectBody.id,
        rowCounterId: saveProjectBody.rowCounter.id,
      },
    });
    expect(prisma.rowInstruction.createMany).not.toHaveBeenCalled();
    // SYNC-08: 요청 본문에 세션이 없어도 기존 세션은 보존한다.
    // 삭제는 전용 DELETE 엔드포인트만 수행한다.
    expect(prisma.workSession.deleteMany).not.toHaveBeenCalled();
    expect(prisma.workSession.upsert).not.toHaveBeenCalled();
    expect(prisma.workSession.createMany).not.toHaveBeenCalled();
  });

  it('soft-deletes an active project owned by the current user', async () => {
    await request(app.getHttpServer())
      .delete('/api/v1/projects/11111111-1111-4111-8111-111111111111')
      .set('Authorization', 'Bearer dev-token')
      .expect(204);

    expect(prisma.project.findFirst).toHaveBeenCalledWith({
      where: {
        id: userAProject.id,
        ownerId: 'user-a',
        deletedAt: null,
      },
      include: expect.any(Object),
    });
    expect(prisma.project.update).toHaveBeenCalledWith({
      where: { id: userAProject.id },
      data: expect.objectContaining({
        deletedAt: expect.any(Date),
        rowCounter: {
          update: {
            deletedAt: expect.any(Date),
          },
        },
      }),
    });
    expect(prisma.workSession.updateMany).toHaveBeenCalledWith({
      where: {
        ownerId: 'user-a',
        projectId: userAProject.id,
      },
      data: {
        deletedAt: expect.any(Date),
      },
    });
  });

  it('returns 404 when deleting a missing project', async () => {
    await request(app.getHttpServer())
      .delete('/api/v1/projects/99999999-9999-4999-8999-999999999999')
      .set('Authorization', 'Bearer dev-token')
      .expect(404)
      .expect(({ body }) => {
        expect(body.code).toBe('PROJECT_NOT_FOUND');
      });
  });

  it('rejects a project memo longer than 500 characters', async () => {
    await request(app.getHttpServer())
      .post('/api/v1/projects')
      .set('Authorization', 'Bearer dev-token')
      .send({
        ...saveProjectBody,
        memo: 'a'.repeat(501),
      })
      .expect(400);

    expect(prisma.project.create).not.toHaveBeenCalled();
  });

  it('rejects a row counter name longer than 30 characters', async () => {
    await request(app.getHttpServer())
      .post('/api/v1/projects')
      .set('Authorization', 'Bearer dev-token')
      .send({
        ...saveProjectBody,
        rowCounter: {
          ...saveProjectBody.rowCounter,
          name: 'a'.repeat(31),
        },
      })
      .expect(400);

    expect(prisma.project.create).not.toHaveBeenCalled();
  });

  it('rejects a work session memo longer than 500 characters', async () => {
    await request(app.getHttpServer())
      .post('/api/v1/projects')
      .set('Authorization', 'Bearer dev-token')
      .send({
        ...saveProjectBody,
        workSessions: [
          {
            ...saveProjectBody.workSessions[0],
            memo: 'a'.repeat(501),
          },
        ],
      })
      .expect(400);

    expect(prisma.project.create).not.toHaveBeenCalled();
  });

  it('rejects a work session whose end time is not after its start time', async () => {
    await request(app.getHttpServer())
      .post(`/api/v1/projects/${userAProject.id}/work-sessions`)
      .set('Authorization', 'Bearer dev-token')
      .send({
        ...saveProjectBody.workSessions[0],
        startedAt: '2026-07-03T09:00:00.000Z',
        endedAt: '2026-07-03T09:00:00.000Z',
      })
      .expect(400)
      .expect(({ body }) => {
        expect(body.code).toBe('VALIDATION_FAILED');
        expect(body.message).toBe(
          'Work session end time must be after the start time.',
        );
      });

    expect(prisma.workSession.upsert).not.toHaveBeenCalled();
  });

  it('rejects a work session longer than 24 hours', async () => {
    await request(app.getHttpServer())
      .post(`/api/v1/projects/${userAProject.id}/work-sessions`)
      .set('Authorization', 'Bearer dev-token')
      .send({
        ...saveProjectBody.workSessions[0],
        startedAt: '2026-07-03T08:00:00.000Z',
        endedAt: '2026-07-04T08:00:00.001Z',
      })
      .expect(400)
      .expect(({ body }) => {
        expect(body.code).toBe('VALIDATION_FAILED');
        expect(body.message).toBe(
          'Work session length must be 24 hours or less.',
        );
      });

    expect(prisma.workSession.upsert).not.toHaveBeenCalled();
  });

  it('accepts a work session exactly 24 hours long', async () => {
    await request(app.getHttpServer())
      .post(`/api/v1/projects/${userAProject.id}/work-sessions`)
      .set('Authorization', 'Bearer dev-token')
      .send({
        ...saveProjectBody.workSessions[0],
        startedAt: '2026-07-03T08:00:00.000Z',
        endedAt: '2026-07-04T08:00:00.000Z',
      })
      .expect(201);

    expect(prisma.workSession.upsert).toHaveBeenCalled();
  });

  it('rejects a project save whose work session reverses time', async () => {
    await request(app.getHttpServer())
      .post('/api/v1/projects')
      .set('Authorization', 'Bearer dev-token')
      .send({
        ...saveProjectBody,
        workSessions: [
          {
            ...saveProjectBody.workSessions[0],
            startedAt: '2026-07-03T09:00:00.000Z',
            endedAt: '2026-07-03T08:00:00.000Z',
          },
        ],
      })
      .expect(400)
      .expect(({ body }) => {
        expect(body.code).toBe('VALIDATION_FAILED');
        expect(body.message).toBe(
          'Work session end time must be after the start time.',
        );
      });

    expect(prisma.project.create).not.toHaveBeenCalled();
    expect(prisma.workSession.upsert).not.toHaveBeenCalled();
  });

  it('rejects a new project when the owner already has 200 active projects', async () => {
    prisma.project.count.mockResolvedValueOnce(200);

    await request(app.getHttpServer())
      .post('/api/v1/projects')
      .set('Authorization', 'Bearer dev-token')
      .send(saveProjectBody)
      .expect(400)
      .expect(({ body }) => {
        expect(body.code).toBe('PROJECT_LIMIT_EXCEEDED');
      });

    expect(prisma.project.count).toHaveBeenCalledWith({
      where: {
        ownerId: 'user-a',
        deletedAt: null,
      },
    });
    expect(prisma.project.create).not.toHaveBeenCalled();
  });

  // 생성(POST)이 기존 행을 만나면 409다(GitHub #14). 상한 검사는 그 전에 걸리지 않는다는
  // 것이 이 케이스의 확인 대상이며, 기존 프로젝트를 고치는 길이 상한 때문에 막히지는
  // 않는다는 사실은 PATCH 쪽 케이스가 담당한다.
  it('rejects an existing project on create without consulting the project limit', async () => {
    prisma.project.findFirst.mockResolvedValueOnce(userAProject);
    prisma.project.count.mockResolvedValueOnce(200);

    await request(app.getHttpServer())
      .post('/api/v1/projects')
      .set('Authorization', 'Bearer dev-token')
      .send(saveProjectBody)
      .expect(409)
      .expect(({ body }) => {
        expect(body.code).toBe('PROJECT_ALREADY_EXISTS');
      });

    expect(prisma.project.count).not.toHaveBeenCalled();
    expect(prisma.project.update).not.toHaveBeenCalled();
    expect(prisma.project.create).not.toHaveBeenCalled();
  });

  it('returns 409 when creating a project whose ID belongs to another owner', async () => {
    prisma.project.create.mockRejectedValueOnce(
      new Prisma.PrismaClientKnownRequestError(
        'Unique constraint failed on the fields: (`id`)',
        {
          code: 'P2002',
          clientVersion: '6.0.0',
        },
      ),
    );

    await request(app.getHttpServer())
      .post('/api/v1/projects')
      .set('Authorization', 'Bearer dev-token')
      .send(saveProjectBody)
      .expect(409)
      .expect(({ body }) => {
        expect(body.code).toBe('PROJECT_ID_CONFLICT');
      });
  });

  it('returns 409 with the server copy when baseUpdatedAt is older than the stored project', async () => {
    prisma.project.findFirst.mockResolvedValueOnce(userAProject);

    await request(app.getHttpServer())
      .patch('/api/v1/projects/11111111-1111-4111-8111-111111111111')
      .set('Authorization', 'Bearer dev-token')
      .send({
        ...saveProjectBody,
        // 서버 updatedAt(2026-07-03T09:00Z)보다 이른 기준 시각 → 그 사이 다른 저장이 있었다.
        baseUpdatedAt: '2026-07-03T08:00:00.000Z',
      })
      .expect(409)
      .expect(({ body }) => {
        expect(body.code).toBe('PROJECT_CONFLICT');
        expect(body.details.latest.id).toBe(userAProject.id);
        expect(body.details.latest.updatedAt).toBe('2026-07-03T09:00:00.000Z');
      });

    expect(prisma.project.update).not.toHaveBeenCalled();
    expect(prisma.project.create).not.toHaveBeenCalled();
  });

  it('saves a project when baseUpdatedAt matches the stored updatedAt', async () => {
    prisma.project.findFirst.mockResolvedValueOnce(userAProject);

    await request(app.getHttpServer())
      .patch('/api/v1/projects/11111111-1111-4111-8111-111111111111')
      .set('Authorization', 'Bearer dev-token')
      .send({
        ...saveProjectBody,
        baseUpdatedAt: '2026-07-03T09:00:00.000Z',
      })
      .expect(200);

    expect(prisma.project.update).toHaveBeenCalled();
  });

  // 저장된 updatedAt은 밀리초를 가지는데(Prisma DateTime은 timestamp(3)),
  // 클라이언트가 그 값을 초 단위로 잘라 baseUpdatedAt으로 보내면 서버는 그것을
  // 잘린 값인지 실제로 뒤처진 값인지 구분할 수 없어 409를 낸다.
  // 그래서 클라이언트는 서버가 준 시각을 밀리초까지 그대로 되돌려 보내야 한다.
  it('returns 409 when baseUpdatedAt is truncated to seconds while the stored updatedAt has milliseconds', async () => {
    prisma.project.findFirst.mockResolvedValueOnce({
      ...userAProject,
      updatedAt: new Date('2026-07-03T09:00:00.123Z'),
    });

    await request(app.getHttpServer())
      .patch('/api/v1/projects/11111111-1111-4111-8111-111111111111')
      .set('Authorization', 'Bearer dev-token')
      .send({
        ...saveProjectBody,
        baseUpdatedAt: '2026-07-03T09:00:00Z',
      })
      .expect(409)
      .expect(({ body }) => {
        expect(body.code).toBe('PROJECT_CONFLICT');
        expect(body.details.latest.updatedAt).toBe('2026-07-03T09:00:00.123Z');
      });

    expect(prisma.project.update).not.toHaveBeenCalled();
    expect(prisma.project.create).not.toHaveBeenCalled();
  });

  it('saves a project when baseUpdatedAt echoes the stored updatedAt down to the millisecond', async () => {
    prisma.project.findFirst.mockResolvedValueOnce({
      ...userAProject,
      updatedAt: new Date('2026-07-03T09:00:00.123Z'),
    });

    await request(app.getHttpServer())
      .patch('/api/v1/projects/11111111-1111-4111-8111-111111111111')
      .set('Authorization', 'Bearer dev-token')
      .send({
        ...saveProjectBody,
        baseUpdatedAt: '2026-07-03T09:00:00.123Z',
      })
      .expect(200);

    expect(prisma.project.update).toHaveBeenCalled();
  });

  it('rejects a stale patch when baseUpdatedAt is older than the stored project', async () => {
    await request(app.getHttpServer())
      .patch(`/api/v1/projects/${userAProject.id}`)
      .set('Authorization', 'Bearer dev-token')
      .send({
        ...saveProjectBody,
        baseUpdatedAt: '2026-07-03T08:00:00.000Z',
      })
      .expect(409)
      .expect(({ body }) => {
        expect(body.code).toBe('PROJECT_CONFLICT');
        expect(body.details.latest.id).toBe(userAProject.id);
      });

    expect(prisma.project.update).not.toHaveBeenCalled();
  });

  function expectedProjectYarnUsageResponse() {
    return {
      id: projectYarnUsage.id,
      ownerId: 'user-a',
      projectId: userAProject.id,
      projectNameSnapshot: null,
      yarnId: activeYarn.id,
      yarnNameSnapshot: activeYarn.name,
      quantityUsed: 2,
      memo: 'Sleeve swatch',
      usedAt: '2026-07-09T02:00:00.000Z',
      createdAt: '2026-07-09T02:00:00.000Z',
      updatedAt: '2026-07-09T02:05:00.000Z',
      deletedAt: null,
      syncStatus: 'Synced',
    };
  }

  function expectedProjectProgressPhotoResponse() {
    return {
      id: projectProgressPhoto.id,
      ownerId: 'user-a',
      projectId: userAProject.id,
      fileName: 'progress.jpg',
      contentType: 'image/jpeg',
      byteSize: 4,
      caption: 'Body progress',
      takenAt: '2026-07-09T03:00:00.000Z',
      createdAt: '2026-07-09T03:00:00.000Z',
      updatedAt: '2026-07-09T03:05:00.000Z',
      deletedAt: null,
      syncStatus: 'Synced',
    };
  }
});
