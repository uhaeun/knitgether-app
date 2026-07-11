export type SyncStatusDto = 'Synced';

export type RowCounterResponseDto = {
  id: string;
  ownerId: string;
  projectId: string;
  name: string;
  mode: string;
  sectionName: string | null;
  memo: string | null;
  currentRow: number;
  targetRow: number | null;
  rowInstructions: RowInstructionResponseDto[];
  createdAt: string;
  updatedAt: string;
  deletedAt: string | null;
  syncStatus: SyncStatusDto;
};

export type RowInstructionResponseDto = {
  id: string;
  ownerId: string;
  projectId: string;
  rowCounterId: string;
  rowNumber: number;
  instructionText: string;
  skillTags: string;
  createdAt: string;
  updatedAt: string;
  deletedAt: string | null;
  syncStatus: SyncStatusDto;
};

export type WorkSessionResponseDto = {
  id: string;
  ownerId: string;
  projectId: string;
  startedAt: string;
  endedAt: string | null;
  memo: string | null;
  createdAt: string;
  updatedAt: string;
  deletedAt: string | null;
  syncStatus: SyncStatusDto;
};

export type ProjectYarnUsageResponseDto = {
  id: string;
  ownerId: string;
  projectId: string;
  projectNameSnapshot: string | null;
  yarnId: string | null;
  yarnNameSnapshot: string;
  quantityUsed: number;
  memo: string;
  usedAt: string;
  createdAt: string;
  updatedAt: string;
  deletedAt: string | null;
  syncStatus: SyncStatusDto;
};

export type ProjectProgressPhotoResponseDto = {
  id: string;
  ownerId: string;
  projectId: string;
  fileName: string;
  contentType: string;
  byteSize: number;
  caption: string;
  takenAt: string;
  createdAt: string;
  updatedAt: string;
  deletedAt: string | null;
  syncStatus: SyncStatusDto;
};

export type ProjectPatternCopyResponseDto = {
  id: string;
  ownerId: string;
  projectId: string;
  sourcePatternDocumentId: string | null;
  titleSnapshot: string;
  designerSnapshot: string | null;
  fileNameSnapshot: string | null;
  localCopyPath: string | null;
  pageCountSnapshot: number | null;
  drawingDataPath: string | null;
  drawingUpdatedAt: string | null;
  copiedAt: string;
  createdAt: string;
  updatedAt: string;
  deletedAt: string | null;
  syncStatus: SyncStatusDto;
};

export type ProjectResponseDto = {
  id: string;
  ownerId: string;
  name: string;
  status: string;
  isFavorite: boolean;
  memo: string;
  startDate: string;
  targetDate: string | null;
  finishedAt: string | null;
  lastWorkedAt: string | null;
  yarnId: string | null;
  yarnNameSnapshot: string | null;
  yarnBrandSnapshot: string | null;
  yarnColorwaySnapshot: string | null;
  yarnWeightSnapshot: string | null;
  needleId: string | null;
  needleNameSnapshot: string | null;
  needleTypeSnapshot: string | null;
  needleSizeSnapshot: string | null;
  needleLengthSnapshot: string | null;
  patternCopy: ProjectPatternCopyResponseDto | null;
  workspaceDisplayMode: string | null;
  workspaceSheetPosition: string | null;
  rowCounter: RowCounterResponseDto;
  workSessions: WorkSessionResponseDto[];
  relatedSkillIds: string[];
  createdAt: string;
  updatedAt: string;
  deletedAt: string | null;
  syncStatus: SyncStatusDto;
};
