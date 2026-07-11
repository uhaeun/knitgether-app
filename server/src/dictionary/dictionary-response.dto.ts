export type SyncStatusDto = 'Synced';

export type DictionaryTermModel = {
  id: string;
  ownerId: string;
  term: string;
  fullName: string | null;
  description: string;
  relatedSkillAbbreviations: string;
  createdAt: Date;
  updatedAt: Date;
  deletedAt: Date | null;
};

export type DictionaryTermResponseDto = {
  id: string;
  ownerId: string;
  term: string;
  fullName: string | null;
  description: string;
  relatedSkillAbbreviations: string;
  createdAt: string;
  updatedAt: string;
  deletedAt: string | null;
  syncStatus: SyncStatusDto;
};

export function toDictionaryTermResponse(
  term: DictionaryTermModel,
): DictionaryTermResponseDto {
  return {
    id: term.id,
    ownerId: term.ownerId,
    term: term.term,
    fullName: term.fullName,
    description: term.description,
    relatedSkillAbbreviations: term.relatedSkillAbbreviations,
    createdAt: term.createdAt.toISOString(),
    updatedAt: term.updatedAt.toISOString(),
    deletedAt: term.deletedAt?.toISOString() ?? null,
    syncStatus: 'Synced',
  };
}
