import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import { PrismaService } from '../database/prisma.service';
import { ProjectYarnUsageResponseDto } from '../projects/project-response.dto';
import {
  NeedleResponseDto,
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
  constructor(private readonly prisma: PrismaService) {}

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
