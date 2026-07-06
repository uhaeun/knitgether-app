import { PatternDocument, StoredFile } from '@prisma/client';

export type PatternWithFile = PatternDocument & {
  storedFile: StoredFile | null;
};

export class PatternResponseDto {
  id!: string;
  ownerId!: string;
  title!: string;
  designer!: string | null;
  fileName!: string | null;
  localFilePath!: string | null;
  pageCount!: number | null;
  notes!: string;
  createdAt!: string;
  updatedAt!: string;
  deletedAt!: string | null;
  syncStatus!: 'Synced';

  static fromModel(pattern: PatternWithFile): PatternResponseDto {
    return {
      id: pattern.id,
      ownerId: pattern.ownerId,
      title: pattern.title,
      designer: pattern.designer,
      fileName: pattern.fileName,
      localFilePath: null,
      pageCount: pattern.pageCount,
      notes: pattern.notes,
      createdAt: pattern.createdAt.toISOString(),
      updatedAt: pattern.updatedAt.toISOString(),
      deletedAt: pattern.deletedAt?.toISOString() ?? null,
      syncStatus: 'Synced',
    };
  }
}
