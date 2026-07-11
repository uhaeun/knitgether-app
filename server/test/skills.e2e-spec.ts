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
  skill: {
    findMany: jest.Mock;
    findFirst: jest.Mock;
    create: jest.Mock;
    update: jest.Mock;
  };
  userSkillLevel: {
    findMany: jest.Mock;
    upsert: jest.Mock;
  };
  skillAnimation: {
    findMany: jest.Mock;
  };
  $transaction: jest.Mock;
};

describe('Skills route', () => {
  let app: INestApplication;
  let prisma: MockPrismaService;

  const skillId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
  const animationId = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
  const activeSkill = {
    id: skillId,
    ownerId: 'user-a',
    name: 'Knit',
    abbreviation: 'K',
    description: 'Knit stitch.',
    category: '기초',
    difficulty: '잘 알아요',
    animationName: 'knit-loop',
    animationType: 'loop',
    steps: ['Insert right needle.', 'Wrap yarn.', 'Pull through.'],
    animationIds: [animationId],
    createdAt: new Date('2026-07-09T00:00:00.000Z'),
    updatedAt: new Date('2026-07-09T00:05:00.000Z'),
    deletedAt: null,
    isSystem: false,
  };
  const systemSkill = {
    ...activeSkill,
    id: '11111111-1111-4111-8111-111111111111',
    ownerId: 'system',
    name: 'Make one right',
    abbreviation: 'M1R',
    description: 'Increase one stitch leaning right.',
    difficulty: '중급',
    isSystem: true,
  };
  const activeSkillLevel = {
    id: '22222222-2222-4222-8222-222222222222',
    ownerId: 'user-a',
    skillId: systemSkill.id,
    level: '헷갈려요',
    createdAt: new Date('2026-07-09T00:00:00.000Z'),
    updatedAt: new Date('2026-07-09T00:05:00.000Z'),
    deletedAt: null,
  };
  const activeAnimation = {
    id: animationId,
    ownerId: 'user-a',
    skillId,
    title: 'Knit stitch loop',
    localAssetName: 'knit-loop',
    durationSeconds: 8,
    createdAt: new Date('2026-07-09T00:00:00.000Z'),
    updatedAt: new Date('2026-07-09T00:05:00.000Z'),
    deletedAt: null,
  };
  const saveSkillBody = {
    id: skillId,
    name: 'Knit',
    abbreviation: 'K',
    description: 'Knit stitch.',
    category: '기초',
    difficulty: '잘 알아요',
    animationName: 'knit-loop',
    animationType: 'loop',
    steps: ['Insert right needle.', 'Wrap yarn.', 'Pull through.'],
    animationIds: [animationId],
  };

  beforeAll(async () => {
    process.env.DEV_AUTH_TOKEN = 'dev-token';
    process.env.DEV_AUTH_USER_ID = 'user-a';

    prisma = {
      userProfile: {
        upsert: jest.fn(),
      },
      skill: {
        findMany: jest.fn(),
        findFirst: jest.fn(),
        create: jest.fn(),
        update: jest.fn(),
      },
      userSkillLevel: {
        findMany: jest.fn(),
        upsert: jest.fn(),
      },
      skillAnimation: {
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
    prisma.skill.findMany.mockReset();
    prisma.skill.findFirst.mockReset();
    prisma.skill.create.mockReset();
    prisma.skill.update.mockReset();
    prisma.userSkillLevel.findMany.mockReset();
    prisma.userSkillLevel.upsert.mockReset();
    prisma.skillAnimation.findMany.mockReset();
    prisma.$transaction.mockReset();
    prisma.$transaction.mockImplementation(async (callback) => callback(prisma));
    prisma.userProfile.upsert.mockResolvedValue(undefined);
    prisma.skill.findMany.mockResolvedValue([activeSkill]);
    prisma.skill.findFirst.mockResolvedValue(activeSkill);
    prisma.skill.create.mockResolvedValue(activeSkill);
    prisma.skill.update.mockResolvedValue(activeSkill);
    prisma.userSkillLevel.findMany.mockResolvedValue([]);
    prisma.userSkillLevel.upsert.mockResolvedValue(activeSkillLevel);
    prisma.skillAnimation.findMany.mockResolvedValue([activeAnimation]);
  });

  afterAll(async () => {
    delete process.env.DEV_AUTH_TOKEN;
    delete process.env.DEV_AUTH_USER_ID;
    await app.close();
  });

  it('rejects unauthenticated requests', async () => {
    await request(app.getHttpServer())
      .get('/api/v1/skills')
      .expect(401)
      .expect(({ body }) => {
        expect(body.code).toBe('UNAUTHENTICATED');
      });
  });

  it('lists active system and user skills with current user levels', async () => {
    prisma.skill.findMany.mockResolvedValue([systemSkill, activeSkill]);
    prisma.userSkillLevel.findMany.mockResolvedValue([activeSkillLevel]);

    const response = await request(app.getHttpServer())
      .get('/api/v1/skills')
      .set('Authorization', 'Bearer dev-token')
      .expect(200);

    expect(prisma.skill.findMany).toHaveBeenCalledWith({
      where: {
        deletedAt: null,
        OR: [
          { isSystem: true },
          { ownerId: 'user-a' },
        ],
      },
      orderBy: [
        { category: 'asc' },
        { name: 'asc' },
      ],
    });
    expect(prisma.userSkillLevel.findMany).toHaveBeenCalledWith({
      where: {
        ownerId: 'user-a',
        skillId: {
          in: [systemSkill.id, activeSkill.id],
        },
        deletedAt: null,
      },
    });
    expect(response.body).toEqual([
      expectedSkillResponse({
        id: systemSkill.id,
        ownerId: 'system',
        name: 'Make one right',
        abbreviation: 'M1R',
        description: 'Increase one stitch leaning right.',
        difficulty: '중급',
        isSystem: true,
        userLevel: '헷갈려요',
      }),
      expectedSkillResponse(),
    ]);
  });

  it('returns one active skill owned by the current user', async () => {
    const response = await request(app.getHttpServer())
      .get(`/api/v1/skills/${skillId}`)
      .set('Authorization', 'Bearer dev-token')
      .expect(200);

    expect(prisma.skill.findFirst).toHaveBeenCalledWith({
      where: {
        id: skillId,
        deletedAt: null,
        OR: [
          { isSystem: true },
          { ownerId: 'user-a' },
        ],
      },
    });
    expect(response.body).toEqual(expectedSkillResponse());
  });

  it('creates a skill for the current user', async () => {
    const response = await request(app.getHttpServer())
      .post('/api/v1/skills')
      .set('Authorization', 'Bearer dev-token')
      .send(saveSkillBody)
      .expect(201);

    expect(prisma.userProfile.upsert).toHaveBeenCalledWith({
      where: { id: 'user-a' },
      create: {
        id: 'user-a',
        displayName: 'user-a',
      },
      update: {},
    });
    expect(prisma.skill.create).toHaveBeenCalledWith({
      data: expect.objectContaining({
        id: skillId,
        ownerId: 'user-a',
        name: 'Knit',
        abbreviation: 'K',
        description: 'Knit stitch.',
        category: '기초',
        difficulty: '잘 알아요',
        animationName: 'knit-loop',
        animationType: 'loop',
        steps: ['Insert right needle.', 'Wrap yarn.', 'Pull through.'],
        animationIds: [animationId],
        deletedAt: null,
      }),
    });
    expect(response.body).toEqual(expectedSkillResponse());
  });

  it('updates an owned skill', async () => {
    const response = await request(app.getHttpServer())
      .patch(`/api/v1/skills/${skillId}`)
      .set('Authorization', 'Bearer dev-token')
      .send({
        ...saveSkillBody,
        name: 'Knit stitch',
      })
      .expect(200);

    expect(prisma.skill.findFirst).toHaveBeenCalledWith({
      where: {
        id: skillId,
        deletedAt: null,
        OR: [
          { isSystem: true },
          { ownerId: 'user-a' },
        ],
      },
    });
    expect(prisma.skill.update).toHaveBeenCalledWith({
      where: { id: skillId },
      data: expect.objectContaining({
        name: 'Knit stitch',
        abbreviation: 'K',
        description: 'Knit stitch.',
        category: '기초',
        difficulty: '잘 알아요',
        animationName: 'knit-loop',
        animationType: 'loop',
        steps: ['Insert right needle.', 'Wrap yarn.', 'Pull through.'],
        animationIds: [animationId],
      }),
    });
    expect(response.body).toEqual(expectedSkillResponse());
  });

  it('rejects direct updates to system skills', async () => {
    prisma.skill.findFirst.mockResolvedValue(systemSkill);

    await request(app.getHttpServer())
      .patch(`/api/v1/skills/${systemSkill.id}`)
      .set('Authorization', 'Bearer dev-token')
      .send(saveSkillBody)
      .expect(403);

    expect(prisma.skill.update).not.toHaveBeenCalled();
  });

  it('updates the current user level for a system skill', async () => {
    prisma.skill.findFirst.mockResolvedValue(systemSkill);
    prisma.userSkillLevel.upsert.mockResolvedValue({
      ...activeSkillLevel,
      level: '잘 알아요',
    });

    const response = await request(app.getHttpServer())
      .patch(`/api/v1/skills/${systemSkill.id}/level`)
      .set('Authorization', 'Bearer dev-token')
      .send({ level: '잘 알아요' })
      .expect(200);

    expect(prisma.userProfile.upsert).toHaveBeenCalledWith({
      where: { id: 'user-a' },
      create: {
        id: 'user-a',
        displayName: 'user-a',
      },
      update: {},
    });
    expect(prisma.userSkillLevel.upsert).toHaveBeenCalledWith({
      where: {
        ownerId_skillId: {
          ownerId: 'user-a',
          skillId: systemSkill.id,
        },
      },
      create: expect.objectContaining({
        ownerId: 'user-a',
        skillId: systemSkill.id,
        level: '잘 알아요',
        deletedAt: null,
      }),
      update: {
        level: '잘 알아요',
        deletedAt: null,
      },
    });
    expect(response.body.userLevel).toBe('잘 알아요');
    expect(response.body.isSystem).toBe(true);
  });

  it('lists active skill animations owned by the current user', async () => {
    const response = await request(app.getHttpServer())
      .get('/api/v1/skill-animations')
      .set('Authorization', 'Bearer dev-token')
      .expect(200);

    expect(prisma.skillAnimation.findMany).toHaveBeenCalledWith({
      where: {
        ownerId: 'user-a',
        deletedAt: null,
      },
      orderBy: {
        title: 'asc',
      },
    });
    expect(response.body).toEqual([expectedAnimationResponse()]);
  });

  it('soft deletes an owned skill', async () => {
    await request(app.getHttpServer())
      .delete(`/api/v1/skills/${skillId}`)
      .set('Authorization', 'Bearer dev-token')
      .expect(204);

    expect(prisma.skill.findFirst).toHaveBeenCalledWith({
      where: {
        id: skillId,
        deletedAt: null,
        OR: [
          { isSystem: true },
          { ownerId: 'user-a' },
        ],
      },
    });
    expect(prisma.skill.update).toHaveBeenCalledWith({
      where: { id: skillId },
      data: {
        deletedAt: expect.any(Date),
      },
    });
  });

  function expectedSkillResponse(overrides: Record<string, unknown> = {}) {
    return {
      ...baseExpectedSkillResponse(),
      ...overrides,
    };
  }

  function baseExpectedSkillResponse() {
    return {
      id: skillId,
      ownerId: 'user-a',
      name: 'Knit',
      abbreviation: 'K',
      description: 'Knit stitch.',
      category: '기초',
      difficulty: '잘 알아요',
      animationName: 'knit-loop',
      animationType: 'loop',
      createdAt: '2026-07-09T00:00:00.000Z',
      updatedAt: '2026-07-09T00:05:00.000Z',
      deletedAt: null,
      syncStatus: 'Synced',
      isSystem: false,
      userLevel: null,
      steps: ['Insert right needle.', 'Wrap yarn.', 'Pull through.'],
      animationIds: [animationId],
    };
  }

  function expectedAnimationResponse() {
    return {
      id: animationId,
      ownerId: 'user-a',
      skillId,
      title: 'Knit stitch loop',
      localAssetName: 'knit-loop',
      durationSeconds: 8,
      createdAt: '2026-07-09T00:00:00.000Z',
      updatedAt: '2026-07-09T00:05:00.000Z',
      deletedAt: null,
      syncStatus: 'Synced',
    };
  }
});
