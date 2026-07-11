import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { DatabaseModule } from '../database/database.module';
import { StorageModule } from '../storage/storage.module';
import { PatternsController } from './patterns.controller';
import { PatternsService } from './patterns.service';

@Module({
  imports: [AuthModule, DatabaseModule, StorageModule],
  controllers: [PatternsController],
  providers: [PatternsService],
})
export class PatternsModule {}
