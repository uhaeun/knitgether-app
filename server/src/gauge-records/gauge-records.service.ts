import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import { PrismaService } from '../database/prisma.service';
import {
  GaugeRecordResponseDto,
  toGaugeRecordResponse,
} from './gauge-record-response.dto';
import { SaveGaugeRecordDto } from './gauge-record-save.dto';

@Injectable()
export class GaugeRecordsService {
  constructor(private readonly prisma: PrismaService) {}

  async listGaugeRecords(ownerId: string): Promise<GaugeRecordResponseDto[]> {
    const records = await this.prisma.gaugeRecord.findMany({
      where: {
        ownerId,
        deletedAt: null,
      },
      orderBy: {
        measuredAt: 'desc',
      },
    });

    return records.map(toGaugeRecordResponse);
  }

  async createGaugeRecord(
    ownerId: string,
    body: SaveGaugeRecordDto,
  ): Promise<GaugeRecordResponseDto> {
    this.assertPositiveMeasurements(body);

    const record = await this.prisma.$transaction(async (transaction) => {
      await this.ensureUserProfile(transaction, ownerId);

      return transaction.gaugeRecord.create({
        data: {
          id: body.id ?? randomUUID(),
          ownerId,
          ...this.buildGaugeRecordMutationData(body),
          deletedAt: null,
        },
      });
    });

    return toGaugeRecordResponse(record);
  }

  async updateGaugeRecord(
    ownerId: string,
    id: string,
    body: SaveGaugeRecordDto,
  ): Promise<GaugeRecordResponseDto> {
    this.assertPositiveMeasurements(body);
    await this.findActiveGaugeRecord(ownerId, id);

    const record = await this.prisma.gaugeRecord.update({
      where: { id },
      data: this.buildGaugeRecordMutationData(body),
    });

    return toGaugeRecordResponse(record);
  }

  async deleteGaugeRecord(ownerId: string, id: string): Promise<void> {
    await this.findActiveGaugeRecord(ownerId, id);

    await this.prisma.gaugeRecord.update({
      where: { id },
      data: {
        deletedAt: new Date(),
      },
    });
  }

  private async findActiveGaugeRecord(ownerId: string, id: string) {
    const record = await this.prisma.gaugeRecord.findFirst({
      where: {
        id,
        ownerId,
        deletedAt: null,
      },
    });

    if (!record) {
      throw new NotFoundException({
        code: 'GAUGE_RECORD_NOT_FOUND',
        message: 'Gauge record not found.',
      });
    }

    return record;
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

  private assertPositiveMeasurements(body: SaveGaugeRecordDto): void {
    const values = [
      body.sampleWidthCm,
      body.sampleHeightCm,
      body.stitchCount,
      body.rowCount,
      body.targetWidthCm,
      body.targetHeightCm,
    ];

    if (values.some((value) => !Number.isFinite(value) || value <= 0)) {
      throw new BadRequestException({
        code: 'VALIDATION_FAILED',
        message: 'Gauge measurements must be greater than zero.',
      });
    }
  }

  private buildGaugeRecordMutationData(body: SaveGaugeRecordDto) {
    const stitchesPerCm = body.stitchCount / body.sampleWidthCm;
    const rowsPerCm = body.rowCount / body.sampleHeightCm;

    return {
      projectId: this.nullableTrimmed(body.projectId),
      projectNameSnapshot: this.nullableTrimmed(body.projectNameSnapshot),
      patternNameSnapshot: this.nullableTrimmed(body.patternNameSnapshot),
      measurementStage: body.measurementStage,
      sampleWidthCm: body.sampleWidthCm,
      sampleHeightCm: body.sampleHeightCm,
      stitchCount: body.stitchCount,
      rowCount: body.rowCount,
      targetWidthCm: body.targetWidthCm,
      targetHeightCm: body.targetHeightCm,
      stitchesPer10Cm: stitchesPerCm * 10,
      rowsPer10Cm: rowsPerCm * 10,
      targetStitches: Math.round(stitchesPerCm * body.targetWidthCm),
      targetRows: Math.round(rowsPerCm * body.targetHeightCm),
      needle: body.needle?.trim() ?? '',
      memo: body.memo ?? '',
      measuredAt: body.measuredAt ?? new Date(),
    };
  }

  private nullableTrimmed(value: string | null | undefined): string | null {
    const trimmed = value?.trim();
    return trimmed && trimmed.length > 0 ? trimmed : null;
  }
}
