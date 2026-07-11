import { Module } from '@nestjs/common';
import { ApiAuthGuard } from './api-auth.guard';
import { DatabaseModule } from '../database/database.module';
import { AccessTokenService } from './access-token.service';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { PasswordService } from './password.service';

@Module({
  imports: [DatabaseModule],
  controllers: [AuthController],
  providers: [AccessTokenService, ApiAuthGuard, AuthService, PasswordService],
  exports: [AccessTokenService, ApiAuthGuard],
})
export class AuthModule {}
