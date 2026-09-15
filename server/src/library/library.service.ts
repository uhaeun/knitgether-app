import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import { PrismaService } from '../database/prisma.service';
import { LocalFileStorageService } from '../storage/local-file-storage.service';
import { UploadedPatternFile } from '../patterns/uploaded-pattern-file';
import { ProjectYarnUsageResponseDto } from '../projects/project-response.dto';
import {
  NeedleResponseDto,
  LinkedProjectCountResponseDto,
  ProjectNeedleLinkResponseDto,
  ProjectYarnLinkResponseDto,
  ToolItemResponseDto,
  YarnResponseDto,
  toNeedleResponse,
  toProjectNeedleLinkResponse,
  toProjectYarnLinkResponse,
  toToolItemResponse,
  toYarnResponse,
} from './library-response.dto';
import { SaveNeedleDto, SaveToolItemDto, SaveYarnDto } from './library-save.dto';

@Injectable()
export class LibraryService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly fileStorage: LocalFileStorageService,
  ) {}

  async listYarns(ownerId: string): Promise<YarnResponseDto[]> {
    const yarns = await this.prisma.yarn.findMany({
      where: {
        ownerId,
        deletedAt: null,
      },
      orderBy: {
        name: 'asc',
      },
    });

    return yarns.map(toYarnResponse);
  }

  async createYarn(
    ownerId: string,
    body: SaveYarnDto,
  ): Promise<YarnResponseDto> {
    const data = this.toYarnData(ownerId, body);

    const yarn = await this.prisma.$transaction(async (transaction) => {
      await this.ensureUserProfile(transaction, ownerId);

      return transaction.yarn.create({
        data: {
          id: body.id ?? randomUUID(),
          ...data,
          deletedAt: null,
        },
      });
    });

    return toYarnResponse(yarn);
  }

  async updateYarn(
    ownerId: string,
    id: string,
    body: SaveYarnDto,
  ): Promise<YarnResponseDto> {
    await this.findActiveYarn(ownerId, id);

    const yarn = await this.prisma.yarn.update({
      where: { id },
      data: this.toYarnData(ownerId, body),
    });

    return toYarnResponse(yarn);
  }

  async deleteYarn(ownerId: string, id: string): Promise<void> {
    await this.findActiveYarn(ownerId, id);

    await this.prisma.yarn.update({
      where: { id },
      data: {
        deletedAt: new Date(),
      },
    });
  }

  async listYarnUsages(
    ownerId: string,
    id: string,
  ): Promise<ProjectYarnUsageResponseDto[]> {
    await this.findActiveYarn(ownerId, id);

    const usages = await this.prisma.projectYarnUsage.findMany({
      where: {
        ownerId,
        yarnId: id,
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

    return usages.map((usage) => ({
      id: usage.id,
      ownerId: usage.ownerId,
      projectId: usage.projectId,
      projectNameSnapshot: usage.project?.name ?? null,
      yarnId: usage.yarnId,
      yarnNameSnapshot: usage.yarnNameSnapshot,
      quantityUsed: usage.quantityUsed,
      memo: usage.memo,
      usedAt: usage.usedAt.toISOString(),
      createdAt: usage.createdAt.toISOString(),
      updatedAt: usage.updatedAt.toISOString(),
      deletedAt: usage.deletedAt?.toISOString() ?? null,
      syncStatus: 'Synced',
    }));
  }

  async listNeedles(ownerId: string): Promise<NeedleResponseDto[]> {
    const needles = await this.prisma.needle.findMany({
      where: {
        ownerId,
        deletedAt: null,
      },
      orderBy: {
        name: 'asc',
      },
    });

    return needles.map(toNeedleResponse);
  }

  async createNeedle(
    ownerId: string,
    body: SaveNeedleDto,
  ): Promise<NeedleResponseDto> {
    const data = this.toNeedleData(ownerId, body);

    const needle = await this.prisma.$transaction(async (transaction) => {
      await this.ensureUserProfile(transaction, ownerId);

      return transaction.needle.create({
        data: {
          id: body.id ?? randomUUID(),
          ...data,
          deletedAt: null,
        },
      });
    });

    return toNeedleResponse(needle);
  }

  async updateNeedle(
    ownerId: string,
    id: string,
    body: SaveNeedleDto,
  ): Promise<NeedleResponseDto> {
    await this.findActiveNeedle(ownerId, id);

    const needle = await this.prisma.needle.update({
      where: { id },
      data: this.toNeedleData(ownerId, body),
    });

    return toNeedleResponse(needle);
  }

  async deleteNeedle(ownerId: string, id: string): Promise<void> {
    await this.findActiveNeedle(ownerId, id);

    await this.prisma.needle.update({
      where: { id },
      data: {
        deletedAt: new Date(),
      },
    });
  }

  async listTools(ownerId: string): Promise<ToolItemResponseDto[]> {
    const tools = await this.prisma.toolItem.findMany({
      where: {
        ownerId,
        deletedAt: null,
      },
      include: {
        _count: {
          select: {
            projectLinks: {
              where: {
                deletedAt: null,
              },
            },
          },
        },
      },
      orderBy: {
        updatedAt: 'desc',
      },
    });

    return tools.map(toToolItemResponse);
  }

  async createTool(
    ownerId: string,
    body: SaveToolItemDto,
  ): Promise<ToolItemResponseDto> {
    const data = this.toToolItemData(ownerId, body);

    const tool = await this.prisma.$transaction(async (transaction) => {
      await this.ensureUserProfile(transaction, ownerId);

      return transaction.toolItem.create({
        data: {
          id: body.id ?? randomUUID(),
          ...data,
          deletedAt: null,
        },
        include: {
          _count: {
            select: {
              projectLinks: {
                where: {
                  deletedAt: null,
                },
              },
            },
          },
        },
      });
    });

    return toToolItemResponse(tool);
  }

  async updateTool(
    ownerId: string,
    id: string,
    body: SaveToolItemDto,
  ): Promise<ToolItemResponseDto> {
    await this.findActiveTool(ownerId, id);

    const tool = await this.prisma.toolItem.update({
      where: { id },
      data: this.toToolItemData(ownerId, body),
      include: {
        _count: {
          select: {
            projectLinks: {
              where: {
                deletedAt: null,
              },
            },
          },
        },
      },
    });

    return toToolItemResponse(tool);
  }

  async deleteTool(ownerId: string, id: string): Promise<void> {
    await this.findActiveTool(ownerId, id);

    await this.prisma.$transaction([
      this.prisma.projectToolLink.updateMany({
        where: {
          ownerId,
          toolId: id,
          deletedAt: null,
        },
        data: {
          deletedAt: new Date(),
        },
      }),
      this.prisma.toolItem.update({
        where: { id },
        data: {
          deletedAt: new Date(),
        },
      }),
    ]);
  }

  async listProjectTools(
    ownerId: string,
    projectId: string,
  ): Promise<ToolItemResponseDto[]> {
    await this.findActiveProject(ownerId, projectId);

    const links = await this.prisma.projectToolLink.findMany({
      where: {
        ownerId,
        projectId,
        deletedAt: null,
        tool: {
          deletedAt: null,
        },
      },
      include: {
        tool: {
          include: {
            _count: {
              select: {
                projectLinks: {
                  where: {
                    deletedAt: null,
                  },
                },
              },
            },
          },
        },
      },
      orderBy: {
        linkedAt: 'desc',
      },
    });

    return links.map((link) => toToolItemResponse(link.tool));
  }

  async linkToolToProject(
    ownerId: string,
    projectId: string,
    toolId: string,
  ): Promise<ToolItemResponseDto> {
    await this.findActiveProject(ownerId, projectId);
    const tool = await this.findActiveTool(ownerId, toolId);
    const now = new Date();

    await this.prisma.projectToolLink.upsert({
      where: {
        projectId_toolId: {
          projectId,
          toolId,
        },
      },
      create: {
        id: randomUUID(),
        ownerId,
        projectId,
        toolId,
        linkedAt: now,
        deletedAt: null,
      },
      update: {
        ownerId,
        linkedAt: now,
        deletedAt: null,
      },
    });

    const linkedTool = await this.prisma.toolItem.findUniqueOrThrow({
      where: {
        id: tool.id,
      },
      include: {
        _count: {
          select: {
            projectLinks: {
              where: {
                deletedAt: null,
              },
            },
          },
        },
      },
    });

    return toToolItemResponse(linkedTool);
  }

  async unlinkToolFromProject(
    ownerId: string,
    projectId: string,
    toolId: string,
  ): Promise<void> {
    await this.findActiveProject(ownerId, projectId);
    await this.findActiveTool(ownerId, toolId);

    await this.prisma.projectToolLink.updateMany({
      where: {
        ownerId,
        projectId,
        toolId,
        deletedAt: null,
      },
      data: {
        deletedAt: new Date(),
      },
    });
  }

  // LINK-02 v1.4: 실/바늘 다중 연결. 연결 시점 스냅샷을 링크에 저장하고,
  // 목록은 원본 생존 여부와 무관하게 링크 스냅샷을 반환한다(LINK-04/05).
  /// 창고 항목이 현재 연결된 프로젝트 수(DEF-25). 삭제 확인창의 고지에 쓴다.
  ///
  /// 삭제된 프로젝트에 걸린 링크는 세지 않는다. 세면 사용자가 찾을 수 없는 개수를
  /// 고지하게 된다. 링크 자체가 해제(deletedAt)된 것도 제외한다.
  ///
  /// 실은 사용 기록(ProjectYarnUsage)이 아니라 연결(ProjectYarnLink)을 센다. 예전에는
  /// 사용 기록 기준이었는데, 연결만 해두고 아직 쓰지 않은 실이 "사용 중 아님"으로 나와
  /// 삭제 고지 없이 지워졌다. 바늘과 도구는 고지가 아예 없었다. 셋을 연결 기준으로 맞춘다.
  async countProjectsLinkedToYarn(
    ownerId: string,
    yarnId: string,
  ): Promise<LinkedProjectCountResponseDto> {
    await this.findActiveYarn(ownerId, yarnId);

    const links = await this.prisma.projectYarnLink.findMany({
      where: {
        ownerId,
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

    return { projectCount: links.length };
  }

  async countProjectsLinkedToNeedle(
    ownerId: string,
    needleId: string,
  ): Promise<LinkedProjectCountResponseDto> {
    await this.findActiveNeedle(ownerId, needleId);

    const links = await this.prisma.projectNeedleLink.findMany({
      where: {
        ownerId,
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

    return { projectCount: links.length };
  }

  async countProjectsLinkedToTool(
    ownerId: string,
    toolId: string,
  ): Promise<LinkedProjectCountResponseDto> {
    await this.findActiveTool(ownerId, toolId);

    const links = await this.prisma.projectToolLink.findMany({
      where: {
        ownerId,
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

    return { projectCount: links.length };
  }

  async listProjectYarnLinks(
    ownerId: string,
    projectId: string,
  ): Promise<ProjectYarnLinkResponseDto[]> {
    await this.findActiveProject(ownerId, projectId);

    const links = await this.prisma.projectYarnLink.findMany({
      where: {
        ownerId,
        projectId,
        deletedAt: null,
      },
      orderBy: {
        linkedAt: 'asc',
      },
    });

    return links.map(toProjectYarnLinkResponse);
  }

  async linkYarnToProject(
    ownerId: string,
    projectId: string,
    yarnId: string,
  ): Promise<ProjectYarnLinkResponseDto> {
    await this.findActiveProject(ownerId, projectId);
    const yarn = await this.findActiveYarn(ownerId, yarnId);
    const now = new Date();
    const snapshot = {
      nameSnapshot: yarn.name,
      brandSnapshot: yarn.brand,
      colorwaySnapshot: yarn.colorway,
      weightSnapshot: yarn.weight,
    };

    const existing = await this.prisma.projectYarnLink.findFirst({
      where: {
        ownerId,
        projectId,
        yarnId,
      },
    });

    // 재연결은 연결 시점 스냅샷을 새로 찍는다(LINK-05 실측 관례와 동일).
    const link = existing
      ? await this.prisma.projectYarnLink.update({
          where: { id: existing.id },
          data: {
            ...snapshot,
            linkedAt: now,
            deletedAt: null,
          },
        })
      : await this.prisma.projectYarnLink.create({
          data: {
            id: randomUUID(),
            ownerId,
            projectId,
            yarnId,
            ...snapshot,
            linkedAt: now,
            deletedAt: null,
          },
        });

    return toProjectYarnLinkResponse(link);
  }

  async unlinkYarnFromProject(
    ownerId: string,
    projectId: string,
    yarnId: string,
  ): Promise<void> {
    await this.findActiveProject(ownerId, projectId);

    // 원본 실이 이미 삭제(tombstone)됐어도 연결 해제는 가능해야 한다.
    await this.prisma.projectYarnLink.updateMany({
      where: {
        ownerId,
        projectId,
        yarnId,
        deletedAt: null,
      },
      data: {
        deletedAt: new Date(),
      },
    });
  }

  async listProjectNeedleLinks(
    ownerId: string,
    projectId: string,
  ): Promise<ProjectNeedleLinkResponseDto[]> {
    await this.findActiveProject(ownerId, projectId);

    const links = await this.prisma.projectNeedleLink.findMany({
      where: {
        ownerId,
        projectId,
        deletedAt: null,
      },
      orderBy: {
        linkedAt: 'asc',
      },
    });

    return links.map(toProjectNeedleLinkResponse);
  }

  async linkNeedleToProject(
    ownerId: string,
    projectId: string,
    needleId: string,
  ): Promise<ProjectNeedleLinkResponseDto> {
    await this.findActiveProject(ownerId, projectId);
    const needle = await this.findActiveNeedle(ownerId, needleId);
    const now = new Date();
    const snapshot = {
      nameSnapshot: needle.name,
      typeSnapshot: needle.needleType,
      sizeSnapshot: needle.size,
      lengthSnapshot: needle.length,
    };

    const existing = await this.prisma.projectNeedleLink.findFirst({
      where: {
        ownerId,
        projectId,
        needleId,
      },
    });

    const link = existing
      ? await this.prisma.projectNeedleLink.update({
          where: { id: existing.id },
          data: {
            ...snapshot,
            linkedAt: now,
            deletedAt: null,
          },
        })
      : await this.prisma.projectNeedleLink.create({
          data: {
            id: randomUUID(),
            ownerId,
            projectId,
            needleId,
            ...snapshot,
            linkedAt: now,
            deletedAt: null,
          },
        });

    return toProjectNeedleLinkResponse(link);
  }

  async unlinkNeedleFromProject(
    ownerId: string,
    projectId: string,
    needleId: string,
  ): Promise<void> {
    await this.findActiveProject(ownerId, projectId);

    await this.prisma.projectNeedleLink.updateMany({
      where: {
        ownerId,
        projectId,
        needleId,
        deletedAt: null,
      },
      data: {
        deletedAt: new Date(),
      },
    });
  }

  // 관찰 6: 실, 바늘, 도구의 대표 사진 1장. 교체 시 이전 파일은 정리한다.
  async uploadYarnPhoto(
    ownerId: string,
    id: string,
    file: UploadedPatternFile | undefined,
  ): Promise<YarnResponseDto> {
    this.assertImage(file);
    const yarn = await this.findActiveYarn(ownerId, id);
    const stored = await this.fileStorage.saveLibraryItemPhoto({
      ownerId,
      itemKind: 'yarns',
      itemId: id,
      fileId: randomUUID(),
      fileName: file.originalname,
      buffer: file.buffer,
    });

    const updated = await this.prisma.yarn.update({
      where: { id },
      data: {
        photoStorageKey: stored.storageKey,
        photoContentType: file.mimetype,
        photoByteSize: stored.byteSize,
      },
    });

    await this.fileStorage.remove(yarn.photoStorageKey);
    return toYarnResponse(updated);
  }

  async getYarnPhotoFile(ownerId: string, id: string) {
    const yarn = await this.findActiveYarn(ownerId, id);

    if (!yarn.photoStorageKey) {
      throw new NotFoundException({
        code: 'PHOTO_NOT_FOUND',
        message: 'Photo not found.',
      });
    }

    await this.fileStorage.assertExists(yarn.photoStorageKey);
    return {
      storageKey: yarn.photoStorageKey,
      contentType: yarn.photoContentType ?? 'image/jpeg',
    };
  }

  async deleteYarnPhoto(ownerId: string, id: string): Promise<YarnResponseDto> {
    const yarn = await this.findActiveYarn(ownerId, id);
    const updated = await this.prisma.yarn.update({
      where: { id },
      data: {
        photoStorageKey: null,
        photoContentType: null,
        photoByteSize: null,
      },
    });

    await this.fileStorage.remove(yarn.photoStorageKey);
    return toYarnResponse(updated);
  }

  async uploadNeedlePhoto(
    ownerId: string,
    id: string,
    file: UploadedPatternFile | undefined,
  ): Promise<NeedleResponseDto> {
    this.assertImage(file);
    const needle = await this.findActiveNeedle(ownerId, id);
    const stored = await this.fileStorage.saveLibraryItemPhoto({
      ownerId,
      itemKind: 'needles',
      itemId: id,
      fileId: randomUUID(),
      fileName: file.originalname,
      buffer: file.buffer,
    });

    const updated = await this.prisma.needle.update({
      where: { id },
      data: {
        photoStorageKey: stored.storageKey,
        photoContentType: file.mimetype,
        photoByteSize: stored.byteSize,
      },
    });

    await this.fileStorage.remove(needle.photoStorageKey);
    return toNeedleResponse(updated);
  }

  async getNeedlePhotoFile(ownerId: string, id: string) {
    const needle = await this.findActiveNeedle(ownerId, id);

    if (!needle.photoStorageKey) {
      throw new NotFoundException({
        code: 'PHOTO_NOT_FOUND',
        message: 'Photo not found.',
      });
    }

    await this.fileStorage.assertExists(needle.photoStorageKey);
    return {
      storageKey: needle.photoStorageKey,
      contentType: needle.photoContentType ?? 'image/jpeg',
    };
  }

  async deleteNeedlePhoto(
    ownerId: string,
    id: string,
  ): Promise<NeedleResponseDto> {
    const needle = await this.findActiveNeedle(ownerId, id);
    const updated = await this.prisma.needle.update({
      where: { id },
      data: {
        photoStorageKey: null,
        photoContentType: null,
        photoByteSize: null,
      },
    });

    await this.fileStorage.remove(needle.photoStorageKey);
    return toNeedleResponse(updated);
  }

  async uploadToolPhoto(
    ownerId: string,
    id: string,
    file: UploadedPatternFile | undefined,
  ): Promise<ToolItemResponseDto> {
    this.assertImage(file);
    const tool = await this.findActiveTool(ownerId, id);
    const stored = await this.fileStorage.saveLibraryItemPhoto({
      ownerId,
      itemKind: 'tools',
      itemId: id,
      fileId: randomUUID(),
      fileName: file.originalname,
      buffer: file.buffer,
    });

    const updated = await this.prisma.toolItem.update({
      where: { id },
      data: {
        photoStorageKey: stored.storageKey,
        photoContentType: file.mimetype,
        photoByteSize: stored.byteSize,
      },
      include: {
        _count: {
          select: {
            projectLinks: {
              where: {
                deletedAt: null,
              },
            },
          },
        },
      },
    });

    await this.fileStorage.remove(tool.photoStorageKey);
    return toToolItemResponse(updated);
  }

  async getToolPhotoFile(ownerId: string, id: string) {
    const tool = await this.findActiveTool(ownerId, id);

    if (!tool.photoStorageKey) {
      throw new NotFoundException({
        code: 'PHOTO_NOT_FOUND',
        message: 'Photo not found.',
      });
    }

    await this.fileStorage.assertExists(tool.photoStorageKey);
    return {
      storageKey: tool.photoStorageKey,
      contentType: tool.photoContentType ?? 'image/jpeg',
    };
  }

  async deleteToolPhoto(
    ownerId: string,
    id: string,
  ): Promise<ToolItemResponseDto> {
    const tool = await this.findActiveTool(ownerId, id);
    const updated = await this.prisma.toolItem.update({
      where: { id },
      data: {
        photoStorageKey: null,
        photoContentType: null,
        photoByteSize: null,
      },
      include: {
        _count: {
          select: {
            projectLinks: {
              where: {
                deletedAt: null,
              },
            },
          },
        },
      },
    });

    await this.fileStorage.remove(tool.photoStorageKey);
    return toToolItemResponse(updated);
  }

  openPhotoReadStream(storageKey: string) {
    return this.fileStorage.openReadStream(storageKey);
  }

  private assertImage(
    file: UploadedPatternFile | undefined,
  ): asserts file is UploadedPatternFile {
    if (!file) {
      throw new BadRequestException({
        code: 'VALIDATION_FAILED',
        message: 'Photo file is required.',
      });
    }

    if (!file.mimetype?.startsWith('image/')) {
      throw new BadRequestException({
        code: 'VALIDATION_FAILED',
        message: 'Photo upload must be an image file.',
      });
    }
  }

  private async findActiveYarn(ownerId: string, id: string) {
    const yarn = await this.prisma.yarn.findFirst({
      where: {
        id,
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

  private async findActiveNeedle(ownerId: string, id: string) {
    const needle = await this.prisma.needle.findFirst({
      where: {
        id,
        ownerId,
        deletedAt: null,
      },
    });

    if (!needle) {
      throw new NotFoundException({
        code: 'NEEDLE_NOT_FOUND',
        message: 'Needle not found.',
      });
    }

    return needle;
  }

  private async findActiveTool(ownerId: string, id: string) {
    const tool = await this.prisma.toolItem.findFirst({
      where: {
        id,
        ownerId,
        deletedAt: null,
      },
    });

    if (!tool) {
      throw new NotFoundException({
        code: 'TOOL_NOT_FOUND',
        message: 'Tool not found.',
      });
    }

    return tool;
  }

  private async findActiveProject(ownerId: string, id: string) {
    const project = await this.prisma.project.findFirst({
      where: {
        id,
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

  private async ensureUserProfile(
    transaction: Pick<PrismaService, 'userProfile'>,
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

  private toYarnData(ownerId: string, body: SaveYarnDto) {
    const name = body.name.trim();

    if (!name) {
      throw new BadRequestException({
        code: 'VALIDATION_FAILED',
        message: 'Yarn name is required.',
      });
    }

    return {
      ownerId,
      name,
      brand: this.nullableTrimmed(body.brand),
      colorway: this.nullableTrimmed(body.colorway),
      weight: this.nullableTrimmed(body.weight),
      quantity: body.quantity,
      notes: this.trimmedOrEmpty(body.notes),
    };
  }

  private toNeedleData(ownerId: string, body: SaveNeedleDto) {
    const name = body.name.trim();
    const needleType = body.needleType.trim();
    const size = body.size.trim();

    if (!name || !needleType || !size) {
      throw new BadRequestException({
        code: 'VALIDATION_FAILED',
        message: 'Needle name, type, and size are required.',
      });
    }

    return {
      ownerId,
      name,
      needleType,
      size,
      length: this.nullableTrimmed(body.length),
      notes: this.trimmedOrEmpty(body.notes),
    };
  }

  private toToolItemData(ownerId: string, body: SaveToolItemDto) {
    const name = body.name.trim();
    const type = body.type.trim();

    if (!name || !type) {
      throw new BadRequestException({
        code: 'VALIDATION_FAILED',
        message: 'Tool name and type are required.',
      });
    }

    return {
      ownerId,
      name,
      type,
      link: this.nullableTrimmed(body.link),
      memo: this.trimmedOrEmpty(body.memo),
    };
  }

  private nullableTrimmed(value: string | null | undefined): string | null {
    const trimmed = value?.trim();
    return trimmed && trimmed.length > 0 ? trimmed : null;
  }

  private trimmedOrEmpty(value: string | null | undefined): string {
    return value?.trim() ?? '';
  }
}
