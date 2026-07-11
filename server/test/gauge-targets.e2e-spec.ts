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
  gaugeTarget: {
    findMany: jest.Mock;
    findFirst: jest.Mock;
    create: jest.Mock;
    update: jest.Mock;
  };
  gaugeSwatch: {
    create: jest.Mock;
    updateMany: jest.Mock;
  };
  gaugeMeasurement: {
    createMany: jest.Mock;
    updateMany: jest.Mock;
  };
  $transaction: jest.Mock;
};

describe('Gauge targets route', () => {
  let app: INestApplication;
  let prisma: MockPrismaService;

  const targetId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
  const patternId = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
  const swatchId = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';
  const measurementId = 'dddddddd-dddd-4ddd-8ddd-dddddddddddd';

  const activeGaugeMeasurement = {
    id: measurementId,
    ownerId: 'user-a',
    gaugeTargetId: targetId,
    gaugeSwatchId: swatchId,
    method: 'manual',
    washState: 'before',
    measuredWidth: 10,
    measuredHeight: 10,
    rawStitches: 22,
    rawRows: 30,
    normalizedStitches: 22,
    normalizedRows: 30,
    finalStitches: 22,
    finalRows: 30,
    autoStitches: 0,
    autoRows: 0,
    autoConfidence: null,
    userModified: false,
    photoPath: null,
    cornerCoordinates: null,
    createdAt: new Date('2026-07-09T03:02:00.000Z'),
    updatedAt: new Date('2026-07-09T03:02:00.000Z'),
    deletedAt: null,
  };

  const activeGaugeSwatch = {
    id: swatchId,
    ownerId: 'user-a',
    gaugeTargetId: targetId,
    isSelected: true,
    knittedAt: new Date('2026-07-09T02:00:00.000Z'),
    needleMaterial: 'Wood',
    needleSize: '4.0 mm',
    needleType: 'Circular',
    notes: 'Before blocking.',
    stitchPattern: 'stockinette',
    yarnBrand: 'Sample Yarn Co.',
    yarnColor: 'Cloud Gray',
    yarnLot: 'LOT-1',
    yarnName: 'Soft Merino DK',
    createdAt: new Date('2026-07-09T03:01:00.000Z'),
    updatedAt: new Date('2026-07-09T03:01:00.000Z'),
    deletedAt: null,
    measurements: [activeGaugeMeasurement],
  };

  const activeGaugeTarget = {
    id: targetId,
    ownerId: 'user-a',
    name: 'Cozy Shawl gauge',
    targetStitches: 22,
    targetWidth: 10,
    targetRows: 30,
    targetHeight: 10,
    isQuickMeasure: false,
    gaugeAfterWash: true,
    recommendedNeedle: '4.0 mm circular',
    sourcePatternId: patternId,
    createdAt: new Date('2026-07-09T03:00:00.000Z'),
    updatedAt: new Date('2026-07-09T03:00:00.000Z'),
    deletedAt: null,
    swatches: [activeGaugeSwatch],
  };

  const saveGaugeTargetBody = {
    id: targetId,
    name: 'Cozy Shawl gauge',
    targetStitches: 22,
    targetWidth: 10,
    targetRows: 30,
    targetHeight: 10,
    isQuickMeasure: false,
    gaugeAfterWash: true,
    recommendedNeedle: '4.0 mm circular',
    sourcePatternId: patternId,
    createdAt: '2026-07-09T03:00:00.000Z',
    swatches: [
      {
        id: swatchId,
        isSelected: true,
        knittedAt: '2026-07-09T02:00:00.000Z',
        needleMaterial: 'Wood',
        needleSize: '4.0 mm',
        needleType: 'Circular',
        notes: 'Before blocking.',
        stitchPattern: 'stockinette',
        yarnBrand: 'Sample Yarn Co.',
        yarnColor: 'Cloud Gray',
        yarnLot: 'LOT-1',
        yarnName: 'Soft Merino DK',
        createdAt: '2026-07-09T03:01:00.000Z',
        measurements: [
          {
            id: measurementId,
            method: 'manual',
            washState: 'before',
            measuredWidth: 10,
            measuredHeight: 10,
            rawStitches: 22,
            rawRows: 30,
            normalizedStitches: 22,
            normalizedRows: 30,
            finalStitches: 22,
            finalRows: 30,
            autoStitches: 0,
            autoRows: 0,
            autoConfidence: null,
            userModified: false,
            photoPath: null,
            cornerCoordinates: null,
            createdAt: '2026-07-09T03:02:00.000Z',
          },
        ],
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
      gaugeTarget: {
        findMany: jest.fn(),
        findFirst: jest.fn(),
        create: jest.fn(),
        update: jest.fn(),
      },
      gaugeSwatch: {
        create: jest.fn(),
        updateMany: jest.fn(),
      },
      gaugeMeasurement: {
        createMany: jest.fn(),
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
    prisma.gaugeTarget.findMany.mockReset();
    prisma.gaugeTarget.findFirst.mockReset();
    prisma.gaugeTarget.create.mockReset();
    prisma.gaugeTarget.update.mockReset();
    prisma.gaugeSwatch.create.mockReset();
    prisma.gaugeSwatch.updateMany.mockReset();
    prisma.gaugeMeasurement.createMany.mockReset();
    prisma.gaugeMeasurement.updateMany.mockReset();
    prisma.$transaction.mockReset();
    prisma.$transaction.mockImplementation(async (callback) => callback(prisma));

    prisma.userProfile.upsert.mockResolvedValue(undefined);
    prisma.gaugeTarget.findMany.mockResolvedValue([activeGaugeTarget]);
    prisma.gaugeTarget.findFirst.mockResolvedValue(activeGaugeTarget);
    prisma.gaugeTarget.create.mockResolvedValue(activeGaugeTarget);
    prisma.gaugeTarget.update.mockResolvedValue(activeGaugeTarget);
    prisma.gaugeSwatch.create.mockResolvedValue(activeGaugeSwatch);
    prisma.gaugeSwatch.updateMany.mockResolvedValue({ count: 1 });
    prisma.gaugeMeasurement.createMany.mockResolvedValue({ count: 1 });
    prisma.gaugeMeasurement.updateMany.mockResolvedValue({ count: 1 });
  });

  afterAll(async () => {
    delete process.env.DEV_AUTH_TOKEN;
    delete process.env.DEV_AUTH_USER_ID;
    await app.close();
  });

  it('rejects unauthenticated requests', async () => {
    await request(app.getHttpServer())
      .get('/api/v1/gauge-targets')
      .expect(401)
      .expect(({ body }) => {
        expect(body.code).toBe('UNAUTHENTICATED');
      });
  });

  it('lists active gauge targets with swatches and measurements', async () => {
    const response = await request(app.getHttpServer())
      .get('/api/v1/gauge-targets')
      .set('Authorization', 'Bearer dev-token')
      .expect(200);

    expect(prisma.gaugeTarget.findMany).toHaveBeenCalledWith({
      where: {
        ownerId: 'user-a',
        deletedAt: null,
      },
      include: expect.any(Object),
      orderBy: {
        createdAt: 'desc',
      },
    });
    expect(response.body).toEqual([expectedGaugeTargetResponse()]);
  });

  it('creates a gauge target with nested swatches and measurements', async () => {
    const response = await request(app.getHttpServer())
      .post('/api/v1/gauge-targets')
      .set('Authorization', 'Bearer dev-token')
      .send(saveGaugeTargetBody)
      .expect(201);

    expect(prisma.userProfile.upsert).toHaveBeenCalledWith({
      where: { id: 'user-a' },
      create: {
        id: 'user-a',
        displayName: 'user-a',
      },
      update: {},
    });
    expect(prisma.gaugeTarget.create).toHaveBeenCalledWith({
      data: expect.objectContaining({
        id: targetId,
        ownerId: 'user-a',
        name: 'Cozy Shawl gauge',
        targetStitches: 22,
        targetWidth: 10,
        targetRows: 30,
        targetHeight: 10,
        isQuickMeasure: false,
        gaugeAfterWash: true,
        recommendedNeedle: '4.0 mm circular',
        sourcePatternId: patternId,
        deletedAt: null,
      }),
      include: expect.any(Object),
    });
    expect(prisma.gaugeSwatch.create).toHaveBeenCalledWith({
      data: expect.objectContaining({
        id: swatchId,
        ownerId: 'user-a',
        gaugeTargetId: targetId,
        isSelected: true,
        needleSize: '4.0 mm',
      }),
    });
    expect(prisma.gaugeMeasurement.createMany).toHaveBeenCalledWith({
      data: [
        expect.objectContaining({
          id: measurementId,
          ownerId: 'user-a',
          gaugeTargetId: targetId,
          gaugeSwatchId: swatchId,
          method: 'manual',
          washState: 'before',
          finalStitches: 22,
          finalRows: 30,
        }),
      ],
    });
    expect(response.body).toEqual(expectedGaugeTargetResponse());
  });

  it('rejects invalid target dimensions', async () => {
    await request(app.getHttpServer())
      .post('/api/v1/gauge-targets')
      .set('Authorization', 'Bearer dev-token')
      .send({
        ...saveGaugeTargetBody,
        targetWidth: 0,
      })
      .expect(400)
      .expect(({ body }) => {
        expect(body.code).toBe('VALIDATION_FAILED');
      });
  });

  it('soft deletes an owned gauge target and its nested data', async () => {
    await request(app.getHttpServer())
      .delete(`/api/v1/gauge-targets/${targetId}`)
      .set('Authorization', 'Bearer dev-token')
      .expect(204);

    expect(prisma.gaugeTarget.findFirst).toHaveBeenCalledWith({
      where: {
        id: targetId,
        ownerId: 'user-a',
        deletedAt: null,
      },
    });
    expect(prisma.gaugeTarget.update).toHaveBeenCalledWith({
      where: { id: targetId },
      data: {
        deletedAt: expect.any(Date),
      },
    });
    expect(prisma.gaugeSwatch.updateMany).toHaveBeenCalledWith({
      where: {
        ownerId: 'user-a',
        gaugeTargetId: targetId,
        deletedAt: null,
      },
      data: {
        deletedAt: expect.any(Date),
      },
    });
    expect(prisma.gaugeMeasurement.updateMany).toHaveBeenCalledWith({
      where: {
        ownerId: 'user-a',
        gaugeTargetId: targetId,
        deletedAt: null,
      },
      data: {
        deletedAt: expect.any(Date),
      },
    });
  });

  function expectedGaugeTargetResponse() {
    return {
      id: targetId,
      ownerId: 'user-a',
      name: 'Cozy Shawl gauge',
      targetStitches: 22,
      targetWidth: 10,
      targetRows: 30,
      targetHeight: 10,
      isQuickMeasure: false,
      gaugeAfterWash: true,
      recommendedNeedle: '4.0 mm circular',
      sourcePatternId: patternId,
      createdAt: '2026-07-09T03:00:00.000Z',
      updatedAt: '2026-07-09T03:00:00.000Z',
      deletedAt: null,
      syncStatus: 'Synced',
      swatches: [
        {
          id: swatchId,
          ownerId: 'user-a',
          gaugeTargetId: targetId,
          isSelected: true,
          knittedAt: '2026-07-09T02:00:00.000Z',
          needleMaterial: 'Wood',
          needleSize: '4.0 mm',
          needleType: 'Circular',
          notes: 'Before blocking.',
          stitchPattern: 'stockinette',
          yarnBrand: 'Sample Yarn Co.',
          yarnColor: 'Cloud Gray',
          yarnLot: 'LOT-1',
          yarnName: 'Soft Merino DK',
          createdAt: '2026-07-09T03:01:00.000Z',
          updatedAt: '2026-07-09T03:01:00.000Z',
          deletedAt: null,
          syncStatus: 'Synced',
          measurements: [
            {
              id: measurementId,
              ownerId: 'user-a',
              gaugeTargetId: targetId,
              gaugeSwatchId: swatchId,
              method: 'manual',
              washState: 'before',
              measuredWidth: 10,
              measuredHeight: 10,
              rawStitches: 22,
              rawRows: 30,
              normalizedStitches: 22,
              normalizedRows: 30,
              finalStitches: 22,
              finalRows: 30,
              autoStitches: 0,
              autoRows: 0,
              autoConfidence: null,
              userModified: false,
              photoPath: null,
              cornerCoordinates: null,
              createdAt: '2026-07-09T03:02:00.000Z',
              updatedAt: '2026-07-09T03:02:00.000Z',
              deletedAt: null,
              syncStatus: 'Synced',
            },
          ],
        },
      ],
    };
  }
});
