import {
  BadRequestException,
  Injectable,
  InternalServerErrorException,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import {
  Prisma,
  ProjectYarnUsage,
  ProjectProgressPhoto,
  RowInstruction,
  RowCounter,
  WorkSession,
} from '@prisma/client';
import { randomUUID } from 'node:crypto';
import { PrismaService } from '../database/prisma.service';
import {
  ProjectResponseDto,
  ProjectPatternCopyResponseDto,
  ProjectProgressPhotoResponseDto,
  ProjectYarnUsageResponseDto,
  RowInstructionResponseDto,
  RowCounterResponseDto,
  WorkSessionResponseDto,
} from './project-response.dto';
import {
  SaveRowCounterDto,
  SaveRowInstructionDto,
  SaveWorkSessionDto,
  SaveProjectDto,
  SaveProjectPatternCopyDto,
  SaveProjectProgressPhotoDto,
  SaveProjectYarnUsageDto,
} from './project-save.dto';
import { LocalFileStorageService } from '../storage/local-file-storage.service';
import { UploadedPatternFile } from '../patterns/uploaded-pattern-file';

type ProjectWithChildren = Prisma.ProjectGetPayload<{
  include: {
    rowCounter: {
      include: {
        rowInstructions: true;
      };
    };
    workSessions: true;
    patternCopy: {
      include: {
        sourcePatternDocument: {
          include: {
            storedFile: true;
          };
        };
      };
    };
  };
}>;
type RowCounterWithInstructions = NonNullable<ProjectWithChildren['rowCounter']>;
type ProjectPatternCopyWithSource = NonNullable<
  ProjectWithChildren['patternCopy']
>;
type ProjectPatternCopyFile = {
  storageKey: string;
  contentType: string;
  fileName: string;
};

@Injectable()
export class ProjectsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly fileStorage: LocalFileStorageService,
  ) {}

  private readonly logger = new Logger(ProjectsService.name);

  async listProjects(ownerId: string): Promise<ProjectResponseDto[]> {
    const projects = await this.prisma.project.findMany({
      where: {
        ownerId,
        deletedAt: null,
      },
      include: this.projectInclude(ownerId),
    });

    const sorted = projects.sort((first, second) =>
      this.compareProjects(first, second),
    );

    // 한 프로젝트의 자식 레코드가 결손이어도 목록 전체를 실패시키지 않는다.
    // 변환에 실패한 항목만 제외하고 나머지는 정상 반환한다.
    const responses: ProjectResponseDto[] = [];

    for (const project of sorted) {
      try {
        responses.push(this.toResponse(project, ownerId));
      } catch (error) {
        this.logger.error(
          `Skipped project ${project.id} in list response: ${
            error instanceof Error ? error.message : String(error)
          }`,
        );
      }
    }

    return responses;
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
    this.assertProjectChildReferences(body);

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

    this.assertProjectChildReferences(body);

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
    await this.prisma.rowInstruction.updateMany({
      where: {
        ownerId,
        projectId: id,
      },
      data: {
        deletedAt,
      },
    });
    await this.prisma.projectPatternCopy.updateMany({
      where: {
        ownerId,
        projectId: id,
      },
      data: {
        deletedAt,
      },
    });
    await this.prisma.projectProgressPhoto.updateMany({
      where: {
        ownerId,
        projectId: id,
      },
      data: {
        deletedAt,
      },
    });
  }

  async updateProjectRowCounter(
    ownerId: string,
    projectId: string,
    body: SaveRowCounterDto,
  ): Promise<RowCounterResponseDto> {
    await this.findActiveProject(ownerId, projectId);

    if (body.projectId !== projectId) {
      throw new BadRequestException({
        code: 'VALIDATION_FAILED',
        message: 'Row counter project ID must match the project ID.',
      });
    }

    const updated = await this.prisma.rowCounter.update({
      where: {
        projectId,
      },
      data: {
        ownerId,
        name: body.name,
        mode: this.normalizedCounterMode(body.mode),
        sectionName: this.trimmedOrNull(body.sectionName),
        memo: this.trimmedOrNull(body.memo),
        currentRow: body.currentRow,
        targetRow: body.targetRow,
        deletedAt: null,
      },
      include: this.rowCounterInclude(ownerId),
    });

    return this.toRowCounterResponse(updated);
  }

  async upsertProjectRowInstruction(
    ownerId: string,
    projectId: string,
    body: SaveRowInstructionDto,
    instructionId?: string,
  ): Promise<RowInstructionResponseDto> {
    if (instructionId && instructionId !== body.id) {
      throw new BadRequestException({
        code: 'VALIDATION_FAILED',
        message: 'Row instruction ID must match the route ID.',
      });
    }

    const rowCounter = await this.findActiveProjectRowCounter(ownerId, projectId);

    if (body.rowCounterId !== rowCounter.id) {
      throw new NotFoundException({
        code: 'ROW_COUNTER_NOT_FOUND',
        message: 'Row counter not found.',
      });
    }

    if (body.instructionText.trim().length === 0) {
      throw new BadRequestException({
        code: 'VALIDATION_FAILED',
        message: 'Row instruction text is required.',
      });
    }

    if (instructionId) {
      await this.findActiveRowInstruction(
        ownerId,
        projectId,
        rowCounter.id,
        instructionId,
      );
    }

    const duplicate = await this.prisma.rowInstruction.findFirst({
      where: {
        ownerId,
        projectId,
        rowCounterId: rowCounter.id,
        rowNumber: body.rowNumber,
        deletedAt: null,
        NOT: {
          id: body.id,
        },
      },
    });

    if (duplicate) {
      throw new BadRequestException({
        code: 'ROW_INSTRUCTION_ROW_DUPLICATED',
        message: 'A row instruction for this row already exists.',
      });
    }

    const data = {
      ownerId,
      projectId,
      rowCounterId: rowCounter.id,
      rowNumber: body.rowNumber,
      instructionText: body.instructionText.trim(),
      skillTags: body.skillTags?.trim() ?? '',
      deletedAt: null,
    };

    const instruction = instructionId
      ? await this.prisma.rowInstruction.update({
          where: {
            id: instructionId,
          },
          data,
        })
      : await this.prisma.rowInstruction.upsert({
          where: {
            id: body.id,
          },
          create: {
            id: body.id,
            ...data,
          },
          update: data,
        });

    return this.toRowInstructionResponse(instruction);
  }

  async deleteProjectRowInstruction(
    ownerId: string,
    projectId: string,
    instructionId: string,
  ): Promise<void> {
    const rowCounter = await this.findActiveProjectRowCounter(ownerId, projectId);
    await this.findActiveRowInstruction(
      ownerId,
      projectId,
      rowCounter.id,
      instructionId,
    );

    await this.prisma.rowInstruction.update({
      where: {
        id: instructionId,
      },
      data: {
        deletedAt: new Date(),
      },
    });
  }

  async listProjectWorkSessions(
    ownerId: string,
    projectId: string,
  ): Promise<WorkSessionResponseDto[]> {
    await this.findActiveProject(ownerId, projectId);

    const sessions = await this.prisma.workSession.findMany({
      where: {
        ownerId,
        projectId,
        deletedAt: null,
      },
      orderBy: {
        startedAt: 'asc',
      },
    });

    return sessions.map((session) => this.toWorkSessionResponse(session));
  }

  async upsertProjectWorkSession(
    ownerId: string,
    projectId: string,
    body: SaveWorkSessionDto,
    sessionId?: string,
  ): Promise<WorkSessionResponseDto> {
    await this.findActiveProject(ownerId, projectId);

    if (sessionId && sessionId !== body.id) {
      throw new BadRequestException({
        code: 'VALIDATION_FAILED',
        message: 'Work session ID must match the route ID.',
      });
    }

    if (body.projectId !== projectId) {
      throw new BadRequestException({
        code: 'VALIDATION_FAILED',
        message: 'Work session project ID must match the project ID.',
      });
    }

    if (sessionId) {
      await this.findActiveWorkSession(ownerId, projectId, sessionId);
    }

    const startedAt = new Date(body.startedAt);
    const endedAt = body.endedAt ? new Date(body.endedAt) : null;

    if (endedAt && endedAt.getTime() < startedAt.getTime()) {
      throw new BadRequestException({
        code: 'VALIDATION_FAILED',
        message: 'Work session end time must be after the start time.',
      });
    }

    const data = {
      ownerId,
      projectId,
      startedAt,
      endedAt,
      memo: this.trimmedOrNull(body.memo),
      deletedAt: null,
    };

    const session = sessionId
      ? await this.prisma.workSession.update({
          where: {
            id: sessionId,
          },
          data,
        })
      : await this.prisma.workSession.upsert({
          where: {
            id: body.id,
          },
          create: {
            id: body.id,
            ...data,
          },
          update: data,
        });

    return this.toWorkSessionResponse(session);
  }

  async deleteProjectWorkSession(
    ownerId: string,
    projectId: string,
    sessionId: string,
  ): Promise<void> {
    await this.findActiveWorkSession(ownerId, projectId, sessionId);

    await this.prisma.workSession.update({
      where: {
        id: sessionId,
      },
      data: {
        deletedAt: new Date(),
      },
    });
  }

  async listProjectYarnUsages(
    ownerId: string,
    projectId: string,
  ): Promise<ProjectYarnUsageResponseDto[]> {
    await this.findActiveProject(ownerId, projectId);

    const usages = await this.prisma.projectYarnUsage.findMany({
      where: {
        ownerId,
        projectId,
        deletedAt: null,
      },
      orderBy: {
        usedAt: 'desc',
      },
    });

    return usages.map((usage) => this.toProjectYarnUsageResponse(usage));
  }

  async recordProjectYarnUsage(
    ownerId: string,
    projectId: string,
    body: SaveProjectYarnUsageDto,
  ): Promise<ProjectYarnUsageResponseDto> {
    return this.prisma.$transaction(async (transaction) => {
      const project = await transaction.project.findFirst({
        where: {
          id: projectId,
          ownerId,
          deletedAt: null,
        },
      });

      if (!project) {
        throw new NotFoundException({
          code: 'PROJECT_NOT_FOUND',
          message: 'Project not found.',
        });
      }

      const yarnId = body.yarnId ?? project.yarnId;

      if (!yarnId) {
        throw new BadRequestException({
          code: 'PROJECT_YARN_REQUIRED',
          message: 'Project yarn is required.',
        });
      }

      const yarn = await transaction.yarn.findFirst({
        where: {
          id: yarnId,
          ownerId,
          deletedAt: null,
        },
      });

      if (!yarn) {
        throw new NotFoundException({
          code: 'YARN_NOT_FOUND',
          message: 'Yarn not found.',
        });
      }

      if (yarn.quantity < body.quantityUsed) {
        throw new BadRequestException({
          code: 'YARN_QUANTITY_INSUFFICIENT',
          message: 'Yarn quantity is insufficient.',
        });
      }

      await transaction.yarn.update({
        where: { id: yarn.id },
        data: {
          quantity: yarn.quantity - body.quantityUsed,
        },
      });

      const usage = await transaction.projectYarnUsage.create({
        data: {
          id: body.id ?? randomUUID(),
          ownerId,
          projectId,
          yarnId: yarn.id,
          yarnNameSnapshot:
            this.trimmedOrNull(body.yarnNameSnapshot) ??
            project.yarnNameSnapshot ??
            yarn.name,
          quantityUsed: body.quantityUsed,
          memo: this.trimmedOrEmpty(body.memo),
          usedAt: body.usedAt ? new Date(body.usedAt) : new Date(),
          deletedAt: null,
        },
      });

      return this.toProjectYarnUsageResponse(usage);
    });
  }

  async updateProjectYarnUsage(
    ownerId: string,
    projectId: string,
    usageId: string,
    body: SaveProjectYarnUsageDto,
  ): Promise<ProjectYarnUsageResponseDto> {
    return this.prisma.$transaction(async (transaction) => {
      const usage = await this.findActiveProjectYarnUsage(
        transaction,
        ownerId,
        projectId,
        usageId,
      );

      const yarnId = usage.yarnId ?? body.yarnId;
      if (!yarnId) {
        throw new BadRequestException({
          code: 'PROJECT_YARN_REQUIRED',
          message: 'Project yarn is required.',
        });
      }

      const yarn = await this.findActiveYarn(transaction, ownerId, yarnId);
      const quantityDelta = body.quantityUsed - usage.quantityUsed;

      if (quantityDelta > 0 && yarn.quantity < quantityDelta) {
        throw new BadRequestException({
          code: 'YARN_QUANTITY_INSUFFICIENT',
          message: 'Yarn quantity is insufficient.',
        });
      }

      await transaction.yarn.update({
        where: { id: yarn.id },
        data: {
          quantity: yarn.quantity - quantityDelta,
        },
      });

      const updatedUsage = await transaction.projectYarnUsage.update({
        where: { id: usage.id },
        data: {
          yarnId: yarn.id,
          yarnNameSnapshot:
            this.trimmedOrNull(body.yarnNameSnapshot) ??
            usage.yarnNameSnapshot,
          quantityUsed: body.quantityUsed,
          memo: this.trimmedOrEmpty(body.memo),
          usedAt: body.usedAt ? new Date(body.usedAt) : usage.usedAt,
        },
      });

      return this.toProjectYarnUsageResponse(updatedUsage);
    });
  }

  async deleteProjectYarnUsage(
    ownerId: string,
    projectId: string,
    usageId: string,
  ): Promise<void> {
    await this.prisma.$transaction(async (transaction) => {
      const usage = await this.findActiveProjectYarnUsage(
        transaction,
        ownerId,
        projectId,
        usageId,
      );

      if (usage.yarnId) {
        const yarn = await transaction.yarn.findFirst({
          where: {
            id: usage.yarnId,
            ownerId,
            deletedAt: null,
          },
        });

        if (yarn) {
          await transaction.yarn.update({
            where: { id: yarn.id },
            data: {
              quantity: yarn.quantity + usage.quantityUsed,
            },
          });
        }
      }

      await transaction.projectYarnUsage.update({
        where: { id: usage.id },
        data: {
          deletedAt: new Date(),
        },
      });
    });
  }

  async listProjectProgressPhotos(
    ownerId: string,
    projectId: string,
  ): Promise<ProjectProgressPhotoResponseDto[]> {
    await this.findActiveProject(ownerId, projectId);

    const photos = await this.prisma.projectProgressPhoto.findMany({
      where: {
        ownerId,
        projectId,
        deletedAt: null,
      },
      orderBy: {
        takenAt: 'desc',
      },
    });

    return photos.map((photo) => this.toProjectProgressPhotoResponse(photo));
  }

  async uploadProjectProgressPhoto(
    ownerId: string,
    projectId: string,
    body: SaveProjectProgressPhotoDto & { id?: string },
    file: UploadedPatternFile | undefined,
  ): Promise<ProjectProgressPhotoResponseDto> {
    this.assertImage(file);
    await this.findActiveProject(ownerId, projectId);

    const photoId = body.id ?? randomUUID();
    const fileName = this.trimmedOrDefault(file.originalname, 'progress-photo');
    const stored = await this.fileStorage.saveProjectProgressPhoto({
      ownerId,
      projectId,
      photoId,
      fileName,
      buffer: file.buffer,
    });
    const photo = await this.prisma.projectProgressPhoto.create({
      data: {
        id: photoId,
        ownerId,
        projectId,
        fileName,
        contentType: file.mimetype || 'application/octet-stream',
        byteSize: stored.byteSize,
        storageKey: stored.storageKey,
        caption: this.trimmedOrEmpty(body.caption),
        takenAt: body.takenAt ? new Date(body.takenAt) : new Date(),
        deletedAt: null,
      },
    });

    return this.toProjectProgressPhotoResponse(photo);
  }

  async updateProjectProgressPhoto(
    ownerId: string,
    projectId: string,
    photoId: string,
    body: SaveProjectProgressPhotoDto,
  ): Promise<ProjectProgressPhotoResponseDto> {
    const photo = await this.findActiveProjectProgressPhoto(
      ownerId,
      projectId,
      photoId,
    );
    const updated = await this.prisma.projectProgressPhoto.update({
      where: {
        id: photo.id,
      },
      data: {
        caption: this.trimmedOrEmpty(body.caption),
        takenAt: body.takenAt ? new Date(body.takenAt) : photo.takenAt,
      },
    });

    return this.toProjectProgressPhotoResponse(updated);
  }

  async getProjectProgressPhotoFile(
    ownerId: string,
    projectId: string,
    photoId: string,
  ): Promise<ProjectPatternCopyFile> {
    const photo = await this.findActiveProjectProgressPhoto(
      ownerId,
      projectId,
      photoId,
    );

    await this.fileStorage.assertExists(photo.storageKey);
    return {
      storageKey: photo.storageKey,
      contentType: photo.contentType,
      fileName: photo.fileName,
    };
  }

  async deleteProjectProgressPhoto(
    ownerId: string,
    projectId: string,
    photoId: string,
  ): Promise<void> {
    const photo = await this.findActiveProjectProgressPhoto(
      ownerId,
      projectId,
      photoId,
    );

    await this.fileStorage.remove(photo.storageKey);
    await this.prisma.projectProgressPhoto.update({
      where: {
        id: photo.id,
      },
      data: {
        deletedAt: new Date(),
      },
    });
  }

  async getProjectPatternCopyFile(
    ownerId: string,
    projectId: string,
  ): Promise<ProjectPatternCopyFile> {
    const patternCopy = await this.findActiveProjectPatternCopy(
      ownerId,
      projectId,
    );

    if (patternCopy.fileStorageKey) {
      await this.fileStorage.assertExists(patternCopy.fileStorageKey);
      return {
        storageKey: patternCopy.fileStorageKey,
        contentType: patternCopy.fileContentType ?? 'application/pdf',
        fileName: patternCopy.fileNameSnapshot ?? 'pattern.pdf',
      };
    }

    const storedFile = patternCopy?.sourcePatternDocument?.storedFile;

    if (
      !storedFile ||
      storedFile.deletedAt !== null
    ) {
      throw new NotFoundException({
        code: 'PROJECT_PATTERN_COPY_FILE_NOT_FOUND',
        message: 'Project pattern copy file not found.',
      });
    }

    await this.fileStorage.assertExists(storedFile.storageKey);
    return {
      storageKey: storedFile.storageKey,
      contentType: storedFile.contentType,
      fileName: storedFile.originalFileName,
    };
  }

  async uploadProjectPatternCopyFile(
    ownerId: string,
    projectId: string,
    file: UploadedPatternFile | undefined,
  ): Promise<ProjectPatternCopyResponseDto> {
    this.assertPdf(file);

    const patternCopy = await this.findActiveProjectPatternCopy(
      ownerId,
      projectId,
    );
    const previousStorageKey = patternCopy.fileStorageKey;
    const stored = await this.fileStorage.saveProjectPatternCopyPdf({
      ownerId,
      projectId,
      copyId: patternCopy.id,
      fileId: randomUUID(),
      buffer: file.buffer,
    });
    const updated = await this.prisma.projectPatternCopy.update({
      where: {
        id: patternCopy.id,
      },
      data: {
        fileNameSnapshot: this.trimmedOrDefault(
          file.originalname,
          patternCopy.fileNameSnapshot ?? 'pattern.pdf',
        ),
        fileStorageKey: stored.storageKey,
        fileContentType: file.mimetype || 'application/pdf',
        fileByteSize: stored.byteSize,
      },
      include: {
        sourcePatternDocument: {
          include: {
            storedFile: true,
          },
        },
      },
    });

    if (previousStorageKey && previousStorageKey !== stored.storageKey) {
      await this.fileStorage.remove(previousStorageKey);
    }

    const response = this.toProjectPatternCopyResponse(updated, ownerId);

    if (!response) {
      throw new NotFoundException({
        code: 'PROJECT_PATTERN_COPY_NOT_FOUND',
        message: 'Project pattern copy not found.',
      });
    }

    return response;
  }

  async uploadProjectPatternCopyDrawing(
    ownerId: string,
    projectId: string,
    file: UploadedPatternFile | undefined,
  ): Promise<ProjectPatternCopyResponseDto> {
    this.assertDrawingFile(file);

    const patternCopy = await this.findActiveProjectPatternCopy(
      ownerId,
      projectId,
    );
    const stored = await this.fileStorage.saveProjectPatternDrawing({
      ownerId,
      projectId,
      copyId: patternCopy.id,
      buffer: file.buffer,
    });
    const updated = await this.prisma.projectPatternCopy.update({
      where: {
        id: patternCopy.id,
      },
      data: {
        drawingStorageKey: stored.storageKey,
        drawingContentType: file.mimetype || 'application/octet-stream',
        drawingByteSize: stored.byteSize,
        drawingUpdatedAt: new Date(),
      },
      include: {
        sourcePatternDocument: {
          include: {
            storedFile: true,
          },
        },
      },
    });
    const response = this.toProjectPatternCopyResponse(updated, ownerId);

    if (!response) {
      throw new NotFoundException({
        code: 'PROJECT_PATTERN_COPY_NOT_FOUND',
        message: 'Project pattern copy not found.',
      });
    }

    return response;
  }

  async getProjectPatternCopyDrawing(
    ownerId: string,
    projectId: string,
  ): Promise<ProjectPatternCopyWithSource> {
    const patternCopy = await this.findActiveProjectPatternCopy(
      ownerId,
      projectId,
    );

    if (!patternCopy.drawingStorageKey) {
      throw new NotFoundException({
        code: 'PROJECT_PATTERN_COPY_DRAWING_NOT_FOUND',
        message: 'Project pattern copy drawing not found.',
      });
    }

    await this.fileStorage.assertExists(patternCopy.drawingStorageKey);
    return patternCopy;
  }

  async deleteProjectPatternCopyDrawing(
    ownerId: string,
    projectId: string,
  ): Promise<void> {
    const patternCopy = await this.findActiveProjectPatternCopy(
      ownerId,
      projectId,
    );

    await this.fileStorage.remove(patternCopy.drawingStorageKey);
    await this.prisma.projectPatternCopy.update({
      where: {
        id: patternCopy.id,
      },
      data: {
        drawingStorageKey: null,
        drawingContentType: null,
        drawingByteSize: null,
        drawingUpdatedAt: null,
      },
    });
  }

  openFileReadStream(storageKey: string) {
    return this.fileStorage.openReadStream(storageKey);
  }

  private async findActiveProject(ownerId: string, projectId: string) {
    const project = await this.prisma.project.findFirst({
      where: {
        id: projectId,
        ownerId,
        deletedAt: null,
      },
    });

    if (!project) {
      throw new NotFoundException({
        code: 'PROJECT_NOT_FOUND',
        message: 'Project not found.',
      });
    }

    return project;
  }

  private async findActiveProjectRowCounter(
    ownerId: string,
    projectId: string,
  ): Promise<RowCounterWithInstructions> {
    await this.findActiveProject(ownerId, projectId);

    const rowCounter = await this.prisma.rowCounter.findFirst({
      where: {
        ownerId,
        projectId,
        deletedAt: null,
      },
      include: this.rowCounterInclude(ownerId),
    });

    if (!rowCounter) {
      throw new NotFoundException({
        code: 'ROW_COUNTER_NOT_FOUND',
        message: 'Row counter not found.',
      });
    }

    return rowCounter;
  }

  private async findActiveRowInstruction(
    ownerId: string,
    projectId: string,
    rowCounterId: string,
    instructionId: string,
  ): Promise<RowInstruction> {
    const instruction = await this.prisma.rowInstruction.findFirst({
      where: {
        id: instructionId,
        ownerId,
        projectId,
        rowCounterId,
        deletedAt: null,
      },
    });

    if (!instruction) {
      throw new NotFoundException({
        code: 'ROW_INSTRUCTION_NOT_FOUND',
        message: 'Row instruction not found.',
      });
    }

    return instruction;
  }

  private async findActiveWorkSession(
    ownerId: string,
    projectId: string,
    sessionId: string,
  ): Promise<WorkSession> {
    await this.findActiveProject(ownerId, projectId);

    const session = await this.prisma.workSession.findFirst({
      where: {
        id: sessionId,
        ownerId,
        projectId,
        deletedAt: null,
      },
    });

    if (!session) {
      throw new NotFoundException({
        code: 'WORK_SESSION_NOT_FOUND',
        message: 'Work session not found.',
      });
    }

    return session;
  }

  private async findActiveProjectYarnUsage(
    transaction: Pick<PrismaService, 'projectYarnUsage'>,
    ownerId: string,
    projectId: string,
    usageId: string,
  ): Promise<ProjectYarnUsage> {
    const usage = await transaction.projectYarnUsage.findFirst({
      where: {
        id: usageId,
        ownerId,
        projectId,
        deletedAt: null,
      },
    });

    if (!usage) {
      throw new NotFoundException({
        code: 'PROJECT_YARN_USAGE_NOT_FOUND',
        message: 'Project yarn usage not found.',
      });
    }

    return usage;
  }

  private async findActiveProjectProgressPhoto(
    ownerId: string,
    projectId: string,
    photoId: string,
  ): Promise<ProjectProgressPhoto> {
    const photo = await this.prisma.projectProgressPhoto.findFirst({
      where: {
        id: photoId,
        ownerId,
        projectId,
        deletedAt: null,
      },
    });

    if (!photo) {
      throw new NotFoundException({
        code: 'PROJECT_PROGRESS_PHOTO_NOT_FOUND',
        message: 'Project progress photo not found.',
      });
    }

    return photo;
  }

  private async findActiveYarn(
    transaction: Pick<PrismaService, 'yarn'>,
    ownerId: string,
    yarnId: string,
  ) {
    const yarn = await transaction.yarn.findFirst({
      where: {
        id: yarnId,
        ownerId,
        deletedAt: null,
      },
    });

    if (!yarn) {
      throw new NotFoundException({
        code: 'YARN_NOT_FOUND',
        message: 'Yarn not found.',
      });
    }

    return yarn;
  }

  private async findActiveProjectPatternCopy(
    ownerId: string,
    projectId: string,
  ): Promise<ProjectPatternCopyWithSource> {
    const project = await this.prisma.project.findFirst({
      where: {
        id: projectId,
        ownerId,
        deletedAt: null,
      },
      include: {
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

    const patternCopy = project?.patternCopy;

    if (
      !patternCopy ||
      patternCopy.ownerId !== ownerId ||
      patternCopy.deletedAt !== null
    ) {
      throw new NotFoundException({
        code: 'PROJECT_PATTERN_COPY_NOT_FOUND',
        message: 'Project pattern copy not found.',
      });
    }

    return patternCopy;
  }

  private assertDrawingFile(
    file: UploadedPatternFile | undefined,
  ): asserts file is UploadedPatternFile {
    if (!file) {
      throw new BadRequestException({
        code: 'VALIDATION_FAILED',
        message: 'Drawing file is required.',
      });
    }
  }

  private assertPdf(
    file: UploadedPatternFile | undefined,
  ): asserts file is UploadedPatternFile {
    if (!file) {
      throw new BadRequestException({
        code: 'VALIDATION_FAILED',
        message: 'Project pattern copy PDF file is required.',
      });
    }

    const extensionIsPdf = file.originalname.toLowerCase().endsWith('.pdf');
    const mimeIsPdf = file.mimetype === 'application/pdf';

    if (!extensionIsPdf || !mimeIsPdf) {
      throw new BadRequestException({
        code: 'VALIDATION_FAILED',
        message: 'Project pattern copy upload must be a PDF file.',
      });
    }
  }

  private projectInclude(ownerId: string) {
    const include = {
      rowCounter: {
        include: this.rowCounterInclude(ownerId),
      },
      workSessions: {
        where: {
          ownerId,
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
    } satisfies Prisma.ProjectInclude;

    return include;
  }

  private rowCounterInclude(ownerId: string) {
    return {
      rowInstructions: {
        where: {
          ownerId,
          deletedAt: null,
        },
        orderBy: {
          rowNumber: 'asc',
        },
      },
    } satisfies Prisma.RowCounterInclude;
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

  private assertProjectChildReferences(body: SaveProjectDto): void {
    if (body.rowCounter.projectId !== body.id) {
      throw new BadRequestException({
        code: 'VALIDATION_FAILED',
        message: 'Row counter project ID must match the project ID.',
      });
    }

    const mismatchedWorkSession = body.workSessions.some(
      (session) => session.projectId !== body.id,
    );

    if (mismatchedWorkSession) {
      throw new BadRequestException({
        code: 'VALIDATION_FAILED',
        message: 'Work session project ID must match the project ID.',
      });
    }
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
      targetDate: body.targetDate ? new Date(body.targetDate) : null,
      finishedAt: body.finishedAt ? new Date(body.finishedAt) : null,
      lastWorkedAt: body.lastWorkedAt ? new Date(body.lastWorkedAt) : null,
      yarnId: body.yarnId ?? null,
      yarnNameSnapshot: this.trimmedOrNull(body.yarnNameSnapshot),
      yarnBrandSnapshot: this.trimmedOrNull(body.yarnBrandSnapshot),
      yarnColorwaySnapshot: this.trimmedOrNull(body.yarnColorwaySnapshot),
      yarnWeightSnapshot: this.trimmedOrNull(body.yarnWeightSnapshot),
      needleId: body.needleId ?? null,
      needleNameSnapshot: this.trimmedOrNull(body.needleNameSnapshot),
      needleTypeSnapshot: this.trimmedOrNull(body.needleTypeSnapshot),
      needleSizeSnapshot: this.trimmedOrNull(body.needleSizeSnapshot),
      needleLengthSnapshot: this.trimmedOrNull(body.needleLengthSnapshot),
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
        mode: this.normalizedCounterMode(body.rowCounter.mode),
        sectionName: this.trimmedOrNull(body.rowCounter.sectionName),
        memo: this.trimmedOrNull(body.rowCounter.memo),
        currentRow: body.rowCounter.currentRow,
        targetRow: body.rowCounter.targetRow,
        deletedAt: null,
      },
      update: {
        ownerId,
        name: body.rowCounter.name,
        mode: this.normalizedCounterMode(body.rowCounter.mode),
        sectionName: this.trimmedOrNull(body.rowCounter.sectionName),
        memo: this.trimmedOrNull(body.rowCounter.memo),
        currentRow: body.rowCounter.currentRow,
        targetRow: body.rowCounter.targetRow,
        deletedAt: null,
      },
    });

    await this.saveRowInstructions(transaction, ownerId, body);

    // 기존 full-replace(deleteMany 후 createMany)는 요청 본문에 없는 작업 세션을
    // 무이력 삭제해, 다른 기기가 생성했거나 오래된 스냅샷이 모르는 세션을 소멸시켰다(SYNC-08).
    // 증분 upsert로 바꿔 요청에 담긴 세션만 갱신/생성하고 나머지는 보존한다.
    // 세션 삭제는 전용 DELETE 엔드포인트(deleteWorkSession)가 담당한다.
    for (const session of body.workSessions) {
      await transaction.workSession.upsert({
        where: { id: session.id },
        create: {
          id: session.id,
          ownerId,
          projectId: body.id,
          startedAt: new Date(session.startedAt),
          endedAt: session.endedAt ? new Date(session.endedAt) : null,
          memo: session.memo,
          deletedAt: null,
        },
        update: {
          startedAt: new Date(session.startedAt),
          endedAt: session.endedAt ? new Date(session.endedAt) : null,
          memo: session.memo,
          deletedAt: null,
        },
      });
    }

    await this.saveProjectPatternCopy(transaction, ownerId, body);
  }

  private async saveRowInstructions(
    transaction: Prisma.TransactionClient,
    ownerId: string,
    body: SaveProjectDto,
  ): Promise<void> {
    if (body.rowCounter.rowInstructions === undefined) {
      return;
    }

    await transaction.rowInstruction.deleteMany({
      where: {
        ownerId,
        projectId: body.id,
        rowCounterId: body.rowCounter.id,
      },
    });

    if (body.rowCounter.rowInstructions.length === 0) {
      return;
    }

    const seenRowNumbers = new Set<number>();
    const instructions = body.rowCounter.rowInstructions.map((instruction) => {
      if (instruction.rowCounterId !== body.rowCounter.id) {
        throw new NotFoundException({
          code: 'ROW_COUNTER_NOT_FOUND',
          message: 'Row counter not found.',
        });
      }

      if (seenRowNumbers.has(instruction.rowNumber)) {
        throw new BadRequestException({
          code: 'VALIDATION_FAILED',
          message: 'Duplicate row instruction numbers are not allowed.',
        });
      }
      seenRowNumbers.add(instruction.rowNumber);

      return {
        id: instruction.id,
        ownerId,
        projectId: body.id,
        rowCounterId: body.rowCounter.id,
        rowNumber: instruction.rowNumber,
        instructionText: instruction.instructionText.trim(),
        skillTags: instruction.skillTags?.trim() ?? '',
        deletedAt: null,
      };
    });

    if (instructions.some((instruction) => instruction.instructionText.length === 0)) {
      throw new BadRequestException({
        code: 'VALIDATION_FAILED',
        message: 'Row instruction text is required.',
      });
    }

    await transaction.rowInstruction.createMany({
      data: instructions,
    });
  }

  private async saveProjectPatternCopy(
    transaction: Prisma.TransactionClient,
    ownerId: string,
    body: SaveProjectDto,
  ): Promise<void> {
    if (body.patternCopy === undefined) {
      return;
    }

    if (body.patternCopy === null) {
      await transaction.projectPatternCopy.deleteMany({
        where: {
          ownerId,
          projectId: body.id,
        },
      });
      return;
    }

    const copy = body.patternCopy;

    if (copy.projectId !== body.id) {
      throw new NotFoundException({
        code: 'PROJECT_PATTERN_COPY_NOT_FOUND',
        message: 'Project pattern copy not found.',
      });
    }

    let sourceStoredFile: {
      storageKey: string;
      contentType: string | null;
    } | null = null;

    if (copy.sourcePatternDocumentId) {
      const sourcePattern = await transaction.patternDocument.findFirst({
        where: {
          id: copy.sourcePatternDocumentId,
          ownerId,
          deletedAt: null,
        },
        include: {
          storedFile: true,
        },
      });

      if (!sourcePattern) {
        throw new NotFoundException({
          code: 'PATTERN_NOT_FOUND',
          message: 'Pattern not found.',
        });
      }

      if (sourcePattern.storedFile && !sourcePattern.storedFile.deletedAt) {
        sourceStoredFile = {
          storageKey: sourcePattern.storedFile.storageKey,
          contentType: sourcePattern.storedFile.contentType,
        };
      }
    }

    const scalarInput = this.toProjectPatternCopyScalarInput(copy);

    const existing = await transaction.projectPatternCopy.findUnique({
      where: { projectId: body.id },
    });

    // 창고 경로 연결은 파일 업로드 없이 메타만 도착해 서버 복사본에 파일 키가 비었다(결함 19/38).
    // 원본 StoredFile을 물리 복사해 복사본을 원본과 독립시킨다(LINK-04/05 원칙).
    // 업로드 경로로 이미 파일이 채워진 복사본은 덮지 않는다.
    const materializedFileInput = async (): Promise<
      | {
          fileStorageKey: string;
          fileContentType: string | null;
          fileByteSize: number;
        }
      | Record<string, never>
    > => {
      if (!sourceStoredFile) {
        return {};
      }

      const buffer = await this.fileStorage.readFile(
        sourceStoredFile.storageKey,
      );
      const stored = await this.fileStorage.saveProjectPatternCopyPdf({
        ownerId,
        projectId: body.id,
        copyId: copy.id,
        fileId: randomUUID(),
        buffer,
      });

      return {
        fileStorageKey: stored.storageKey,
        fileContentType: sourceStoredFile.contentType,
        fileByteSize: stored.byteSize,
      };
    };

    // 다른 도안으로 교체되는 경우(복사본 id가 바뀜) 기존 레코드를 지우고 새로 만든다.
    // upsert의 update 브랜치는 scalarInput에 없는 파일/드로잉 키를 갱신하지 않아
    // 이전 도안의 파일과 드로잉이 새 도안에 그대로 계승된다(결함 37). 완전 교체로 참조를 끊는다.
    // 교체로 참조가 끊긴 물리 파일 정리는 RC-08(파일 고아화)에서 별도로 다룬다.
    if (existing && existing.id !== copy.id) {
      await transaction.projectPatternCopy.delete({
        where: { projectId: body.id },
      });
      await transaction.projectPatternCopy.create({
        data: {
          id: copy.id,
          ownerId,
          projectId: body.id,
          ...scalarInput,
          ...(await materializedFileInput()),
          deletedAt: null,
        },
      });
      return;
    }

    const fileInput =
      existing?.fileStorageKey ? {} : await materializedFileInput();

    await transaction.projectPatternCopy.upsert({
      where: {
        projectId: body.id,
      },
      create: {
        id: copy.id,
        ownerId,
        projectId: body.id,
        ...scalarInput,
        ...fileInput,
        deletedAt: null,
      },
      update: {
        ownerId,
        ...scalarInput,
        ...fileInput,
        deletedAt: null,
      },
    });
  }

  private toProjectPatternCopyScalarInput(copy: SaveProjectPatternCopyDto) {
    return {
      sourcePatternDocumentId: copy.sourcePatternDocumentId,
      titleSnapshot: copy.titleSnapshot.trim(),
      designerSnapshot: this.trimmedOrNull(copy.designerSnapshot),
      fileNameSnapshot: this.trimmedOrNull(copy.fileNameSnapshot),
      pageCountSnapshot: copy.pageCountSnapshot,
      drawingUpdatedAt: copy.drawingUpdatedAt
        ? new Date(copy.drawingUpdatedAt)
        : null,
      copiedAt: new Date(copy.copiedAt),
    };
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
      targetDate: project.targetDate?.toISOString() ?? null,
      finishedAt: project.finishedAt?.toISOString() ?? null,
      lastWorkedAt: project.lastWorkedAt?.toISOString() ?? null,
      yarnId: project.yarnId,
      yarnNameSnapshot: project.yarnNameSnapshot,
      yarnBrandSnapshot: project.yarnBrandSnapshot,
      yarnColorwaySnapshot: project.yarnColorwaySnapshot,
      yarnWeightSnapshot: project.yarnWeightSnapshot,
      needleId: project.needleId,
      needleNameSnapshot: project.needleNameSnapshot,
      needleTypeSnapshot: project.needleTypeSnapshot,
      needleSizeSnapshot: project.needleSizeSnapshot,
      needleLengthSnapshot: project.needleLengthSnapshot,
      patternCopy: this.toProjectPatternCopyResponse(project.patternCopy, ownerId),
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

  private toRowCounterResponse(
    rowCounter: RowCounterWithInstructions,
  ): RowCounterResponseDto {
    return {
      id: rowCounter.id,
      ownerId: rowCounter.ownerId,
      projectId: rowCounter.projectId,
      name: rowCounter.name,
      mode: this.normalizedCounterMode(rowCounter.mode),
      sectionName: rowCounter.sectionName,
      memo: rowCounter.memo,
      currentRow: rowCounter.currentRow,
      targetRow: rowCounter.targetRow,
      rowInstructions: (rowCounter.rowInstructions ?? []).map((instruction) =>
        this.toRowInstructionResponse(instruction),
      ),
      createdAt: rowCounter.createdAt.toISOString(),
      updatedAt: rowCounter.updatedAt.toISOString(),
      deletedAt: rowCounter.deletedAt?.toISOString() ?? null,
      syncStatus: 'Synced',
    };
  }

  private toRowInstructionResponse(
    instruction: RowInstruction,
  ): RowInstructionResponseDto {
    return {
      id: instruction.id,
      ownerId: instruction.ownerId,
      projectId: instruction.projectId,
      rowCounterId: instruction.rowCounterId,
      rowNumber: instruction.rowNumber,
      instructionText: instruction.instructionText,
      skillTags: instruction.skillTags,
      createdAt: instruction.createdAt.toISOString(),
      updatedAt: instruction.updatedAt.toISOString(),
      deletedAt: instruction.deletedAt?.toISOString() ?? null,
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

  private toProjectPatternCopyResponse(
    patternCopy: ProjectWithChildren['patternCopy'],
    ownerId: string,
  ): ProjectPatternCopyResponseDto | null {
    if (
      !patternCopy ||
      patternCopy.ownerId !== ownerId ||
      patternCopy.deletedAt !== null
    ) {
      return null;
    }

    return {
      id: patternCopy.id,
      ownerId: patternCopy.ownerId,
      projectId: patternCopy.projectId,
      sourcePatternDocumentId: patternCopy.sourcePatternDocumentId,
      titleSnapshot: patternCopy.titleSnapshot,
      designerSnapshot: patternCopy.designerSnapshot,
      fileNameSnapshot: patternCopy.fileNameSnapshot,
      localCopyPath: null,
      pageCountSnapshot: patternCopy.pageCountSnapshot,
      drawingDataPath: null,
      drawingUpdatedAt: patternCopy.drawingUpdatedAt?.toISOString() ?? null,
      copiedAt: patternCopy.copiedAt.toISOString(),
      createdAt: patternCopy.createdAt.toISOString(),
      updatedAt: patternCopy.updatedAt.toISOString(),
      deletedAt: null,
      syncStatus: 'Synced',
    };
  }

  private toProjectYarnUsageResponse(
    usage: ProjectYarnUsage,
  ): ProjectYarnUsageResponseDto {
    return {
      id: usage.id,
      ownerId: usage.ownerId,
      projectId: usage.projectId,
      projectNameSnapshot: null,
      yarnId: usage.yarnId,
      yarnNameSnapshot: usage.yarnNameSnapshot,
      quantityUsed: usage.quantityUsed,
      memo: usage.memo,
      usedAt: usage.usedAt.toISOString(),
      createdAt: usage.createdAt.toISOString(),
      updatedAt: usage.updatedAt.toISOString(),
      deletedAt: usage.deletedAt?.toISOString() ?? null,
      syncStatus: 'Synced',
    };
  }

  private toProjectProgressPhotoResponse(
    photo: ProjectProgressPhoto,
  ): ProjectProgressPhotoResponseDto {
    return {
      id: photo.id,
      ownerId: photo.ownerId,
      projectId: photo.projectId,
      fileName: photo.fileName,
      contentType: photo.contentType,
      byteSize: photo.byteSize,
      caption: photo.caption,
      takenAt: photo.takenAt.toISOString(),
      createdAt: photo.createdAt.toISOString(),
      updatedAt: photo.updatedAt.toISOString(),
      deletedAt: photo.deletedAt?.toISOString() ?? null,
      syncStatus: 'Synced',
    };
  }

  private trimmedOrNull(value: string | null | undefined): string | null {
    const trimmed = value?.trim();
    return trimmed && trimmed.length > 0 ? trimmed : null;
  }

  private trimmedOrEmpty(value: string | null | undefined): string {
    return value?.trim() ?? '';
  }

  private trimmedOrDefault(value: string | undefined, fallback: string): string {
    const trimmed = value?.trim();
    return trimmed && trimmed.length > 0 ? trimmed : fallback;
  }

  private assertImage(file: UploadedPatternFile | undefined): asserts file is UploadedPatternFile {
    if (!file || !file.buffer || file.buffer.byteLength === 0) {
      throw new BadRequestException({
        code: 'PROJECT_PROGRESS_PHOTO_REQUIRED',
        message: 'Progress photo file is required.',
      });
    }

    if (!file.mimetype?.startsWith('image/')) {
      throw new BadRequestException({
        code: 'PROJECT_PROGRESS_PHOTO_UNSUPPORTED',
        message: 'Progress photo must be an image file.',
      });
    }
  }

  private normalizedCounterMode(value: string | null | undefined): string {
    return value === 'rowGuide' ? 'rowGuide' : 'simple';
  }
}
