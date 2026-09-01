import { IsString, MaxLength } from 'class-validator';

export class SaveProfileDto {
  // 표시 이름 상한 80자. 회원가입(RegisterDto)의 displayName 상한과 맞춘다.
  @IsString()
  @MaxLength(80)
  displayName!: string;

  @IsString()
  preferredUnits!: string;
}
