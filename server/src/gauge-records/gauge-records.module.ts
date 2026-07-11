import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { DatabaseModule } from '../database/database.module';
import { GaugeRecordsController } from './gauge-records.controller';
import { GaugeRecordsService } from './gauge-records.service';

@Module({
  imports: [AuthModule, DatabaseModule],
  controllers: [GaugeRecordsController],
  providers: [GaugeRecordsService],
})
export class GaugeRecordsModule {}
