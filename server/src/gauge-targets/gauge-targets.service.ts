import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import { PrismaService } from '../database/prisma.service';
import {
  GaugeTargetResponseDto,
  toGaugeTargetResponse,
} from './gauge-target-response.dto';
import {
  SaveGaugeMeasurementDto,
  SaveGaugeSwatchDto,
  SaveGaugeTargetDto,
} from './gauge-target-save.dto';

@Injectable()
export class GaugeTargetsService {
  constructor(private readonly prisma: PrismaService) {}

  async listGaugeTargets(ownerId: string): Promise<GaugeTargetResponseDto[]> {
    const targets = await this.prisma.gaugeTarget.findMany({
      where: {
        ownerId,
        deletedAt: null,
      },
      include: this.gaugeTargetInclude(ownerId),
      orderBy: {
        createdAt: 'desc',
      },
    });

    return targets.map(toGaugeTargetResponse);
  }

  async getGaugeTarget(
    ownerId: string,
    id: string,
  ): Promise<GaugeTargetResponseDto> {
    const target = await this.findActiveGaugeTarget(ownerId, id);
    return toGaugeTargetResponse(target);
  }

  async createGaugeTarget(
    ownerId: string,
    body: SaveGaugeTargetDto,
  ): Promise<GaugeTargetResponseDto> {
    this.assertValidTarget(body);

    const targetId = body.id ?? randomUUID();

    await this.prisma.$transaction(async (transaction) => {
      await this.ensureUserProfile(transaction, ownerId);

      await transaction.gaugeTarget.create({
        data: this.gaugeTargetCreateData(ownerId, targetId, body),
        include: this.gaugeTargetInclude(ownerId),
      });

      for (const swatchBody of body.swatches ?? []) {
        await this.createSwatchWithMeasurements(
          transaction,
          ownerId,
          targetId,
          swatchBody,
        );
      }
    });

    const target = await this.findActiveGaugeTarget(ownerId, targetId);
    return toGaugeTargetResponse(target);
  }

  async updateGaugeTarget(
    ownerId: string,
    id: string,
    body: SaveGaugeTargetDto,
  ): Promise<GaugeTargetResponseDto> {
    this.assertValidTarget(body);
    await this.findActiveGaugeTargetForDelete(ownerId, id);

    await this.prisma.$transaction(async (transaction) => {
      await transaction.gaugeMeasurement.updateMany({
        where: {
          ownerId,
          gaugeTargetId: id,
          deletedAt: null,
        },
        data: {
          deletedAt: new Date(),
        },
      });
      await transaction.gaugeSwatch.updateMany({
        where: {
          ownerId,
          gaugeTargetId: id,
          deletedAt: null,
        },
        data: {
          deletedAt: new Date(),
        },
      });
      await transaction.gaugeTarget.update({
        where: { id },
        data: this.gaugeTargetUpdateData(body),
      });

      for (const swatchBody of body.swatches ?? []) {
        await this.saveSwatchWithMeasurements(
          transaction,
          ownerId,
          id,
          swatchBody,
        );
      }
    });

    const target = await this.findActiveGaugeTarget(ownerId, id);
    return toGaugeTargetResponse(target);
  }

  async deleteGaugeTarget(ownerId: string, id: string): Promise<void> {
    await this.findActiveGaugeTargetForDelete(ownerId, id);

    await this.prisma.$transaction(async (transaction) => {
      const now = new Date();

      await transaction.gaugeTarget.update({
        where: { id },
        data: {
          deletedAt: now,
        },
      });
      await transaction.gaugeSwatch.updateMany({
        where: {
          ownerId,
          gaugeTargetId: id,
          deletedAt: null,
        },
        data: {
          deletedAt: now,
        },
      });
      await transaction.gaugeMeasurement.updateMany({
        where: {
          ownerId,
          gaugeTargetId: id,
          deletedAt: null,
        },
        data: {
          deletedAt: now,
        },
      });
    });
  }

  private async createSwatchWithMeasurements(
    transaction: any,
    ownerId: string,
    targetId: string,
    swatchBody: SaveGaugeSwatchDto,
  ): Promise<void> {
    const swatchId = swatchBody.id ?? randomUUID();

    for (const measurementBody of swatchBody.measurements ?? []) {
      this.assertValidMeasurement(measurementBody);
    }

    await transaction.gaugeSwatch.create({
      data: this.gaugeSwatchCreateData(ownerId, targetId, swatchId, swatchBody),
    });

    const measurements = (swatchBody.measurements ?? []).map((measurement) =>
      this.gaugeMeasurementCreateData(ownerId, targetId, swatchId, measurement),
    );
    if (measurements.length > 0) {
      await transaction.gaugeMeasurement.createMany({
        data: measurements,
      });
    }
  }

