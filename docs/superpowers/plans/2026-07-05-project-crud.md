# Project CRUD Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the server-backed iOS project repository support project detail, create, update, and delete.

**Architecture:** Keep the existing NestJS `projects` module as the owner of project HTTP behavior, adding DTOs and service methods beside the current list endpoint. Keep the Swift `ProjectRepository` protocol unchanged and make `RemoteProjectRepository` serialize the existing `KnittingProject` model through request DTOs.

**Tech Stack:** NestJS, Prisma, Jest/Supertest, Swift, Swift Testing, URLSession.

---

## File Structure

- Modify `server/src/projects/projects.controller.ts`: add detail/create/update/delete routes.
- Modify `server/src/projects/projects.service.ts`: add owner-scoped detail, save, and soft-delete behavior.
- Create `server/src/projects/project-save.dto.ts`: validated request DTOs for project saves.
- Modify `server/test/projects.e2e-spec.ts`: expand controller-level tests for CRUD behavior using mocked Prisma methods.
- Modify `KnitGether/Networking/APIClient.swift`: add request methods that can ignore a JSON response body for `DELETE`.
- Modify `KnitGether/Repositories/Remote/RemoteProjectRepository.swift`: implement remote save/delete and local-to-API request mapping.
- Modify `KnitGetherTests/RemoteProjectRepositoryTests.swift`: replace unsupported-operation tests with request behavior tests.

## Task 1: Server DTOs and Read Detail

**Files:**
- Create: `server/src/projects/project-save.dto.ts`
- Modify: `server/src/projects/projects.controller.ts`
- Modify: `server/src/projects/projects.service.ts`
- Test: `server/test/projects.e2e-spec.ts`

- [ ] **Step 1: Write failing server detail tests**

Add mocked Prisma methods to the test type in `server/test/projects.e2e-spec.ts`:

```ts
type MockPrismaService = {
  project: {
    findMany: jest.Mock;
    findFirst: jest.Mock;
  };
};
```

Initialize the new mock:

```ts
prisma = {
  project: {
    findMany: jest.fn(),
    findFirst: jest.fn(),
  },
};
```

Reset and default it in `beforeEach`:

```ts
prisma.project.findFirst.mockReset();
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
```

Add these tests:

```ts
it('returns one active project owned by the current user', async () => {
  const response = await request(app.getHttpServer())
    .get('/api/v1/projects/11111111-1111-1111-1111-111111111111')
    .set('Authorization', 'Bearer dev-token')
    .expect(200);

  expect(prisma.project.findFirst).toHaveBeenCalledWith({
    where: {
      id: '11111111-1111-1111-1111-111111111111',
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

  expect(response.body.id).toBe('11111111-1111-1111-1111-111111111111');
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
```

- [ ] **Step 2: Run the failing server detail tests**

Run:

```bash
cd server
npm test -- --runTestsByPath test/projects.e2e-spec.ts
```

Expected: FAIL because `GET /api/v1/projects/:id` is not implemented.

- [ ] **Step 3: Add DTO file skeleton**

Create `server/src/projects/project-save.dto.ts`:

```ts
import {
  IsArray,
  IsBoolean,
  IsInt,
  IsISO8601,
  IsOptional,
  IsString,
  IsUUID,
  Min,
  ValidateNested,
} from 'class-validator';
import { Type } from 'class-transformer';

export class SaveRowCounterDto {
  @IsUUID()
  id!: string;

  @IsUUID()
  projectId!: string;

  @IsString()
  name!: string;

  @IsInt()
  @Min(0)
  currentRow!: number;

  @IsOptional()
  @IsInt()
  @Min(0)
  targetRow!: number | null;
}

export class SaveWorkSessionDto {
  @IsUUID()
  id!: string;

  @IsUUID()
  projectId!: string;

  @IsISO8601()
  startedAt!: string;

  @IsOptional()
  @IsISO8601()
  endedAt!: string | null;

  @IsOptional()
  @IsString()
  memo!: string | null;
}

export class SaveProjectDto {
  @IsUUID()
  id!: string;

  @IsString()
  name!: string;

  @IsString()
  status!: string;

  @IsBoolean()
  isFavorite!: boolean;

  @IsString()
  memo!: string;

  @IsISO8601()
  startDate!: string;

  @IsOptional()
  @IsISO8601()
  lastWorkedAt!: string | null;

  @IsOptional()
  @IsString()
  workspaceDisplayMode!: string | null;

  @IsOptional()
  @IsString()
  workspaceSheetPosition!: string | null;

  @IsArray()
  @IsUUID('all', { each: true })
  relatedSkillIds!: string[];

  @ValidateNested()
  @Type(() => SaveRowCounterDto)
  rowCounter!: SaveRowCounterDto;

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => SaveWorkSessionDto)
  workSessions!: SaveWorkSessionDto[];
}
```

