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
  yarn: {
    findMany: jest.Mock;
    findFirst: jest.Mock;
    create: jest.Mock;
    update: jest.Mock;
  };
  needle: {
    findMany: jest.Mock;
    findFirst: jest.Mock;
    create: jest.Mock;
    update: jest.Mock;
  };
  projectYarnUsage: {
    findMany: jest.Mock;
  };
  $transaction: jest.Mock;
};

describe('Library route', () => {
  let app: INestApplication;
  let prisma: MockPrismaService;

  const yarnId = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';
  const needleId = 'dddddddd-dddd-4ddd-8ddd-dddddddddddd';
  const activeYarn = {
    id: yarnId,
    ownerId: 'user-a',
    name: 'Soft Merino DK',
    brand: 'Sample Yarn Co.',
    colorway: 'Cloud Gray',
    weight: 'DK',
    quantity: 5,
    notes: 'Reserved for beanie and swatches.',
    createdAt: new Date('2026-07-09T01:00:00.000Z'),
    updatedAt: new Date('2026-07-09T01:05:00.000Z'),
    deletedAt: null,
  };
  const activeNeedle = {
    id: needleId,
    ownerId: 'user-a',
    name: 'Wood Circular Needle',
    needleType: 'Circular',
    size: '5.0 mm',
    length: '80 cm',
    notes: 'Used for cardigan body.',
    createdAt: new Date('2026-07-09T01:00:00.000Z'),
    updatedAt: new Date('2026-07-09T01:05:00.000Z'),
    deletedAt: null,
  };
  const saveYarnBody = {
    id: yarnId,
    name: 'Soft Merino DK',
    brand: 'Sample Yarn Co.',
    colorway: 'Cloud Gray',
    weight: 'DK',
    quantity: 5,
    notes: 'Reserved for beanie and swatches.',
  };
  const saveNeedleBody = {
    id: needleId,
    name: 'Wood Circular Needle',
    needleType: 'Circular',
    size: '5.0 mm',
    length: '80 cm',
    notes: 'Used for cardigan body.',
  };
  const yarnUsage = {
    id: '99999999-9999-4999-8999-999999999999',
    ownerId: 'user-a',
    projectId: '11111111-1111-4111-8111-111111111111',
    yarnId,
    yarnNameSnapshot: activeYarn.name,
    quantityUsed: 2,
    memo: 'Sleeve swatch',
    usedAt: new Date('2026-07-09T02:00:00.000Z'),
    createdAt: new Date('2026-07-09T02:00:00.000Z'),
    updatedAt: new Date('2026-07-09T02:05:00.000Z'),
    deletedAt: null,
    project: {
      name: 'Favorite Cardigan',
    },
  };

  beforeAll(async () => {
    process.env.DEV_AUTH_TOKEN = 'dev-token';
    process.env.DEV_AUTH_USER_ID = 'user-a';

    prisma = {
      userProfile: {
        upsert: jest.fn(),
      },
      yarn: {
        findMany: jest.fn(),
        findFirst: jest.fn(),
        create: jest.fn(),
        update: jest.fn(),
      },
      needle: {
        findMany: jest.fn(),
        findFirst: jest.fn(),
        create: jest.fn(),
        update: jest.fn(),
      },
      projectYarnUsage: {
        findMany: jest.fn(),
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
    prisma.yarn.findMany.mockReset();
    prisma.yarn.findFirst.mockReset();
    prisma.yarn.create.mockReset();
    prisma.yarn.update.mockReset();
    prisma.needle.findMany.mockReset();
    prisma.needle.findFirst.mockReset();
    prisma.needle.create.mockReset();
    prisma.needle.update.mockReset();
    prisma.projectYarnUsage.findMany.mockReset();
    prisma.$transaction.mockReset();
    prisma.$transaction.mockImplementation(async (callback) => callback(prisma));
    prisma.userProfile.upsert.mockResolvedValue(undefined);
    prisma.yarn.findMany.mockResolvedValue([activeYarn]);
    prisma.yarn.findFirst.mockResolvedValue(activeYarn);
    prisma.yarn.create.mockResolvedValue(activeYarn);
    prisma.yarn.update.mockResolvedValue(activeYarn);
    prisma.needle.findMany.mockResolvedValue([activeNeedle]);
    prisma.needle.findFirst.mockResolvedValue(activeNeedle);
    prisma.needle.create.mockResolvedValue(activeNeedle);
    prisma.needle.update.mockResolvedValue(activeNeedle);
    prisma.projectYarnUsage.findMany.mockResolvedValue([yarnUsage]);
  });

  afterAll(async () => {
    delete process.env.DEV_AUTH_TOKEN;
    delete process.env.DEV_AUTH_USER_ID;
    await app.close();
  });

  it('rejects unauthenticated yarn requests', async () => {
    await request(app.getHttpServer())
      .get('/api/v1/library/yarns')
      .expect(401)
      .expect(({ body }) => {
        expect(body.code).toBe('UNAUTHENTICATED');
      });
  });

  it('lists active yarns owned by the current user', async () => {
    const response = await request(app.getHttpServer())
      .get('/api/v1/library/yarns')
      .set('Authorization', 'Bearer dev-token')
      .expect(200);

    expect(prisma.yarn.findMany).toHaveBeenCalledWith({
      where: {
        ownerId: 'user-a',
        deletedAt: null,
      },
      orderBy: {
        name: 'asc',
      },
    });
    expect(response.body).toEqual([expectedYarnResponse()]);
  });

  it('lists active needles owned by the current user', async () => {
    const response = await request(app.getHttpServer())
      .get('/api/v1/library/needles')
      .set('Authorization', 'Bearer dev-token')
      .expect(200);

    expect(prisma.needle.findMany).toHaveBeenCalledWith({
      where: {
        ownerId: 'user-a',
        deletedAt: null,
      },
      orderBy: {
        name: 'asc',
      },
    });
    expect(response.body).toEqual([expectedNeedleResponse()]);
  });

  it('lists project usages for an owned yarn', async () => {
    const response = await request(app.getHttpServer())
      .get(`/api/v1/library/yarns/${yarnId}/usages`)
      .set('Authorization', 'Bearer dev-token')
      .expect(200);

    expect(prisma.yarn.findFirst).toHaveBeenCalledWith({
      where: {
        id: yarnId,
        ownerId: 'user-a',
        deletedAt: null,
      },
    });
    expect(prisma.projectYarnUsage.findMany).toHaveBeenCalledWith({
      where: {
        ownerId: 'user-a',
        yarnId,
        deletedAt: null,
      },
      include: {
        project: {
          select: {
            name: true,
          },
        },
      },
      orderBy: {
        usedAt: 'desc',
      },
    });
    expect(response.body).toEqual([expectedYarnUsageResponse()]);
  });

  it('creates a yarn for the current user', async () => {
    const response = await request(app.getHttpServer())
      .post('/api/v1/library/yarns')
      .set('Authorization', 'Bearer dev-token')
      .send(saveYarnBody)
      .expect(201);

    expect(prisma.userProfile.upsert).toHaveBeenCalledWith({
      where: { id: 'user-a' },
      create: {
        id: 'user-a',
        displayName: 'user-a',
      },
      update: {},
    });
    expect(prisma.yarn.create).toHaveBeenCalledWith({
      data: expect.objectContaining({
        id: yarnId,
        ownerId: 'user-a',
        name: 'Soft Merino DK',
        brand: 'Sample Yarn Co.',
        colorway: 'Cloud Gray',
        weight: 'DK',
        quantity: 5,
        notes: 'Reserved for beanie and swatches.',
        deletedAt: null,
      }),
    });
    expect(response.body).toEqual(expectedYarnResponse());
  });

  it('updates an owned yarn', async () => {
    const response = await request(app.getHttpServer())
      .patch(`/api/v1/library/yarns/${yarnId}`)
      .set('Authorization', 'Bearer dev-token')
      .send({
        ...saveYarnBody,
        quantity: 3,
      })
      .expect(200);

    expect(prisma.yarn.findFirst).toHaveBeenCalledWith({
      where: {
        id: yarnId,
        ownerId: 'user-a',
        deletedAt: null,
      },
    });
    expect(prisma.yarn.update).toHaveBeenCalledWith({
      where: { id: yarnId },
      data: expect.objectContaining({
        ownerId: 'user-a',
        name: 'Soft Merino DK',
        brand: 'Sample Yarn Co.',
        colorway: 'Cloud Gray',
        weight: 'DK',
        quantity: 3,
        notes: 'Reserved for beanie and swatches.',
      }),
    });
    expect(response.body).toEqual(expectedYarnResponse());
  });

  it('soft deletes an owned yarn', async () => {
    await request(app.getHttpServer())
      .delete(`/api/v1/library/yarns/${yarnId}`)
      .set('Authorization', 'Bearer dev-token')
      .expect(204);

    expect(prisma.yarn.findFirst).toHaveBeenCalledWith({
      where: {
        id: yarnId,
        ownerId: 'user-a',
        deletedAt: null,
      },
    });
    expect(prisma.yarn.update).toHaveBeenCalledWith({
      where: { id: yarnId },
      data: {
        deletedAt: expect.any(Date),
      },
    });
  });

  it('creates a needle for the current user', async () => {
    const response = await request(app.getHttpServer())
      .post('/api/v1/library/needles')
      .set('Authorization', 'Bearer dev-token')
      .send(saveNeedleBody)
      .expect(201);

    expect(prisma.userProfile.upsert).toHaveBeenCalledWith({
      where: { id: 'user-a' },
      create: {
        id: 'user-a',
        displayName: 'user-a',
      },
      update: {},
    });
    expect(prisma.needle.create).toHaveBeenCalledWith({
      data: expect.objectContaining({
        id: needleId,
        ownerId: 'user-a',
        name: 'Wood Circular Needle',
        needleType: 'Circular',
        size: '5.0 mm',
        length: '80 cm',
        notes: 'Used for cardigan body.',
        deletedAt: null,
      }),
    });
    expect(response.body).toEqual(expectedNeedleResponse());
  });

  it('updates an owned needle', async () => {
    const response = await request(app.getHttpServer())
      .patch(`/api/v1/library/needles/${needleId}`)
      .set('Authorization', 'Bearer dev-token')
      .send({
        ...saveNeedleBody,
        length: '100 cm',
      })
      .expect(200);

    expect(prisma.needle.findFirst).toHaveBeenCalledWith({
      where: {
        id: needleId,
        ownerId: 'user-a',
        deletedAt: null,
      },
    });
    expect(prisma.needle.update).toHaveBeenCalledWith({
      where: { id: needleId },
      data: expect.objectContaining({
        ownerId: 'user-a',
        name: 'Wood Circular Needle',
        needleType: 'Circular',
        size: '5.0 mm',
        length: '100 cm',
        notes: 'Used for cardigan body.',
      }),
    });
    expect(response.body).toEqual(expectedNeedleResponse());
  });

  it('soft deletes an owned needle', async () => {
    await request(app.getHttpServer())
      .delete(`/api/v1/library/needles/${needleId}`)
      .set('Authorization', 'Bearer dev-token')
      .expect(204);

    expect(prisma.needle.findFirst).toHaveBeenCalledWith({
      where: {
        id: needleId,
        ownerId: 'user-a',
        deletedAt: null,
      },
    });
    expect(prisma.needle.update).toHaveBeenCalledWith({
      where: { id: needleId },
      data: {
        deletedAt: expect.any(Date),
      },
    });
  });

  function expectedYarnResponse() {
    return {
      id: yarnId,
      ownerId: 'user-a',
      name: 'Soft Merino DK',
      brand: 'Sample Yarn Co.',
      colorway: 'Cloud Gray',
      weight: 'DK',
      quantity: 5,
      notes: 'Reserved for beanie and swatches.',
      createdAt: '2026-07-09T01:00:00.000Z',
      updatedAt: '2026-07-09T01:05:00.000Z',
      deletedAt: null,
      syncStatus: 'Synced',
    };
  }

  function expectedNeedleResponse() {
    return {
      id: needleId,
      ownerId: 'user-a',
      name: 'Wood Circular Needle',
      needleType: 'Circular',
      size: '5.0 mm',
      length: '80 cm',
      notes: 'Used for cardigan body.',
      createdAt: '2026-07-09T01:00:00.000Z',
      updatedAt: '2026-07-09T01:05:00.000Z',
      deletedAt: null,
      syncStatus: 'Synced',
    };
  }

  function expectedYarnUsageResponse() {
    return {
      id: yarnUsage.id,
      ownerId: 'user-a',
      projectId: yarnUsage.projectId,
      projectNameSnapshot: 'Favorite Cardigan',
      yarnId,
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
});
