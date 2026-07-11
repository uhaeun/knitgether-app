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
  profile?: UserProfileModel | null;
};

@Injectable()
export class AuthService {
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

    if (
      !account ||
      !this.passwordService.verify(
        body.password,
        account.passwordHash,
        account.passwordSalt,
      )
    ) {
      throw new UnauthorizedException({
        code: 'INVALID_CREDENTIALS',
        message: 'Email or password is incorrect.',
        details: {},
      });
    }

    const profile = await this.profileForAccount(account);

    return this.sessionFor(account.email, profile);
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