- [ ] **Step 4: Implement detail route and service method**

Modify imports in `server/src/projects/projects.controller.ts`:

```ts
import { Body, Controller, Delete, Get, Param, Patch, Post, UseGuards } from '@nestjs/common';
```

Add this method:

```ts
  @Get(':id')
  getProject(
    @CurrentUser() currentUser: CurrentUserPayload,
    @Param('id') id: string,
  ): Promise<ProjectResponseDto> {
    return this.projectsService.getProject(currentUser.id, id);
  }
```

Modify imports in `server/src/projects/projects.service.ts`:

```ts
import {
  Injectable,
  InternalServerErrorException,
  NotFoundException,
} from '@nestjs/common';
```

Add this service method:

```ts
  async getProject(ownerId: string, id: string): Promise<ProjectResponseDto> {
    const project = await this.prisma.project.findFirst({
      where: {
        id,
        ownerId,
        deletedAt: null,
      },
      include: this.projectInclude(ownerId),
    });

    if (!project) {
      throw new NotFoundException({
        code: 'PROJECT_NOT_FOUND',
        message: 'Project not found.',
      });
    }

    return this.toResponse(project, ownerId);
  }
```

Extract the repeated include shape:

```ts
  private projectInclude(ownerId: string): Prisma.ProjectInclude {
    return {
      rowCounter: true,
      workSessions: {
        where: {
          ownerId,
          deletedAt: null,
        },
        orderBy: {
          startedAt: 'asc',
        },
      },
    };
  }
```

Update `listProjects` to use it:

```ts
      include: this.projectInclude(ownerId),
```

- [ ] **Step 5: Run detail tests again**

Run:

```bash
cd server
npm test -- --runTestsByPath test/projects.e2e-spec.ts
```

Expected: PASS for the new detail tests and existing list/auth tests.

- [ ] **Step 6: Commit server detail slice**

Run:

```bash
git add server/src/projects/project-save.dto.ts server/src/projects/projects.controller.ts server/src/projects/projects.service.ts server/test/projects.e2e-spec.ts
git commit -m "feat: add project detail API"
```

## Task 2: Server Create and Update

**Files:**
- Modify: `server/src/projects/projects.controller.ts`
- Modify: `server/src/projects/projects.service.ts`
- Test: `server/test/projects.e2e-spec.ts`

- [ ] **Step 1: Write failing create/update tests**

Extend `MockPrismaService`:

```ts
type MockPrismaService = {
  userProfile: {
    upsert: jest.Mock;
  };
  project: {
    findMany: jest.Mock;
    findFirst: jest.Mock;
    findFirstOrThrow: jest.Mock;
    upsert: jest.Mock;
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
```

Initialize the new mocks:

```ts
prisma = {
  userProfile: {
    upsert: jest.fn(),
  },
  project: {
    findMany: jest.fn(),
    findFirst: jest.fn(),
    findFirstOrThrow: jest.fn(),
    upsert: jest.fn(),
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
```

Add this request body helper near `userAProject`:

```ts
const saveProjectBody = {
  id: '11111111-1111-1111-1111-111111111111',
  name: 'Favorite Cardigan',
  status: 'WIP',
  isFavorite: true,
  memo: 'Use smaller needles for ribbing.',
  startDate: '2026-07-01T00:00:00.000Z',
  lastWorkedAt: '2026-07-03T09:00:00.000Z',
  workspaceDisplayMode: 'patternAndCounter',
  workspaceSheetPosition: 'medium',
  relatedSkillIds: ['aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'],
  rowCounter: {
    id: '22222222-2222-2222-2222-222222222222',
    projectId: '11111111-1111-1111-1111-111111111111',
    name: 'Main Counter',
    currentRow: 42,
    targetRow: 120,
  },
  workSessions: [
    {
      id: '33333333-3333-3333-3333-333333333333',
      projectId: '11111111-1111-1111-1111-111111111111',
      startedAt: '2026-07-03T08:00:00.000Z',
      endedAt: '2026-07-03T09:00:00.000Z',
      memo: 'Sleeve increases.',
    },
  ],
};
```

