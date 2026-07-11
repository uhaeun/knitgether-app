import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { DatabaseModule } from '../database/database.module';
import { LibraryController } from './library.controller';
import { LibraryService } from './library.service';

@Module({
  imports: [AuthModule, DatabaseModule],
  controllers: [LibraryController],
  providers: [LibraryService],
})
export class LibraryModule {}
