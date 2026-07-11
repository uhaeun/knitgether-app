import {
  IsInt,
  IsOptional,
  IsString,
  IsUUID,
  Min,
} from 'class-validator';

export class SaveYarnDto {
  @IsOptional()
  @IsUUID()
  id?: string;

  @IsString()
  name!: string;

  @IsOptional()
  @IsString()
  brand?: string | null;

  @IsOptional()
  @IsString()
  colorway?: string | null;

  @IsOptional()
  @IsString()
  weight?: string | null;

  @IsInt()
  @Min(0)
  quantity!: number;

  @IsOptional()
  @IsString()
  notes?: string | null;
}

export class SaveNeedleDto {
  @IsOptional()
  @IsUUID()
  id?: string;

  @IsString()
  name!: string;

  @IsString()
  needleType!: string;

  @IsString()
  size!: string;

  @IsOptional()
  @IsString()
  length?: string | null;

  @IsOptional()
  @IsString()
  notes?: string | null;
}

export class SaveToolItemDto {
  @IsOptional()
  @IsUUID()
  id?: string;

  @IsString()
  name!: string;

  @IsString()
  type!: string;

  @IsOptional()
  @IsString()
  link?: string | null;

  @IsOptional()
  @IsString()
  memo?: string | null;
}
