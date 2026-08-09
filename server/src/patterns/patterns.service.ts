import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { randomUUID } from 'node:crypto';
import { PrismaService } from '../database/prisma.service';
import { LocalFileStorageService } from '../storage/local-file-storage.service';
import { PatternCreateFieldsDto } from './pattern-create-fields.dto';
import { PatternResponseDto, PatternWithFile } from './pattern-response.dto';
import { PatternUpdateDto } from './pattern-update.dto';
import { UploadedPatternFile } from './uploaded-pattern-file';

@Injectable()
export class PatternsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly fileStorage: LocalFileStorageService,
  ) {}

  async listPatterns(ownerId: string): Promise<PatternResponseDto[]> {
    const patterns = await this.prisma.patternDocument.findMany({
      where: {
        ownerId,
        deletedAt: null,
      },
      include: {
        storedFile: true,
      },
      orderBy: {
        createdAt: 'desc',
      },
    });

    return patterns.map(PatternResponseDto.fromModel);
  }

  async createPattern(
    ownerId: string,
    fields: PatternCreateFieldsDto,
    file: UploadedPatternFile | undefined,
  ): Promise<PatternResponseDto> {
    // 파일 없는 생성 허용: 제목을 먼저 등록하고 파일은 attachPatternFile로 나중에 채운다.
    if (!file) {
      return this.createTitleOnlyPattern(ownerId, fields);
    }

    this.assertPdf(file);

    const patternId = fields.id ?? randomUUID();
    const fileId = randomUUID();
    const stored = await this.fileStorage.savePatternPdf({
      ownerId,
      patternId,
      fileId,
      buffer: file.buffer,
    });
    const title = this.trimmedOrDefault(
      fields.title,
      this.titleFromFileName(file.originalname),
    );

    const pattern = await this.prisma.$transaction(async (transaction) => {
      await this.ensureUserProfile(transaction, ownerId);

      return transaction.patternDocument.create({
        data: {
          id: patternId,
          title,
          designer: this.trimmedOrNull(fields.designer),
          fileName: file.originalname,
          pageCount: fields.pageCount,
          notes: fields.notes ?? '',
          deletedAt: null,
          owner: {
            connect: {
              id: ownerId,
            },
          },
          storedFile: {
            create: {
              id: fileId,
              ownerId,
              kind: 'patternPdf',
              originalFileName: file.originalname,
              contentType: 'application/pdf',
              byteSize: stored.byteSize,
              storageKey: stored.storageKey,
              deletedAt: null,
            },
          },
        },
        include: {
          storedFile: true,
        },
      });
    });

    return PatternResponseDto.fromModel(pattern);
  }

  async getPattern(ownerId: string, id: string): Promise<PatternResponseDto> {
    return PatternResponseDto.fromModel(await this.findActivePattern(ownerId, id));
  }

  async updatePattern(
    ownerId: string,
    id: string,
    body: PatternUpdateDto,
  ): Promise<PatternResponseDto> {
    await this.findActivePattern(ownerId, id);

    const data: Prisma.PatternDocumentUncheckedUpdateInput = {};

    if (body.title !== undefined) {
      data.title = body.title.trim();
    }
    if (body.designer !== undefined) {
      data.designer = this.trimmedOrNull(body.designer);
    }
    if (body.pageCount !== undefined) {
      data.pageCount = body.pageCount;
    }
    if (body.notes !== undefined) {
      data.notes = body.notes;
    }

    const pattern = await this.prisma.patternDocument.update({
      where: { id },
      data,
      include: {
        storedFile: true,
      },
    });

    return PatternResponseDto.fromModel(pattern);
  }

  async attachPatternFile(
    ownerId: string,
    id: string,
    file: UploadedPatternFile | undefined,
  ): Promise<PatternResponseDto> {
    this.assertPdf(file);

    const pattern = await this.findActivePattern(ownerId, id);

    // 파일 채우기는 파일이 없는 도안에만 허용한다. 파일 교체는 별도 판단 대상이다.
    if (pattern.storedFile && !pattern.storedFile.deletedAt) {
      throw new BadRequestException({
        code: 'VALIDATION_FAILED',
        message: 'Pattern already has a file.',
      });
    }

    const fileId = randomUUID();
    const stored = await this.fileStorage.savePatternPdf({
      ownerId,
      patternId: id,
      fileId,
      buffer: file.buffer,
    });

    const updated = await this.prisma.patternDocument.update({
      where: { id },
      data: {
        fileName: file.originalname,
        storedFile: {
          create: {
            id: fileId,
            ownerId,
            kind: 'patternPdf',
            originalFileName: file.originalname,
            contentType: 'application/pdf',
            byteSize: stored.byteSize,
            storageKey: stored.storageKey,
            deletedAt: null,
          },
        },
      },
      include: {
        storedFile: true,
      },
    });

    return PatternResponseDto.fromModel(updated);
  }

  private async createTitleOnlyPattern(
    ownerId: string,
    fields: PatternCreateFieldsDto,
  ): Promise<PatternResponseDto> {
    const title = fields.title?.trim();

    if (!title) {
      throw new BadRequestException({
        code: 'VALIDATION_FAILED',
        message: 'Title is required when no file is uploaded.',
      });
    }

    const pattern = await this.prisma.$transaction(async (transaction) => {
      await this.ensureUserProfile(transaction, ownerId);

      return transaction.patternDocument.create({
        data: {
          id: fields.id ?? randomUUID(),
          title,
          designer: this.trimmedOrNull(fields.designer),
          fileName: null,
          pageCount: fields.pageCount,
          notes: fields.notes ?? '',
          deletedAt: null,
          owner: {
            connect: {
              id: ownerId,
            },
          },
        },
        include: {
          storedFile: true,
        },
      });
    });

    return PatternResponseDto.fromModel(pattern);
  }

  async getPatternFile(ownerId: string, id: string): Promise<PatternWithFile> {
    const pattern = await this.findActivePattern(ownerId, id);

    if (!pattern.storedFile || pattern.storedFile.deletedAt) {
      throw new NotFoundException({
        code: 'PATTERN_FILE_NOT_FOUND',
        message: 'Pattern file not found.',
      });
    }

    await this.fileStorage.assertExists(pattern.storedFile.storageKey);
    return pattern;
  }

  async deletePattern(ownerId: string, id: string): Promise<void> {
    const pattern = await this.findActivePattern(ownerId, id);
    const deletedAt = new Date();

    await this.prisma.patternDocument.update({
      where: { id },
      data: {
        deletedAt,
        storedFile: pattern.storedFile
          ? {
              update: {
                deletedAt,
              },
            }
          : undefined,
      },
    });

    await this.fileStorage.remove(pattern.storedFile?.storageKey);
  }

  openFileReadStream(storageKey: string) {
    return this.fileStorage.openReadStream(storageKey);
  }

  private async findActivePattern(
    ownerId: string,
    id: string,
  ): Promise<PatternWithFile> {
    const pattern = await this.prisma.patternDocument.findFirst({
      where: {
        id,
        ownerId,
        deletedAt: null,
      },
      include: {
        storedFile: true,
      },
    });

    if (!pattern) {
      throw new NotFoundException({
        code: 'PATTERN_NOT_FOUND',
        message: 'Pattern not found.',
      });
    }

    return pattern;
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

  private assertPdf(
    file: UploadedPatternFile | undefined,
  ): asserts file is UploadedPatternFile {
    if (!file) {
      throw new BadRequestException({
        code: 'VALIDATION_FAILED',
        message: 'Pattern PDF file is required.',
      });
    }

    const extensionIsPdf = file.originalname.toLowerCase().endsWith('.pdf');
    const mimeIsPdf = file.mimetype === 'application/pdf';

    if (!extensionIsPdf || !mimeIsPdf) {
      throw new BadRequestException({
        code: 'VALIDATION_FAILED',
        message: 'Pattern upload must be a PDF file.',
      });
    }
  }

  private titleFromFileName(fileName: string): string {
    const withoutExtension = fileName.replace(/\.pdf$/i, '').trim();
    return withoutExtension || fileName;
  }

  private trimmedOrDefault(value: string | undefined, fallback: string): string {
    const trimmed = value?.trim();
    return trimmed && trimmed.length > 0 ? trimmed : fallback;
  }

  private trimmedOrNull(value: string | null | undefined): string | null {
    const trimmed = value?.trim();
    return trimmed && trimmed.length > 0 ? trimmed : null;
  }
}
