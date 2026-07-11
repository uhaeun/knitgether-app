import { IsString } from 'class-validator';

export class SaveProfileDto {
  @IsString()
  displayName!: string;

  @IsString()
  preferredUnits!: string;
}
