import { IsIn } from 'class-validator';

export class SaveSkillLevelDto {
  @IsIn(['몰라요', '헷갈려요', '잘 알아요'])
  level!: string;
}
