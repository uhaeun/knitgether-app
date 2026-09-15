import {
  ConflictException,
  Injectable,
  InternalServerErrorException,
  UnauthorizedException,
} from '@nestjs/common';
import { randomUUID } from 'crypto';
import { PrismaService } from '../database/prisma.service';
import { UserProfileModel } from '../profile/profile-response.dto';
import { AccessTokenService } from './access-token.service';
import { LoginDto } from './auth-login.dto';
import {
  AuthSessionResponseDto,
  AuthUserResponseDto,
  toAuthSessionResponse,
  toAuthUserResponse,
} from './auth-response.dto';
import { RegisterDto } from './auth-register.dto';
import { PasswordService } from './password.service';

type AccountWithProfile = {
  id: string;
  email: string;
  passwordHash: string;
  passwordSalt: string;
  // 로그인 시도 제한(SPEC AUTH-08). 조회하는 곳에서 함께 읽어 온다.
  failedLoginCount: number;
  lockedUntil: Date | null;
  profile?: UserProfileModel | null;
};

@Injectable()
export class AuthService {
  /// 연속 실패 상한과 잠금 시간(SPEC AUTH-08).
  ///
  /// 5회와 15분은 사용자가 비밀번호를 잘못 기억해 몇 번 틀리는 것은 막지 않으면서,
  /// 자동 대입의 속도를 의미 있게 떨어뜨리는 선으로 잡았다. 잠금이 풀린 뒤 다시 5회를
  /// 쓸 수 있으므로 시간당 20회가 상한이 된다.
  private static readonly MAX_FAILED_LOGIN_ATTEMPTS = 5;
  private static readonly LOGIN_LOCK_DURATION_MS = 15 * 60 * 1000;

  constructor(
    private readonly prisma: PrismaService,
    private readonly passwordService: PasswordService,
    private readonly accessTokenService: AccessTokenService,
  ) {}

  async register(body: RegisterDto): Promise<AuthSessionResponseDto> {
    const email = this.normalizeEmail(body.email);
    const existingAccount = await this.prisma.userAccount.findFirst({
      where: {
        email,
        deletedAt: null,
      },
    });

    if (existingAccount) {
      throw new ConflictException({
        code: 'EMAIL_ALREADY_REGISTERED',
        message: 'Email is already registered.',
        details: {},
      });
    }

    const userId = randomUUID();
    const { passwordHash, passwordSalt } = this.passwordService.hash(body.password);
    const profile = await this.prisma.$transaction(async (transaction) => {
      await transaction.userProfile.create({
        data: {
          id: userId,
          displayName: this.normalizedDisplayName(body.displayName, email),
          preferredUnits: this.normalizedPreferredUnits(body.preferredUnits),
        },
      });

      await transaction.userAccount.create({
        data: {
          id: userId,
          email,
          passwordHash,
          passwordSalt,
        },
      });

      const createdProfile = await transaction.userProfile.findUnique({
        where: { id: userId },
      });

      if (!createdProfile) {
        throw new InternalServerErrorException({
          code: 'PROFILE_CREATE_FAILED',
          message: 'Profile was not created.',
          details: {},
        });
      }

      return createdProfile;
    });

    return this.sessionFor(email, profile);
  }

  async login(body: LoginDto): Promise<AuthSessionResponseDto> {
    const email = this.normalizeEmail(body.email);
    const account = await this.findActiveAccountByEmail(email);

    this.assertNotLockedOut(account);

    if (
      !account ||
      !this.passwordService.verify(
        body.password,
        account.passwordHash,
        account.passwordSalt,
      )
    ) {
      await this.recordFailedLogin(account);

      throw new UnauthorizedException({
        code: 'INVALID_CREDENTIALS',
        message: 'Email or password is incorrect.',
        details: {},
      });
    }

    await this.clearFailedLogins(account);

    const profile = await this.profileForAccount(account);

    return this.sessionFor(account.email, profile);
  }

