import { Type } from 'class-transformer';
import {
  IsArray,
  IsBoolean,
  IsDefined,
  IsInt,
  IsISO8601,
  IsIn,
  IsOptional,
  IsString,
  IsUUID,
  Min,
  ValidateNested,
  MaxLength,
  MinLength,
} from 'class-validator';

export class SaveRowInstructionDto {
  @IsUUID()
  id!: string;

  @IsUUID()
  rowCounterId!: string;

  @IsInt()
  @Min(1)
  rowNumber!: number;

  @IsString()
  instructionText!: string;

  @IsOptional()
  @IsString()
  skillTags!: string | null;
}

export class SaveRowCounterDto {
  @IsUUID()
  id!: string;

  @IsUUID()
  projectId!: string;

  // 카운터 이름 상한 30자. 프로젝트 이름(30자)과 같은 급의 짧은 라벨이다.
  @IsString()
  @MaxLength(30)
  name!: string;

  @IsOptional()
  @IsIn(['simple', 'rowGuide'])
  mode!: string | null;

  @IsOptional()
  @IsString()
  sectionName!: string | null;

  @IsOptional()
  @IsString()
  memo!: string | null;

  @IsInt()
  @Min(0)
  currentRow!: number;

  @IsOptional()
  @IsInt()
  @Min(0)
  targetRow!: number | null;

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => SaveRowInstructionDto)
  rowInstructions!: SaveRowInstructionDto[] | undefined;
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

  // 세션 메모 상한 500자(프로젝트 memo와 동일한 메모류 상한).
  @IsOptional()
  @IsString()
  @MaxLength(500)
  memo!: string | null;
}

export class SaveProjectYarnUsageDto {
  @IsOptional()
  @IsUUID()
  id!: string | undefined;

  @IsOptional()
  @IsUUID()
  yarnId!: string | null;

  @IsOptional()
  @IsString()
  yarnNameSnapshot!: string | null;

  @IsInt()
  @Min(1)
  quantityUsed!: number;

  @IsOptional()
  @IsString()
  memo!: string | null;

  @IsOptional()
  @IsISO8601()
  usedAt!: string | null;
}

export class SaveProjectProgressPhotoDto {
  @IsOptional()
  @IsString()
  caption!: string | null;

  @IsOptional()
  @IsISO8601()
  takenAt!: string | null;
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

  // 이름은 1~30자 (SPEC-PROJ-01). 클라이언트 폼과 서버 두 층에서 막는다.
  @IsString()
  @MinLength(1)
  @MaxLength(30)
  name!: string;

  @IsString()
  status!: string;

  @IsBoolean()
  isFavorite!: boolean;

  // 프로젝트 메모 상한 500자.
  @IsString()
  @MaxLength(500)
  memo!: string;

  @IsISO8601()
  startDate!: string;

  @IsOptional()
  @IsISO8601()
  targetDate!: string | null;

  @IsOptional()
  @IsISO8601()
  finishedAt!: string | null;

  @IsOptional()
  @IsISO8601()
  lastWorkedAt!: string | null;

  @IsOptional()
  @IsUUID()
  yarnId!: string | null;

  @IsOptional()
  @IsString()
  yarnNameSnapshot!: string | null;

  @IsOptional()
  @IsString()
  yarnBrandSnapshot!: string | null;

  @IsOptional()
  @IsString()
  yarnColorwaySnapshot!: string | null;

  @IsOptional()
  @IsString()
  yarnWeightSnapshot!: string | null;

  @IsOptional()
  @IsUUID()
  needleId!: string | null;

  @IsOptional()
  @IsString()
  needleNameSnapshot!: string | null;

  @IsOptional()
  @IsString()
  needleTypeSnapshot!: string | null;

  @IsOptional()
  @IsString()
  needleSizeSnapshot!: string | null;

  @IsOptional()
  @IsString()
  needleLengthSnapshot!: string | null;

  @IsOptional()
  @IsString()
  workspaceDisplayMode!: string | null;

  @IsOptional()
  @IsString()
  workspaceSheetPosition!: string | null;

  @IsArray()
  @IsUUID('all', { each: true })
  relatedSkillIds!: string[];

  @IsDefined()
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

  // 낙관적 잠금 기준 시각. 클라이언트가 마지막으로 본 서버 updatedAt을 보내면
  // 서버 updatedAt이 그보다 뒤일 때 409(PROJECT_CONFLICT)로 거부한다.
  // 보내지 않으면 기존 last-write-wins 동작을 유지한다(하위 호환).
  @IsOptional()
  @IsISO8601()
  baseUpdatedAt?: string | null;
}
