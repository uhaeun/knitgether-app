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
import { DevAuthGuard } from '../auth/dev-auth.guard';
import { PatternCreateFieldsDto } from './pattern-create-fields.dto';
import { PatternResponseDto } from './pattern-response.dto';
import { PatternUpdateDto } from './pattern-update.dto';
import { PatternsService } from './patterns.service';
import { UploadedPatternFile } from './uploaded-pattern-file';

@UseGuards(DevAuthGuard)
@Controller('patterns')
export class PatternsController {
  constructor(private readonly patternsService: PatternsService) {}

  @Get()
  listPatterns(
    @CurrentUser() currentUser: CurrentUserPayload,
  ): Promise<PatternResponseDto[]> {
    return this.patternsService.listPatterns(currentUser.id);
  }

  @Post()
  @UseInterceptors(
    FileInterceptor('file', {
      limits: {
        fileSize: Number(process.env.PATTERN_UPLOAD_MAX_BYTES ?? 52_428_800),
      },
    }),
  )
  createPattern(
    @CurrentUser() currentUser: CurrentUserPayload,
    @Body() body: PatternCreateFieldsDto,
    @UploadedFile() file?: UploadedPatternFile,
  ): Promise<PatternResponseDto> {
    return this.patternsService.createPattern(currentUser.id, body, file);
  }

  @Get(':id')
  getPattern(
    @CurrentUser() currentUser: CurrentUserPayload,
    @Param('id') id: string,
  ): Promise<PatternResponseDto> {
    return this.patternsService.getPattern(currentUser.id, id);
  }

  @Patch(':id')
  updatePattern(
    @CurrentUser() currentUser: CurrentUserPayload,
    @Param('id') id: string,
    @Body() body: PatternUpdateDto,
  ): Promise<PatternResponseDto> {
    return this.patternsService.updatePattern(currentUser.id, id, body);
  }

  @Get(':id/file')
  async downloadPatternFile(
    @CurrentUser() currentUser: CurrentUserPayload,
    @Param('id') id: string,
    @Res() response: Response,
  ): Promise<void> {
    const pattern = await this.patternsService.getPatternFile(currentUser.id, id);
    const storedFile = pattern.storedFile;

    if (!storedFile) {
      response.status(404).send();
      return;
    }

    response.setHeader('Content-Type', 'application/pdf');
    response.setHeader(
      'Content-Disposition',
      `attachment; filename="${storedFile.originalFileName.replace(/"/g, '')}"`,
    );
    this.patternsService.openFileReadStream(storedFile.storageKey).pipe(response);
  }

  @Delete(':id')
  @HttpCode(204)
  deletePattern(
    @CurrentUser() currentUser: CurrentUserPayload,
    @Param('id') id: string,
  ): Promise<void> {
    return this.patternsService.deletePattern(currentUser.id, id);
  }
}
