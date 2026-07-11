import { Injectable, InternalServerErrorException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createHmac, timingSafeEqual } from 'crypto';

export type AccessTokenPayload = {
  sub: string;
  email: string;
  exp: number;
};

@Injectable()
export class AccessTokenService {
  constructor(private readonly configService: ConfigService) {}

  sign(payload: { userId: string; email: string }): string {
    const expiresInSeconds = this.expiresInSeconds();
    const tokenPayload: AccessTokenPayload = {
      sub: payload.userId,
      email: payload.email,
      exp: Math.floor(Date.now() / 1000) + expiresInSeconds,
    };

    const header = this.encodeJSON({ alg: 'HS256', typ: 'JWT' });
    const body = this.encodeJSON(tokenPayload);
    const signature = this.signSegments(header, body);

    return `${header}.${body}.${signature}`;
  }

  verify(token: string): AccessTokenPayload | null {
    const [header, body, signature] = token.split('.');

    if (!header || !body || !signature) {
      return null;
    }

    const expectedSignature = this.signSegments(header, body);

    if (!this.safeEquals(signature, expectedSignature)) {
      return null;
    }

    const payload = this.decodePayload(body);

    if (!payload || payload.exp <= Math.floor(Date.now() / 1000)) {
      return null;
    }

    return payload;
  }

  private signSegments(header: string, body: string): string {
    return createHmac('sha256', this.secret())
      .update(`${header}.${body}`)
      .digest('base64url');
  }

  private encodeJSON(value: unknown): string {
    return Buffer.from(JSON.stringify(value)).toString('base64url');
  }

  private decodePayload(body: string): AccessTokenPayload | null {
    try {
      const decoded = JSON.parse(
        Buffer.from(body, 'base64url').toString('utf8'),
      ) as Partial<AccessTokenPayload>;

      if (
        typeof decoded.sub !== 'string' ||
        typeof decoded.email !== 'string' ||
        typeof decoded.exp !== 'number'
      ) {
        return null;
      }

      return {
        sub: decoded.sub,
        email: decoded.email,
        exp: decoded.exp,
      };
    } catch {
      return null;
    }
  }

  private safeEquals(left: string, right: string): boolean {
    const leftBuffer = Buffer.from(left);
    const rightBuffer = Buffer.from(right);

    if (leftBuffer.length !== rightBuffer.length) {
      return false;
    }

    return timingSafeEqual(leftBuffer, rightBuffer);
  }

  private secret(): string {
    const configuredSecret = this.configService
      .get<string>('AUTH_JWT_SECRET')
      ?.trim();

    if (configuredSecret) {
      return configuredSecret;
    }

    if (!this.allowsDevelopmentDefaults()) {
      throw new InternalServerErrorException({
        code: 'AUTH_JWT_SECRET_REQUIRED',
        message: this.missingSecretMessage(),
        details: {},
      });
    }

    return 'knitgether-local-development-secret';
  }

  private expiresInSeconds(): number {
    const rawValue = this.configService.get<string>('AUTH_JWT_EXPIRES_IN_SECONDS');
    const value = rawValue ? Number(rawValue) : 60 * 60 * 24 * 30;

    return Number.isFinite(value) && value > 0 ? value : 60 * 60 * 24 * 30;
  }

  private allowsDevelopmentDefaults(): boolean {
    const nodeEnv = this.nodeEnv();

    return nodeEnv === 'development' || nodeEnv === 'test';
  }

  private missingSecretMessage(): string {
    return this.nodeEnv() === 'production'
      ? 'AUTH_JWT_SECRET is required in production.'
      : 'AUTH_JWT_SECRET is required outside development and test.';
  }

  private nodeEnv(): string | undefined {
    return this.configService.get<string>('NODE_ENV')?.trim();
  }
}
