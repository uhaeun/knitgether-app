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
  dictionaryTerm: {
    findMany: jest.Mock;
    findFirst: jest.Mock;
    create: jest.Mock;
    update: jest.Mock;
  };
  $transaction: jest.Mock;
};

describe('Dictionary terms route', () => {
  let app: INestApplication;
  let prisma: MockPrismaService;

  const termId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
  const activeTerm = {
    id: termId,
    ownerId: 'user-a',
    term: 'K2TOG',
    fullName: 'Knit two together',
    description: 'Two stitches are knit together as one decrease.',
    relatedSkillAbbreviations: 'K,K2TOG',
    isSystem: false,
    createdAt: new Date('2026-07-09T00:00:00.000Z'),
    updatedAt: new Date('2026-07-09T00:05:00.000Z'),
    deletedAt: null,
  };
  const saveTermBody = {
    id: termId,
    term: ' K2TOG ',
    fullName: ' Knit two together ',
    description: ' Two stitches are knit together as one decrease. ',
    relatedSkillAbbreviations: ' K, K2TOG ',
  };

  beforeAll(async () => {
    process.env.DEV_AUTH_TOKEN = 'dev-token';
    process.env.DEV_AUTH_USER_ID = 'user-a';

    prisma = {
      userProfile: {
        upsert: jest.fn(),
      },
      dictionaryTerm: {
        findMany: jest.fn(),
        findFirst: jest.fn(),
        create: jest.fn(),
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

  beforeEach(() => {
    prisma.userProfile.upsert.mockReset();
    prisma.dictionaryTerm.findMany.mockReset();
    prisma.dictionaryTerm.findFirst.mockReset();
    prisma.dictionaryTerm.create.mockReset();
    prisma.dictionaryTerm.update.mockReset();
    prisma.$transaction.mockReset();
    prisma.$transaction.mockImplementation(async (callback) => callback(prisma));
    prisma.userProfile.upsert.mockResolvedValue(undefined);
    prisma.dictionaryTerm.findMany.mockResolvedValue([activeTerm]);
    prisma.dictionaryTerm.findFirst.mockResolvedValue(activeTerm);
    prisma.dictionaryTerm.create.mockResolvedValue(activeTerm);
    prisma.dictionaryTerm.update.mockResolvedValue(activeTerm);
  });

  afterAll(async () => {
    delete process.env.DEV_AUTH_TOKEN;
    delete process.env.DEV_AUTH_USER_ID;
    await app.close();
  });

  it('rejects unauthenticated requests', async () => {
    await request(app.getHttpServer())
      .get('/api/v1/dictionary-terms')
      .expect(401)
      .expect(({ body }) => {
        expect(body.code).toBe('UNAUTHENTICATED');
      });
  });

  it('lists active dictionary terms owned by the current user', async () => {
    const response = await request(app.getHttpServer())
      .get('/api/v1/dictionary-terms')
      .set('Authorization', 'Bearer dev-token')
      .expect(200);

    expect(prisma.dictionaryTerm.findMany).toHaveBeenCalledWith({
      where: {
        deletedAt: null,
        OR: [
          { isSystem: true },
          { ownerId: 'user-a' },
        ],
      },
      orderBy: [
        { term: 'asc' },
      ],
    });
    expect(response.body).toEqual([expectedTermResponse()]);
  });

  it('returns one active dictionary term owned by the current user', async () => {
    const response = await request(app.getHttpServer())
      .get(`/api/v1/dictionary-terms/${termId}`)
      .set('Authorization', 'Bearer dev-token')
      .expect(200);

    expect(prisma.dictionaryTerm.findFirst).toHaveBeenCalledWith({
      where: {
        id: termId,
        deletedAt: null,
        OR: [
          { isSystem: true },
          { ownerId: 'user-a' },
        ],
      },
    });
    expect(response.body).toEqual(expectedTermResponse());
  });

  it('creates a dictionary term for the current user', async () => {
    const response = await request(app.getHttpServer())
      .post('/api/v1/dictionary-terms')
      .set('Authorization', 'Bearer dev-token')
      .send(saveTermBody)
      .expect(201);

    expect(prisma.userProfile.upsert).toHaveBeenCalledWith({
      where: { id: 'user-a' },
      create: {
        id: 'user-a',
        displayName: 'user-a',
      },
      update: {},
    });
    expect(prisma.dictionaryTerm.create).toHaveBeenCalledWith({
      data: expect.objectContaining({
        id: termId,
        ownerId: 'user-a',
        term: 'K2TOG',
        fullName: 'Knit two together',
        description: 'Two stitches are knit together as one decrease.',
        relatedSkillAbbreviations: 'K, K2TOG',
        deletedAt: null,
      }),
    });
    expect(response.body).toEqual(expectedTermResponse());
  });

  it('updates an owned dictionary term', async () => {
    const response = await request(app.getHttpServer())
      .patch(`/api/v1/dictionary-terms/${termId}`)
      .set('Authorization', 'Bearer dev-token')
      .send({
        ...saveTermBody,
        term: 'K2TOG decrease',
      })
      .expect(200);

    expect(prisma.dictionaryTerm.findFirst).toHaveBeenCalledWith({
      where: {
        id: termId,
        deletedAt: null,
        OR: [
          { isSystem: true },
          { ownerId: 'user-a' },
        ],
      },
    });
    expect(prisma.dictionaryTerm.update).toHaveBeenCalledWith({
      where: { id: termId },
      data: expect.objectContaining({
        ownerId: 'user-a',
        term: 'K2TOG decrease',
        fullName: 'Knit two together',
        description: 'Two stitches are knit together as one decrease.',
        relatedSkillAbbreviations: 'K, K2TOG',
      }),
    });
    expect(response.body).toEqual(expectedTermResponse());
  });

  it('soft deletes an owned dictionary term', async () => {
    await request(app.getHttpServer())
      .delete(`/api/v1/dictionary-terms/${termId}`)
      .set('Authorization', 'Bearer dev-token')
      .expect(204);

    expect(prisma.dictionaryTerm.findFirst).toHaveBeenCalledWith({
      where: {
        id: termId,
        deletedAt: null,
        OR: [
          { isSystem: true },
          { ownerId: 'user-a' },
        ],
      },
    });
    expect(prisma.dictionaryTerm.update).toHaveBeenCalledWith({
      where: { id: termId },
      data: {
        deletedAt: expect.any(Date),
      },
    });
  });

  it('returns 400 when required text is missing', async () => {
    await request(app.getHttpServer())
      .post('/api/v1/dictionary-terms')
      .set('Authorization', 'Bearer dev-token')
      .send({
        term: '   ',
        description: '   ',
      })
      .expect(400)
      .expect(({ body }) => {
        expect(body.code).toBe('VALIDATION_FAILED');
      });
  });

  function expectedTermResponse() {
    return {
      id: termId,
      ownerId: 'user-a',
      term: 'K2TOG',
      fullName: 'Knit two together',
      description: 'Two stitches are knit together as one decrease.',
      relatedSkillAbbreviations: 'K,K2TOG',
      createdAt: '2026-07-09T00:00:00.000Z',
      updatedAt: '2026-07-09T00:05:00.000Z',
      deletedAt: null,
      syncStatus: 'Synced',
    };
  }
});