Reset create/update mocks in `beforeEach`:

```ts
prisma.userProfile.upsert.mockReset();
prisma.project.upsert.mockReset();
prisma.project.update.mockReset();
prisma.project.findFirstOrThrow.mockReset();
prisma.rowCounter.upsert.mockReset();
prisma.workSession.deleteMany.mockReset();
prisma.workSession.updateMany.mockReset();
prisma.workSession.createMany.mockReset();
prisma.$transaction.mockReset();
prisma.$transaction.mockImplementation(async (callback) => callback(prisma));
prisma.userProfile.upsert.mockResolvedValue(undefined);
prisma.project.upsert.mockResolvedValue(userAProject);
prisma.project.update.mockResolvedValue(userAProject);
prisma.project.findFirstOrThrow.mockResolvedValue(userAProject);
prisma.rowCounter.upsert.mockResolvedValue(userAProject.rowCounter);
prisma.workSession.deleteMany.mockResolvedValue({ count: 0 });
prisma.workSession.updateMany.mockResolvedValue({ count: 0 });
prisma.workSession.createMany.mockResolvedValue({ count: 1 });
```

Add create test:

```ts
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
  expect(prisma.project.upsert).toHaveBeenCalledWith(
    expect.objectContaining({
      where: { id: saveProjectBody.id },
      create: expect.objectContaining({
        id: saveProjectBody.id,
        ownerId: 'user-a',
        name: saveProjectBody.name,
        status: saveProjectBody.status,
      }),
      update: expect.objectContaining({
        ownerId: 'user-a',
        name: saveProjectBody.name,
        status: saveProjectBody.status,
      }),
      include: expect.any(Object),
    }),
  );
  expect(prisma.rowCounter.upsert).toHaveBeenCalled();
  expect(prisma.workSession.deleteMany).toHaveBeenCalledWith({
    where: {
      ownerId: 'user-a',
      projectId: saveProjectBody.id,
    },
  });
  expect(prisma.workSession.createMany).toHaveBeenCalled();
  expect(response.body.id).toBe(saveProjectBody.id);
});
```

Add update test:

```ts
it('updates an active project owned by the current user', async () => {
  const response = await request(app.getHttpServer())
    .patch('/api/v1/projects/11111111-1111-1111-1111-111111111111')
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
        name: saveProjectBody.name,
        status: saveProjectBody.status,
        isFavorite: saveProjectBody.isFavorite,
      }),
      include: expect.any(Object),
    }),
  );
  expect(response.body.name).toBe(saveProjectBody.name);
});
```

- [ ] **Step 2: Run create/update tests and confirm failure**

Run:

```bash
cd server
npm test -- --runTestsByPath test/projects.e2e-spec.ts
```

Expected: FAIL because `POST /projects` and `PATCH /projects/:id` are not implemented.

- [ ] **Step 3: Add controller write routes**

Modify `server/src/projects/projects.controller.ts`:

```ts
import { SaveProjectDto } from './project-save.dto';
```

Add methods:

```ts
  @Post()
  createProject(
    @CurrentUser() currentUser: CurrentUserPayload,
    @Body() body: SaveProjectDto,
  ): Promise<ProjectResponseDto> {
    return this.projectsService.createProject(currentUser.id, body);
  }

  @Patch(':id')
  updateProject(
    @CurrentUser() currentUser: CurrentUserPayload,
    @Param('id') id: string,
    @Body() body: SaveProjectDto,
  ): Promise<ProjectResponseDto> {
    return this.projectsService.updateProject(currentUser.id, id, body);
  }
```

- [ ] **Step 4: Add service save helpers**

Modify `server/src/projects/projects.service.ts` imports:

```ts
import { SaveProjectDto } from './project-save.dto';
```

Add methods:

