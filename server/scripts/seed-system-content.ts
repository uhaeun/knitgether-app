/**
 * 시스템 공유 콘텐츠 seed (Issue #11).
 *
 * v2.2 §22(스킬 초기 데이터)·§23(뜨개 사전 기본 등록 용어)이 요구하는 기본 데이터를
 * `system` 프로필 소유의 isSystem=true 레코드로 보장한다. 조회 시 모든 사용자에게
 * 병합 노출된다(SkillsService / DictionaryService의 isSystem OR ownerId).
 *
 * 멱등성(§32 #16 준수): 자연키(스킬=abbreviation, 사전=term)로 존재 여부를 확인하고
 * 없을 때만 생성한다. 재실행해도 중복 생성되지 않는다.
 *
 * 스킬은 서버에 이미 37종(블로그 확장 마이그레이션)이 있으므로, §22 15종 중
 * 서버에 없는 표기성 4종(RS/WS/Rep/St)만 보강한다. 기존 스킬은 건드리지 않는다.
 *
 * 사용:
 *   npm run seed
 */
import 'dotenv/config';
import { PrismaClient } from '@prisma/client';
import { randomUUID } from 'node:crypto';

const SYSTEM_PROFILE_ID = 'system';

const LOCAL_DEV_DATABASE_URL =
  'postgresql://knitgether:knitgether@localhost:5433/knitgether_dev?schema=public';

if (!process.env.DATABASE_URL) {
  process.env.DATABASE_URL = LOCAL_DEV_DATABASE_URL;
}

// §22 스킬 초기 데이터 15종 중, 서버 시스템 스킬에 누락된 표기성 4종.
const MISSING_SYSTEM_SKILLS = [
  { abbreviation: 'RS', name: '겉면', description: '편물의 겉면(Right Side).' },
  { abbreviation: 'WS', name: '안면', description: '편물의 안면(Wrong Side).' },
  { abbreviation: 'REP', name: '반복', description: '지정한 구간을 반복하라는 표기(Repeat).' },
  { abbreviation: 'ST', name: '코', description: '뜨개의 기본 단위인 한 코(Stitch).' },
];

// §23 뜨개 사전 기본 등록 용어 18종. description은 §23이 term+fullName만 명시하므로
// 정확한 한국어 설명을 부여했다.
const SYSTEM_DICTIONARY_TERMS = [
  { term: 'CO', fullName: 'Cast On', description: '뜨개를 시작할 때 바늘에 첫 코들을 만드는 것(코 잡기).', related: 'CO' },
  { term: 'FO', fullName: 'Finished Object', description: '완성한 작품.', related: '' },
  { term: 'BO', fullName: 'Bind Off', description: '뜨개를 마칠 때 코를 정리해 마무리하는 것(코 막기).', related: 'BO' },
  { term: 'WIP', fullName: 'Work In Progress', description: '진행 중인 작업.', related: '' },
  { term: 'UFO', fullName: 'Unfinished Object', description: '오래 방치된 미완성 작업.', related: '' },
  { term: '푸르시오', fullName: null, description: '뜬 것을 다시 풀어내는 것을 뜻하는 뜨개 은어.', related: '' },
  { term: '문어발', fullName: null, description: '여러 작품을 동시에 진행하는 것을 뜻하는 뜨개 은어.', related: '' },
  { term: '게이지', fullName: null, description: '일정 면적(보통 10cm)당 코 수와 단 수.', related: '' },
  { term: '스와치', fullName: null, description: '게이지 측정을 위해 미리 떠보는 견본 조각.', related: '' },
  { term: '코', fullName: null, description: '뜨개의 기본 단위. 가로 방향 한 땀.', related: '' },
  { term: '단', fullName: null, description: '코가 가로로 이어진 한 줄(세로 방향으로 쌓인다).', related: '' },
  { term: '겉뜨기', fullName: null, description: '겉면에서 뜨는 기본 뜨기.', related: 'K' },
  { term: '안뜨기', fullName: null, description: '안면 방향으로 뜨는 기본 뜨기.', related: 'P' },
  { term: 'YO', fullName: 'Yarn Over', description: '바늘에 실을 감아 코를 늘리는 기법(바늘비우기).', related: 'YO' },
  { term: 'K', fullName: 'Knit', description: '겉뜨기.', related: 'K' },
  { term: 'P', fullName: 'Purl', description: '안뜨기.', related: 'P' },
  { term: 'K2tog', fullName: 'Knit 2 Together', description: '겉뜨기 2코 모아뜨기(오른쪽으로 기우는 줄임).', related: 'K2tog' },
  { term: 'SSK', fullName: 'Slip Slip Knit', description: '왼쪽으로 기우는 줄임.', related: 'SSK' },
];

async function ensureSystemProfile(prisma: PrismaClient): Promise<void> {
  await prisma.userProfile.upsert({
    where: { id: SYSTEM_PROFILE_ID },
    create: { id: SYSTEM_PROFILE_ID, displayName: 'System' },
    update: {},
  });
}

async function seedMissingSkills(prisma: PrismaClient): Promise<number> {
  let created = 0;
  for (const skill of MISSING_SYSTEM_SKILLS) {
    const exists = await prisma.skill.findFirst({
      where: { isSystem: true, deletedAt: null, abbreviation: skill.abbreviation },
    });
    if (exists) {
      continue;
    }
    await prisma.skill.create({
      data: {
        id: randomUUID(),
        ownerId: SYSTEM_PROFILE_ID,
        name: skill.name,
        abbreviation: skill.abbreviation,
        description: skill.description,
        category: '기본',
        difficulty: '기초',
        isSystem: true,
      },
    });
    created += 1;
  }
  return created;
}

async function seedDictionaryTerms(prisma: PrismaClient): Promise<number> {
  let created = 0;
  for (const entry of SYSTEM_DICTIONARY_TERMS) {
    const exists = await prisma.dictionaryTerm.findFirst({
      where: { isSystem: true, deletedAt: null, term: entry.term },
    });
    if (exists) {
      continue;
    }
    await prisma.dictionaryTerm.create({
      data: {
        id: randomUUID(),
        ownerId: SYSTEM_PROFILE_ID,
        term: entry.term,
        fullName: entry.fullName,
        description: entry.description,
        relatedSkillAbbreviations: entry.related,
        isSystem: true,
      },
    });
    created += 1;
  }
  return created;
}

async function main(): Promise<void> {
  const prisma = new PrismaClient();
  try {
    await ensureSystemProfile(prisma);
    const skillsCreated = await seedMissingSkills(prisma);
    const termsCreated = await seedDictionaryTerms(prisma);

    const skillTotal = await prisma.skill.count({ where: { isSystem: true, deletedAt: null } });
    const termTotal = await prisma.dictionaryTerm.count({ where: { isSystem: true, deletedAt: null } });

    console.log(
      `[seed] system skills +${skillsCreated} (총 ${skillTotal}) / ` +
        `dictionary terms +${termsCreated} (총 ${termTotal})`,
    );
  } finally {
    await prisma.$disconnect();
  }
}

main().catch((error) => {
  console.error('[seed] failed:', error);
  process.exit(1);
});
