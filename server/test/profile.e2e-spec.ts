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
};

describe('Profile route', () => {
  let app: INestApplication;
  let prisma: MockPrismaService;

  const activeProfile = {
    id: 'user-a',
    displayName: 'Local Knitter',
    preferredUnits: 'Metric',
    createdAt: new Date('2026-07-09T02:00:00.000Z'),
    updatedAt: new Date('2026-07-09T02:05:00.000Z'),
    deletedAt: null,
  };

  beforeAll(async () => {
    process.env.DEV_AUTH_TOKEN = 'dev-token';
    process.env.DEV_AUTH_USER_ID = 'user-a';

    prisma = {
      userProfile: {
        upsert: jest.fn(),
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
    prisma.userProfile.upsert.mockReset();
    prisma.userProfile.upsert.mockResolvedValue(activeProfile);
  });

  afterAll(async () => {
    delete process.env.DEV_AUTH_TOKEN;
    delete process.env.DEV_AUTH_USER_ID;
    await app.close();
  });

  it('rejects unauthenticated profile requests', async () => {
    await request(app.getHttpServer())
      .get('/api/v1/profile')
      .expect(401)
      .expect(({ body }) => {
        expect(body.code).toBe('UNAUTHENTICATED');
      });
  });

  it('returns the current user profile and creates a default when missing', async () => {
    const response = await request(app.getHttpServer())
      .get('/api/v1/profile')
      .set('Authorization', 'Bearer dev-token')
      .expect(200);

    expect(prisma.userProfile.upsert).toHaveBeenCalledWith({
      where: { id: 'user-a' },
      create: {
        id: 'user-a',
        displayName: 'user-a',
        preferredUnits: 'Metric',
      },
      update: {},
    });
    expect(response.body).toEqual(expectedProfileResponse());
  });

  it('updates the current user profile', async () => {
    const response = await request(app.getHttpServer())
      .patch('/api/v1/profile')
      .set('Authorization', 'Bearer dev-token')
      .send({
        displayName: '  Yuha  ',
        preferredUnits: '  Metric  ',
      })
      .expect(200);

    expect(prisma.userProfile.upsert).toHaveBeenCalledWith({
      where: { id: 'user-a' },
      create: {
        id: 'user-a',
        displayName: 'Yuha',
        preferredUnits: 'Metric',
      },
      update: {
        displayName: 'Yuha',
        preferredUnits: 'Metric',
        deletedAt: null,
      },
    });
    expect(response.body).toEqual(expectedProfileResponse());
  });

  it('rejects a display name longer than 80 characters', async () => {
    await request(app.getHttpServer())
      .patch('/api/v1/profile')
      .set('Authorization', 'Bearer dev-token')
      .send({
        displayName: 'a'.repeat(81),
        preferredUnits: 'Metric',
      })
      .expect(400);

    expect(prisma.userProfile.upsert).not.toHaveBeenCalled();
  });

  function expectedProfileResponse() {
    return {
      id: 'user-a',
      ownerId: 'user-a',
      displayName: 'Local Knitter',
      preferredUnits: 'Metric',
      createdAt: '2026-07-09T02:00:00.000Z',
      updatedAt: '2026-07-09T02:05:00.000Z',
      deletedAt: null,
      syncStatus: 'Synced',
    };
  }
});