```ts
  async createProject(
    ownerId: string,
    body: SaveProjectDto,
  ): Promise<ProjectResponseDto> {
    return this.prisma.$transaction(async (transaction) => {
      await this.ensureUserProfile(transaction, ownerId);
      const project = await transaction.project.upsert({
        where: { id: body.id },
        create: this.toProjectCreateInput(ownerId, body),
        update: this.toProjectUpdateInput(ownerId, body),
        include: this.projectInclude(ownerId),
      });
      await this.saveProjectChildren(transaction, ownerId, body);
      return this.toResponse(
        await transaction.project.findFirstOrThrow({
          where: { id: project.id, ownerId, deletedAt: null },
          include: this.projectInclude(ownerId),
        }),
        ownerId,
      );
    });
  }

  async updateProject(
    ownerId: string,
    id: string,
    body: SaveProjectDto,
  ): Promise<ProjectResponseDto> {
    if (id !== body.id) {
      throw new NotFoundException({
        code: 'PROJECT_NOT_FOUND',
        message: 'Project not found.',
      });
    }

    return this.prisma.$transaction(async (transaction) => {
      const existingProject = await transaction.project.findFirst({
        where: { id, ownerId, deletedAt: null },
        include: this.projectInclude(ownerId),
      });

      if (!existingProject) {
        throw new NotFoundException({
          code: 'PROJECT_NOT_FOUND',
          message: 'Project not found.',
        });
      }

      await transaction.project.update({
        where: { id },
        data: this.toProjectUpdateInput(ownerId, body),
        include: this.projectInclude(ownerId),
      });
      await this.saveProjectChildren(transaction, ownerId, body);

      const project = await transaction.project.findFirstOrThrow({
        where: { id, ownerId, deletedAt: null },
        include: this.projectInclude(ownerId),
      });
      return this.toResponse(project, ownerId);
    });
  }
```

Add helpers:

```ts
  private async ensureUserProfile(
    transaction: Prisma.TransactionClient,
    ownerId: string,
  ): Promise<void> {
    await transaction.userProfile.upsert({
      where: { id: ownerId },
      create: {
        id: ownerId,
        displayName: ownerId,
      },
      update: {},
    });
  }

  private toProjectCreateInput(
    ownerId: string,
    body: SaveProjectDto,
  ): Prisma.ProjectUncheckedCreateInput {
    return {
      id: body.id,
      ownerId,
      ...this.toProjectScalarInput(body),
      deletedAt: null,
    };
  }

  private toProjectUpdateInput(
    ownerId: string,
    body: SaveProjectDto,
  ): Prisma.ProjectUncheckedUpdateInput {
    return {
      ownerId,
      ...this.toProjectScalarInput(body),
      deletedAt: null,
    };
  }

  private toProjectScalarInput(body: SaveProjectDto) {
    return {
      name: body.name.trim(),
      status: body.status,
      isFavorite: body.isFavorite,
      memo: body.memo,
      startDate: new Date(body.startDate),
      lastWorkedAt: body.lastWorkedAt ? new Date(body.lastWorkedAt) : null,
      workspaceDisplayMode: body.workspaceDisplayMode,
      workspaceSheetPosition: body.workspaceSheetPosition,
      relatedSkillIds: body.relatedSkillIds,
    };
  }

  private async saveProjectChildren(
    transaction: Prisma.TransactionClient,
    ownerId: string,
    body: SaveProjectDto,
  ): Promise<void> {
    await transaction.rowCounter.upsert({
      where: { projectId: body.id },
      create: {
        id: body.rowCounter.id,
        ownerId,
        projectId: body.id,
        name: body.rowCounter.name,
        currentRow: body.rowCounter.currentRow,
        targetRow: body.rowCounter.targetRow,
        deletedAt: null,
      },
      update: {
        ownerId,
        name: body.rowCounter.name,
        currentRow: body.rowCounter.currentRow,
        targetRow: body.rowCounter.targetRow,
        deletedAt: null,
      },
    });

    await transaction.workSession.deleteMany({
      where: {
        ownerId,
        projectId: body.id,
      },
    });

    if (body.workSessions.length > 0) {
      await transaction.workSession.createMany({
        data: body.workSessions.map((session) => ({
          id: session.id,
          ownerId,
          projectId: body.id,
          startedAt: new Date(session.startedAt),
          endedAt: session.endedAt ? new Date(session.endedAt) : null,
          memo: session.memo,
          deletedAt: null,
        })),
      });
    }
  }
```

- [ ] **Step 5: Run create/update tests again**

Run:

```bash
cd server
npm test -- --runTestsByPath test/projects.e2e-spec.ts
```

Expected: PASS for create/update tests and previous tests. If TypeScript reports `findFirstOrThrow` missing from the mocked transaction type, add it to the mock and return `userAProject`.

- [ ] **Step 6: Commit server create/update slice**

Run:

