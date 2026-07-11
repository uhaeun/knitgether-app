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
import {
  SaveRowCounterDto,
  SaveRowInstructionDto,
  SaveWorkSessionDto,
  SaveProjectDto,
  SaveProjectProgressPhotoDto,
  SaveProjectYarnUsageDto,
} from './project-save.dto';
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

  @Patch(':id/row-counter')
  updateProjectRowCounter(
    @CurrentUser() currentUser: CurrentUserPayload,
    @Param('id') id: string,
    @Body() body: SaveRowCounterDto,
  ) {
    return this.projectsService.updateProjectRowCounter(
      currentUser.id,
      id,
      body,
    );
  }

  @Post(':id/row-instructions')
  upsertProjectRowInstruction(
    @CurrentUser() currentUser: CurrentUserPayload,
    @Param('id') id: string,
    @Body() body: SaveRowInstructionDto,
  ) {
    return this.projectsService.upsertProjectRowInstruction(
      currentUser.id,
      id,
      body,
    );
  }

  @Patch(':id/row-instructions/:instructionId')
  updateProjectRowInstruction(
    @CurrentUser() currentUser: CurrentUserPayload,
    @Param('id') id: string,
    @Param('instructionId') instructionId: string,
    @Body() body: SaveRowInstructionDto,
  ) {
    return this.projectsService.upsertProjectRowInstruction(
      currentUser.id,
      id,
      body,
      instructionId,
    );
  }

  @Delete(':id/row-instructions/:instructionId')
  @HttpCode(204)
  deleteProjectRowInstruction(
    @CurrentUser() currentUser: CurrentUserPayload,
    @Param('id') id: string,
    @Param('instructionId') instructionId: string,
  ): Promise<void> {
    return this.projectsService.deleteProjectRowInstruction(
      currentUser.id,
      id,
      instructionId,
    );
  }

  @Get(':id/work-sessions')
  listProjectWorkSessions(
    @CurrentUser() currentUser: CurrentUserPayload,
    @Param('id') id: string,
  ) {
    return this.projectsService.listProjectWorkSessions(currentUser.id, id);
  }

  @Post(':id/work-sessions')
  upsertProjectWorkSession(
    @CurrentUser() currentUser: CurrentUserPayload,
    @Param('id') id: string,
    @Body() body: SaveWorkSessionDto,
  ) {
    return this.projectsService.upsertProjectWorkSession(
      currentUser.id,
      id,
      body,
    );
  }

  @Patch(':id/work-sessions/:sessionId')
  updateProjectWorkSession(
    @CurrentUser() currentUser: CurrentUserPayload,
    @Param('id') id: string,
    @Param('sessionId') sessionId: string,
    @Body() body: SaveWorkSessionDto,
  ) {
    return this.projectsService.upsertProjectWorkSession(
      currentUser.id,
      id,
      body,
      sessionId,
    );
  }

  @Delete(':id/work-sessions/:sessionId')
  @HttpCode(204)
  deleteProjectWorkSession(
    @CurrentUser() currentUser: CurrentUserPayload,
    @Param('id') id: string,
    @Param('sessionId') sessionId: string,
  ): Promise<void> {
    return this.projectsService.deleteProjectWorkSession(
      currentUser.id,
      id,
      sessionId,
    );
  }

  @Get(':id/yarn-usages')
  listProjectYarnUsages(
    @CurrentUser() currentUser: CurrentUserPayload,
    @Param('id') id: string,
  ) {
    return this.projectsService.listProjectYarnUsages(currentUser.id, id);
  }

  @Post(':id/yarn-usages')
  recordProjectYarnUsage(
    @CurrentUser() currentUser: CurrentUserPayload,
    @Param('id') id: string,
    @Body() body: SaveProjectYarnUsageDto,
  ) {
    return this.projectsService.recordProjectYarnUsage(
      currentUser.id,
      id,
      body,
    );
  }

  @Patch(':id/yarn-usages/:usageId')
  updateProjectYarnUsage(
    @CurrentUser() currentUser: CurrentUserPayload,
    @Param('id') id: string,
    @Param('usageId') usageId: string,
    @Body() body: SaveProjectYarnUsageDto,
  ) {
    return this.projectsService.updateProjectYarnUsage(
      currentUser.id,
      id,
      usageId,
      body,
    );
  }

  @Delete(':id/yarn-usages/:usageId')
  @HttpCode(204)
  deleteProjectYarnUsage(
    @CurrentUser() currentUser: CurrentUserPayload,
    @Param('id') id: string,
    @Param('usageId') usageId: string,
  ): Promise<void> {
    return this.projectsService.deleteProjectYarnUsage(
      currentUser.id,
      id,
      usageId,
    );
  }

  @Get(':id/progress-photos')
  listProjectProgressPhotos(
    @CurrentUser() currentUser: CurrentUserPayload,
    @Param('id') id: string,
  ) {
    return this.projectsService.listProjectProgressPhotos(currentUser.id, id);
  }

  @Post(':id/progress-photos')
  @UseInterceptors(
    FileInterceptor('file', {
      limits: {
        fileSize: Number(process.env.PROGRESS_PHOTO_UPLOAD_MAX_BYTES ?? 15_728_640),
      },
    }),
  )
  uploadProjectProgressPhoto(
    @CurrentUser() currentUser: CurrentUserPayload,
    @Param('id') id: string,
    @Body() body: SaveProjectProgressPhotoDto & { id?: string },
    @UploadedFile() file?: UploadedPatternFile,
  ) {
    return this.projectsService.uploadProjectProgressPhoto(
      currentUser.id,
      id,
      body,
      file,
    );
  }

  @Patch(':id/progress-photos/:photoId')
  updateProjectProgressPhoto(
    @CurrentUser() currentUser: CurrentUserPayload,
    @Param('id') id: string,
    @Param('photoId') photoId: string,
    @Body() body: SaveProjectProgressPhotoDto,
  ) {
    return this.projectsService.updateProjectProgressPhoto(
      currentUser.id,
      id,
      photoId,
      body,
    );
  }

  @Get(':id/progress-photos/:photoId/file')
  async downloadProjectProgressPhoto(
    @CurrentUser() currentUser: CurrentUserPayload,
    @Param('id') id: string,
    @Param('photoId') photoId: string,
    @Res() response: Response,
  ): Promise<void> {
    const photoFile = await this.projectsService.getProjectProgressPhotoFile(
      currentUser.id,
      id,
      photoId,
    );

    response.setHeader('Content-Type', photoFile.contentType);
    response.setHeader(
      'Content-Disposition',
      `attachment; filename="${photoFile.fileName.replace(/"/g, '')}"`,
    );
    this.projectsService.openFileReadStream(photoFile.storageKey).pipe(response);
  }

  @Delete(':id/progress-photos/:photoId')
  @HttpCode(204)
  deleteProjectProgressPhoto(
    @CurrentUser() currentUser: CurrentUserPayload,
    @Param('id') id: string,
    @Param('photoId') photoId: string,
  ): Promise<void> {
    return this.projectsService.deleteProjectProgressPhoto(
      currentUser.id,
      id,
      photoId,
    );
  }

  @Get(':id/pattern-copy/file')
  async downloadProjectPatternCopyFile(
    @CurrentUser() currentUser: CurrentUserPayload,
    @Param('id') id: string,
    @Res() response: Response,
  ): Promise<void> {
    const patternFile = await this.projectsService.getProjectPatternCopyFile(
      currentUser.id,
      id,
    );

    response.setHeader('Content-Type', patternFile.contentType);
    response.setHeader(
      'Content-Disposition',
      `attachment; filename="${patternFile.fileName.replace(/"/g, '')}"`,
    );
    this.projectsService.openFileReadStream(patternFile.storageKey).pipe(response);
  }

  @Post(':id/pattern-copy/file')
  @UseInterceptors(
    FileInterceptor('file', {
      limits: {
        fileSize: Number(process.env.PATTERN_UPLOAD_MAX_BYTES ?? 52_428_800),
      },
    }),
  )
  uploadProjectPatternCopyFile(
    @CurrentUser() currentUser: CurrentUserPayload,
    @Param('id') id: string,
    @UploadedFile() file?: UploadedPatternFile,
  ) {
    return this.projectsService.uploadProjectPatternCopyFile(
      currentUser.id,
      id,
      file,
    );
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
