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
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { Response } from 'express';
import {
  CurrentUser,
  CurrentUserPayload,
} from '../auth/current-user.decorator';
import { ApiAuthGuard } from '../auth/api-auth.guard';
import { ProjectResponseDto } from './project-response.dto';
import { SaveProjectDto } from './project-save.dto';
import { ProjectsService } from './projects.service';
import { UploadedPatternFile } from '../patterns/uploaded-pattern-file';

@UseGuards(ApiAuthGuard)
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

  @Post(':id/pattern-copy/drawing')
  @UseInterceptors(
    FileInterceptor('file', {
      limits: {
        fileSize: Number(process.env.DRAWING_UPLOAD_MAX_BYTES ?? 10_485_760),
      },
    }),
  )
  uploadProjectPatternCopyDrawing(
    @CurrentUser() currentUser: CurrentUserPayload,
    @Param('id') id: string,
    @UploadedFile() file?: UploadedPatternFile,
  ) {
    return this.projectsService.uploadProjectPatternCopyDrawing(
      currentUser.id,
      id,
      file,
    );
  }

  @Get(':id/pattern-copy/drawing')
  async downloadProjectPatternCopyDrawing(
    @CurrentUser() currentUser: CurrentUserPayload,
    @Param('id') id: string,
    @Res() response: Response,
  ): Promise<void> {
    const patternCopy =
      await this.projectsService.getProjectPatternCopyDrawing(
        currentUser.id,
        id,
      );
    const storageKey = patternCopy.drawingStorageKey;

    if (!storageKey) {
      response.status(404).send();
      return;
    }

    response.setHeader(
      'Content-Type',
      patternCopy.drawingContentType ?? 'application/octet-stream',
    );
    response.setHeader(
      'Content-Disposition',
      'attachment; filename="drawing.pkdrawing"',
    );
    this.projectsService.openFileReadStream(storageKey).pipe(response);
  }

  @Delete(':id/pattern-copy/drawing')
  @HttpCode(204)
  deleteProjectPatternCopyDrawing(
    @CurrentUser() currentUser: CurrentUserPayload,
    @Param('id') id: string,
  ): Promise<void> {
    return this.projectsService.deleteProjectPatternCopyDrawing(
      currentUser.id,
      id,
    );
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
