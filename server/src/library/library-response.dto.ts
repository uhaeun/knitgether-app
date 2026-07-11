export type SyncStatusDto = 'Synced';

export type YarnModel = {
  id: string;
  ownerId: string;
  name: string;
  brand: string | null;
  colorway: string | null;
  weight: string | null;
  quantity: number;
  notes: string;
  createdAt: Date;
  updatedAt: Date;
  deletedAt: Date | null;
};

export type NeedleModel = {
  id: string;
  ownerId: string;
  name: string;
  needleType: string;
  size: string;
  length: string | null;
  notes: string;
  createdAt: Date;
  updatedAt: Date;
  deletedAt: Date | null;
};

export type ToolItemModel = {
  id: string;
  ownerId: string;
  name: string;
  type: string;
  link: string | null;
  memo: string;
  createdAt: Date;
  updatedAt: Date;
  deletedAt: Date | null;
  _count?: {
    projectLinks: number;
  };
};

export type YarnResponseDto = {
  id: string;
  ownerId: string;
  name: string;
  brand: string | null;
  colorway: string | null;
  weight: string | null;
  quantity: number;
  notes: string;
  createdAt: string;
  updatedAt: string;
  deletedAt: string | null;
  syncStatus: SyncStatusDto;
};

export type NeedleResponseDto = {
  id: string;
  ownerId: string;
  name: string;
  needleType: string;
  size: string;
  length: string | null;
  notes: string;
  createdAt: string;
  updatedAt: string;
  deletedAt: string | null;
  syncStatus: SyncStatusDto;
};

export type ToolItemResponseDto = {
  id: string;
  ownerId: string;
  name: string;
  type: string;
  link: string | null;
  memo: string;
  usageCount: number;
  createdAt: string;
  updatedAt: string;
  deletedAt: string | null;
  syncStatus: SyncStatusDto;
};

export function toYarnResponse(yarn: YarnModel): YarnResponseDto {
  return {
    id: yarn.id,
    ownerId: yarn.ownerId,
    name: yarn.name,
    brand: yarn.brand,
    colorway: yarn.colorway,
    weight: yarn.weight,
    quantity: yarn.quantity,
    notes: yarn.notes,
    createdAt: yarn.createdAt.toISOString(),
    updatedAt: yarn.updatedAt.toISOString(),
    deletedAt: yarn.deletedAt?.toISOString() ?? null,
    syncStatus: 'Synced',
  };
}

export function toNeedleResponse(needle: NeedleModel): NeedleResponseDto {
  return {
    id: needle.id,
    ownerId: needle.ownerId,
    name: needle.name,
    needleType: needle.needleType,
    size: needle.size,
    length: needle.length,
    notes: needle.notes,
    createdAt: needle.createdAt.toISOString(),
    updatedAt: needle.updatedAt.toISOString(),
    deletedAt: needle.deletedAt?.toISOString() ?? null,
    syncStatus: 'Synced',
  };
}

export function toToolItemResponse(tool: ToolItemModel): ToolItemResponseDto {
  return {
    id: tool.id,
    ownerId: tool.ownerId,
    name: tool.name,
    type: tool.type,
    link: tool.link,
    memo: tool.memo,
    usageCount: tool._count?.projectLinks ?? 0,
    createdAt: tool.createdAt.toISOString(),
    updatedAt: tool.updatedAt.toISOString(),
    deletedAt: tool.deletedAt?.toISOString() ?? null,
    syncStatus: 'Synced',
  };
}
