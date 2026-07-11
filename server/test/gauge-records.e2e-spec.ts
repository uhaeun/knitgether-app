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
  gaugeRecord: {
    findMany: jest.Mock;
    findFirst: jest.Mock;
    create: jest.Mock;
    update: jest.Mock;
  };
  $transaction: jest.Mock;
};

describe('Gauge records route', () => {
  let app: INestApplication;
  let prisma: MockPrismaService;

  const recordId = '88888888-8888-4888-8888-888888888888';
  const projectId = '11111111-1111-4111-8111-111111111111';
  const activeGaugeRecord = {
    id: recordId,
    ownerId: 'user-a',
    projectId,
    projectNameSnapshot: 'Favorite Cardigan',
    patternNameSnapshot: 'Cozy Shawl',
    measurementStage: 'beforeWash',
    sampleWidthCm: 10,
    sampleHeightCm: 10,
    stitchCount: 22,
    rowCount: 30,
    targetWidthCm: 40,
    targetHeightCm: 55,
    stitchesPer10Cm: 22,
    rowsPer10Cm: 30,
    targetStitches: 88,
    targetRows: 165,
    needle: '4.0mm circular',
    memo: 'Measured before blocking.',
    measuredAt: new Date('2026-07-08T12:00:00.000Z'),
    createdAt: new Date('2026-07-08T12:01:00.000Z'),
    updatedAt: new Date('2026-07-08T12:01:00.000Z'),
    deletedAt: null,
  };

  const saveGaugeRecordBody = {
    id: recordId,
    projectId,
    projectNameSnapshot: 'Favorite Cardigan',
    patternNameSnapshot: 'Cozy Shawl',
    measurementStage: 'beforeWash',
    sampleWidthCm: 10,
    sampleHeightCm: 10,
    stitchCount: 22,
    rowCount: 30,
    targetWidthCm: 40,
    targetHeightCm: 55,
    needle: '4.0mm circular',
    memo: 'Measured before blocking.',
    measuredAt: '2026-07-08T12:00:00.000Z',
  };

  beforeAll(async () => {
    process.env.DEV_AUTH_TOKEN = 'dev-token';
    process.env.DEV_AUTH_USER_ID = 'user-a';

    prisma = {
      userProfile: {
        upsert: jest.fn(),
      },
      gaugeRecord: {
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
    prisma.gaugeRecord.findMany.mockReset();
    prisma.gaugeRecord.findFirst.mockReset();
    prisma.gaugeRecord.create.mockReset();
    prisma.gaugeRecord.update.mockReset();
    prisma.$transaction.mockReset();
    prisma.$transaction.mockImplementation(async (callback) => callback(prisma));
    prisma.userProfile.upsert.mockResolvedValue(undefined);
    prisma.gaugeRecord.findMany.mockResolvedValue([activeGaugeRecord]);
    prisma.gaugeRecord.findFirst.mockResolvedValue(activeGaugeRecord);
    prisma.gaugeRecord.create.mockResolvedValue(activeGaugeRecord);
    prisma.gaugeRecord.update.mockResolvedValue(activeGaugeRecord);
  });

  afterAll(async () => {
    delete process.env.DEV_AUTH_TOKEN;
    delete process.env.DEV_AUTH_USER_ID;
    await app.close();
  });

  it('rejects unauthenticated requests', async () => {
    await request(app.getHttpServer())
      .get('/api/v1/gauge-records')
      .expect(401)
      .expect(({ body }) => {
        expect(body.code).toBe('UNAUTHENTICATED');
      });
  });

  it('lists active gauge records owned by the current user', async () => {
    const response = await request(app.getHttpServer())
      .get('/api/v1/gauge-records')
      .set('Authorization', 'Bearer dev-token')
      .expect(200);

    expect(prisma.gaugeRecord.findMany).toHaveBeenCalledWith({
      where: {
        ownerId: 'user-a',
        deletedAt: null,
      },
      orderBy: {
        measuredAt: 'desc',
      },
    });
    expect(response.body).toEqual([expectedGaugeRecordResponse()]);
  });

  it('creates a before-wash gauge record with calculated results', async () => {
    const response = await request(app.getHttpServer())
      .post('/api/v1/gauge-records')
      .set('Authorization', 'Bearer dev-token')
      .send(saveGaugeRecordBody)
      .expect(201);

    expect(prisma.userProfile.upsert).toHaveBeenCalledWith({
      where: { id: 'user-a' },
      create: {
        id: 'user-a',
        displayName: 'user-a',
      },
      update: {},
    });
    expect(prisma.gaugeRecord.create).toHaveBeenCalledWith({
      data: expect.objectContaining({
        id: recordId,
        ownerId: 'user-a',
        projectId,
        projectNameSnapshot: 'Favorite Cardigan',
        patternNameSnapshot: 'Cozy Shawl',
        measurementStage: 'beforeWash',
        sampleWidthCm: 10,
        sampleHeightCm: 10,
        stitchCount: 22,
        rowCount: 30,
        targetWidthCm: 40,
        targetHeightCm: 55,
        stitchesPer10Cm: 22,
        rowsPer10Cm: 30,
        targetStitches: 88,
        targetRows: 165,
        needle: '4.0mm circular',
        memo: 'Measured before blocking.',
        measuredAt: new Date('2026-07-08T12:00:00.000Z'),
        deletedAt: null,
      }),
    });
    expect(response.body).toEqual(expectedGaugeRecordResponse());
  });

  it('rejects invalid measurement values', async () => {
    await request(app.getHttpServer())
      .post('/api/v1/gauge-records')
      .set('Authorization', 'Bearer dev-token')
      .send({
        ...saveGaugeRecordBody,
        sampleWidthCm: 0,
      })
      .expect(400)
      .expect(({ body }) => {
        expect(body.code).toBe('VALIDATION_FAILED');
      });
  });

  it('updates an owned gauge record with recalculated results', async () => {
    const updatedGaugeRecord = {
      ...activeGaugeRecord,
      measurementStage: 'afterWash',
      sampleWidthCm: 12,
      sampleHeightCm: 8,
      stitchCount: 24,
      rowCount: 28,
      targetWidthCm: 48,
      targetHeightCm: 60,
      stitchesPer10Cm: 20,
      rowsPer10Cm: 35,
      targetStitches: 96,
      targetRows: 210,
      needle: '5.0mm circular',
      memo: 'Edited after blocking.',
      measuredAt: new Date('2026-07-09T12:00:00.000Z'),
      updatedAt: new Date('2026-07-09T12:01:00.000Z'),
    };
    prisma.gaugeRecord.update.mockResolvedValueOnce(updatedGaugeRecord);

    const response = await request(app.getHttpServer())
      .patch(`/api/v1/gauge-records/${recordId}`)
      .set('Authorization', 'Bearer dev-token')
      .send({
        ...saveGaugeRecordBody,
        measurementStage: 'afterWash',
        sampleWidthCm: 12,
        sampleHeightCm: 8,
        stitchCount: 24,
        rowCount: 28,
        targetWidthCm: 48,
        targetHeightCm: 60,
        needle: '5.0mm circular',
        memo: 'Edited after blocking.',
        measuredAt: '2026-07-09T12:00:00.000Z',
      })
      .expect(200);

    expect(prisma.gaugeRecord.findFirst).toHaveBeenCalledWith({
      where: {
        id: recordId,
        ownerId: 'user-a',
        deletedAt: null,
      },
    });
    expect(prisma.gaugeRecord.update).toHaveBeenCalledWith({
      where: { id: recordId },
      data: expect.objectContaining({
        projectId,
        projectNameSnapshot: 'Favorite Cardigan',
        patternNameSnapshot: 'Cozy Shawl',
        measurementStage: 'afterWash',
        sampleWidthCm: 12,
        sampleHeightCm: 8,
        stitchCount: 24,
        rowCount: 28,
        targetWidthCm: 48,
        targetHeightCm: 60,
        stitchesPer10Cm: 20,
        rowsPer10Cm: 35,
        targetStitches: 96,
        targetRows: 210,
        needle: '5.0mm circular',
        memo: 'Edited after blocking.',
        measuredAt: new Date('2026-07-09T12:00:00.000Z'),
      }),
    });
    expect(response.body).toEqual({
      ...expectedGaugeRecordResponse(),
      measurementStage: 'afterWash',
      sampleWidthCm: 12,
      sampleHeightCm: 8,
      stitchCount: 24,
      rowCount: 28,
      targetWidthCm: 48,
      targetHeightCm: 60,
      stitchesPer10Cm: 20,
      rowsPer10Cm: 35,
      targetStitches: 96,
      targetRows: 210,
      needle: '5.0mm circular',
      memo: 'Edited after blocking.',
      measuredAt: '2026-07-09T12:00:00.000Z',
      updatedAt: '2026-07-09T12:01:00.000Z',
    });
  });

  it('does not update a missing gauge record', async () => {
    prisma.gaugeRecord.findFirst.mockResolvedValueOnce(null);

    await request(app.getHttpServer())
      .patch(`/api/v1/gauge-records/${recordId}`)
      .set('Authorization', 'Bearer dev-token')
      .send(saveGaugeRecordBody)
      .expect(404)
      .expect(({ body }) => {
        expect(body.code).toBe('GAUGE_RECORD_NOT_FOUND');
      });

    expect(prisma.gaugeRecord.update).not.toHaveBeenCalled();
  });

  it('soft deletes an owned gauge record', async () => {
    await request(app.getHttpServer())
      .delete(`/api/v1/gauge-records/${recordId}`)
      .set('Authorization', 'Bearer dev-token')
      .expect(204);

    expect(prisma.gaugeRecord.findFirst).toHaveBeenCalledWith({
      where: {
        id: recordId,
        ownerId: 'user-a',
        deletedAt: null,
      },
    });
    expect(prisma.gaugeRecord.update).toHaveBeenCalledWith({
      where: { id: recordId },
      data: {
        deletedAt: expect.any(Date),
      },
    });
  });

  function expectedGaugeRecordResponse() {
    return {
      id: recordId,
      ownerId: 'user-a',
      projectId,
      projectNameSnapshot: 'Favorite Cardigan',
      patternNameSnapshot: 'Cozy Shawl',
      measurementStage: 'beforeWash',
      sampleWidthCm: 10,
      sampleHeightCm: 10,
      stitchCount: 22,
      rowCount: 30,
      targetWidthCm: 40,
      targetHeightCm: 55,
      stitchesPer10Cm: 22,
      rowsPer10Cm: 30,
      targetStitches: 88,
      targetRows: 165,
      needle: '4.0mm circular',
      memo: 'Measured before blocking.',
      measuredAt: '2026-07-08T12:00:00.000Z',
      createdAt: '2026-07-08T12:01:00.000Z',
      updatedAt: '2026-07-08T12:01:00.000Z',
      deletedAt: null,
      syncStatus: 'Synced',
    };
  }
});
