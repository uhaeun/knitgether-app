import { Injectable } from '@nestjs/common';
import { pbkdf2Sync, randomBytes, timingSafeEqual } from 'crypto';

@Injectable()
export class PasswordService {
  hash(password: string): { passwordHash: string; passwordSalt: string } {
    const passwordSalt = randomBytes(16).toString('base64url');
    const passwordHash = this.deriveHash(password, passwordSalt);

    return {
      passwordHash,
      passwordSalt,
    };
  }

  verify(password: string, passwordHash: string, passwordSalt: string): boolean {
    const candidateHash = this.deriveHash(password, passwordSalt);
    const candidateBuffer = Buffer.from(candidateHash);
    const expectedBuffer = Buffer.from(passwordHash);

    if (candidateBuffer.length !== expectedBuffer.length) {
      return false;
    }

    return timingSafeEqual(candidateBuffer, expectedBuffer);
  }

  private deriveHash(password: string, salt: string): string {
    return pbkdf2Sync(password, salt, 120_000, 32, 'sha256').toString('base64url');
  }
}