  private async saveSwatchWithMeasurements(
    transaction: any,
    ownerId: string,
    targetId: string,
    swatchBody: SaveGaugeSwatchDto,
  ): Promise<void> {
    const swatchId = swatchBody.id ?? randomUUID();

    for (const measurementBody of swatchBody.measurements ?? []) {
      this.assertValidMeasurement(measurementBody);
    }

    const swatchUpdate = await transaction.gaugeSwatch.updateMany({
      where: {
        id: swatchId,
        ownerId,
        gaugeTargetId: targetId,
      },
      data: this.gaugeSwatchUpdateData(ownerId, targetId, swatchBody),
    });
    if (swatchUpdate.count === 0) {
      await transaction.gaugeSwatch.create({
        data: this.gaugeSwatchCreateData(
          ownerId,
          targetId,
          swatchId,
          swatchBody,
        ),
      });
    }

    for (const measurementBody of swatchBody.measurements ?? []) {
      const measurementCreateData = this.gaugeMeasurementCreateData(
        ownerId,
        targetId,
        swatchId,
        measurementBody,
      );

      const measurementUpdate = await transaction.gaugeMeasurement.updateMany({
        where: {
          id: measurementCreateData.id,
          ownerId,
          gaugeTargetId: targetId,
          gaugeSwatchId: swatchId,
        },
        data: this.gaugeMeasurementUpdateData(
          ownerId,
          targetId,
          swatchId,
          measurementBody,
        ),
      });
      if (measurementUpdate.count === 0) {
        await transaction.gaugeMeasurement.createMany({
          data: [measurementCreateData],
        });
      }
    }
  }

  private async findActiveGaugeTarget(ownerId: string, id: string) {
    const target = await this.prisma.gaugeTarget.findFirst({
      where: {
        id,
        ownerId,
        deletedAt: null,
      },
      include: this.gaugeTargetInclude(ownerId),
    });

    if (!target) {
      throw new NotFoundException({
        code: 'GAUGE_TARGET_NOT_FOUND',
        message: 'Gauge target not found.',
      });
    }

    return target;
  }

  private async findActiveGaugeTargetForDelete(ownerId: string, id: string) {
    const target = await this.prisma.gaugeTarget.findFirst({
      where: {
        id,
        ownerId,
        deletedAt: null,
      },
    });

    if (!target) {
      throw new NotFoundException({
        code: 'GAUGE_TARGET_NOT_FOUND',
        message: 'Gauge target not found.',
      });
    }

    return target;
  }

  private gaugeTargetInclude(ownerId: string) {
    return {
      swatches: {
        where: {
          ownerId,
          deletedAt: null,
        },
        include: {
          measurements: {
            where: {
              ownerId,
              deletedAt: null,
            },
            orderBy: {
              createdAt: 'asc' as const,
            },
          },
        },
        orderBy: {
          createdAt: 'asc' as const,
        },
      },
    };
  }

  private gaugeTargetCreateData(
    ownerId: string,
    targetId: string,
    body: SaveGaugeTargetDto,
  ) {
    return {
      id: targetId,
      ownerId,
      name: body.name.trim(),
      targetStitches: body.targetStitches,
      targetWidth: body.targetWidth,
      targetRows: body.targetRows ?? 0,
      targetHeight: body.targetHeight ?? 0,
      isQuickMeasure: body.isQuickMeasure ?? false,
      gaugeAfterWash: body.gaugeAfterWash ?? false,
      recommendedNeedle: this.nullableTrimmed(body.recommendedNeedle),
      sourcePatternId: this.nullableTrimmed(body.sourcePatternId),
      createdAt: body.createdAt,
      deletedAt: null,
    };
  }

  private gaugeTargetUpdateData(body: SaveGaugeTargetDto) {
    return {
      name: body.name.trim(),
      targetStitches: body.targetStitches,
      targetWidth: body.targetWidth,
      targetRows: body.targetRows ?? 0,
      targetHeight: body.targetHeight ?? 0,
      isQuickMeasure: body.isQuickMeasure ?? false,
      gaugeAfterWash: body.gaugeAfterWash ?? false,
      recommendedNeedle: this.nullableTrimmed(body.recommendedNeedle),
      sourcePatternId: this.nullableTrimmed(body.sourcePatternId),
    };
  }

  private gaugeSwatchCreateData(
    ownerId: string,
    targetId: string,
    swatchId: string,
    body: SaveGaugeSwatchDto,
  ) {
    return {
      id: swatchId,
      ownerId,
      gaugeTargetId: targetId,
      isSelected: body.isSelected ?? false,
      knittedAt: body.knittedAt ?? null,
      needleMaterial: this.nullableTrimmed(body.needleMaterial),
      needleSize: this.nullableTrimmed(body.needleSize),
      needleType: this.nullableTrimmed(body.needleType),
      notes: this.nullableTrimmed(body.notes),
      stitchPattern: this.nullableTrimmed(body.stitchPattern),
      yarnBrand: this.nullableTrimmed(body.yarnBrand),
      yarnColor: this.nullableTrimmed(body.yarnColor),
      yarnLot: this.nullableTrimmed(body.yarnLot),
      yarnName: this.nullableTrimmed(body.yarnName),
      createdAt: body.createdAt,
      deletedAt: null,
    };
  }

