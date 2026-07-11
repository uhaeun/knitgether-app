import {
  BadRequestException,
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
    const terms = await this.prisma.dictionaryTerm.findMany({
      where: {
        ownerId,
        deletedAt: null,
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
    return toDictionaryTermResponse(await this.findActiveTerm(ownerId, id));
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
    await this.findActiveTerm(ownerId, id);

    const term = await this.prisma.dictionaryTerm.update({
      where: { id },
      data: this.toTermData(ownerId, body),
    });

    return toDictionaryTermResponse(term);
  }

  async deleteTerm(ownerId: string, id: string): Promise<void> {
    await this.findActiveTerm(ownerId, id);

    await this.prisma.dictionaryTerm.update({
      where: { id },
      data: {
        deletedAt: new Date(),
      },
    });
  }

  private async findActiveTerm(ownerId: string, id: string) {
    const term = await this.prisma.dictionaryTerm.findFirst({
      where: {
        id,
        ownerId,
        deletedAt: null,
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