```bash
git add server/src/projects/projects.controller.ts server/src/projects/projects.service.ts server/test/projects.e2e-spec.ts
git commit -m "feat: add project create and update API"
```

## Task 3: Server Soft Delete

**Files:**
- Modify: `server/src/projects/projects.controller.ts`
- Modify: `server/src/projects/projects.service.ts`
- Test: `server/test/projects.e2e-spec.ts`

- [ ] **Step 1: Write failing delete tests**

Add this test:

```ts
it('soft-deletes an active project owned by the current user', async () => {
  await request(app.getHttpServer())
    .delete('/api/v1/projects/11111111-1111-1111-1111-111111111111')
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
    .delete('/api/v1/projects/99999999-9999-9999-9999-999999999999')
    .set('Authorization', 'Bearer dev-token')
    .expect(404)
    .expect(({ body }) => {
      expect(body.code).toBe('PROJECT_NOT_FOUND');
    });
});
```

- [ ] **Step 2: Run delete tests and confirm failure**

Run:

```bash
cd server
npm test -- --runTestsByPath test/projects.e2e-spec.ts
```

Expected: FAIL because `DELETE /projects/:id` is not implemented.

- [ ] **Step 3: Add controller delete route**

Modify imports in `server/src/projects/projects.controller.ts`:

```ts
import { Body, Controller, Delete, Get, HttpCode, Param, Patch, Post, UseGuards } from '@nestjs/common';
```

Add method:

```ts
  @Delete(':id')
  @HttpCode(204)
  deleteProject(
    @CurrentUser() currentUser: CurrentUserPayload,
    @Param('id') id: string,
  ): Promise<void> {
    return this.projectsService.deleteProject(currentUser.id, id);
  }
```

- [ ] **Step 4: Add service soft delete method**

Add method:

```ts
  async deleteProject(ownerId: string, id: string): Promise<void> {
    const existingProject = await this.prisma.project.findFirst({
      where: { id, ownerId, deletedAt: null },
      include: this.projectInclude(ownerId),
    });

    if (!existingProject) {
      throw new NotFoundException({
        code: 'PROJECT_NOT_FOUND',
        message: 'Project not found.',
      });
    }

    const deletedAt = new Date();
    await this.prisma.project.update({
      where: { id },
      data: {
        deletedAt,
        rowCounter: {
          update: {
            deletedAt,
          },
        },
      },
    });
    await this.prisma.workSession.updateMany({
      where: { ownerId, projectId: id },
      data: { deletedAt },
    });
  }
```

- [ ] **Step 5: Run delete tests again**

Run:

```bash
cd server
npm test -- --runTestsByPath test/projects.e2e-spec.ts
```

Expected: PASS.

- [ ] **Step 6: Commit server delete slice**

Run:

```bash
git add server/src/projects/projects.controller.ts server/src/projects/projects.service.ts server/test/projects.e2e-spec.ts
git commit -m "feat: add project delete API"
```

## Task 4: Swift Remote Save/Delete

**Files:**
- Modify: `KnitGether/Networking/APIClient.swift`
- Modify: `KnitGether/Repositories/Remote/RemoteProjectRepository.swift`
- Test: `KnitGetherTests/RemoteProjectRepositoryTests.swift`

- [ ] **Step 1: Write failing Swift save/delete tests**

Replace unsupported-operation tests in `KnitGetherTests/RemoteProjectRepositoryTests.swift` with tests that assert HTTP behavior:

