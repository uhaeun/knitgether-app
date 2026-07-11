export type SyncStatusDto = 'Synced';

export type GaugeMeasurementModel = {
  id: string;
  ownerId: string;
  gaugeTargetId: string;
  gaugeSwatchId: string;
  method: string;
  washState: string;
  measuredWidth: number;
  measuredHeight: number;
  rawStitches: number;
  rawRows: number;
  normalizedStitches: number;
  normalizedRows: number;
  finalStitches: number;
  finalRows: number;
  autoStitches: number;
  autoRows: number;
  autoConfidence: string | null;
  userModified: boolean;
  photoPath: string | null;
  cornerCoordinates: string | null;
  createdAt: Date;
  updatedAt: Date;
  deletedAt: Date | null;
};

export type GaugeSwatchModel = {
  id: string;
  ownerId: string;
  gaugeTargetId: string;
  isSelected: boolean;
  knittedAt: Date | null;
  needleMaterial: string | null;
  needleSize: string | null;
  needleType: string | null;
  notes: string | null;
  stitchPattern: string | null;
  yarnBrand: string | null;
  yarnColor: string | null;
  yarnLot: string | null;
  yarnName: string | null;
  createdAt: Date;
  updatedAt: Date;
  deletedAt: Date | null;
  measurements?: GaugeMeasurementModel[];
};

export type GaugeTargetModel = {
  id: string;
  ownerId: string;
  name: string;
  targetStitches: number;
  targetWidth: number;
  targetRows: number;
  targetHeight: number;
  isQuickMeasure: boolean;
  gaugeAfterWash: boolean;
  recommendedNeedle: string | null;
  sourcePatternId: string | null;
  createdAt: Date;
  updatedAt: Date;
  deletedAt: Date | null;
  swatches?: GaugeSwatchModel[];
};

export type GaugeMeasurementResponseDto = Omit<
  GaugeMeasurementModel,
  'createdAt' | 'updatedAt' | 'deletedAt'
> & {
  createdAt: string;
  updatedAt: string;
  deletedAt: string | null;
  syncStatus: SyncStatusDto;
};

export type GaugeSwatchResponseDto = Omit<
  GaugeSwatchModel,
  'knittedAt' | 'createdAt' | 'updatedAt' | 'deletedAt' | 'measurements'
> & {
  knittedAt: string | null;
  createdAt: string;
  updatedAt: string;
  deletedAt: string | null;
  syncStatus: SyncStatusDto;
  measurements: GaugeMeasurementResponseDto[];
};

export type GaugeTargetResponseDto = Omit<
  GaugeTargetModel,
  'createdAt' | 'updatedAt' | 'deletedAt' | 'swatches'
> & {
  createdAt: string;
  updatedAt: string;
  deletedAt: string | null;
  syncStatus: SyncStatusDto;
  swatches: GaugeSwatchResponseDto[];
};

export function toGaugeTargetResponse(
  target: GaugeTargetModel,
): GaugeTargetResponseDto {
  return {
    id: target.id,
    ownerId: target.ownerId,
    name: target.name,
    targetStitches: target.targetStitches,
    targetWidth: target.targetWidth,
    targetRows: target.targetRows,
    targetHeight: target.targetHeight,
    isQuickMeasure: target.isQuickMeasure,
    gaugeAfterWash: target.gaugeAfterWash,
    recommendedNeedle: target.recommendedNeedle,
    sourcePatternId: target.sourcePatternId,
    createdAt: target.createdAt.toISOString(),
    updatedAt: target.updatedAt.toISOString(),
    deletedAt: target.deletedAt?.toISOString() ?? null,
    syncStatus: 'Synced',
    swatches: (target.swatches ?? []).map(toGaugeSwatchResponse),
  };
}

function toGaugeSwatchResponse(
  swatch: GaugeSwatchModel,
): GaugeSwatchResponseDto {
  return {
    id: swatch.id,
    ownerId: swatch.ownerId,
    gaugeTargetId: swatch.gaugeTargetId,
    isSelected: swatch.isSelected,
    knittedAt: swatch.knittedAt?.toISOString() ?? null,
    needleMaterial: swatch.needleMaterial,
    needleSize: swatch.needleSize,
    needleType: swatch.needleType,
    notes: swatch.notes,
    stitchPattern: swatch.stitchPattern,
    yarnBrand: swatch.yarnBrand,
    yarnColor: swatch.yarnColor,
    yarnLot: swatch.yarnLot,
    yarnName: swatch.yarnName,
    createdAt: swatch.createdAt.toISOString(),
    updatedAt: swatch.updatedAt.toISOString(),
    deletedAt: swatch.deletedAt?.toISOString() ?? null,
    syncStatus: 'Synced',
    measurements: (swatch.measurements ?? []).map(toGaugeMeasurementResponse),
  };
}

function toGaugeMeasurementResponse(
  measurement: GaugeMeasurementModel,
): GaugeMeasurementResponseDto {
  return {
    id: measurement.id,
    ownerId: measurement.ownerId,
    gaugeTargetId: measurement.gaugeTargetId,
    gaugeSwatchId: measurement.gaugeSwatchId,
    method: measurement.method,
    washState: measurement.washState,
    measuredWidth: measurement.measuredWidth,
    measuredHeight: measurement.measuredHeight,
    rawStitches: measurement.rawStitches,
    rawRows: measurement.rawRows,
    normalizedStitches: measurement.normalizedStitches,
    normalizedRows: measurement.normalizedRows,
    finalStitches: measurement.finalStitches,
    finalRows: measurement.finalRows,
    autoStitches: measurement.autoStitches,
    autoRows: measurement.autoRows,
    autoConfidence: measurement.autoConfidence,
    userModified: measurement.userModified,
    photoPath: measurement.photoPath,
    cornerCoordinates: measurement.cornerCoordinates,
    createdAt: measurement.createdAt.toISOString(),
    updatedAt: measurement.updatedAt.toISOString(),
    deletedAt: measurement.deletedAt?.toISOString() ?? null,
    syncStatus: 'Synced',
  };
}
