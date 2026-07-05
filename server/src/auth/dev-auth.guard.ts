import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AuthenticatedRequest } from './current-user.decorator';

@Injectable()
export class DevAuthGuard implements CanActivate {
  constructor(private readonly configService: ConfigService) {}

  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest<AuthenticatedRequest>();
    const authorization = request.header('authorization');
    const token = this.extractBearerToken(authorization);
    const expectedToken =
      this.configService.get<string>('DEV_AUTH_TOKEN') ?? 'dev-token';

    if (token !== expectedToken) {
      throw new UnauthorizedException({
        code: 'UNAUTHENTICATED',
        message: 'Missing or invalid bearer token.',
        details: {},
      });
    }

    request.user = {
      id: this.configService.get<string>('DEV_AUTH_USER_ID') ?? 'dev-user',
    };

    return true;
  }

  private extractBearerToken(authorization: string | undefined): string | null {
    if (!authorization) {
      return null;
    }

    const match = authorization.match(/^Bearer (.+)$/);
    return match?.[1] ?? null;
  }
}
