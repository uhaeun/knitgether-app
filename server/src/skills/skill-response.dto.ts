export type SyncStatusDto = 'Synced';

export type SkillModel = {
  id: string;
  ownerId: string;
  name: string;
  abbreviation: string;
  description: string;
  category: string | null;
  difficulty: string | null;
  animationName: string | null;
  animationType: string | null;
  isSystem: boolean;
  steps: string[];
  animationIds: string[];
  createdAt: Date;
  updatedAt: Date;
  deletedAt: Date | null;
};

export type SkillAnimationModel = {
  id: string;
  ownerId: string;
  skillId: string | null;
  title: string;
  localAssetName: string | null;
  durationSeconds: number | null;
  createdAt: Date;
  updatedAt: Date;
  deletedAt: Date | null;
};

export type SkillResponseDto = {
  id: string;
  ownerId: string;
  name: string;
  abbreviation: string;
  description: string;
  category: string | null;
  difficulty: string | null;
  animationName: string | null;
  animationType: string | null;
  isSystem: boolean;
  userLevel: string | null;
  createdAt: string;
  updatedAt: string;
  deletedAt: string | null;
  syncStatus: SyncStatusDto;
  steps: string[];
  animationIds: string[];
};

export type SkillAnimationResponseDto = {
  id: string;
  ownerId: string;
  skillId: string | null;
  title: string;
  localAssetName: string | null;
  durationSeconds: number | null;
  createdAt: string;
  updatedAt: string;
  deletedAt: string | null;
  syncStatus: SyncStatusDto;
};

export function toSkillResponse(
  skill: SkillModel,
  userLevel: string | null = null,
): SkillResponseDto {
  return {
    id: skill.id,
    ownerId: skill.ownerId,
    name: skill.name,
    abbreviation: skill.abbreviation,
    description: skill.description,
    category: skill.category,
    difficulty: skill.difficulty,
    animationName: skill.animationName,
    animationType: skill.animationType,
    isSystem: skill.isSystem,
    userLevel,
    createdAt: skill.createdAt.toISOString(),
    updatedAt: skill.updatedAt.toISOString(),
    deletedAt: skill.deletedAt?.toISOString() ?? null,
    syncStatus: 'Synced',
    steps: skill.steps,
    animationIds: skill.animationIds,
  };
}

export function toSkillAnimationResponse(
  animation: SkillAnimationModel,
): SkillAnimationResponseDto {
  return {
    id: animation.id,
    ownerId: animation.ownerId,
    skillId: animation.skillId,
    title: animation.title,
    localAssetName: animation.localAssetName,
    durationSeconds: animation.durationSeconds,
    createdAt: animation.createdAt.toISOString(),
    updatedAt: animation.updatedAt.toISOString(),
    deletedAt: animation.deletedAt?.toISOString() ?? null,
    syncStatus: 'Synced',
  };
}
