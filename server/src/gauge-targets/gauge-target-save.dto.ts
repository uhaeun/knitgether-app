import { Type } from 'class-transformer';
import {
  IsArray,
  IsBoolean,
  IsDate,
  IsIn,
  IsNumber,
  IsOptional,
  IsString,
  IsUUID,
  ValidateNested,
} from 'class-validator';

export class SaveGaugeMeasurementDto {
  @IsOptional()
  @IsUUID()
  id?: string;

  @IsString()
  @IsIn(['manual', 'photo4pt', 'marker', 'ar'])
  method!: string;

  @IsString()
  @IsIn(['before', 'after'])
  washState!: string;

  @Type(() => Number)
  @IsNumber()
  measuredWidth!: number;

  @Type(() => Number)
  @IsNumber()
  measuredHeight!: number;

  @Type(() => Number)
  @IsNumber()
  rawStitches!: number;

  @Type(() => Number)
  @IsNumber()
  rawRows!: number;

  @Type(() => Number)
  @IsNumber()
  normalizedStitches!: number;

  @Type(() => Number)
  @IsNumber()
  normalizedRows!: number;

  @Type(() => Number)
  @IsNumber()
  finalStitches!: number;

  @Type(() => Number)
  @IsNumber()
  finalRows!: number;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  autoStitches?: number;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  autoRows?: number;

  @IsOptional()
  @IsString()
  autoConfidence?: string | null;

  @IsOptional()
  @IsBoolean()
  userModified?: boolean;

  @IsOptional()
  @IsString()
  photoPath?: string | null;

  @IsOptional()
  @IsString()
  cornerCoordinates?: string | null;

  @IsOptional()
  @Type(() => Date)
  @IsDate()
  createdAt?: Date;
}

export class SaveGaugeSwatchDto {
  @IsOptional()
  @IsUUID()
  id?: string;

  @IsOptional()
  @IsBoolean()
  isSelected?: boolean;

  @IsOptional()
  @Type(() => Date)
  @IsDate()
  knittedAt?: Date | null;

  @IsOptional()
  @IsString()
  needleMaterial?: string | null;

  @IsOptional()
  @IsString()
  needleSize?: string | null;

  @IsOptional()
  @IsString()
  needleType?: string | null;

  @IsOptional()
  @IsString()
  notes?: string | null;

  @IsOptional()
  @IsString()
  stitchPattern?: string | null;

  @IsOptional()
  @IsString()
  yarnBrand?: string | null;

  @IsOptional()
  @IsString()
  yarnColor?: string | null;

  @IsOptional()
  @IsString()
  yarnLot?: string | null;

  @IsOptional()
  @IsString()
  yarnName?: string | null;

  @IsOptional()
  @Type(() => Date)
  @IsDate()
  createdAt?: Date;

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => SaveGaugeMeasurementDto)
  measurements?: SaveGaugeMeasurementDto[];
}

export class SaveGaugeTargetDto {
  @IsOptional()
  @IsUUID()
  id?: string;

  @IsString()
  name!: string;

  @Type(() => Number)
  @IsNumber()
  targetStitches!: number;

  @Type(() => Number)
  @IsNumber()
  targetWidth!: number;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  targetRows?: number;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  targetHeight?: number;

  @IsOptional()
  @IsBoolean()
  isQuickMeasure?: boolean;

  @IsOptional()
  @IsBoolean()
  gaugeAfterWash?: boolean;

  @IsOptional()
  @IsString()
  recommendedNeedle?: string | null;

  @IsOptional()
  @IsUUID()
  sourcePatternId?: string | null;

  @IsOptional()
  @Type(() => Date)
  @IsDate()
  createdAt?: Date;

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => SaveGaugeSwatchDto)
  swatches?: SaveGaugeSwatchDto[];
}
