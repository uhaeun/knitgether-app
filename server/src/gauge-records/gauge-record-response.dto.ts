export type SyncStatusDto = 'Synced';

export type GaugeRecordModel = {
  id: string;
  ownerId: string;
  projectId: string | null;
  projectNameSnapshot: string | null;
  patternNameSnapshot: string | null;
  measurementStage: string;
  sampleWidthCm: number;
  sampleHeightCm: number;
  stitchCount: number;
  rowCount: number;
  targetWidthCm: number;
  targetHeightCm: number;
  stitchesPer10Cm: number;
  rowsPer10Cm: number;
  targetStitches: number;
  targetRows: number;
  needle: string;
  memo: string;
  measuredAt: Date;
  createdAt: Date;
  updatedAt: Date;
  deletedAt: Date | null;
};

export type GaugeRecordResponseDto = {
  id: string;
  ownerId: string;
  projectId: string | null;
  projectNameSnapshot: string | null;
  patternNameSnapshot: string | null;
  measurementStage: string;
  sampleWidthCm: number;
  sampleHeightCm: number;
  stitchCount: number;
  rowCount: number;
  targetWidthCm: number;
  targetHeightCm: number;
  stitchesPer10Cm: number;
  rowsPer10Cm: number;
  targetStitches: number;
  targetRows: number;
  needle: string;
  memo: string;
  measuredAt: string;
  createdAt: string;
  updatedAt: string;
  deletedAt: string | null;
  syncStatus: SyncStatusDto;
};

export function toGaugeRecordResponse(
  record: GaugeRecordModel,
): GaugeRecordResponseDto {
  return {
    id: record.id,
    ownerId: record.ownerId,
    projectId: record.projectId,
    projectNameSnapshot: record.projectNameSnapshot,
    patternNameSnapshot: record.patternNameSnapshot,
    measurementStage: record.measurementStage,
    sampleWidthCm: record.sampleWidthCm,
    sampleHeightCm: record.sampleHeightCm,
    stitchCount: record.stitchCount,
    rowCount: record.rowCount,
    targetWidthCm: record.targetWidthCm,
    targetHeightCm: record.targetHeightCm,
    stitchesPer10Cm: record.stitchesPer10Cm,
    rowsPer10Cm: record.rowsPer10Cm,
    targetStitches: record.targetStitches,
    targetRows: record.targetRows,
    needle: record.needle,
    memo: record.memo,
    measuredAt: record.measuredAt.toISOString(),
    createdAt: record.createdAt.toISOString(),
    updatedAt: record.updatedAt.toISOString(),
    deletedAt: record.deletedAt?.toISOString() ?? null,
    syncStatus: 'Synced',
  };
}
