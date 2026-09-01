import {
  IsInt,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
  Min,
} from 'class-validator';

// 창고 항목 길이 상한: 이름과 짧은 텍스트 필드 30자, 메모류 500자.
// link는 URL이라 30자로는 실사용 주소를 담을 수 없어 메모류와 같은 500자로 잡았다.
export class SaveYarnDto {
  @IsOptional()
  @IsUUID()
  id?: string;

  @IsString()
  @MaxLength(30)
  name!: string;

  @IsOptional()
  @IsString()
  @MaxLength(30)
  brand?: string | null;

  @IsOptional()
  @IsString()
  @MaxLength(30)
  colorway?: string | null;

  @IsOptional()
  @IsString()
  @MaxLength(30)
  weight?: string | null;

  @IsInt()
  @Min(0)
  quantity!: number;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  notes?: string | null;
}

export class SaveNeedleDto {
  @IsOptional()
  @IsUUID()
  id?: string;

  @IsString()
  @MaxLength(30)
  name!: string;

  @IsString()
  @MaxLength(30)
  needleType!: string;

  @IsString()
  @MaxLength(30)
  size!: string;

  @IsOptional()
  @IsString()
  @MaxLength(30)
  length?: string | null;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  notes?: string | null;
}

export class SaveToolItemDto {
  @IsOptional()
  @IsUUID()
  id?: string;

  @IsString()
  @MaxLength(30)
  name!: string;

  @IsString()
  @MaxLength(30)
  type!: string;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  link?: string | null;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  memo?: string | null;
}
