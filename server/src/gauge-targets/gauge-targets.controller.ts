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
import { GaugeTargetResponseDto } from './gauge-target-response.dto';
import { SaveGaugeTargetDto } from './gauge-target-save.dto';
import { GaugeTargetsService } from './gauge-targets.service';

@UseGuards(ApiAuthGuard)
@Controller('gauge-targets')
export class GaugeTargetsController {
  constructor(private readonly gaugeTargetsService: GaugeTargetsService) {}

  @Get()
  listGaugeTargets(
    @CurrentUser() currentUser: CurrentUserPayload,
  ): Promise<GaugeTargetResponseDto[]> {
    return this.gaugeTargetsService.listGaugeTargets(currentUser.id);
  }

  @Get(':id')
  getGaugeTarget(
    @CurrentUser() currentUser: CurrentUserPayload,
    @Param('id') id: string,
  ): Promise<GaugeTargetResponseDto> {
    return this.gaugeTargetsService.getGaugeTarget(currentUser.id, id);
  }

  @Post()
  createGaugeTarget(
    @CurrentUser() currentUser: CurrentUserPayload,
    @Body() body: SaveGaugeTargetDto,
  ): Promise<GaugeTargetResponseDto> {
    return this.gaugeTargetsService.createGaugeTarget(currentUser.id, body);
  }

  @Patch(':id')
  updateGaugeTarget(
    @CurrentUser() currentUser: CurrentUserPayload,
    @Param('id') id: string,
    @Body() body: SaveGaugeTargetDto,
  ): Promise<GaugeTargetResponseDto> {
    return this.gaugeTargetsService.updateGaugeTarget(currentUser.id, id, body);
  }

  @Delete(':id')
  @HttpCode(204)
  deleteGaugeTarget(
    @CurrentUser() currentUser: CurrentUserPayload,
    @Param('id') id: string,
  ): Promise<void> {
    return this.gaugeTargetsService.deleteGaugeTarget(currentUser.id, id);
  }
}
