import { Injectable, InternalServerErrorException } from '@nestjs/common';
import { Prisma, RowCounter, WorkSession } from '@prisma/client';
import { PrismaService } from '../database/prisma.service';
import {
  ProjectResponseDto,
  RowCounterResponseDto,
  WorkSessionResponseDto,
} from './project-response.dto';

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
      include: {
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
      },
    });

    return projects
      .sort((first, second) => this.compareProjects(first, second))
      .map((project) => this.toResponse(project, ownerId));
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
