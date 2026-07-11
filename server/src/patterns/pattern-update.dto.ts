import { IsInt, IsOptional, IsString, Min } from 'class-validator';

export class PatternUpdateDto {
  @IsOptional()
  @IsString()
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
