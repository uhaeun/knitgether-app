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
import { DictionaryTermResponseDto } from './dictionary-response.dto';
import { SaveDictionaryTermDto } from './dictionary-save.dto';
import { DictionaryService } from './dictionary.service';

@UseGuards(ApiAuthGuard)
@Controller('dictionary-terms')
export class DictionaryController {
  constructor(private readonly dictionaryService: DictionaryService) {}

  @Get()
  listTerms(
    @CurrentUser() currentUser: CurrentUserPayload,
  ): Promise<DictionaryTermResponseDto[]> {
    return this.dictionaryService.listTerms(currentUser.id);
  }

  @Get(':id')
  getTerm(
    @CurrentUser() currentUser: CurrentUserPayload,
    @Param('id') id: string,
  ): Promise<DictionaryTermResponseDto> {
    return this.dictionaryService.getTerm(currentUser.id, id);
  }

  @Post()
  createTerm(
    @CurrentUser() currentUser: CurrentUserPayload,
    @Body() body: SaveDictionaryTermDto,
  ): Promise<DictionaryTermResponseDto> {
    return this.dictionaryService.createTerm(currentUser.id, body);
  }

  @Patch(':id')
  updateTerm(
    @CurrentUser() currentUser: CurrentUserPayload,
    @Param('id') id: string,
    @Body() body: SaveDictionaryTermDto,
  ): Promise<DictionaryTermResponseDto> {
    return this.dictionaryService.updateTerm(currentUser.id, id, body);
  }

  @Delete(':id')
  @HttpCode(204)
  deleteTerm(
    @CurrentUser() currentUser: CurrentUserPayload,
    @Param('id') id: string,
  ): Promise<void> {
    return this.dictionaryService.deleteTerm(currentUser.id, id);
  }
}
