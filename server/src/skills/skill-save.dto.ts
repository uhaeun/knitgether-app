import {
  IsArray,
  IsOptional,
  IsString,
  IsUUID,
} from 'class-validator';

export class SaveSkillDto {
  @IsOptional()
  @IsUUID()
  id?: string;

  @IsString()
  name!: string;

  @IsString()
  abbreviation!: string;

  @IsString()
  description!: string;

  @IsOptional()
  @IsString()
  category?: string | null;

  @IsOptional()
  @IsString()
  difficulty?: string | null;

  @IsOptional()
  @IsString()
  animationName?: string | null;

  @IsOptional()
  @IsString()
  animationType?: string | null;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  steps?: string[];

  @IsOptional()
  @IsArray()
  @IsUUID('4', { each: true })
  animationIds?: string[];
}
