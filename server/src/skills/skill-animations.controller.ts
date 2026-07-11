import { Controller, Get, UseGuards } from '@nestjs/common';
import { ApiAuthGuard } from '../auth/api-auth.guard';
import {
  CurrentUser,
  CurrentUserPayload,
} from '../auth/current-user.decorator';
import { SkillAnimationResponseDto } from './skill-response.dto';
import { SkillsService } from './skills.service';

@UseGuards(ApiAuthGuard)
@Controller('skill-animations')
export class SkillAnimationsController {
  constructor(private readonly skillsService: SkillsService) {}

  @Get()
  listSkillAnimations(
    @CurrentUser() currentUser: CurrentUserPayload,
  ): Promise<SkillAnimationResponseDto[]> {
    return this.skillsService.listSkillAnimations(currentUser.id);
  }
}