  /// 로그인 시도 제한(SPEC AUTH-08).
  ///
  /// 잠긴 계정이면 비밀번호를 확인하기 전에 막는다. 확인한 뒤에 막으면 잠금 중에도 해시
  /// 검증이 돌아 비용이 그대로 들고, 응답 시간 차이로 비밀번호의 정오를 읽을 수 있다.
  ///
  /// 계정이 없을 때도 같은 코드를 돌려준다. 잠금 여부로 계정의 존재를 알려주면 열거가
  /// 가능해진다. 이 서버는 원래 존재 여부를 숨기고 있으므로(INVALID_CREDENTIALS 단일 코드)
  /// 그 성질을 깨지 않는다.
  private assertNotLockedOut(account: { lockedUntil: Date | null } | null): void {
    if (!account?.lockedUntil) {
      return;
    }

    if (account.lockedUntil.getTime() <= Date.now()) {
      return;
    }

    throw new UnauthorizedException({
      code: 'LOGIN_TEMPORARILY_LOCKED',
      message:
        'Too many failed attempts. Try again after the lock period expires.',
      details: {},
    });
  }

  /// 실패를 센다. 상한에 닿으면 잠그고 카운터를 0으로 되돌린다.
  ///
  /// 계정이 없으면 셀 대상이 없다. 존재하지 않는 이메일에 대한 시도는 이 카운터로 막을 수
  /// 없으며, 그쪽은 IP 기준 제한이 맡아야 할 몫이다. 이 사이클의 범위 밖이므로 남겨 둔다.
  private async recordFailedLogin(
    account: { id: string; failedLoginCount: number } | null,
  ): Promise<void> {
    if (!account) {
      return;
    }

    const nextCount = account.failedLoginCount + 1;

    if (nextCount < AuthService.MAX_FAILED_LOGIN_ATTEMPTS) {
      await this.prisma.userAccount.update({
        where: { id: account.id },
        data: { failedLoginCount: nextCount },
      });
      return;
    }

    await this.prisma.userAccount.update({
      where: { id: account.id },
      data: {
        failedLoginCount: 0,
        lockedUntil: new Date(Date.now() + AuthService.LOGIN_LOCK_DURATION_MS),
      },
    });
  }

  /// 성공하면 카운터와 잠금을 지운다. 잠금이 만료된 뒤의 성공도 여기로 온다.
  private async clearFailedLogins(account: {
    id: string;
    failedLoginCount: number;
    lockedUntil: Date | null;
  }): Promise<void> {
    if (account.failedLoginCount === 0 && !account.lockedUntil) {
      return;
    }

    await this.prisma.userAccount.update({
      where: { id: account.id },
      data: { failedLoginCount: 0, lockedUntil: null },
    });
  }

  async currentUser(userId: string): Promise<AuthUserResponseDto> {
    const account = await this.findActiveAccountById(userId);

    if (!account) {
      throw new UnauthorizedException({
        code: 'INVALID_CREDENTIALS',
        message: 'Authenticated account no longer exists.',
        details: {},
      });
    }

    return toAuthUserResponse({
      id: account.id,
      email: account.email,
      profile: await this.profileForAccount(account),
    });
  }

  private async findActiveAccountByEmail(
    email: string,
  ): Promise<AccountWithProfile | null> {
    return this.prisma.userAccount.findFirst({
      where: {
        email,
        deletedAt: null,
      },
      include: {
        profile: true,
      },
    });
  }

  private async findActiveAccountById(
    id: string,
  ): Promise<AccountWithProfile | null> {
    return this.prisma.userAccount.findFirst({
      where: {
        id,
        deletedAt: null,
      },
      include: {
        profile: true,
      },
    });
  }

  private async profileForAccount(
    account: AccountWithProfile,
  ): Promise<UserProfileModel> {
    if (account.profile) {
      return account.profile;
    }

    const profile = await this.prisma.userProfile.findUnique({
      where: { id: account.id },
    });

    if (!profile) {
      throw new UnauthorizedException({
        code: 'INVALID_CREDENTIALS',
        message: 'Authenticated account profile no longer exists.',
        details: {},
      });
    }

    return profile;
  }

  private sessionFor(
    email: string,
    profile: UserProfileModel,
  ): AuthSessionResponseDto {
    return toAuthSessionResponse({
      accessToken: this.accessTokenService.sign({
        userId: profile.id,
        email,
      }),
      profile,
    });
  }

  private normalizeEmail(email: string): string {
    return email.trim().toLowerCase();
  }

  private normalizedDisplayName(
    displayName: string | undefined,
    email: string,
  ): string {
    const normalized = displayName?.trim();
    return normalized && normalized.length > 0 ? normalized : email.split('@')[0];
  }

  private normalizedPreferredUnits(preferredUnits: string | undefined): string {
    const normalized = preferredUnits?.trim();
    return normalized && normalized.length > 0 ? normalized : 'Metric';
  }
}
