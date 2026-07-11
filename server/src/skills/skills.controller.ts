import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  Param,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { ApiAuthGuard } from '../auth/api-auth.guard';
import {
  CurrentUser,
  CurrentUserPayload,
} from '../auth/current-user.decorator';
import { SaveSkillLevelDto } from './skill-level-save.dto';
import { SaveSkillDto } from './skill-save.dto';
import { SkillResponseDto } from './skill-response.dto';
import { SkillsService } from './skills.service';

@UseGuards(ApiAuthGuard)
@Controller('skills')
export class SkillsController {
  constructor(private readonly skillsService: SkillsService) {}

  @Get()
  listSkills(
    @CurrentUser() currentUser: CurrentUserPayload,
  ): Promise<SkillResponseDto[]> {
    return this.skillsService.listSkills(currentUser.id);
  }

  @Get(':id')
  getSkill(
    @CurrentUser() currentUser: CurrentUserPayload,
    @Param('id') id: string,
  ): Promise<SkillResponseDto> {
    return this.skillsService.getSkill(currentUser.id, id);
  }

  @Post()
  createSkill(
    @CurrentUser() currentUser: CurrentUserPayload,
    @Body() body: SaveSkillDto,
  ): Promise<SkillResponseDto> {
    return this.skillsService.createSkill(currentUser.id, body);
  }

  @Patch(':id/level')
  updateSkillLevel(
    @CurrentUser() currentUser: CurrentUserPayload,
    @Param('id') id: string,
    @Body() body: SaveSkillLevelDto,
  ): Promise<SkillResponseDto> {
    return this.skillsService.updateSkillLevel(currentUser.id, id, body);
  }

  @Patch(':id')
  updateSkill(
    @CurrentUser() currentUser: CurrentUserPayload,
    @Param('id') id: string,
    @Body() body: SaveSkillDto,
  ): Promise<SkillResponseDto> {
    return this.skillsService.updateSkill(currentUser.id, id, body);
  }

  @Delete(':id')
  @HttpCode(204)
  deleteSkill(
    @CurrentUser() currentUser: CurrentUserPayload,
    @Param('id') id: string,
  ): Promise<void> {
    return this.skillsService.deleteSkill(currentUser.id, id);
  }
}
