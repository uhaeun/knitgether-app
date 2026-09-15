export type SyncStatusDto = 'Synced';

export type YarnModel = {
  id: string;
  ownerId: string;
  photoContentType?: string | null;
  photoByteSize?: number | null;
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
  photoContentType?: string | null;
  photoByteSize?: number | null;
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
  photoContentType?: string | null;
  photoByteSize?: number | null;
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
  photoContentType: string | null;
  photoByteSize: number | null;
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
  photoContentType: string | null;
  photoByteSize: number | null;
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
  photoContentType: string | null;
  photoByteSize: number | null;
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
    photoContentType: yarn.photoContentType ?? null,
    photoByteSize: yarn.photoByteSize ?? null,
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
    photoContentType: needle.photoContentType ?? null,
    photoByteSize: needle.photoByteSize ?? null,
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
    photoContentType: tool.photoContentType ?? null,
    photoByteSize: tool.photoByteSize ?? null,
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

// LINK-02 v1.4 다중 연결. 표시는 연결 시점 스냅샷을 쓴다(LINK-05).
export type ProjectYarnLinkModel = {
  id: string;
  ownerId: string;
  projectId: string;
  yarnId: string | null;
  nameSnapshot: string;
  brandSnapshot: string | null;
  colorwaySnapshot: string | null;
  weightSnapshot: string | null;
  linkedAt: Date;
  createdAt: Date;
  updatedAt: Date;
  deletedAt: Date | null;
};

export type ProjectNeedleLinkModel = {
  id: string;
  ownerId: string;
  projectId: string;
  needleId: string | null;
  nameSnapshot: string;
  typeSnapshot: string | null;
  sizeSnapshot: string | null;
  lengthSnapshot: string | null;
  linkedAt: Date;
  createdAt: Date;
  updatedAt: Date;
  deletedAt: Date | null;
};

export type ProjectYarnLinkResponseDto = {
  id: string;
  ownerId: string;
  projectId: string;
  yarnId: string | null;
  nameSnapshot: string;
  brandSnapshot: string | null;
  colorwaySnapshot: string | null;
  weightSnapshot: string | null;
  linkedAt: string;
  createdAt: string;
  updatedAt: string;
  deletedAt: string | null;
  syncStatus: SyncStatusDto;
};

export type ProjectNeedleLinkResponseDto = {
  id: string;
  ownerId: string;
  projectId: string;
  needleId: string | null;
  nameSnapshot: string;
  typeSnapshot: string | null;
  sizeSnapshot: string | null;
  lengthSnapshot: string | null;
  linkedAt: string;
  createdAt: string;
  updatedAt: string;
  deletedAt: string | null;
  syncStatus: SyncStatusDto;
};

export function toProjectYarnLinkResponse(
  link: ProjectYarnLinkModel,
): ProjectYarnLinkResponseDto {
  return {
    id: link.id,
    ownerId: link.ownerId,
    projectId: link.projectId,
    yarnId: link.yarnId,
    nameSnapshot: link.nameSnapshot,
    brandSnapshot: link.brandSnapshot,
    colorwaySnapshot: link.colorwaySnapshot,
    weightSnapshot: link.weightSnapshot,
    linkedAt: link.linkedAt.toISOString(),
    createdAt: link.createdAt.toISOString(),
    updatedAt: link.updatedAt.toISOString(),
    deletedAt: link.deletedAt?.toISOString() ?? null,
    syncStatus: 'Synced',
  };
}

export function toProjectNeedleLinkResponse(
  link: ProjectNeedleLinkModel,
): ProjectNeedleLinkResponseDto {
  return {
    id: link.id,
    ownerId: link.ownerId,
    projectId: link.projectId,
    needleId: link.needleId,
    nameSnapshot: link.nameSnapshot,
    typeSnapshot: link.typeSnapshot,
    sizeSnapshot: link.sizeSnapshot,
    lengthSnapshot: link.lengthSnapshot,
    linkedAt: link.linkedAt.toISOString(),
    createdAt: link.createdAt.toISOString(),
    updatedAt: link.updatedAt.toISOString(),
    deletedAt: link.deletedAt?.toISOString() ?? null,
    syncStatus: 'Synced',
  };
}

/// 창고 항목이 현재 연결돼 있는 프로젝트 수. 삭제 확인창의 연결 고지에 쓴다(DEF-25).
export type LinkedProjectCountResponseDto = {
  projectCount: number;
};
