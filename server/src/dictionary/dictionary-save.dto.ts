import {
  IsOptional,
  IsString,
  IsUUID,
} from 'class-validator';

export class SaveDictionaryTermDto {
  @IsOptional()
  @IsUUID()
  id?: string;

  @IsString()
  term!: string;

  @IsOptional()
  @IsString()
  fullName?: string | null;

  @IsString()
  description!: string;

  @IsOptional()
  @IsString()
  relatedSkillAbbreviations?: string | null;
}
