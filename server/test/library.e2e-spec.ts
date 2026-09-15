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
  project: {
    findFirst: jest.Mock;
  };
  projectYarnLink: {
    findMany: jest.Mock;
    findFirst: jest.Mock;
    create: jest.Mock;
    update: jest.Mock;
    updateMany: jest.Mock;
  };
  projectNeedleLink: {
    findMany: jest.Mock;
    findFirst: jest.Mock;
    create: jest.Mock;
    update: jest.Mock;
    updateMany: jest.Mock;
  };
  projectToolLink: {
    findMany: jest.Mock;
  };
  toolItem: {
    findFirst: jest.Mock;
  };
  $transaction: jest.Mock;
};

describe('Library route', () => {
  let app: INestApplication;
  let prisma: MockPrismaService;
  let storageRoot: string;

  const yarnId = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';
  const needleId = 'dddddddd-dddd-4ddd-8ddd-dddddddddddd';
  const toolId = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee';
  const activeTool = {
    id: toolId,
    ownerId: 'user-a',
    name: 'Stitch marker',
    deletedAt: null,
  };
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

  const projectId = '11111111-1111-4111-8111-111111111111';
  const activeProject = {
    id: projectId,
    ownerId: 'user-a',
    deletedAt: null,
  };
  const yarnLink = {
    id: 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee',
    ownerId: 'user-a',
    projectId,
    yarnId,
    nameSnapshot: activeYarn.name,
    brandSnapshot: activeYarn.brand,
    colorwaySnapshot: activeYarn.colorway,
    weightSnapshot: activeYarn.weight,
    linkedAt: new Date('2026-07-09T03:00:00.000Z'),
    createdAt: new Date('2026-07-09T03:00:00.000Z'),
    updatedAt: new Date('2026-07-09T03:00:00.000Z'),
    deletedAt: null,
  };
  const needleLink = {
    id: 'ffffffff-ffff-4fff-8fff-ffffffffffff',
    ownerId: 'user-a',
    projectId,
    needleId,
    nameSnapshot: activeNeedle.name,
    typeSnapshot: activeNeedle.needleType,
    sizeSnapshot: activeNeedle.size,
    lengthSnapshot: activeNeedle.length,
    linkedAt: new Date('2026-07-09T03:00:00.000Z'),
    createdAt: new Date('2026-07-09T03:00:00.000Z'),
    updatedAt: new Date('2026-07-09T03:00:00.000Z'),
    deletedAt: null,
  };

  beforeAll(async () => {
    process.env.DEV_AUTH_TOKEN = 'dev-token';
    process.env.DEV_AUTH_USER_ID = 'user-a';
    storageRoot = await fs.mkdtemp(join(tmpdir(), 'knitgether-library-'));
    process.env.FILE_STORAGE_ROOT = storageRoot;

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
      project: {
        findFirst: jest.fn(),
      },
      projectYarnLink: {
        findMany: jest.fn(),
        findFirst: jest.fn(),
        create: jest.fn(),
        update: jest.fn(),
        updateMany: jest.fn(),
      },
      projectNeedleLink: {
        findMany: jest.fn(),
        findFirst: jest.fn(),
        create: jest.fn(),
        update: jest.fn(),
        updateMany: jest.fn(),
      },
      projectToolLink: {
        findMany: jest.fn(),
      },
      toolItem: {
        findFirst: jest.fn(),
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
    prisma.project.findFirst.mockReset();
    prisma.projectYarnLink.findMany.mockReset();
    prisma.projectYarnLink.findFirst.mockReset();
    prisma.projectYarnLink.create.mockReset();
    prisma.projectYarnLink.update.mockReset();
    prisma.projectYarnLink.updateMany.mockReset();
    prisma.projectNeedleLink.findMany.mockReset();
    prisma.projectNeedleLink.findFirst.mockReset();
    prisma.projectNeedleLink.create.mockReset();
    prisma.projectNeedleLink.update.mockReset();
    prisma.projectNeedleLink.updateMany.mockReset();
    prisma.projectToolLink.findMany.mockReset();
    prisma.projectToolLink.findMany.mockResolvedValue([]);
    prisma.toolItem.findFirst.mockReset();
    prisma.toolItem.findFirst.mockResolvedValue(activeTool);
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
    prisma.project.findFirst.mockResolvedValue(activeProject);
    prisma.projectYarnLink.findMany.mockResolvedValue([yarnLink]);
    prisma.projectYarnLink.findFirst.mockResolvedValue(null);
    prisma.projectYarnLink.create.mockResolvedValue(yarnLink);
    prisma.projectYarnLink.update.mockResolvedValue(yarnLink);
    prisma.projectYarnLink.updateMany.mockResolvedValue({ count: 1 });
    prisma.projectNeedleLink.findMany.mockResolvedValue([needleLink]);
    prisma.projectNeedleLink.findFirst.mockResolvedValue(null);
    prisma.projectNeedleLink.create.mockResolvedValue(needleLink);
    prisma.projectNeedleLink.update.mockResolvedValue(needleLink);
    prisma.projectNeedleLink.updateMany.mockResolvedValue({ count: 1 });
  });

  afterAll(async () => {
    delete process.env.DEV_AUTH_TOKEN;
    delete process.env.DEV_AUTH_USER_ID;
    delete process.env.FILE_STORAGE_ROOT;
    await app.close();
    await fs.rm(storageRoot, { recursive: true, force: true });
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

  it('links a yarn to a project with a link-time snapshot', async () => {
    const response = await request(app.getHttpServer())
      .post(`/api/v1/library/projects/${projectId}/yarns/${yarnId}`)
      .set('Authorization', 'Bearer dev-token')
      .expect(201);

    expect(prisma.projectYarnLink.create).toHaveBeenCalledWith({
      data: expect.objectContaining({
        ownerId: 'user-a',
        projectId,
        yarnId,
        nameSnapshot: activeYarn.name,
        brandSnapshot: activeYarn.brand,
        colorwaySnapshot: activeYarn.colorway,
        weightSnapshot: activeYarn.weight,
        deletedAt: null,
      }),
    });
    expect(response.body.nameSnapshot).toBe(activeYarn.name);
  });

  it('refreshes the snapshot when relinking an existing yarn link', async () => {
    prisma.projectYarnLink.findFirst.mockResolvedValue(yarnLink);

    await request(app.getHttpServer())
      .post(`/api/v1/library/projects/${projectId}/yarns/${yarnId}`)
      .set('Authorization', 'Bearer dev-token')
      .expect(201);

    expect(prisma.projectYarnLink.create).not.toHaveBeenCalled();
    expect(prisma.projectYarnLink.update).toHaveBeenCalledWith({
      where: { id: yarnLink.id },
      data: expect.objectContaining({
        nameSnapshot: activeYarn.name,
        deletedAt: null,
      }),
    });
  });

  // DEF-25. 창고 삭제 고지를 연결 기준으로 통일하면서 신설한 역방향 조회.
  // 실은 사용 기록 기준이었고 바늘과 도구는 고지가 아예 없었다.
  it('counts only live projects linked to a yarn', async () => {
    prisma.projectYarnLink.findMany.mockResolvedValue([
      { projectId: projectId },
      { projectId: '22222222-2222-4222-8222-222222222222' },
    ]);

    const response = await request(app.getHttpServer())
      .get(`/api/v1/library/yarns/${yarnId}/linked-project-count`)
      .set('Authorization', 'Bearer dev-token')
      .expect(200);

    expect(response.body).toEqual({ projectCount: 2 });
    // 삭제된 프로젝트에 걸린 링크를 세면 사용자가 찾을 수 없는 개수를 고지하게 된다.
    // 이 조건이 없으면 전부 세는 구현도 개수만 맞으면 통과한다.
    expect(prisma.projectYarnLink.findMany).toHaveBeenCalledWith({
      where: {
        ownerId: 'user-a',
        yarnId,
        deletedAt: null,
        project: {
          deletedAt: null,
        },
      },
      select: {
        projectId: true,
      },
      distinct: ['projectId'],
    });
  });

  it('counts only live projects linked to a needle', async () => {
    prisma.projectNeedleLink.findMany.mockResolvedValue([
      { projectId: projectId },
    ]);

    const response = await request(app.getHttpServer())
      .get(`/api/v1/library/needles/${needleId}/linked-project-count`)
      .set('Authorization', 'Bearer dev-token')
      .expect(200);

    expect(response.body).toEqual({ projectCount: 1 });
    expect(prisma.projectNeedleLink.findMany).toHaveBeenCalledWith({
      where: {
        ownerId: 'user-a',
        needleId,
        deletedAt: null,
        project: {
          deletedAt: null,
        },
      },
      select: {
        projectId: true,
      },
      distinct: ['projectId'],
    });
  });

  it('counts only live projects linked to a tool', async () => {
    prisma.projectToolLink.findMany.mockResolvedValue([
      { projectId: projectId },
    ]);

    const response = await request(app.getHttpServer())
      .get(`/api/v1/library/tools/${toolId}/linked-project-count`)
      .set('Authorization', 'Bearer dev-token')
      .expect(200);

    expect(response.body).toEqual({ projectCount: 1 });
    expect(prisma.projectToolLink.findMany).toHaveBeenCalledWith({
      where: {
        ownerId: 'user-a',
        toolId,
        deletedAt: null,
        project: {
          deletedAt: null,
        },
      },
      select: {
        projectId: true,
      },
      distinct: ['projectId'],
    });
  });

  it('returns 404 when counting links for a yarn that does not exist', async () => {
    prisma.yarn.findFirst.mockResolvedValue(null);

    await request(app.getHttpServer())
      .get(`/api/v1/library/yarns/${yarnId}/linked-project-count`)
      .set('Authorization', 'Bearer dev-token')
      .expect(404);
  });

  it('lists project yarn links regardless of yarn liveness', async () => {
    const response = await request(app.getHttpServer())
      .get(`/api/v1/library/projects/${projectId}/yarn-links`)
      .set('Authorization', 'Bearer dev-token')
      .expect(200);

    expect(prisma.projectYarnLink.findMany).toHaveBeenCalledWith({
      where: {
        ownerId: 'user-a',
        projectId,
        deletedAt: null,
      },
      orderBy: {
        linkedAt: 'asc',
      },
    });
    expect(response.body).toHaveLength(1);
    expect(response.body[0].nameSnapshot).toBe(activeYarn.name);
  });

  it('unlinks a yarn from a project with a tombstone', async () => {
    await request(app.getHttpServer())
      .delete(`/api/v1/library/projects/${projectId}/yarns/${yarnId}`)
      .set('Authorization', 'Bearer dev-token')
      .expect(204);

    expect(prisma.projectYarnLink.updateMany).toHaveBeenCalledWith({
      where: {
        ownerId: 'user-a',
        projectId,
        yarnId,
        deletedAt: null,
      },
      data: {
        deletedAt: expect.any(Date),
      },
    });
  });

  it('links a needle to a project with a link-time snapshot', async () => {
    const response = await request(app.getHttpServer())
      .post(`/api/v1/library/projects/${projectId}/needles/${needleId}`)
      .set('Authorization', 'Bearer dev-token')
      .expect(201);

    expect(prisma.projectNeedleLink.create).toHaveBeenCalledWith({
      data: expect.objectContaining({
        ownerId: 'user-a',
        projectId,
        needleId,
        nameSnapshot: activeNeedle.name,
        typeSnapshot: activeNeedle.needleType,
        sizeSnapshot: activeNeedle.size,
        lengthSnapshot: activeNeedle.length,
        deletedAt: null,
      }),
    });
    expect(response.body.sizeSnapshot).toBe(activeNeedle.size);
  });

  it('uploads a representative photo for an owned yarn', async () => {
    const photoBytes = Buffer.from([0xff, 0xd8, 0xff, 0xe0, 0x00, 0x10]);
    prisma.yarn.update.mockResolvedValue({
      ...activeYarn,
      photoContentType: 'image/jpeg',
      photoByteSize: photoBytes.byteLength,
    });

    const response = await request(app.getHttpServer())
      .post(`/api/v1/library/yarns/${yarnId}/photo`)
      .set('Authorization', 'Bearer dev-token')
      .attach('file', photoBytes, {
        filename: 'yarn.jpg',
        contentType: 'image/jpeg',
      })
      .expect(201);

    expect(prisma.yarn.update).toHaveBeenCalledWith({
      where: { id: yarnId },
      data: expect.objectContaining({
        photoStorageKey: expect.stringContaining(`library/user-a/yarns/${yarnId}`),
        photoContentType: 'image/jpeg',
        photoByteSize: photoBytes.byteLength,
      }),
    });
    expect(response.body.photoContentType).toBe('image/jpeg');
  });

  it('rejects a non-image yarn photo upload', async () => {
    await request(app.getHttpServer())
      .post(`/api/v1/library/yarns/${yarnId}/photo`)
      .set('Authorization', 'Bearer dev-token')
      .attach('file', Buffer.from('plain text'), {
        filename: 'notes.txt',
        contentType: 'text/plain',
      })
      .expect(400)
      .expect(({ body }) => {
        expect(body.code).toBe('VALIDATION_FAILED');
      });

    expect(prisma.yarn.update).not.toHaveBeenCalled();
  });

  it('deletes a yarn photo and clears photo fields', async () => {
    prisma.yarn.findFirst.mockResolvedValue({
      ...activeYarn,
      photoStorageKey: `library/user-a/yarns/${yarnId}/old.jpg`,
      photoContentType: 'image/jpeg',
      photoByteSize: 6,
    });

    await request(app.getHttpServer())
      .delete(`/api/v1/library/yarns/${yarnId}/photo`)
      .set('Authorization', 'Bearer dev-token')
      .expect(200);

    expect(prisma.yarn.update).toHaveBeenCalledWith({
      where: { id: yarnId },
      data: {
        photoStorageKey: null,
        photoContentType: null,
        photoByteSize: null,
      },
    });
  });

  it('rejects a yarn name longer than 30 characters', async () => {
    await request(app.getHttpServer())
      .post('/api/v1/library/yarns')
      .set('Authorization', 'Bearer dev-token')
      .send({
        ...saveYarnBody,
        name: 'a'.repeat(31),
      })
      .expect(400);

    expect(prisma.yarn.create).not.toHaveBeenCalled();
  });

  it('rejects yarn notes longer than 500 characters', async () => {
    await request(app.getHttpServer())
      .post('/api/v1/library/yarns')
      .set('Authorization', 'Bearer dev-token')
      .send({
        ...saveYarnBody,
        notes: 'a'.repeat(501),
      })
      .expect(400);

    expect(prisma.yarn.create).not.toHaveBeenCalled();
  });

  it('rejects a needle name longer than 30 characters', async () => {
    await request(app.getHttpServer())
      .post('/api/v1/library/needles')
      .set('Authorization', 'Bearer dev-token')
      .send({
        ...saveNeedleBody,
        name: 'a'.repeat(31),
      })
      .expect(400);

    expect(prisma.needle.create).not.toHaveBeenCalled();
  });

  it('rejects a tool name longer than 30 characters', async () => {
    // 길이 검증은 ValidationPipe 단계에서 끝나므로 도구 모델 목킹 없이도 검증된다.
    await request(app.getHttpServer())
      .post('/api/v1/library/tools')
      .set('Authorization', 'Bearer dev-token')
      .send({
        name: 'a'.repeat(31),
        type: 'marker',
      })
      .expect(400);
  });

  function expectedYarnResponse() {
    return {
      id: yarnId,
      ownerId: 'user-a',
      photoContentType: null,
      photoByteSize: null,
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
      photoContentType: null,
      photoByteSize: null,
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
