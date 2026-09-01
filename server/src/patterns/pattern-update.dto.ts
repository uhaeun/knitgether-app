import { IsInt, IsOptional, IsString, MaxLength, Min } from 'class-validator';

export class PatternUpdateDto {
  // 도안 제목 상한 30자(수동 등록 포함).
  @IsOptional()
  @IsString()
  @MaxLength(30)
  title?: string;

  @IsOptional()
  @IsString()
  designer?: string | null;

  @IsOptional()
  @IsInt()
  @Min(1)
  pageCount?: number | null;

  @IsOptional()
  @IsString()
  notes?: string;
}
