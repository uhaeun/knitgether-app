import { Transform } from 'class-transformer';
import {
  IsInt,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
  Min,
} from 'class-validator';

export class PatternCreateFieldsDto {
  @IsOptional()
  @IsUUID()
  id?: string;

  // 도안 제목 상한 30자(수동 등록 포함).
  @IsOptional()
  @IsString()
  @MaxLength(30)
  title?: string;

  @IsOptional()
  @IsString()
  designer?: string;

  @IsOptional()
  @Transform(({ value }) => {
    if (value === undefined || value === null || value === '') {
      return undefined;
    }

    return Number(value);
  })
  @IsInt()
  @Min(1)
  pageCount?: number;

  @IsOptional()
  @IsString()
  notes?: string;
}