```swift
@Test func saveNewProjectPostsProjectPayload() async throws {
    let project = Self.project(syncStatus: .localOnly)
    let session = MockURLProtocol.makeSession { request in
        #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/projects")
        #expect(request.httpMethod == "POST")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer dev-token")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")

        let body = try #require(request.httpBody)
        let object = try #require(
            JSONSerialization.jsonObject(with: body) as? [String: Any]
        )
        #expect(object["id"] as? String == "11111111-1111-1111-1111-111111111111")
        #expect(object["name"] as? String == "Favorite Cardigan")
        #expect(object["status"] as? String == "WIP")
        #expect(object["isFavorite"] as? Bool == true)
        #expect(object["memo"] as? String == "Use smaller needles for ribbing.")
        #expect(object["relatedSkillIds"] as? [String] == ["aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"])
        let rowCounter = try #require(object["rowCounter"] as? [String: Any])
        #expect(rowCounter["currentRow"] as? Int == 42)

        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!
        return (response, Data(Self.projectResponseJSON.utf8))
    }

    let repository = Self.makeRepository(session: session)
    try await repository.saveProject(project)
}

@Test func saveSyncedProjectPatchesProjectPayload() async throws {
    let project = Self.project(syncStatus: .synced)
    let session = MockURLProtocol.makeSession { request in
        #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/projects/11111111-1111-1111-1111-111111111111")
        #expect(request.httpMethod == "PATCH")

        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!
        return (response, Data(Self.projectResponseJSON.utf8))
    }

    let repository = Self.makeRepository(session: session)
    try await repository.saveProject(project)
}

@Test func deleteProjectRequestsProjectDeleteEndpoint() async throws {
    let projectID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    let session = MockURLProtocol.makeSession { request in
        #expect(request.url?.absoluteString == "http://127.0.0.1:3000/api/v1/projects/\(projectID.uuidString.lowercased())")
        #expect(request.httpMethod == "DELETE")

        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: 204,
            httpVersion: nil,
            headerFields: nil
        )!
        return (response, Data())
    }

    let repository = Self.makeRepository(session: session)
    try await repository.deleteProject(id: projectID)
}
```

Add `relatedSkillIds` to `project()`:

```swift
relatedSkillIds: [UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!],
```

Add a single-object response constant by reusing the object in `projectsResponseJSON`:

```swift
private static let projectResponseJSON = """
{
  "id": "11111111-1111-1111-1111-111111111111",
  "ownerId": "user-a",
  "name": "Favorite Cardigan",
  "status": "WIP",
  "isFavorite": true,
  "memo": "Use smaller needles for ribbing.",
  "startDate": "2026-07-01T00:00:00.000Z",
  "lastWorkedAt": "2026-07-03T09:00:00.000Z",
  "patternCopy": null,
  "workspaceDisplayMode": "patternAndCounter",
  "workspaceSheetPosition": "medium",
  "rowCounter": {
    "id": "22222222-2222-2222-2222-222222222222",
    "ownerId": "user-a",
    "projectId": "11111111-1111-1111-1111-111111111111",
    "name": "Main Counter",
    "currentRow": 42,
    "targetRow": 120,
    "createdAt": "2026-07-01T00:00:00.000Z",
    "updatedAt": "2026-07-03T09:00:00.000Z",
    "deletedAt": null,
    "syncStatus": "Synced"
  },
  "workSessions": [],
  "relatedSkillIds": ["aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"],
  "createdAt": "2026-07-01T00:00:00.000Z",
  "updatedAt": "2026-07-03T09:00:00.000Z",
  "deletedAt": null,
  "syncStatus": "Synced"
}
"""
```

- [ ] **Step 2: Run Swift repository tests and confirm failure**

Run:

```bash
xcodebuild test -project KnitGether.xcodeproj -scheme KnitGether -destination 'platform=iOS Simulator,id=F882A23F-0389-430D-84F9-9E43E03AD78F' -only-testing:KnitGetherTests/RemoteProjectRepositoryTests -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO
```

Expected: FAIL because save/delete still throw unsupported-operation errors and `APIClient` has no empty-response send helper.

- [ ] **Step 3: Add empty-response API helper**

Modify `KnitGether/Networking/APIClient.swift`:

```swift
func send<RequestBody: Encodable>(
    _ path: String,
    method: String,
    body: RequestBody
) async throws {
    let data = try encoder.encode(body)
    try await request(path, method: method, body: data)
}

func delete(_ path: String) async throws {
    try await request(path, method: "DELETE", body: Optional<Data>.none)
}
```

Add a private empty-response overload:

```swift
private func request(
    _ path: String,
    method: String,
    body: Data?
) async throws {
    let url = configuration.baseURL.appendingPathComponent(path)
    var request = URLRequest(url: url)
    request.httpMethod = method
    request.setValue("application/json", forHTTPHeaderField: "Accept")

    if let body {
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    }

    if let token = try await configuration.authTokenProvider() {
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }

    let (data, response) = try await session.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
        throw APIError.invalidResponse
    }

    guard (200..<300).contains(httpResponse.statusCode) else {
        let envelope = try? decoder.decode(APIErrorEnvelope.self, from: data)
        throw APIError.requestFailed(
            statusCode: httpResponse.statusCode,
            code: envelope?.code,
            message: envelope?.message
        )
    }
}
```

- [ ] **Step 4: Implement remote project request DTOs**

