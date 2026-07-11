import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import { PrismaService } from '../database/prisma.service';
import { SaveSkillLevelDto } from './skill-level-save.dto';
import { SaveSkillDto } from './skill-save.dto';
import {
  SkillAnimationResponseDto,
  SkillResponseDto,
  toSkillAnimationResponse,
  toSkillResponse,
} from './skill-response.dto';

@Injectable()
export class SkillsService {
  constructor(private readonly prisma: PrismaService) {}

  async listSkills(ownerId: string): Promise<SkillResponseDto[]> {
    const skills = await this.prisma.skill.findMany({
      where: {
        deletedAt: null,
        OR: [
          { isSystem: true },
          { ownerId },
        ],
      },
      orderBy: [
        { category: 'asc' },
        { name: 'asc' },
      ],
    });

    const userLevels = await this.skillLevelsBySkillId(
      ownerId,
      skills.map((skill) => skill.id),
    );

    return skills.map((skill) => toSkillResponse(skill, userLevels.get(skill.id) ?? null));
  }

  async getSkill(ownerId: string, id: string): Promise<SkillResponseDto> {
    const skill = await this.findAccessibleSkill(ownerId, id);
    const userLevel = await this.skillLevelForSkill(ownerId, id);
    return toSkillResponse(skill, userLevel);
  }

  async createSkill(
    ownerId: string,
    body: SaveSkillDto,
  ): Promise<SkillResponseDto> {
    const data = this.toSkillData(ownerId, body);

    const skill = await this.prisma.$transaction(async (transaction) => {
      await this.ensureUserProfile(transaction, ownerId);

      return transaction.skill.create({
        data: {
          id: body.id ?? randomUUID(),
          ...data,
          deletedAt: null,
        },
      });
    });

    return toSkillResponse(skill);
  }

  async updateSkill(
    ownerId: string,
    id: string,
    body: SaveSkillDto,
  ): Promise<SkillResponseDto> {
    const existingSkill = await this.findAccessibleSkill(ownerId, id);
    this.ensureEditable(existingSkill);

    const skill = await this.prisma.skill.update({
      where: { id },
      data: this.toSkillData(ownerId, body),
    });

    return toSkillResponse(skill);
  }

  async deleteSkill(ownerId: string, id: string): Promise<void> {
    const existingSkill = await this.findAccessibleSkill(ownerId, id);
    this.ensureEditable(existingSkill);

    await this.prisma.skill.update({
      where: { id },
      data: {
        deletedAt: new Date(),
      },
    });
  }

  async updateSkillLevel(
    ownerId: string,
    id: string,
    body: SaveSkillLevelDto,
  ): Promise<SkillResponseDto> {
    const skill = await this.findAccessibleSkill(ownerId, id);

    const userLevel = await this.prisma.$transaction(async (transaction) => {
      await this.ensureUserProfile(transaction, ownerId);

      return transaction.userSkillLevel.upsert({
        where: {
          ownerId_skillId: {
            ownerId,
            skillId: id,
          },
        },
        create: {
          id: randomUUID(),
          ownerId,
          skillId: id,
          level: body.level,
          deletedAt: null,
        },
        update: {
          level: body.level,
          deletedAt: null,
        },
      });
    });

    return toSkillResponse(skill, userLevel.level);
  }

  async listSkillAnimations(
    ownerId: string,
  ): Promise<SkillAnimationResponseDto[]> {
    const animations = await this.prisma.skillAnimation.findMany({
      where: {
        ownerId,
        deletedAt: null,
      },
      orderBy: {
        title: 'asc',
      },
    });

    return animations.map(toSkillAnimationResponse);
  }

  private async findAccessibleSkill(ownerId: string, id: string) {
    const skill = await this.prisma.skill.findFirst({
      where: {
        id,
        deletedAt: null,
        OR: [
          { isSystem: true },
          { ownerId },
        ],
      },
    });

    if (!skill) {
      throw new NotFoundException({
        code: 'SKILL_NOT_FOUND',
        message: 'Skill not found.',
      });
    }

    return skill;
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

  private toSkillData(ownerId: string, body: SaveSkillDto) {
    const name = body.name.trim();
    const abbreviation = body.abbreviation.trim();
    const description = body.description.trim();

    if (!name || !abbreviation) {
      throw new BadRequestException({
        code: 'VALIDATION_FAILED',
        message: 'Skill name and abbreviation are required.',
      });
    }

    return {
      ownerId,
      name,
      abbreviation,
      description,
      category: this.nullableTrimmed(body.category),
      difficulty: this.nullableTrimmed(body.difficulty),
      animationName: this.nullableTrimmed(body.animationName),
      animationType: this.nullableTrimmed(body.animationType),
      isSystem: false,
      steps: this.normalizedStrings(body.steps),
      animationIds: body.animationIds ?? [],
    };
  }

  private ensureEditable(skill: { isSystem: boolean }): void {
    if (!skill.isSystem) {
      return;
    }

    throw new ForbiddenException({
      code: 'SYSTEM_SKILL_READ_ONLY',
      message: 'System skills cannot be edited directly.',
    });
  }

  private async skillLevelsBySkillId(
    ownerId: string,
    skillIds: string[],
  ): Promise<Map<string, string>> {
    if (skillIds.length === 0) {
      return new Map();
    }

    const userLevels = await this.prisma.userSkillLevel.findMany({
      where: {
        ownerId,
        skillId: {
          in: skillIds,
        },
        deletedAt: null,
      },
    });

    return new Map(userLevels.map((level) => [level.skillId, level.level]));
  }

  private async skillLevelForSkill(
    ownerId: string,
    skillId: string,
  ): Promise<string | null> {
    return (await this.skillLevelsBySkillId(ownerId, [skillId])).get(skillId) ?? null;
  }

  private nullableTrimmed(value: string | null | undefined): string | null {
    const trimmed = value?.trim();
    return trimmed && trimmed.length > 0 ? trimmed : null;
  }

  private normalizedStrings(values: string[] | undefined): string[] {
    return (values ?? [])
      .map((value) => value.trim())
      .filter((value) => value.length > 0);
  }
}
