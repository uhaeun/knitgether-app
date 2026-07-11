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
}
