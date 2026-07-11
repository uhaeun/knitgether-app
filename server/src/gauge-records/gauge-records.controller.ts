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
import {
  CurrentUser,
  CurrentUserPayload,
} from '../auth/current-user.decorator';
import { ApiAuthGuard } from '../auth/api-auth.guard';
import { GaugeRecordResponseDto } from './gauge-record-response.dto';
import { SaveGaugeRecordDto } from './gauge-record-save.dto';
import { GaugeRecordsService } from './gauge-records.service';

@UseGuards(ApiAuthGuard)
@Controller('gauge-records')
export class GaugeRecordsController {
  constructor(private readonly gaugeRecordsService: GaugeRecordsService) {}

  @Get()
  listGaugeRecords(
    @CurrentUser() currentUser: CurrentUserPayload,
  ): Promise<GaugeRecordResponseDto[]> {
    return this.gaugeRecordsService.listGaugeRecords(currentUser.id);
  }

  @Post()
  createGaugeRecord(
    @CurrentUser() currentUser: CurrentUserPayload,
    @Body() body: SaveGaugeRecordDto,
  ): Promise<GaugeRecordResponseDto> {
    return this.gaugeRecordsService.createGaugeRecord(currentUser.id, body);
  }

  @Patch(':id')
  updateGaugeRecord(
    @CurrentUser() currentUser: CurrentUserPayload,
    @Param('id') id: string,
    @Body() body: SaveGaugeRecordDto,
  ): Promise<GaugeRecordResponseDto> {
    return this.gaugeRecordsService.updateGaugeRecord(currentUser.id, id, body);
  }

  @Delete(':id')
  @HttpCode(204)
  deleteGaugeRecord(
    @CurrentUser() currentUser: CurrentUserPayload,
    @Param('id') id: string,
  ): Promise<void> {
    return this.gaugeRecordsService.deleteGaugeRecord(currentUser.id, id);
  }
}
