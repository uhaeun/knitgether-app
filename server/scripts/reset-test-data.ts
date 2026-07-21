/**
 * Resets local test data so manual QA (Postman/Appium/UI) always starts from a clean slate.
 *
 * Deletes every UserProfile except the seeded "system" profile that owns the built-in
 * skills (see prisma/migrations/20260711060000_add_system_skill_levels). Deleting a
 * UserProfile cascades to every table that has `owner UserProfile @relation(... onDelete: Cascade)`,
 * so this removes all user-created projects, patterns, gauge records, library items, etc.
 * without touching the system skill catalog.
 *
 * Usage:
 *   npm run db:reset-test
 */
import 'dotenv/config';
import { PrismaClient } from '@prisma/client';

const SYSTEM_PROFILE_ID = 'system';

// Matches the local Postgres container in docker-compose.yml / .env.example.
// Only used as a fallback when DATABASE_URL isn't already set in the environment.
const LOCAL_DEV_DATABASE_URL =
  'postgresql://knitgether:knitgether@localhost:5433/knitgether_dev?schema=public';

if (!process.env.DATABASE_URL) {
  process.env.DATABASE_URL = LOCAL_DEV_DATABASE_URL;
}

async function main(): Promise<void> {
  const prisma = new PrismaClient();

  try {
    const { count } = await prisma.userProfile.deleteMany({
      where: { id: { not: SYSTEM_PROFILE_ID } },
    });

    const remainingSkills = await prisma.skill.count({
      where: { isSystem: true },
    });

    console.log(`Deleted ${count} user profile(s) and all owned data.`);
    console.log(`System skills remaining: ${remainingSkills}`);
  } finally {
    await prisma.$disconnect();
  }
}

main().catch((error) => {
  console.error('Failed to reset test data:', error);
  process.exitCode = 1;
});
