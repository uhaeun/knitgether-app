import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AccessTokenService } from './access-token.service';
import { AuthenticatedRequest } from './current-user.decorator';

@Injectable()
export class ApiAuthGuard implements CanActivate {
  constructor(
    private readonly configService: ConfigService,
    private readonly accessTokenService: AccessTokenService,
  ) {}

  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest<AuthenticatedRequest>();
    const token = this.extractBearerToken(request.header('authorization'));
    const userId = token ? this.userIdForToken(token) : null;

    if (!userId) {
      throw new UnauthorizedException({
        code: 'UNAUTHENTICATED',
        message: 'Missing or invalid bearer token.',
        details: {},
      });
    }

    request.user = {
      id: userId,
    };

    return true;
  }

  private userIdForToken(token: string): string | null {
    const jwtPayload = this.accessTokenService.verify(token);

    if (jwtPayload) {
      return jwtPayload.sub;
    }

    const configuredTokens = this.configService.get<string>(
      'KNITGETHER_API_TOKENS',
    );
    const mappedUserId = this.userIdFromConfiguredTokens(token, configuredTokens);

    if (mappedUserId) {
      return mappedUserId;
    }

    const devToken = this.developmentDevToken();

    if (devToken && token === devToken) {
      return this.developmentDevUserId();
    }

    return null;
  }

  private developmentDevToken(): string | null {
    if (this.isProduction()) {
      return null;
    }

    return this.configService.get<string>('DEV_AUTH_TOKEN') ?? 'dev-token';
  }

  private developmentDevUserId(): string {
    return this.configService.get<string>('DEV_AUTH_USER_ID') ?? 'dev-user';
  }

  private isProduction(): boolean {
    return this.configService.get<string>('NODE_ENV') === 'production';
  }

  private userIdFromConfiguredTokens(
    token: string,
    configuredTokens: string | undefined,
  ): string | null {
    if (!configuredTokens) {
      return null;
    }

    for (const entry of configuredTokens.split(',')) {
      const [rawUserId, rawToken] = entry.split(':');
      const userId = rawUserId?.trim();
      const candidateToken = rawToken?.trim();

      if (userId && candidateToken && candidateToken === token) {
        return userId;
      }
    }

    return null;
  }

  private extractBearerToken(authorization: string | undefined): string | null {
    if (!authorization) {
      return null;
    }

    const match = authorization.match(/^Bearer (.+)$/);
    return match?.[1] ?? null;
  }
}
