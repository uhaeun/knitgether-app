import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { setupApp } from '../src/app.setup';
import { PrismaService } from '../src/database/prisma.service';

type StoredProfile = {
  id: string;
  displayName: string;
  preferredUnits: string;
  createdAt: Date;
  updatedAt: Date;
  deletedAt: Date | null;
};

type StoredAccount = {
  id: string;
  email: string;
  passwordHash: string;
  passwordSalt: string;
  createdAt: Date;
  updatedAt: Date;
  deletedAt: Date | null;
  profile?: StoredProfile;
};

describe('Auth routes', () => {
  let app: INestApplication;
  let prisma: ReturnType<typeof createMockPrisma>;

  beforeAll(async () => {
    process.env.AUTH_JWT_SECRET = 'test-jwt-secret';

    prisma = createMockPrisma();

    const moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    })
      .overrideProvider(PrismaService)
      .useValue(prisma)
      .compile();

    app = moduleRef.createNestApplication();
    setupApp(app);
    await app.init();
  });

  beforeEach(() => {
    prisma.reset();
  });

  afterAll(async () => {
    delete process.env.AUTH_JWT_SECRET;
    await app.close();
  });

  it('registers an account and returns an access token with profile data', async () => {
    const response = await request(app.getHttpServer())
      .post('/api/v1/auth/register')
      .send({
        email: '  YUHA@example.COM  ',
        password: 'password-1234',
        displayName: '  Yuha  ',
        preferredUnits: '  Metric  ',
      })
      .expect(201);

    expect(response.body.accessToken).toEqual(expect.any(String));
    expect(response.body.tokenType).toBe('Bearer');
    expect(response.body.profile).toMatchObject({
      ownerId: response.body.profile.id,
      displayName: 'Yuha',
      preferredUnits: 'Metric',
      syncStatus: 'Synced',
    });
    expect(prisma.accountsByEmail.has('yuha@example.com')).toBe(true);
  });

  it('rejects duplicate account registration by email', async () => {
    await request(app.getHttpServer())
      .post('/api/v1/auth/register')
      .send({
        email: 'yuha@example.com',
        password: 'password-1234',
        displayName: 'Yuha',
      })
      .expect(201);

    await request(app.getHttpServer())
      .post('/api/v1/auth/register')
      .send({
        email: 'YUHA@example.com',
        password: 'password-5678',
        displayName: 'Other',
      })
      .expect(409)
      .expect(({ body }) => {
        expect(body.code).toBe('EMAIL_ALREADY_REGISTERED');
      });
  });

  it('logs in and uses the issued token for authenticated routes', async () => {
    await request(app.getHttpServer())
      .post('/api/v1/auth/register')
      .send({
        email: 'yuha@example.com',
        password: 'password-1234',
        displayName: 'Yuha',
      })
      .expect(201);

    const loginResponse = await request(app.getHttpServer())
      .post('/api/v1/auth/login')
      .send({
        email: 'YUHA@example.com',
        password: 'password-1234',
      })
      .expect(200);

    const token = loginResponse.body.accessToken;

    await request(app.getHttpServer())
      .get('/api/v1/auth/me')
      .set('Authorization', `Bearer ${token}`)
      .expect(200)
      .expect(({ body }) => {
        expect(body.email).toBe('yuha@example.com');
        expect(body.profile.displayName).toBe('Yuha');
      });

    await request(app.getHttpServer())
      .get('/api/v1/profile')
      .set('Authorization', `Bearer ${token}`)
      .expect(200)
      .expect(({ body }) => {
        expect(body.displayName).toBe('Yuha');
      });
  });

  it('rejects login with an invalid password', async () => {
    await request(app.getHttpServer())
      .post('/api/v1/auth/register')
      .send({
        email: 'yuha@example.com',
        password: 'password-1234',
        displayName: 'Yuha',
      })
      .expect(201);

    await request(app.getHttpServer())
      .post('/api/v1/auth/login')
      .send({
        email: 'yuha@example.com',
        password: 'wrong-password',
      })
      .expect(401)
      .expect(({ body }) => {
        expect(body.code).toBe('INVALID_CREDENTIALS');
      });
  });
});

function createMockPrisma() {
  const profilesById = new Map<string, StoredProfile>();
  const accountsByEmail = new Map<string, StoredAccount>();

  const prisma: any = {};

  Object.assign(prisma, {
    profilesById,
    accountsByEmail,
    reset() {
      profilesById.clear();
      accountsByEmail.clear();
      jest.clearAllMocks();
    },
    $transaction: jest.fn(async (callback: (transaction: any) => unknown) =>
      callback(prisma),
    ),
    userAccount: {
      findFirst: jest.fn(async ({ where }: { where: { email?: string; id?: string } }) => {
        if (where.email) {
          const account = accountsByEmail.get(where.email);
          return account?.deletedAt === null ? withProfile(account) : null;
        }

        if (where.id) {
          const account = Array.from(accountsByEmail.values()).find(
            (candidate) => candidate.id === where.id && candidate.deletedAt === null,
          );
          return account ? withProfile(account) : null;
        }

        return null;
      }),
      create: jest.fn(async ({ data }: { data: StoredAccount }) => {
        const account = {
          ...data,
          createdAt: data.createdAt ?? new Date('2026-07-09T00:00:00.000Z'),
          updatedAt: data.updatedAt ?? new Date('2026-07-09T00:00:00.000Z'),
          deletedAt: data.deletedAt ?? null,
        };
        accountsByEmail.set(account.email, account);
        return withProfile(account);
      }),
    },
    userProfile: {
      create: jest.fn(async ({ data }: { data: StoredProfile }) => {
        const profile = {
          ...data,
          createdAt: data.createdAt ?? new Date('2026-07-09T00:00:00.000Z'),
          updatedAt: data.updatedAt ?? new Date('2026-07-09T00:00:00.000Z'),
          deletedAt: data.deletedAt ?? null,
        };
        profilesById.set(profile.id, profile);
        return profile;
      }),
      findUnique: jest.fn(async ({ where }: { where: { id: string } }) => {
        return profilesById.get(where.id) ?? null;
      }),
      upsert: jest.fn(
        async ({
          where,
          create,
          update,
        }: {
          where: { id: string };
          create: StoredProfile;
          update: Partial<StoredProfile>;
        }) => {
          const existing = profilesById.get(where.id);

          if (existing) {
            const updated = {
              ...existing,
              ...update,
              updatedAt: new Date('2026-07-09T00:05:00.000Z'),
            };
            profilesById.set(where.id, updated);
            return updated;
          }

          const profile = {
            ...create,
            createdAt: create.createdAt ?? new Date('2026-07-09T00:00:00.000Z'),
            updatedAt: create.updatedAt ?? new Date('2026-07-09T00:00:00.000Z'),
            deletedAt: create.deletedAt ?? null,
          };
          profilesById.set(profile.id, profile);
          return profile;
        },
      ),
    },
  });

  function withProfile(account: StoredAccount): StoredAccount {
    return {
      ...account,
      profile: profilesById.get(account.id),
    };
  }

  return prisma;
}