Modify `KnitGether/Repositories/Remote/RemoteProjectRepository.swift`:

```swift
private struct SaveProjectRequest: Encodable {
    let id: String
    let name: String
    let status: String
    let isFavorite: Bool
    let memo: String
    let startDate: Date
    let lastWorkedAt: Date?
    let workspaceDisplayMode: String?
    let workspaceSheetPosition: String?
    let relatedSkillIds: [String]
    let rowCounter: SaveRowCounterRequest
    let workSessions: [SaveWorkSessionRequest]

    init(project: KnittingProject) {
        id = project.id.uuidString.lowercased()
        name = project.name
        status = project.status.rawValue
        isFavorite = project.isFavorite
        memo = project.memo
        startDate = project.startDate
        lastWorkedAt = project.lastWorkedAt
        workspaceDisplayMode = project.workspaceDisplayMode?.rawValue
        workspaceSheetPosition = project.workspaceSheetPosition?.rawValue
        relatedSkillIds = project.relatedSkillIds.map { $0.uuidString.lowercased() }
        rowCounter = SaveRowCounterRequest(rowCounter: project.rowCounter)
        workSessions = project.workSessions.map(SaveWorkSessionRequest.init)
    }
}

private struct SaveRowCounterRequest: Encodable {
    let id: String
    let projectId: String
    let name: String
    let currentRow: Int
    let targetRow: Int?

    init(rowCounter: RowCounter) {
        id = rowCounter.id.uuidString.lowercased()
        projectId = rowCounter.projectId.uuidString.lowercased()
        name = rowCounter.name
        currentRow = rowCounter.currentRow
        targetRow = rowCounter.targetRow
    }
}

private struct SaveWorkSessionRequest: Encodable {
    let id: String
    let projectId: String
    let startedAt: Date
    let endedAt: Date?
    let memo: String?

    init(workSession: WorkSession) {
        id = workSession.id.uuidString.lowercased()
        projectId = workSession.projectId.uuidString.lowercased()
        startedAt = workSession.startedAt
        endedAt = workSession.endedAt
        memo = workSession.memo
    }
}
```

Implement methods:

```swift
func saveProject(_ project: KnittingProject) async throws {
    let body = SaveProjectRequest(project: project)

    if project.syncStatus == .synced {
        let _: KnittingProject = try await apiClient.send(
            "projects/\(project.id.uuidString.lowercased())",
            method: "PATCH",
            body: body
        )
    } else {
        let _: KnittingProject = try await apiClient.send(
            "projects",
            method: "POST",
            body: body
        )
    }
}

func deleteProject(id: UUID) async throws {
    try await apiClient.delete("projects/\(id.uuidString.lowercased())")
}
```

- [ ] **Step 5: Run Swift repository tests again**

Run:

```bash
xcodebuild test -project KnitGether.xcodeproj -scheme KnitGether -destination 'platform=iOS Simulator,id=F882A23F-0389-430D-84F9-9E43E03AD78F' -only-testing:KnitGetherTests/RemoteProjectRepositoryTests -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO
```

Expected: PASS.

- [ ] **Step 6: Commit Swift remote write slice**

Run:

```bash
git add KnitGether/Networking/APIClient.swift KnitGether/Repositories/Remote/RemoteProjectRepository.swift KnitGetherTests/RemoteProjectRepositoryTests.swift
git commit -m "feat: add remote project writes"
```

## Task 5: Full Verification and PR Update

**Files:**
- Verify all changed files.

- [ ] **Step 1: Run server verification**

Run:

```bash
cd server
npm test
npm run build
```

Expected:

- Jest reports all test suites and tests passed.
- Nest build exits with code 0.

- [ ] **Step 2: Run iOS test verification**

Run:

```bash
xcodebuild test -project KnitGether.xcodeproj -scheme KnitGether -destination 'platform=iOS Simulator,id=F882A23F-0389-430D-84F9-9E43E03AD78F' -only-testing:KnitGetherTests -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO
```

Expected: all `KnitGetherTests` pass.

- [ ] **Step 3: Run iOS build verification**

Run:

```bash
xcodebuild -project KnitGether.xcodeproj -scheme KnitGether -destination generic/platform=iOS build CODE_SIGNING_ALLOWED=NO
```

Expected: `BUILD SUCCEEDED`.

- [ ] **Step 4: Check git status and push**

Run:

```bash
git status --short
git push
```

Expected: status is clean before push, and PR branch updates successfully.