  private gaugeSwatchUpdateData(
    ownerId: string,
    targetId: string,
    body: SaveGaugeSwatchDto,
  ) {
    return {
      ownerId,
      gaugeTargetId: targetId,
      isSelected: body.isSelected ?? false,
      knittedAt: body.knittedAt ?? null,
      needleMaterial: this.nullableTrimmed(body.needleMaterial),
      needleSize: this.nullableTrimmed(body.needleSize),
      needleType: this.nullableTrimmed(body.needleType),
      notes: this.nullableTrimmed(body.notes),
      stitchPattern: this.nullableTrimmed(body.stitchPattern),
      yarnBrand: this.nullableTrimmed(body.yarnBrand),
      yarnColor: this.nullableTrimmed(body.yarnColor),
      yarnLot: this.nullableTrimmed(body.yarnLot),
      yarnName: this.nullableTrimmed(body.yarnName),
      deletedAt: null,
    };
  }

  private gaugeMeasurementCreateData(
    ownerId: string,
    targetId: string,
    swatchId: string,
    body: SaveGaugeMeasurementDto,
  ) {
    return {
      id: body.id ?? randomUUID(),
      ownerId,
      gaugeTargetId: targetId,
      gaugeSwatchId: swatchId,
      method: body.method,
      washState: body.washState,
      measuredWidth: body.measuredWidth,
      measuredHeight: body.measuredHeight,
      rawStitches: body.rawStitches,
      rawRows: body.rawRows,
      normalizedStitches: body.normalizedStitches,
      normalizedRows: body.normalizedRows,
      finalStitches: body.finalStitches,
      finalRows: body.finalRows,
      autoStitches: body.autoStitches ?? 0,
      autoRows: body.autoRows ?? 0,
      autoConfidence: this.nullableTrimmed(body.autoConfidence),
      userModified: body.userModified ?? false,
      photoPath: this.nullableTrimmed(body.photoPath),
      cornerCoordinates: this.nullableTrimmed(body.cornerCoordinates),
      createdAt: body.createdAt,
      deletedAt: null,
    };
  }

  private gaugeMeasurementUpdateData(
    ownerId: string,
    targetId: string,
    swatchId: string,
    body: SaveGaugeMeasurementDto,
  ) {
    return {
      ownerId,
      gaugeTargetId: targetId,
      gaugeSwatchId: swatchId,
      method: body.method,
      washState: body.washState,
      measuredWidth: body.measuredWidth,
      measuredHeight: body.measuredHeight,
      rawStitches: body.rawStitches,
      rawRows: body.rawRows,
      normalizedStitches: body.normalizedStitches,
      normalizedRows: body.normalizedRows,
      finalStitches: body.finalStitches,
      finalRows: body.finalRows,
      autoStitches: body.autoStitches ?? 0,
      autoRows: body.autoRows ?? 0,
      autoConfidence: this.nullableTrimmed(body.autoConfidence),
      userModified: body.userModified ?? false,
      photoPath: this.nullableTrimmed(body.photoPath),
      cornerCoordinates: this.nullableTrimmed(body.cornerCoordinates),
      deletedAt: null,
    };
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

  private assertValidTarget(body: SaveGaugeTargetDto): void {
    const name = body.name?.trim();
    if (!name) {
      throw new BadRequestException({
        code: 'VALIDATION_FAILED',
        message: 'Gauge target name is required.',
      });
    }

    if (
      !Number.isFinite(body.targetStitches) ||
      body.targetStitches <= 0 ||
      !Number.isFinite(body.targetWidth) ||
      body.targetWidth <= 0
    ) {
      throw new BadRequestException({
        code: 'VALIDATION_FAILED',
        message: 'Gauge target stitches and width must be greater than zero.',
      });
    }

    if (
      (body.targetRows ?? 0) < 0 ||
      (body.targetHeight ?? 0) < 0 ||
      ((body.targetRows ?? 0) > 0 && (body.targetHeight ?? 0) <= 0)
    ) {
      throw new BadRequestException({
        code: 'VALIDATION_FAILED',
        message: 'Gauge target row dimensions are invalid.',
      });
    }

    for (const swatch of body.swatches ?? []) {
      for (const measurement of swatch.measurements ?? []) {
        this.assertValidMeasurement(measurement);
      }
    }
  }

  private assertValidMeasurement(body: SaveGaugeMeasurementDto): void {
    const positiveValues = [
      body.measuredWidth,
      body.measuredHeight,
      body.rawStitches,
      body.normalizedStitches,
      body.finalStitches,
    ];
    const nonNegativeValues = [
      body.rawRows,
      body.normalizedRows,
      body.finalRows,
      body.autoStitches ?? 0,
      body.autoRows ?? 0,
    ];

    if (
      positiveValues.some((value) => !Number.isFinite(value) || value <= 0) ||
      nonNegativeValues.some((value) => !Number.isFinite(value) || value < 0)
    ) {
      throw new BadRequestException({
        code: 'VALIDATION_FAILED',
        message: 'Gauge measurement values are invalid.',
      });
    }
  }

  private nullableTrimmed(value: string | null | undefined): string | null {
    const trimmed = value?.trim();
    return trimmed && trimmed.length > 0 ? trimmed : null;
  }
}
