export type SyncStatusDto = 'Synced';

export type RowCounterResponseDto = {
  id: string;
  ownerId: string;
  projectId: string;
  name: string;
  currentRow: number;
  targetRow: number | null;
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
  lastWorkedAt: string | null;
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
