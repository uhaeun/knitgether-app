import { Module } from '@nestjs/common';
import { DevAuthGuard } from './dev-auth.guard';

@Module({
  providers: [DevAuthGuard],
  exports: [DevAuthGuard],
})
export class AuthModule {}
