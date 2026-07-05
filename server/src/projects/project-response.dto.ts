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

export type ProjectResponseDto = {
  id: string;
  ownerId: string;
  name: string;
  status: string;
  isFavorite: boolean;
  memo: string;
  startDate: string;
  lastWorkedAt: string | null;
  patternCopy: null;
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
