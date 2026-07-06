import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { promises as fs } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
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
  projectPatternCopy: {
    upsert: jest.Mock;
    update: jest.Mock;
    deleteMany: jest.Mock;
    updateMany: jest.Mock;
  };
  patternDocument: {
    findFirst: jest.Mock;
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

  const projectPatternCopy = {
    id: '66666666-6666-4666-8666-666666666666',
    ownerId: 'user-a',
    projectId: '11111111-1111-4111-8111-111111111111',
    sourcePatternDocumentId: '44444444-4444-4444-8444-444444444444',
    titleSnapshot: 'Cozy Shawl',
    designerSnapshot: 'Yu',
    fileNameSnapshot: 'cozy-shawl.pdf',
    pageCountSnapshot: 12,
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
      projectPatternCopy: {
        upsert: jest.fn(),
        update: jest.fn(),
        deleteMany: jest.fn(),
        updateMany: jest.fn(),
      },
      patternDocument: {
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
    prisma.project.findMany.mockReset();
    prisma.project.findFirst.mockReset();
    prisma.project.findFirstOrThrow.mockReset();
    prisma.project.create.mockReset();
    prisma.project.update.mockReset();
    prisma.rowCounter.upsert.mockReset();
    prisma.workSession.deleteMany.mockReset();
    prisma.workSession.updateMany.mockReset();
    prisma.workSession.createMany.mockReset();
    prisma.projectPatternCopy.upsert.mockReset();
    prisma.projectPatternCopy.update.mockReset();
    prisma.projectPatternCopy.deleteMany.mockReset();
    prisma.projectPatternCopy.updateMany.mockReset();
    prisma.patternDocument.findFirst.mockReset();
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
    prisma.projectPatternCopy.upsert.mockResolvedValue(projectPatternCopy);
    prisma.projectPatternCopy.update.mockResolvedValue(projectPatternCopyWithDrawing);
    prisma.projectPatternCopy.deleteMany.mockResolvedValue({ count: 0 });
    prisma.projectPatternCopy.updateMany.mockResolvedValue({ count: 0 });
    prisma.patternDocument.findFirst.mockResolvedValue(
      projectPatternCopy.sourcePatternDocument,
    );
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

  it('saves a project pattern copy with the project', async () => {
    prisma.project.findFirstOrThrow.mockResolvedValueOnce(userAProjectWithPatternCopy);

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
});
