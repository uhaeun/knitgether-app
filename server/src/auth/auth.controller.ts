import { Body, Controller, Get, HttpCode, Post, UseGuards } from '@nestjs/common';
import { CurrentUser } from './current-user.decorator';
import { ApiAuthGuard } from './api-auth.guard';
import { AuthService } from './auth.service';
import { LoginDto } from './auth-login.dto';
import {
  AuthSessionResponseDto,
  AuthUserResponseDto,
} from './auth-response.dto';
import { RegisterDto } from './auth-register.dto';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('register')
  register(@Body() body: RegisterDto): Promise<AuthSessionResponseDto> {
    return this.authService.register(body);
  }

  @Post('login')
  @HttpCode(200)
  login(@Body() body: LoginDto): Promise<AuthSessionResponseDto> {
    return this.authService.login(body);
  }

  @Get('me')
  @UseGuards(ApiAuthGuard)
  me(@CurrentUser() user: { id: string }): Promise<AuthUserResponseDto> {
    return this.authService.currentUser(user.id);
  }
}
