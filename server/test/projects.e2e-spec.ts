import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
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
    create: jest.Mock;
    update: jest.Mock;
  };
  rowCounter: {
    upsert: jest.Mock;
  };
  workSession: {
    deleteMany: jest.Mock;
    updateMany: jest.Mock;
    createMany: jest.Mock;
  };
  $transaction: jest.Mock;
};

describe('Projects route', () => {
  let app: INestApplication;
  let prisma: MockPrismaService;

  const userAProject = {
    id: '11111111-1111-4111-8111-111111111111',
    ownerId: 'user-a',
    name: 'Favorite Cardigan',
    status: 'WIP',
    isFavorite: true,
    memo: 'Use smaller needles for ribbing.',
    startDate: new Date('2026-07-01T00:00:00.000Z'),
    lastWorkedAt: new Date('2026-07-03T09:00:00.000Z'),
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
      currentRow: 42,
      targetRow: 120,
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
    lastWorkedAt: '2026-07-03T09:00:00.000Z',
    workspaceDisplayMode: 'patternAndCounter',
    workspaceSheetPosition: 'medium',
    relatedSkillIds: ['aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'],
    rowCounter: {
      id: '22222222-2222-4222-8222-222222222222',
      projectId: '11111111-1111-4111-8111-111111111111',
      name: 'Main Counter',
      currentRow: 42,
      targetRow: 120,
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

  beforeAll(async () => {
    process.env.DEV_AUTH_TOKEN = 'dev-token';
    process.env.DEV_AUTH_USER_ID = 'user-a';

    prisma = {
      userProfile: {
        upsert: jest.fn(),
      },
      project: {
        findMany: jest.fn(),
        findFirst: jest.fn(),
        findFirstOrThrow: jest.fn(),
        create: jest.fn(),
        update: jest.fn(),
      },
      rowCounter: {
        upsert: jest.fn(),
      },
      workSession: {
        deleteMany: jest.fn(),
        updateMany: jest.fn(),
        createMany: jest.fn(),
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
    prisma.project.create.mockReset();
    prisma.project.update.mockReset();
    prisma.rowCounter.upsert.mockReset();
    prisma.workSession.deleteMany.mockReset();
    prisma.workSession.updateMany.mockReset();
    prisma.workSession.createMany.mockReset();
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
    prisma.project.create.mockResolvedValue(userAProject);
    prisma.project.update.mockResolvedValue(userAProject);
    prisma.rowCounter.upsert.mockResolvedValue(userAProject.rowCounter);
    prisma.workSession.deleteMany.mockResolvedValue({ count: 0 });
    prisma.workSession.updateMany.mockResolvedValue({ count: 0 });
    prisma.workSession.createMany.mockResolvedValue({ count: 1 });
  });

  afterAll(async () => {
    delete process.env.DEV_AUTH_TOKEN;
    delete process.env.DEV_AUTH_USER_ID;
    await app.close();
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
        rowCounter: true,
        workSessions: {
          where: {
            ownerId: 'user-a',
            deletedAt: null,
          },
          orderBy: {
            startedAt: 'asc',
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
        lastWorkedAt: '2026-07-03T09:00:00.000Z',
        patternCopy: null,
        workspaceDisplayMode: 'patternAndCounter',
        workspaceSheetPosition: 'medium',
        rowCounter: {
          id: '22222222-2222-4222-8222-222222222222',
          ownerId: 'user-a',
          projectId: '11111111-1111-4111-8111-111111111111',
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
        rowCounter: true,
        workSessions: {
          where: {
            ownerId: 'user-a',
            deletedAt: null,
          },
          orderBy: {
            startedAt: 'asc',
          },
        },
      },
    });
    expect(response.body.id).toBe('11111111-1111-4111-8111-111111111111');
    expect(response.body.name).toBe('Favorite Cardigan');
    expect(response.body.syncStatus).toBe('Synced');
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
    expect(prisma.workSession.deleteMany).toHaveBeenCalledWith({
      where: {
        ownerId: 'user-a',
        projectId: saveProjectBody.id,
      },
    });
    expect(prisma.workSession.createMany).toHaveBeenCalledWith({
      data: [
        expect.objectContaining({
          id: saveProjectBody.workSessions[0].id,
          ownerId: 'user-a',
          projectId: saveProjectBody.id,
          memo: saveProjectBody.workSessions[0].memo,
        }),
      ],
    });
    expect(response.body.id).toBe(saveProjectBody.id);
  });

  it('updates an active project owned by the current user', async () => {
    const response = await request(app.getHttpServer())
      .patch('/api/v1/projects/11111111-1111-4111-8111-111111111111')
      .set('Authorization', 'Bearer dev-token')
      .send(saveProjectBody)
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
        }),
        include: expect.any(Object),
      }),
    );
    expect(response.body.name).toBe(saveProjectBody.name);
  });
});
