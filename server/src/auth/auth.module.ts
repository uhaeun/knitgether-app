import { Module } from '@nestjs/common';
import { ApiAuthGuard } from './api-auth.guard';

@Module({
  providers: [ApiAuthGuard],
  exports: [ApiAuthGuard],
})
export class AuthModule {}
