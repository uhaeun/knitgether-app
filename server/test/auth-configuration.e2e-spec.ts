import { ExecutionContext, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AccessTokenService } from '../src/auth/access-token.service';
import { ApiAuthGuard } from '../src/auth/api-auth.guard';
import { AuthenticatedRequest } from '../src/auth/current-user.decorator';

describe('Auth configuration security', () => {
  it('rejects the implicit dev token in production when DEV_AUTH_TOKEN is unset', () => {
    withIsolatedAuthEnv(() => {
      const { guard } = createAuthTools({
        NODE_ENV: 'production',
      });

      expect(() => guard.canActivate(contextWithBearer('dev-token'))).toThrow(
        UnauthorizedException,
      );
    });
  });

  it('rejects the implicit dev token when NODE_ENV is unset', () => {
    withIsolatedAuthEnv(() => {
      const { guard } = createAuthTools({});

      expect(() => guard.canActivate(contextWithBearer('dev-token'))).toThrow(
        UnauthorizedException,
      );
    });
  });

  it('rejects the implicit dev token when NODE_ENV is blank', () => {
    withIsolatedAuthEnv(() => {
      const { guard } = createAuthTools({
        NODE_ENV: '',
      });

      expect(() => guard.canActivate(contextWithBearer('dev-token'))).toThrow(
        UnauthorizedException,
      );
    });
  });

  it('rejects the implicit dev token in staging when DEV_AUTH_TOKEN is unset', () => {
    withIsolatedAuthEnv(() => {
      const { guard } = createAuthTools({
        NODE_ENV: 'staging',
      });

      expect(() => guard.canActivate(contextWithBearer('dev-token'))).toThrow(
        UnauthorizedException,
      );
    });
  });

  it('fails clearly in production when AUTH_JWT_SECRET is unset', () => {
    withIsolatedAuthEnv(() => {
      const { accessTokenService } = createAuthTools({
        NODE_ENV: 'production',
      });

      expect(() =>
        accessTokenService.sign({
          userId: 'user-a',
          email: 'yuha@example.com',
        }),
      ).toThrow('AUTH_JWT_SECRET is required in production.');
    });
  });

  it('fails clearly when NODE_ENV and AUTH_JWT_SECRET are unset', () => {
    withIsolatedAuthEnv(() => {
      const { accessTokenService } = createAuthTools({});

      expect(() =>
        accessTokenService.sign({
          userId: 'user-a',
          email: 'yuha@example.com',
        }),
      ).toThrow('AUTH_JWT_SECRET is required outside development and test.');
    });
  });

  it('fails clearly when NODE_ENV is blank and AUTH_JWT_SECRET is unset', () => {
    withIsolatedAuthEnv(() => {
      const { accessTokenService } = createAuthTools({
        NODE_ENV: '',
      });

      expect(() =>
        accessTokenService.sign({
          userId: 'user-a',
          email: 'yuha@example.com',
        }),
      ).toThrow('AUTH_JWT_SECRET is required outside development and test.');
    });
  });

  it('fails clearly in staging when AUTH_JWT_SECRET is unset', () => {
    withIsolatedAuthEnv(() => {
      const { accessTokenService } = createAuthTools({
        NODE_ENV: 'staging',
      });

      expect(() =>
        accessTokenService.sign({
          userId: 'user-a',
          email: 'yuha@example.com',
        }),
      ).toThrow('AUTH_JWT_SECRET is required outside development and test.');
    });
  });

  it('signs and verifies JWTs in production when AUTH_JWT_SECRET is set', () => {
    withIsolatedAuthEnv(() => {
      const { accessTokenService } = createAuthTools({
        NODE_ENV: 'production',
        AUTH_JWT_SECRET: 'production-test-secret',
      });

      const token = accessTokenService.sign({
        userId: 'user-a',
        email: 'yuha@example.com',
      });

      expect(accessTokenService.verify(token)).toMatchObject({
        sub: 'user-a',
        email: 'yuha@example.com',
      });
    });
  });

  it('keeps the implicit dev token available in development', () => {
    withIsolatedAuthEnv(() => {
      const request = requestWithBearer('dev-token');
      const { guard } = createAuthTools({
        NODE_ENV: 'development',
      });

      expect(guard.canActivate(contextWithRequest(request))).toBe(true);
      expect(request.user).toEqual({ id: 'dev-user' });
    });
  });

  it('keeps the implicit dev token available in test', () => {
    withIsolatedAuthEnv(() => {
      const request = requestWithBearer('dev-token');
      const { guard } = createAuthTools({
        NODE_ENV: 'test',
      });

      expect(guard.canActivate(contextWithRequest(request))).toBe(true);
      expect(request.user).toEqual({ id: 'dev-user' });
    });
  });

  it('keeps the local JWT secret fallback available in development', () => {
    withIsolatedAuthEnv(() => {
      const { accessTokenService } = createAuthTools({
        NODE_ENV: 'development',
      });

      const token = accessTokenService.sign({
        userId: 'user-a',
        email: 'yuha@example.com',
      });

      expect(accessTokenService.verify(token)).toMatchObject({
        sub: 'user-a',
        email: 'yuha@example.com',
      });
    });
  });

  it('keeps the local JWT secret fallback available in test', () => {
    withIsolatedAuthEnv(() => {
      const { accessTokenService } = createAuthTools({
        NODE_ENV: 'test',
      });

      const token = accessTokenService.sign({
        userId: 'user-a',
        email: 'yuha@example.com',
      });

      expect(accessTokenService.verify(token)).toMatchObject({
        sub: 'user-a',
        email: 'yuha@example.com',
      });
    });
  });

  it('keeps configured API token mapping available in production', () => {
    withIsolatedAuthEnv(() => {
      const request = requestWithBearer('api-token');
      const { guard } = createAuthTools({
        NODE_ENV: 'production',
        KNITGETHER_API_TOKENS: 'user-a:api-token',
        AUTH_JWT_SECRET: 'production-test-secret',
      });

      expect(guard.canActivate(contextWithRequest(request))).toBe(true);
      expect(request.user).toEqual({ id: 'user-a' });
    });
  });
});

function createAuthTools(configValues: Record<string, string>) {
  const configService = new ConfigService(configValues);
  const accessTokenService = new AccessTokenService(configService);
  const guard = new ApiAuthGuard(configService, accessTokenService);

  return {
    accessTokenService,
    guard,
  };
}

function contextWithBearer(token: string): ExecutionContext {
  return contextWithRequest(requestWithBearer(token));
}

function contextWithRequest(request: AuthenticatedRequest): ExecutionContext {
  return {
    switchToHttp: () => ({
      getRequest: () => request,
    }),
  } as ExecutionContext;
}

function requestWithBearer(token: string): AuthenticatedRequest {
  return {
    header: (name: string) =>
      name.toLowerCase() === 'authorization' ? `Bearer ${token}` : undefined,
  } as AuthenticatedRequest;
}

function withIsolatedAuthEnv(run: () => void): void {
  const keys = [
    'NODE_ENV',
    'DEV_AUTH_TOKEN',
    'DEV_AUTH_USER_ID',
    'AUTH_JWT_SECRET',
    'KNITGETHER_API_TOKENS',
  ];
  const previousValues = new Map(
    keys.map((key) => [key, process.env[key]] as const),
  );

  for (const key of keys) {
    delete process.env[key];
  }

  try {
    run();
  } finally {
    for (const key of keys) {
      const value = previousValues.get(key);

      if (value === undefined) {
        delete process.env[key];
      } else {
        process.env[key] = value;
      }
    }
  }
}
