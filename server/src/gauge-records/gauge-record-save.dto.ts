import { Type } from 'class-transformer';
import {
  IsDate,
  IsIn,
  IsNumber,
  IsOptional,
  IsString,
  IsUUID,
} from 'class-validator';

export class SaveGaugeRecordDto {
  @IsOptional()
  @IsUUID()
  id?: string;

  @IsOptional()
  @IsUUID()
  projectId?: string | null;

  @IsOptional()
  @IsString()
  projectNameSnapshot?: string | null;

  @IsOptional()
  @IsString()
  patternNameSnapshot?: string | null;

  @IsString()
  @IsIn(['beforeWash', 'afterWash'])
  measurementStage!: string;

  @Type(() => Number)
  @IsNumber()
  sampleWidthCm!: number;

  @Type(() => Number)
  @IsNumber()
  sampleHeightCm!: number;

  @Type(() => Number)
  @IsNumber()
  stitchCount!: number;

  @Type(() => Number)
  @IsNumber()
  rowCount!: number;

  @Type(() => Number)
  @IsNumber()
  targetWidthCm!: number;

  @Type(() => Number)
  @IsNumber()
  targetHeightCm!: number;

  @IsOptional()
  @IsString()
  needle?: string;

  @IsOptional()
  @IsString()
  memo?: string;

  @IsOptional()
  @Type(() => Date)
  @IsDate()
  measuredAt?: Date;
}
