import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  Param,
  Patch,
  Post,
  Res,
  UseGuards,
} from '@nestjs/common';
import { Response } from 'express';
import {
  CurrentUser,
  CurrentUserPayload,
} from '../auth/current-user.decorator';
import { DevAuthGuard } from '../auth/dev-auth.guard';
import { ProjectResponseDto } from './project-response.dto';
import { SaveProjectDto } from './project-save.dto';
import { ProjectsService } from './projects.service';

@UseGuards(DevAuthGuard)
@Controller('projects')
export class ProjectsController {
  constructor(private readonly projectsService: ProjectsService) {}

  @Get()
  listProjects(
    @CurrentUser() currentUser: CurrentUserPayload,
  ): Promise<ProjectResponseDto[]> {
    return this.projectsService.listProjects(currentUser.id);
  }

  @Post()
  createProject(
    @CurrentUser() currentUser: CurrentUserPayload,
    @Body() body: SaveProjectDto,
  ): Promise<ProjectResponseDto> {
    return this.projectsService.createProject(currentUser.id, body);
  }

  @Get(':id')
  getProject(
    @CurrentUser() currentUser: CurrentUserPayload,
    @Param('id') id: string,
  ): Promise<ProjectResponseDto> {
    return this.projectsService.getProject(currentUser.id, id);
  }

  @Get(':id/pattern-copy/file')
  async downloadProjectPatternCopyFile(
    @CurrentUser() currentUser: CurrentUserPayload,
    @Param('id') id: string,
    @Res() response: Response,
  ): Promise<void> {
    const patternCopy = await this.projectsService.getProjectPatternCopyFile(
      currentUser.id,
      id,
    );
    const storedFile = patternCopy.sourcePatternDocument?.storedFile;

    if (!storedFile) {
      response.status(404).send();
      return;
    }

    response.setHeader('Content-Type', 'application/pdf');
    response.setHeader(
      'Content-Disposition',
      `attachment; filename="${storedFile.originalFileName.replace(/"/g, '')}"`,
    );
    this.projectsService.openFileReadStream(storedFile.storageKey).pipe(response);
  }

  @Patch(':id')
  updateProject(
    @CurrentUser() currentUser: CurrentUserPayload,
    @Param('id') id: string,
    @Body() body: SaveProjectDto,
  ): Promise<ProjectResponseDto> {
    return this.projectsService.updateProject(currentUser.id, id, body);
  }

  @Delete(':id')
  @HttpCode(204)
  deleteProject(
    @CurrentUser() currentUser: CurrentUserPayload,
    @Param('id') id: string,
  ): Promise<void> {
    return this.projectsService.deleteProject(currentUser.id, id);
  }
}
