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
import { ProjectYarnUsageResponseDto } from '../projects/project-response.dto';
import {
  NeedleResponseDto,
  ProjectNeedleLinkResponseDto,
  ProjectYarnLinkResponseDto,
  ToolItemResponseDto,
  YarnResponseDto,
} from './library-response.dto';
import { SaveNeedleDto, SaveToolItemDto, SaveYarnDto } from './library-save.dto';
import { LibraryService } from './library.service';

@UseGuards(ApiAuthGuard)
@Controller('library')
export class LibraryController {
  constructor(private readonly libraryService: LibraryService) {}

  @Get('yarns')
  listYarns(
    @CurrentUser() currentUser: CurrentUserPayload,
  ): Promise<YarnResponseDto[]> {
    return this.libraryService.listYarns(currentUser.id);
  }

  @Get('yarns/:id/usages')
  listYarnUsages(
    @CurrentUser() currentUser: CurrentUserPayload,
    @Param('id') id: string,
  ): Promise<ProjectYarnUsageResponseDto[]> {
    return this.libraryService.listYarnUsages(currentUser.id, id);
  }

  @Post('yarns')
  createYarn(
    @CurrentUser() currentUser: CurrentUserPayload,
    @Body() body: SaveYarnDto,
  ): Promise<YarnResponseDto> {
    return this.libraryService.createYarn(currentUser.id, body);
  }

  @Patch('yarns/:id')
  updateYarn(
    @CurrentUser() currentUser: CurrentUserPayload,
    @Param('id') id: string,
    @Body() body: SaveYarnDto,
  ): Promise<YarnResponseDto> {
    return this.libraryService.updateYarn(currentUser.id, id, body);
  }

  @Delete('yarns/:id')
  @HttpCode(204)
  deleteYarn(
    @CurrentUser() currentUser: CurrentUserPayload,
    @Param('id') id: string,
  ): Promise<void> {
    return this.libraryService.deleteYarn(currentUser.id, id);
  }

  @Get('needles')
  listNeedles(
    @CurrentUser() currentUser: CurrentUserPayload,
  ): Promise<NeedleResponseDto[]> {
    return this.libraryService.listNeedles(currentUser.id);
  }

  @Post('needles')
  createNeedle(
    @CurrentUser() currentUser: CurrentUserPayload,
    @Body() body: SaveNeedleDto,
  ): Promise<NeedleResponseDto> {
    return this.libraryService.createNeedle(currentUser.id, body);
  }

  @Patch('needles/:id')
  updateNeedle(
    @CurrentUser() currentUser: CurrentUserPayload,
    @Param('id') id: string,
    @Body() body: SaveNeedleDto,
  ): Promise<NeedleResponseDto> {
    return this.libraryService.updateNeedle(currentUser.id, id, body);
  }

  @Delete('needles/:id')
  @HttpCode(204)
  deleteNeedle(
    @CurrentUser() currentUser: CurrentUserPayload,
    @Param('id') id: string,
  ): Promise<void> {
    return this.libraryService.deleteNeedle(currentUser.id, id);
  }

  @Get('tools')
  listTools(
    @CurrentUser() currentUser: CurrentUserPayload,
  ): Promise<ToolItemResponseDto[]> {
    return this.libraryService.listTools(currentUser.id);
  }

  @Post('tools')
  createTool(
    @CurrentUser() currentUser: CurrentUserPayload,
    @Body() body: SaveToolItemDto,
  ): Promise<ToolItemResponseDto> {
    return this.libraryService.createTool(currentUser.id, body);
  }

  @Patch('tools/:id')
  updateTool(
    @CurrentUser() currentUser: CurrentUserPayload,
    @Param('id') id: string,
    @Body() body: SaveToolItemDto,
  ): Promise<ToolItemResponseDto> {
    return this.libraryService.updateTool(currentUser.id, id, body);
  }

  @Delete('tools/:id')
  @HttpCode(204)
  deleteTool(
    @CurrentUser() currentUser: CurrentUserPayload,
    @Param('id') id: string,
  ): Promise<void> {
    return this.libraryService.deleteTool(currentUser.id, id);
  }

  @Get('projects/:projectId/tools')
  listProjectTools(
    @CurrentUser() currentUser: CurrentUserPayload,
    @Param('projectId') projectId: string,
  ): Promise<ToolItemResponseDto[]> {
    return this.libraryService.listProjectTools(currentUser.id, projectId);
  }

  @Post('projects/:projectId/tools/:toolId')
  linkProjectTool(
    @CurrentUser() currentUser: CurrentUserPayload,
    @Param('projectId') projectId: string,
    @Param('toolId') toolId: string,
  ): Promise<ToolItemResponseDto> {
    return this.libraryService.linkToolToProject(
      currentUser.id,
      projectId,
      toolId,
    );
  }

  @Delete('projects/:projectId/tools/:toolId')
  @HttpCode(204)
  unlinkProjectTool(
    @CurrentUser() currentUser: CurrentUserPayload,
    @Param('projectId') projectId: string,
    @Param('toolId') toolId: string,
  ): Promise<void> {
    return this.libraryService.unlinkToolFromProject(
      currentUser.id,
      projectId,
      toolId,
    );
  }

  @Get('projects/:projectId/yarn-links')
  listProjectYarnLinks(
    @CurrentUser() currentUser: CurrentUserPayload,
    @Param('projectId') projectId: string,
  ): Promise<ProjectYarnLinkResponseDto[]> {
    return this.libraryService.listProjectYarnLinks(currentUser.id, projectId);
  }

  @Post('projects/:projectId/yarns/:yarnId')
  linkProjectYarn(
    @CurrentUser() currentUser: CurrentUserPayload,
    @Param('projectId') projectId: string,
    @Param('yarnId') yarnId: string,
  ): Promise<ProjectYarnLinkResponseDto> {
    return this.libraryService.linkYarnToProject(
      currentUser.id,
      projectId,
      yarnId,
    );
  }

  @Delete('projects/:projectId/yarns/:yarnId')
  @HttpCode(204)
  unlinkProjectYarn(
    @CurrentUser() currentUser: CurrentUserPayload,
    @Param('projectId') projectId: string,
    @Param('yarnId') yarnId: string,
  ): Promise<void> {
    return this.libraryService.unlinkYarnFromProject(
      currentUser.id,
      projectId,
      yarnId,
    );
  }

  @Get('projects/:projectId/needle-links')
  listProjectNeedleLinks(
    @CurrentUser() currentUser: CurrentUserPayload,
    @Param('projectId') projectId: string,
  ): Promise<ProjectNeedleLinkResponseDto[]> {
    return this.libraryService.listProjectNeedleLinks(
      currentUser.id,
      projectId,
    );
  }

  @Post('projects/:projectId/needles/:needleId')
  linkProjectNeedle(
    @CurrentUser() currentUser: CurrentUserPayload,
    @Param('projectId') projectId: string,
    @Param('needleId') needleId: string,
  ): Promise<ProjectNeedleLinkResponseDto> {
    return this.libraryService.linkNeedleToProject(
      currentUser.id,
      projectId,
      needleId,
    );
  }

  @Delete('projects/:projectId/needles/:needleId')
  @HttpCode(204)
  unlinkProjectNeedle(
    @CurrentUser() currentUser: CurrentUserPayload,
    @Param('projectId') projectId: string,
    @Param('needleId') needleId: string,
  ): Promise<void> {
    return this.libraryService.unlinkNeedleFromProject(
      currentUser.id,
      projectId,
      needleId,
    );
  }
}
