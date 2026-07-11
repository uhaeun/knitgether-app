export type SyncStatusDto = 'Synced';

export type UserProfileModel = {
  id: string;
  displayName: string;
  preferredUnits: string;
  createdAt: Date;
  updatedAt: Date;
  deletedAt: Date | null;
};

export type ProfileResponseDto = {
  id: string;
  ownerId: string;
  displayName: string;
  preferredUnits: string;
  createdAt: string;
  updatedAt: string;
  deletedAt: string | null;
  syncStatus: SyncStatusDto;
};

export function toProfileResponse(
  profile: UserProfileModel,
): ProfileResponseDto {
  return {
    id: profile.id,
    ownerId: profile.id,
    displayName: profile.displayName,
    preferredUnits: profile.preferredUnits,
    createdAt: profile.createdAt.toISOString(),
    updatedAt: profile.updatedAt.toISOString(),
    deletedAt: profile.deletedAt?.toISOString() ?? null,
    syncStatus: 'Synced',
  };
}
