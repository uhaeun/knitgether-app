import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { DatabaseModule } from '../database/database.module';
import { DictionaryController } from './dictionary.controller';
import { DictionaryService } from './dictionary.service';

@Module({
  imports: [AuthModule, DatabaseModule],
  controllers: [DictionaryController],
  providers: [DictionaryService],
})
export class DictionaryModule {}
