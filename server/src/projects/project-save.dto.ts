import { Type } from 'class-transformer';
import {
  IsArray,
  IsBoolean,
  IsInt,
  IsISO8601,
  IsOptional,
  IsString,
  IsUUID,
  Min,
  ValidateNested,
} from 'class-validator';

export class SaveRowCounterDto {
  @IsUUID()
  id!: string;

  @IsUUID()
  projectId!: string;

  @IsString()
  name!: string;

  @IsInt()
  @Min(0)
  currentRow!: number;

  @IsOptional()
  @IsInt()
  @Min(0)
  targetRow!: number | null;
}

export class SaveWorkSessionDto {
  @IsUUID()
  id!: string;

  @IsUUID()
  projectId!: string;

  @IsISO8601()
  startedAt!: string;

  @IsOptional()
  @IsISO8601()
  endedAt!: string | null;

  @IsOptional()
  @IsString()
  memo!: string | null;
}

export class SaveProjectPatternCopyDto {
  @IsUUID()
  id!: string;

  @IsUUID()
  projectId!: string;

  @IsOptional()
  @IsUUID()
  sourcePatternDocumentId!: string | null;

  @IsString()
  titleSnapshot!: string;

  @IsOptional()
  @IsString()
  designerSnapshot!: string | null;

  @IsOptional()
  @IsString()
  fileNameSnapshot!: string | null;

  @IsOptional()
  @IsString()
  localCopyPath!: string | null;

  @IsOptional()
  @IsInt()
  @Min(0)
  pageCountSnapshot!: number | null;

  @IsOptional()
  @IsString()
  drawingDataPath!: string | null;

  @IsOptional()
  @IsISO8601()
  drawingUpdatedAt!: string | null;

  @IsISO8601()
  copiedAt!: string;
}

export class SaveProjectDto {
  @IsUUID()
  id!: string;

  @IsString()
  name!: string;

  @IsString()
  status!: string;

  @IsBoolean()
  isFavorite!: boolean;

  @IsString()
  memo!: string;

  @IsISO8601()
  startDate!: string;

  @IsOptional()
  @IsISO8601()
  lastWorkedAt!: string | null;

  @IsOptional()
  @IsString()
  workspaceDisplayMode!: string | null;

  @IsOptional()
  @IsString()
  workspaceSheetPosition!: string | null;

  @IsArray()
  @IsUUID('all', { each: true })
  relatedSkillIds!: string[];

  @ValidateNested()
  @Type(() => SaveRowCounterDto)
  rowCounter!: SaveRowCounterDto;

  @IsOptional()
  @ValidateNested()
  @Type(() => SaveProjectPatternCopyDto)
  patternCopy!: SaveProjectPatternCopyDto | null | undefined;

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => SaveWorkSessionDto)
  workSessions!: SaveWorkSessionDto[];
}
