import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { DatabaseModule } from '../database/database.module';
import { GaugeTargetsController } from './gauge-targets.controller';
import { GaugeTargetsService } from './gauge-targets.service';

@Module({
  imports: [AuthModule, DatabaseModule],
  controllers: [GaugeTargetsController],
  providers: [GaugeTargetsService],
})
export class GaugeTargetsModule {}
