import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { setupApp } from '../src/app.setup';
import { PrismaService } from '../src/database/prisma.service';

type MockPrismaService = {
  project: {
    findMany: jest.Mock;
  };
};

describe('Projects route', () => {
  let app: INestApplication;
  let prisma: MockPrismaService;

  const userAProject = {
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
    deletedAt: null,
    rowCounter: {
      id: '22222222-2222-2222-2222-222222222222',
      ownerId: 'user-a',
      projectId: '11111111-1111-1111-1111-111111111111',
      name: 'Main Counter',
      currentRow: 42,
      targetRow: 120,
      createdAt: new Date('2026-07-01T00:00:00.000Z'),
      updatedAt: new Date('2026-07-03T09:00:00.000Z'),
      deletedAt: null,
    },
    workSessions: [
      {
        id: '33333333-3333-3333-3333-333333333333',
        ownerId: 'user-a',
        projectId: '11111111-1111-1111-1111-111111111111',
        startedAt: new Date('2026-07-03T08:00:00.000Z'),
        endedAt: new Date('2026-07-03T09:00:00.000Z'),
        memo: 'Sleeve increases.',
        createdAt: new Date('2026-07-03T09:00:00.000Z'),
        updatedAt: new Date('2026-07-03T09:00:00.000Z'),
        deletedAt: null,
      },
    ],
  };

  beforeAll(async () => {
    process.env.DEV_AUTH_TOKEN = 'dev-token';
    process.env.DEV_AUTH_USER_ID = 'user-a';

    prisma = {
      project: {
        findMany: jest.fn(),
      },
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
    prisma.project.findMany.mockReset();
    prisma.project.findMany.mockImplementation(async ({ where }) => {
      if (where.ownerId === 'user-a') {
        return [userAProject];
      }

      return [];
    });
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
