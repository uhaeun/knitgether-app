import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { DatabaseModule } from '../database/database.module';
import { SkillAnimationsController } from './skill-animations.controller';
import { SkillsController } from './skills.controller';
import { SkillsService } from './skills.service';

@Module({
  imports: [AuthModule, DatabaseModule],
  controllers: [SkillsController, SkillAnimationsController],
  providers: [SkillsService],
})
export class SkillsModule {}
