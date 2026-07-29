import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import { PrismaService } from '../database/prisma.service';
import {
  DictionaryTermResponseDto,
  toDictionaryTermResponse,
} from './dictionary-response.dto';
import { SaveDictionaryTermDto } from './dictionary-save.dto';

@Injectable()
export class DictionaryService {
  constructor(private readonly prisma: PrismaService) {}

  async listTerms(ownerId: string): Promise<DictionaryTermResponseDto[]> {
    // 시스템 공유 용어(§23 seed)와 사용자 개인 용어를 함께 노출한다(스킬과 대칭).
    const terms = await this.prisma.dictionaryTerm.findMany({
      where: {
        deletedAt: null,
        OR: [
          { isSystem: true },
          { ownerId },
        ],
      },
      orderBy: [
        { term: 'asc' },
      ],
    });

    return terms.map(toDictionaryTermResponse);
  }

  async getTerm(
    ownerId: string,
    id: string,
  ): Promise<DictionaryTermResponseDto> {
    return toDictionaryTermResponse(await this.findAccessibleTerm(ownerId, id));
  }

  async createTerm(
    ownerId: string,
    body: SaveDictionaryTermDto,
  ): Promise<DictionaryTermResponseDto> {
    const data = this.toTermData(ownerId, body);

    const term = await this.prisma.$transaction(async (transaction) => {
      await this.ensureUserProfile(transaction, ownerId);

      return transaction.dictionaryTerm.create({
        data: {
          id: body.id ?? randomUUID(),
          ...data,
          deletedAt: null,
        },
      });
    });

    return toDictionaryTermResponse(term);
  }

  async updateTerm(
    ownerId: string,
    id: string,
    body: SaveDictionaryTermDto,
  ): Promise<DictionaryTermResponseDto> {
    const existing = await this.findAccessibleTerm(ownerId, id);
    this.ensureEditable(existing);

    const term = await this.prisma.dictionaryTerm.update({
      where: { id },
      data: this.toTermData(ownerId, body),
    });

    return toDictionaryTermResponse(term);
  }

  async deleteTerm(ownerId: string, id: string): Promise<void> {
    const existing = await this.findAccessibleTerm(ownerId, id);
    this.ensureEditable(existing);

    await this.prisma.dictionaryTerm.update({
      where: { id },
      data: {
        deletedAt: new Date(),
      },
    });
  }

  private async findAccessibleTerm(ownerId: string, id: string) {
    // 시스템 공유 용어는 모든 사용자가 조회 가능, 개인 용어는 소유자만.
    const term = await this.prisma.dictionaryTerm.findFirst({
      where: {
        id,
        deletedAt: null,
        OR: [
          { isSystem: true },
          { ownerId },
        ],
      },
    });

    if (!term) {
      throw new NotFoundException({
        code: 'DICTIONARY_TERM_NOT_FOUND',
        message: 'Dictionary term not found.',
      });
    }

    return term;
  }

  private ensureEditable(term: { isSystem: boolean }): void {
    if (!term.isSystem) {
      return;
    }

    // 시스템 공유 용어(§23 seed)는 개별 사용자가 수정·삭제할 수 없다(스킬과 대칭).
    throw new ForbiddenException({
      code: 'SYSTEM_DICTIONARY_TERM_READ_ONLY',
      message: 'System dictionary terms cannot be edited directly.',
    });
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

  private toTermData(ownerId: string, body: SaveDictionaryTermDto) {
    const term = body.term.trim();
    const description = body.description.trim();

    if (!term || !description) {
      throw new BadRequestException({
        code: 'VALIDATION_FAILED',
        message: 'Dictionary term and description are required.',
      });
    }

    return {
      ownerId,
      term,
      fullName: this.nullableTrimmed(body.fullName),
      description,
      relatedSkillAbbreviations:
        this.nullableTrimmed(body.relatedSkillAbbreviations) ?? '',
    };
  }

  private nullableTrimmed(value: string | null | undefined): string | null {
    const trimmed = value?.trim();
    return trimmed && trimmed.length > 0 ? trimmed : null;
  }
}
