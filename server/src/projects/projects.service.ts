import {
  Injectable,
  InternalServerErrorException,
  NotFoundException,
} from '@nestjs/common';
import { Prisma, RowCounter, WorkSession } from '@prisma/client';
import { PrismaService } from '../database/prisma.service';
import {
  ProjectResponseDto,
  RowCounterResponseDto,
  WorkSessionResponseDto,
} from './project-response.dto';
import { SaveProjectDto } from './project-save.dto';

type ProjectWithChildren = Prisma.ProjectGetPayload<{
  include: {
    rowCounter: true;
    workSessions: true;
  };
}>;

@Injectable()
export class ProjectsService {
  constructor(private readonly prisma: PrismaService) {}

  async listProjects(ownerId: string): Promise<ProjectResponseDto[]> {
    const projects = await this.prisma.project.findMany({
      where: {
        ownerId,
        deletedAt: null,
      },
      include: this.projectInclude(ownerId),
    });

    return projects
      .sort((first, second) => this.compareProjects(first, second))
      .map((project) => this.toResponse(project, ownerId));
  }

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

  async createProject(
    ownerId: string,
    body: SaveProjectDto,
  ): Promise<ProjectResponseDto> {
    return this.prisma.$transaction(async (transaction) => {
      await this.ensureUserProfile(transaction, ownerId);

      const existingProject = await transaction.project.findFirst({
        where: {
          id: body.id,
          ownerId,
        },
        include: this.projectInclude(ownerId),
      });

      if (existingProject) {
        await transaction.project.update({
          where: { id: body.id },
          data: this.toProjectUpdateInput(ownerId, body),
          include: this.projectInclude(ownerId),
        });
      } else {
        await transaction.project.create({
          data: this.toProjectCreateInput(ownerId, body),
          include: this.projectInclude(ownerId),
        });
      }

      await this.saveProjectChildren(transaction, ownerId, body);

      const project = await transaction.project.findFirstOrThrow({
        where: {
          id: body.id,
          ownerId,
          deletedAt: null,
        },
        include: this.projectInclude(ownerId),
      });

      return this.toResponse(project, ownerId);
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
        where: {
          id,
          ownerId,
          deletedAt: null,
        },
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
        where: {
          id,
          ownerId,
          deletedAt: null,
        },
        include: this.projectInclude(ownerId),
      });

      return this.toResponse(project, ownerId);
    });
  }

  async deleteProject(ownerId: string, id: string): Promise<void> {
    const existingProject = await this.prisma.project.findFirst({
      where: {
        id,
        ownerId,
        deletedAt: null,
      },
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
      where: {
        ownerId,
        projectId: id,
      },
      data: {
        deletedAt,
      },
    });
  }

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

    if (body.workSessions.length === 0) {
      return;
    }

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

  private compareProjects(
    first: ProjectWithChildren,
    second: ProjectWithChildren,
  ): number {
    if (first.isFavorite !== second.isFavorite) {
      return first.isFavorite ? -1 : 1;
    }

    const firstActivity = first.lastWorkedAt ?? first.startDate;
    const secondActivity = second.lastWorkedAt ?? second.startDate;
    return secondActivity.getTime() - firstActivity.getTime();
  }

  private toResponse(
    project: ProjectWithChildren,
    ownerId: string,
  ): ProjectResponseDto {
    if (
      !project.rowCounter ||
      project.rowCounter.ownerId !== ownerId ||
      project.rowCounter.deletedAt !== null
    ) {
      throw new InternalServerErrorException({
        code: 'PROJECT_ROW_COUNTER_MISSING',
        message: 'Project is missing its row counter.',
        details: {
          projectId: project.id,
        },
      });
    }

    return {
      id: project.id,
      ownerId: project.ownerId,
      name: project.name,
      status: project.status,
      isFavorite: project.isFavorite,
      memo: project.memo,
      startDate: project.startDate.toISOString(),
      lastWorkedAt: project.lastWorkedAt?.toISOString() ?? null,
      patternCopy: null,
      workspaceDisplayMode: project.workspaceDisplayMode,
      workspaceSheetPosition: project.workspaceSheetPosition,
      rowCounter: this.toRowCounterResponse(project.rowCounter),
      workSessions: project.workSessions.map((session) =>
        this.toWorkSessionResponse(session),
      ),
      relatedSkillIds: project.relatedSkillIds,
      createdAt: project.createdAt.toISOString(),
      updatedAt: project.updatedAt.toISOString(),
      deletedAt: project.deletedAt?.toISOString() ?? null,
      syncStatus: 'Synced',
    };
  }

  private toRowCounterResponse(rowCounter: RowCounter): RowCounterResponseDto {
    return {
      id: rowCounter.id,
      ownerId: rowCounter.ownerId,
      projectId: rowCounter.projectId,
      name: rowCounter.name,
      currentRow: rowCounter.currentRow,
      targetRow: rowCounter.targetRow,
      createdAt: rowCounter.createdAt.toISOString(),
      updatedAt: rowCounter.updatedAt.toISOString(),
      deletedAt: rowCounter.deletedAt?.toISOString() ?? null,
      syncStatus: 'Synced',
    };
  }

  private toWorkSessionResponse(
    session: WorkSession,
  ): WorkSessionResponseDto {
    return {
      id: session.id,
      ownerId: session.ownerId,
      projectId: session.projectId,
      startedAt: session.startedAt.toISOString(),
      endedAt: session.endedAt?.toISOString() ?? null,
      memo: session.memo,
      createdAt: session.createdAt.toISOString(),
      updatedAt: session.updatedAt.toISOString(),
      deletedAt: session.deletedAt?.toISOString() ?? null,
      syncStatus: 'Synced',
    };
  }
}
