/** Opt-in real PostgreSQL + HTTP tests. Never uses a developer DATABASE_URL. */
import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { Prisma } from '@prisma/client';
import { randomUUID } from 'node:crypto';
import { promises as fs } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { setupApp } from '../src/app.setup';
import { PrismaService } from '../src/database/prisma.service';
import { ProjectsService } from '../src/projects/projects.service';
import { LocalFileStorageService } from '../src/storage/local-file-storage.service';

const realUrl = process.env.QA_REAL_DATABASE_URL;
if (!realUrl) throw new Error('QA_REAL_DATABASE_URL is required; no default database is used.');
const parsed = new URL(realUrl);
if (!/^\/knitgether_qa_sync11_[a-z0-9_]+$/.test(parsed.pathname) ||
    !['127.0.0.1', 'localhost'].includes(parsed.hostname)) {
  throw new Error('Use a dedicated local knitgether_qa_sync11_* database.');
}
const evidence: unknown[] = [];
describe('Project concurrency on real PostgreSQL', () => {
  let app: INestApplication;
  let db: PrismaService;
  let storage: string;
  const owner = randomUUID();
  let target: string | null = null;
  let afterRead: ((value: any) => Promise<void>) | null = null;
  let failAfterPatternWrite = false;
  let afterCas: (() => Promise<void>) | null = null;
  const oldEnv = { ...process.env };

  beforeAll(async () => {
    process.env.NODE_ENV = 'test';
    process.env.DATABASE_URL = realUrl;
    process.env.KNITGETHER_API_TOKENS = '';
    process.env.DEV_AUTH_TOKEN = 'real-db-token';
    process.env.DEV_AUTH_USER_ID = owner;
    process.env.AUTH_JWT_SECRET = 'qa-real-db-only';
    storage = await fs.mkdtemp(join(tmpdir(), 'knitgether-cas-'));
    process.env.FILE_STORAGE_ROOT = storage;
    db = new PrismaService({ datasources: { db: { url: realUrl } } });
    await db.$connect();
    await db.userProfile.create({ data: { id: owner, displayName: 'CAS integration' } });
    const transact = db.$transaction.bind(db) as any;
    // Only scheduling/failure injection is intercepted; all reads/writes use real SQL.
    jest.spyOn(db, '$transaction').mockImplementation((async (callback: any, options: any) =>
      transact(async (tx: Prisma.TransactionClient) => {
        let intercepted = false;
        const project = new Proxy(tx.project, {
          get(delegate, key) {
            if (key === 'findFirst') return async (args: any) => {
              const value = await delegate.findFirst(args);
              if (!intercepted && target && args.where.id === target && afterRead) {
                intercepted = true;
                await afterRead(value);
              }
              return value;
            };
            if (key === 'updateMany') return async (args: any) => {
              const result = await delegate.updateMany(args);
              if (result.count === 1 && target === args.where.id && afterCas) {
                const hook = afterCas; afterCas = null;
                await hook();
              }
              return result;
            };
            const value = Reflect.get(delegate, key);
            return typeof value === 'function' ? value.bind(delegate) : value;
          },
        });
        const pattern = new Proxy(tx.projectPatternCopy, {
          get(delegate, key) {
            if (key === 'upsert' || key === 'create' || key === 'update') return async (args: any) => {
              const value = await (delegate[key] as any)(args);
              if (failAfterPatternWrite) {
                evidence.push({ stage: 'late-failure-after-real-pattern-upsert', id: args.where?.projectId ?? args.data.projectId });
                throw new Error('Injected failure after actual child SQL');
              }
              return value;
            };
            const value = Reflect.get(delegate, key);
            return typeof value === 'function' ? value.bind(delegate) : value;
          },
        });
        const wrapped = new Proxy(tx, {
          get(delegate, key) {
            if (key === 'project') return project;
            if (key === 'projectPatternCopy') return pattern;
            const value = Reflect.get(delegate, key);
            return typeof value === 'function' ? value.bind(delegate) : value;
          },
        });
        return callback(wrapped);
      }, { ...options, maxWait: 5000, timeout: 15000 })) as any);
    const module = await Test.createTestingModule({ imports: [AppModule] })
      .overrideProvider(PrismaService).useValue(db).compile();
    app = module.createNestApplication();
    app.useLogger(false);
    setupApp(app);
    await app.init();
    evidence.push({ isolation: await db.$queryRaw`SHOW transaction_isolation` });
  });
  afterEach(() => { target = null; afterRead = null; afterCas = null; failAfterPatternWrite = false; });
  afterAll(async () => {
    try {
      if (process.env.QA_DB_EVIDENCE_PATH) {
        await fs.writeFile(process.env.QA_DB_EVIDENCE_PATH, JSON.stringify(evidence, null, 2));
      }
    } finally {
      jest.restoreAllMocks();
      if (app) await app.close();
      if (db) await db.$disconnect();
      if (storage) await fs.rm(storage, { recursive: true, force: true });
      process.env = oldEnv;
    }
    // Dedicated database records are preserved as evidence; no reset/delete-all.
  });
  const call = (method: 'get'|'post'|'patch'|'delete', path: string, body?: any) => {
    const req = request(app.getHttpServer())[method]('/api/v1'+path)
      .set('Authorization', 'Bearer real-db-token');
    return body ? req.send(body) : req;
  };
  async function create() {
    const id = randomUUID();
    const body = {
      id, name: 'CAS baseline', memo: '', status: 'WIP', isFavorite: false,
      startDate: '2026-10-24T00:00:00.000Z', relatedSkillIds: [],
      rowCounter: { id: randomUUID(), projectId: id, name: 'Main', currentRow: 0, rowInstructions: [] as any[] },
      workSessions: [] as any[], patternCopy: null as any,
    };
    const res = await call('post', '/projects', body).expect(201);
    return { ...body, baseUpdatedAt: res.body.updatedAt };
  }
  function variant(original: any, marker: string) {
    const b = structuredClone(original);
    b.name = marker; b.memo = marker; b.isFavorite = marker === 'A';
    b.rowCounter.currentRow = marker === 'A' ? 11 : 22;
    b.rowCounter.rowInstructions = [{ id: randomUUID(), rowCounterId: b.rowCounter.id,
      rowNumber: 1, instructionText: marker, skillTags: '' }];
    b.workSessions = [{ id: randomUUID(), projectId: b.id, startedAt: '2026-10-24T00:00:00.000Z',
      endedAt: '2026-10-24T00:01:00.000Z', memo: marker }];
    b.patternCopy = { id: randomUUID(), projectId: b.id, sourcePatternDocumentId: null,
      titleSnapshot: marker, designerSnapshot: null, fileNameSnapshot: null,
      pageCountSnapshot: null, copiedAt: '2026-10-24T00:00:00.000Z', drawingUpdatedAt: null };
    return b;
  }
  const snapshot = (id: string) => db.project.findUniqueOrThrow({ where: { id }, include: {
    rowCounter: true, rowInstructions: { orderBy: { id: 'asc' } },
    workSessions: { orderBy: { id: 'asc' } }, patternCopy: true,
  } });

  it('has exactly one winner with no loser children after both read the same baseline', async () => {
    for (let trial = 0; trial < 5; trial++) {
      const base = await create();
      const a = variant(base, 'A'), b = variant(base, 'B');
      // A session omitted by both updates must survive the incremental upserts.
      const untouched = await db.workSession.create({ data: { id: randomUUID(), ownerId: owner,
        projectId: base.id, startedAt: new Date('2026-10-24T00:02:00Z'), memo: 'untouched' } });
      let release!: () => void;
      let reject!: (e: Error) => void;
      const ready = new Promise<void>((resolve, fail) => { release = resolve; reject = fail; });
      const reads: string[] = [];
      const timer = setTimeout(() => reject(new Error('Read barrier failed to rendezvous')), 3000);
      target = base.id;
      afterRead = async value => {
        reads.push(value.updatedAt.toISOString());
        if (reads.length === 2) { clearTimeout(timer); release(); }
        await ready;
      };
      let responses: any[];
      try { responses = await Promise.all([call('patch', '/projects/'+base.id, a), call('patch', '/projects/'+base.id, b)]); }
      finally { clearTimeout(timer); release(); target = null; afterRead = null; }
      const stored = await snapshot(base.id);
      evidence.push({ trial, reads, requests: [a,b], responses: responses!.map(r => ({ status: r.status, body: r.body })), stored });
      expect(reads).toEqual([base.baseUpdatedAt, base.baseUpdatedAt]);
      expect(responses!.map(r => r.status).sort()).toEqual([200,409]);
      const winner = responses![0].status === 200 ? a : b;
      const loser = winner === a ? b : a;
      expect(stored.memo).toBe(winner.memo);
      expect(stored.name).toBe(winner.name);
      expect(stored.isFavorite).toBe(winner.isFavorite);
      expect(stored.rowCounter!.currentRow).toBe(winner.rowCounter.currentRow);
      expect(stored.rowInstructions.map(r => r.id)).toEqual([winner.rowCounter.rowInstructions[0].id]);
      expect(stored.patternCopy!.id).toBe(winner.patternCopy.id);
      expect(stored.workSessions.map(r => r.id).sort()).toEqual([untouched.id,winner.workSessions[0].id].sort());
      const conflict = responses!.find(r => r.status === 409).body;
      expect(conflict.code).toBe('PROJECT_CONFLICT');
      expect(conflict.details.latest.memo).toBe(winner.memo);
      loser.baseUpdatedAt = conflict.details.latest.updatedAt;
      await call('patch', '/projects/'+base.id, loser).expect(200);
      expect((await snapshot(base.id)).memo).toBe(loser.memo);
    }
  });

  it('rolls back parent/version and early children when row instruction replacement fails', async () => {
    const b = await create();
    const unrelated = await create();
    await db.rowInstruction.create({ data: { id: randomUUID(), ownerId: owner, projectId: b.id,
      rowCounterId: b.rowCounter.id, rowNumber: 1, instructionText: 'original instruction', skillTags: '' } });
    const before = await snapshot(b.id), otherBefore = await snapshot(unrelated.id);
    const body = variant(b,'A');
    body.rowCounter.rowInstructions.push({ ...body.rowCounter.rowInstructions[0], id: randomUUID() });
    const res = await call('patch','/projects/'+b.id,body).expect(400);
    expect(res.body.message).toBe('Duplicate row instruction numbers are not allowed.');
    const after = await snapshot(b.id);
    expect(after).toEqual(before);
    expect(await snapshot(unrelated.id)).toEqual(otherBefore);
    evidence.push({ case: 'early-child-rollback', request: body, status: res.status, before, after });
  });

  it('rolls back all SQL children when an error follows actual pattern upsert', async () => {
    const b = await create(); const before = await snapshot(b.id);
    failAfterPatternWrite = true;
    const eventStart = evidence.length;
    const res = await call('patch','/projects/'+b.id,variant(b,'B')).expect(500);
    expect(evidence.slice(eventStart)).toContainEqual({ stage: 'late-failure-after-real-pattern-upsert', id: b.id });
    const after = await snapshot(b.id);
    expect(after).toEqual(before);
    evidence.push({ case: 'late-child-rollback', status: res.status, before, after });
  });

  it('advances every version even when the stored clock is ahead and rejects future client tokens', async () => {
    const b = await create();
    const time = new Date(Date.now()+3600000);
    await db.project.update({ where: { id: b.id }, data: { updatedAt: time } });
    b.baseUpdatedAt = time.toISOString();
    const first = await call('patch','/projects/'+b.id,b).expect(200);
    expect(new Date(first.body.updatedAt).getTime()).toBe(time.getTime()+1);
    await call('patch','/projects/'+b.id,b).expect(409);
    const second = await call('patch','/projects/'+b.id,{...b,baseUpdatedAt:first.body.updatedAt}).expect(200);
    expect(new Date(second.body.updatedAt).getTime()).toBe(time.getTime()+2);
    await call('patch','/projects/'+b.id,{...b,baseUpdatedAt:new Date(time.getTime()+100).toISOString()}).expect(409);
    const equivalent = second.body.updatedAt.replace('Z','+00:00');
    await call('patch','/projects/'+b.id,{...b,baseUpdatedAt:equivalent}).expect(200);
    evidence.push({ case:'monotonic-clock', base:b.baseUpdatedAt, first:first.body.updatedAt, second:second.body.updatedAt });
  });

  it('returns fresh 409/latest when another write commits between read and CAS', async () => {
    const b = await create(); target=b.id;
    afterRead=async value => { await db.project.update({where:{id:b.id},data:{memo:'intervening',updatedAt:new Date(value.updatedAt.getTime()+1)}}); };
    const res=await call('patch','/projects/'+b.id,b).expect(409);
    expect(res.body.details.latest.memo).toBe('intervening');
    expect((await snapshot(b.id)).rowCounter!.currentRow).toBe(0);
    evidence.push({case:'cas-zero-latest',response:res.body});
  });

  it('returns 404 when the project is deleted between read and CAS', async () => {
    const b=await create(); target=b.id;
    afterRead=async () => {await db.project.update({where:{id:b.id},data:{deletedAt:new Date()}});};
    await call('patch','/projects/'+b.id,b).expect(404);
  });

  it('preserves 409 even if the latest project has no convertible row counter', async () => {
    const b=await create();target=b.id;
    afterRead=async value => {
      await db.rowCounter.delete({where:{projectId:b.id}});
      await db.project.update({where:{id:b.id},data:{updatedAt:new Date(value.updatedAt.getTime()+1)}});
    };
    const res=await call('patch','/projects/'+b.id,b).expect(409);
    expect(res.body.details.latest).toBeNull();
  });

  it('preserves validation, ownership and row-counter compatibility contracts', async () => {
    const b=await create();const before=await snapshot(b.id);
    const noBase={...b};delete (noBase as any).baseUpdatedAt;
    await call('patch','/projects/'+b.id,noBase).expect(400);
    await call('patch','/projects/'+b.id,{...b,baseUpdatedAt:null}).expect(400);
    await call('patch','/projects/'+b.id,{...b,baseUpdatedAt:'invalid'}).expect(400);
    await call('patch','/projects/'+b.id,{...b,id:randomUUID()}).expect(404);
    await call('patch','/projects/'+randomUUID(),b).expect(404);
    const foreignOwner=await db.userProfile.create({data:{id:randomUUID(),displayName:'Other'}});
    await db.project.update({where:{id:b.id},data:{ownerId:foreignOwner.id}});
    await call('patch','/projects/'+b.id,b).expect(404);
    await db.project.update({where:{id:b.id},data:{ownerId:owner,updatedAt:before.updatedAt}});
    expect(await snapshot(b.id)).toEqual(before);
    const mismatched=variant(b,'A');mismatched.rowCounter.id=randomUUID();
    mismatched.rowCounter.rowInstructions[0].rowCounterId=mismatched.rowCounter.id;
    await call('patch','/projects/'+b.id,mismatched).expect(400);
    mismatched.rowCounter.rowInstructions=[];
    await call('patch','/projects/'+b.id,mismatched).expect(200);
    expect((await snapshot(b.id)).rowCounter!.id).toBe(b.rowCounter.id);
  });

  // Former known gaps are now mandatory CI acceptance tests.
  it('Regression: rejects a stale whole save after a child-only counter save', async () => {
    const b = await create();
    const child = await call('patch', '/projects/'+b.id+'/row-counter',
      { ...b.rowCounter, currentRow: 77 }).expect(200);
    const afterChild = await snapshot(b.id);
    const stale = await call('patch', '/projects/'+b.id, b);
    const final = await snapshot(b.id);
    evidence.push({ case: 'child-then-stale-whole', request: b, child: child.body,
      afterChild, status: stale.status, response: stale.body, final });
    expect(stale.status).toBe(409);
    expect(final.rowCounter!.currentRow).toBe(77);
  });

  it('Regression: detects a child API write between the whole save read and CAS', async () => {
    const b = await create(); target = b.id;
    let child: any;
    afterRead = async () => {
      afterRead = null; // Do not intercept the child transaction's own parent read.
      child = await call('patch', '/projects/'+b.id+'/row-counter',
        { ...b.rowCounter, currentRow: 88 }).expect(200);
    };
    const stale = await call('patch', '/projects/'+b.id, b);
    const final = await snapshot(b.id);
    evidence.push({ case: 'child-between-read-and-cas', request: b, child: child.body,
      status: stale.status, response: stale.body, final });
    expect(stale.status).toBe(409);
    expect(final.rowCounter!.currentRow).toBe(88);
  });

  it.each(['create', 'update', 'delete'])('session %s invalidates a stale whole save', async (operation) => {
    const b = await create();
    const session = { id: randomUUID(), projectId: b.id,
      startedAt: '2026-10-24T00:00:00.000Z', endedAt: '2026-10-24T00:01:00.000Z', memo: 'original' };
    if (operation !== 'create') {
      await db.workSession.create({ data: { ...session, ownerId: owner } });
      b.workSessions = [session];
    }
    const path = '/projects/'+b.id+'/work-sessions';
    const child = operation === 'delete'
      ? await call('delete', path+'/'+session.id).expect(204)
      : await call(operation === 'create' ? 'post' : 'patch',
          path+(operation === 'update' ? '/'+session.id : ''), { ...session, memo: 'child' })
          .expect(operation === 'create' ? 201 : 200);
    const before = await snapshot(b.id);
    const stale = await call('patch', '/projects/'+b.id, { ...b, memo: 'stale' });
    const final = await snapshot(b.id);
    evidence.push({ case: 'session-'+operation+'-stale-whole', request: b,
      childStatus: child.status, before, status: stale.status, response: stale.body, final });
    expect(stale.status).toBe(409);
    expect(final).toEqual(before);
    expect(before.updatedAt.getTime()).toBeGreaterThan(new Date(b.baseUpdatedAt).getTime());
    expect(final.workSessions[0].deletedAt !== null).toBe(operation === 'delete');
  });

  it('session deletion between whole read and CAS rejects the stale whole save', async () => {
    const b = await create();
    const session = { id: randomUUID(), projectId: b.id, ownerId: owner,
      startedAt: new Date('2026-10-24T00:00:00.000Z'), memo: 'keep deleted' };
    await db.workSession.create({ data: session });
    b.workSessions = [{ id: session.id, projectId: b.id, startedAt: session.startedAt.toISOString(), memo: session.memo }];
    target = b.id;
    afterRead = async () => {
      afterRead = null;
      await call('delete', '/projects/'+b.id+'/work-sessions/'+session.id).expect(204);
    };
    await call('patch', '/projects/'+b.id, b).expect(409);
    const final = await snapshot(b.id);
    expect(final.workSessions[0].deletedAt).not.toBeNull();
    evidence.push({ case: 'session-delete-between-read-and-cas', final });
  });

  it('rolls back the parent version if the session mutation fails', async () => {
    const b = await create();
    const before = await snapshot(b.id);
    await call('delete', '/projects/'+b.id+'/work-sessions/'+randomUUID()).expect(404);
    const final = await snapshot(b.id);
    expect(final).toEqual(before);
    evidence.push({ case: 'missing-session-parent-rollback', before, final });
  });

  it('serializes session deletion behind an uncommitted whole save', async () => {
    const b = await create();
    const body = variant(b, 'A');
    const session = body.workSessions[0];
    await db.workSession.create({ data: { ...session, ownerId: owner } });
    target = b.id;
    let signal!: () => void, release!: () => void;
    const locked = new Promise<void>(resolve => { signal = resolve; });
    const resume = new Promise<void>(resolve => { release = resolve; });
    afterCas = async () => { signal(); await resume; };
    const whole = call('patch', '/projects/'+b.id, body).then(res => res);
    await locked;
    const child = call('delete', '/projects/'+b.id+'/work-sessions/'+session.id).then(res => res);
    let blocked = false;
    try {
      for (let attempt = 0; attempt < 100; attempt++) {
        const rows = await db.$queryRaw<Array<{ blocked: boolean }>>`
          SELECT EXISTS(SELECT 1 FROM pg_stat_activity
            WHERE datname = current_database() AND wait_event_type = 'Lock'
            AND query LIKE '%UPDATE%Project%') AS blocked`;
        if (rows[0].blocked) { blocked = true; break; }
        await new Promise(resolve => setTimeout(resolve, 10));
      }
    } finally { release(); }
    const [wholeResult, childResult] = await Promise.all([whole, child]);
    expect(blocked).toBe(true);
    expect(wholeResult.status).toBe(200); expect(childResult.status).toBe(204);
    const final = await snapshot(b.id);
    expect(final.memo).toBe('A'); expect(final.workSessions[0].deletedAt).not.toBeNull();
    expect(final.updatedAt.getTime()).toBeGreaterThan(new Date(wholeResult.body.updatedAt).getTime());
    evidence.push({ case: 'session-delete-blocked-on-whole-parent-lock', blocked, final });
  });

  async function sourcePattern() {
    const id = randomUUID(), fileId = randomUUID();
    const key = 'patterns/'+owner+'/'+id+'/'+fileId+'.pdf';
    const buffer = Buffer.from('%PDF-1.4\n% QA fixture\n%%EOF\n');
    await fs.mkdir(join(storage, 'patterns', owner, id), { recursive: true });
    await fs.writeFile(join(storage, key), buffer);
    await db.storedFile.create({ data: { id: fileId, ownerId: owner, kind: 'PATTERN_PDF',
      originalFileName: 'qa.pdf', contentType: 'application/pdf', byteSize: buffer.length, storageKey: key } });
    await db.patternDocument.create({ data: { id, ownerId: owner, title: 'QA source', storedFileId: fileId } });
    return id;
  }
  it('Regression: removes materialized files when the SQL transaction rolls back', async () => {
    const b = await create(), before = await snapshot(b.id);
    const body = variant(b, 'A');
    body.patternCopy.sourcePatternDocumentId = await sourcePattern();
    failAfterPatternWrite = true;
    const res = await call('patch', '/projects/'+b.id, body).expect(500);
    const after = await snapshot(b.id);
    const files = await fs.readdir(storage, { recursive: true });
    const orphans = files.filter(p => p.startsWith('projects/'+owner+'/'+b.id+'/') && p.endsWith('.pdf'));
    evidence.push({ case: 'filesystem-after-sql-rollback', request: body, status: res.status,
      before, after, orphanFiles: orphans });
    expect(after).toEqual(before);
    expect(orphans).toEqual([]);
  });

  it('Regression: cleans an unreferenced PDF after pattern copy replacement', async () => {
    const b = await create(), body = variant(b, 'A');
    body.patternCopy.sourcePatternDocumentId = await sourcePattern();
    const first = await call('patch', '/projects/'+b.id, body).expect(200);
    const oldCopy = (await snapshot(b.id)).patternCopy!;
    const replacement = structuredClone(body);
    replacement.baseUpdatedAt = first.body.updatedAt;
    replacement.patternCopy.id = randomUUID();
    await call('patch', '/projects/'+b.id, replacement).expect(200);
    const final = await snapshot(b.id);
    const oldFileExists = await fs.stat(join(storage, oldCopy.fileStorageKey!)).then(() => true, () => false);
    evidence.push({ case: 'filesystem-after-copy-replacement', oldCopy, final, oldFileExists });
    expect(final.patternCopy!.id).toBe(replacement.patternCopy.id);
    expect(final.patternCopy!.fileStorageKey).not.toBe(oldCopy.fileStorageKey);
    expect(oldFileExists).toBe(false);
  });
  it('serializes a child write after a whole-save CAS without losing the child', async () => {
    const b = await create();
    const whole = await call('patch', '/projects/'+b.id, variant(b, 'A')).expect(200);
    await call('patch', '/projects/'+b.id+'/row-counter', { ...b.rowCounter, currentRow: 99 }).expect(200);
    const final = await snapshot(b.id);
    expect(final.memo).toBe('A');
    expect(final.rowCounter!.currentRow).toBe(99);
    expect(final.updatedAt.getTime()).toBeGreaterThan(new Date(whole.body.updatedAt).getTime());
    evidence.push({ case: 'whole-then-child', final });
  });

  it('rolls back the parent version if the child update fails', async () => {
    const b = await create(), before = await snapshot(b.id);
    await db.rowCounter.delete({ where: { projectId: b.id } });
    await call('patch', '/projects/'+b.id+'/row-counter', { ...b.rowCounter, currentRow: 99 }).expect(500);
    const final = await snapshot(b.id);
    expect(final.updatedAt).toEqual(before.updatedAt);
    evidence.push({ case: 'failed-child-parent-rollback', before, final });
  });

  it('keeps the old PDF and drawing on rollback, then removes both on detach', async () => {
    const b = await create(), body = variant(b, 'A');
    body.patternCopy.sourcePatternDocumentId = await sourcePattern();
    const first = await call('patch', '/projects/'+b.id, body).expect(200);
    const storageService = app.get(LocalFileStorageService);
    const drawing = await storageService.saveProjectPatternDrawing({ ownerId: owner, projectId: b.id,
      copyId: body.patternCopy.id, buffer: Buffer.from('QA drawing') });
    await db.projectPatternCopy.update({ where: { projectId: b.id }, data: { drawingStorageKey: drawing.storageKey } });
    const old = (await snapshot(b.id)).patternCopy!;
    const failed = structuredClone(body); failed.baseUpdatedAt = first.body.updatedAt;
    failed.patternCopy.id = randomUUID();
    // Failure after actual upsert must keep the committed old file intact.
    failAfterPatternWrite = true;
    await call('patch', '/projects/'+b.id, failed).expect(500);
    await fs.access(join(storage, old.fileStorageKey!));
    await fs.access(join(storage, drawing.storageKey));
    const projectPdfs = (await fs.readdir(storage, { recursive: true })).filter(p =>
      p.startsWith('projects/'+owner+'/'+b.id+'/') && p.endsWith('.pdf'));
    expect(projectPdfs).toEqual([old.fileStorageKey!]);
    failAfterPatternWrite = false;
    await call('patch', '/projects/'+b.id, { ...body, baseUpdatedAt: first.body.updatedAt, patternCopy: null }).expect(200);
    expect(await fs.stat(join(storage, old.fileStorageKey!)).then(() => true, () => false)).toBe(false);
    expect(await fs.stat(join(storage, drawing.storageKey)).then(() => true, () => false)).toBe(false);
    evidence.push({ case: 'rollback-preserves-old-and-detach-cleans-pdf-drawing', old });
  });

  it('retries durable failed removals and preserves referenced files after restart', async () => {
    const b = await create(), body = variant(b, 'A');
    body.patternCopy.sourcePatternDocumentId = await sourcePattern();
    const first = await call('patch', '/projects/'+b.id, body).expect(200);
    const old = (await snapshot(b.id)).patternCopy!;
    const storageService = app.get(LocalFileStorageService);
    const fail = jest.spyOn(storageService, 'remove').mockRejectedValueOnce(new Error('Injected unlink failure'));
    const replacement = structuredClone(body); replacement.baseUpdatedAt = first.body.updatedAt;
    replacement.patternCopy.id = randomUUID();
    await call('patch', '/projects/'+b.id, replacement).expect(200);
    await fs.access(join(storage, old.fileStorageKey!));
    fail.mockRestore();
    // Simulate persisted candidates older than the crash recovery grace period.
    for (const name of await fs.readdir(join(storage, '.pattern-cleanup'))) {
      const path = join(storage, '.pattern-cleanup', name);
      const entry = JSON.parse(await fs.readFile(path, 'utf8'));
      entry.queuedAt = Date.now() - 3_600_001;
      await fs.writeFile(path, JSON.stringify(entry));
    }
    const candidates = await storageService.pendingProjectPatternRemovals(Date.now());
    expect(candidates).toContain(old.fileStorageKey);
    // New storage instance reads durable markers, independent of in-memory state.
    const restartedStorage = new LocalFileStorageService({ get: () => storage } as any);
    const restartedService = new ProjectsService(db, restartedStorage);
    await restartedService.retryPatternFileCleanup();
    expect(await fs.stat(join(storage, old.fileStorageKey!)).then(() => true, () => false)).toBe(false);
    const final = await snapshot(b.id);
    await fs.access(join(storage, final.patternCopy!.fileStorageKey!));
    const source = await db.patternDocument.findUniqueOrThrow({ where: { id: body.patternCopy.sourcePatternDocumentId }, include: { storedFile: true } });
    await fs.access(join(storage, source.storedFile!.storageKey));
    evidence.push({ case: 'durable-cleanup-retry-and-live-reference-preserved', candidates, final });
  });

  it('blocks the counter on the parent lock while a whole save is uncommitted', async () => {
    const b = await create(); target = b.id;
    let signal!: () => void, release!: () => void;
    const locked = new Promise<void>(resolve => { signal = resolve; });
    const resume = new Promise<void>(resolve => { release = resolve; });
    afterCas = async () => { signal(); await resume; };
    const whole = call('patch', '/projects/'+b.id, variant(b, 'A')).then(res => res);
    await locked;
    const child = call('patch', '/projects/'+b.id+'/row-counter', { ...b.rowCounter, currentRow: 99 }).then(res => res);
    let blocked = false;
    try {
      for (let attempt = 0; attempt < 100; attempt++) {
        const rows = await db.$queryRaw<Array<{ blocked: boolean }>>`
          SELECT EXISTS(SELECT 1 FROM pg_stat_activity
            WHERE datname = current_database() AND wait_event_type = 'Lock'
            AND query LIKE '%UPDATE%Project%') AS blocked`;
        if (rows[0].blocked) { blocked = true; break; }
        await new Promise(resolve => setTimeout(resolve, 10));
      }
    } finally { release(); }
    const [wholeResult, childResult] = await Promise.all([whole, child]);
    expect(blocked).toBe(true);
    expect(wholeResult.status).toBe(200); expect(childResult.status).toBe(200);
    const final = await snapshot(b.id);
    expect(final.memo).toBe('A'); expect(final.rowCounter!.currentRow).toBe(99);
    expect(final.updatedAt.getTime()).toBeGreaterThan(new Date(wholeResult.body.updatedAt).getTime());
    evidence.push({ case: 'child-blocked-on-whole-parent-lock', blocked, final });
  });

  it('compensates files when project creation rolls back', async () => {
    const id = randomUUID(), counterId = randomUUID();
    const body = variant({ id, name: 'Create rollback', memo: '', status: 'WIP', isFavorite: false,
      startDate: '2026-10-26T00:00:00.000Z', relatedSkillIds: [],
      rowCounter: { id: counterId, projectId: id, name: 'Main', currentRow: 0, rowInstructions: [] },
      workSessions: [], patternCopy: null }, 'A');
    body.patternCopy.sourcePatternDocumentId = await sourcePattern();
    failAfterPatternWrite = true;
    await call('post', '/projects', body).expect(500);
    expect(await db.project.findUnique({ where: { id } })).toBeNull();
    const files = (await fs.readdir(storage, { recursive: true })).filter(p =>
      p.startsWith('projects/'+owner+'/'+id+'/') && p.endsWith('.pdf'));
    expect(files).toEqual([]);
    evidence.push({ case: 'create-rollback-files-compensated', id, files });
  });

  for (const operation of ['create', 'update', 'delete'] as const) {
    it(`protects row instruction ${operation} from a stale whole save`, async () => {
      const b = await create(), body = variant(b, 'A');
      const first = await call('patch', '/projects/'+b.id, body).expect(200);
      body.baseUpdatedAt = first.body.updatedAt;
      const instruction = operation === 'create'
        ? { ...body.rowCounter.rowInstructions[0], id: randomUUID(), rowNumber: 2 }
        : { ...body.rowCounter.rowInstructions[0], instructionText: 'Child edit' };
      const path = '/projects/'+b.id+'/row-instructions';
      if (operation === 'create') await call('post', path, instruction).expect(201);
      else if (operation === 'update') await call('patch', path+'/'+instruction.id, instruction).expect(200);
      else await call('delete', path+'/'+instruction.id).expect(204);
      const saved = await snapshot(b.id);
      const stale = await call('patch', '/projects/'+b.id, body);
      evidence.push({ case: 'row-instruction-'+operation, request: body, response: stale.body, status: stale.status, saved, final: await snapshot(b.id) });
      expect(stale.status).toBe(409);
      expect(await snapshot(b.id)).toEqual(saved);
    });
  }
  for (const operation of ['pdf', 'drawing', 'delete-drawing'] as const) {
    it(`protects pattern ${operation} from a stale whole save`, async () => {
      const b = await create(), body = variant(b, 'A');
      let first = await call('patch', '/projects/'+b.id, body).expect(200);
      if (operation === 'delete-drawing') {
        await call('post', '/projects/'+b.id+'/pattern-copy/drawing')
          .attach('file', Buffer.from('original drawing'), { filename: 'drawing.pkdrawing', contentType: 'application/octet-stream' }).expect(201);
        first = await call('get', '/projects/'+b.id).expect(200);
      }
      body.baseUpdatedAt = first.body.updatedAt;
      if (operation === 'pdf') await call('post', '/projects/'+b.id+'/pattern-copy/file')
        .attach('file', Buffer.from('%PDF-1.4\nQA'), { filename: 'fresh.pdf', contentType: 'application/pdf' }).expect(201);
      else if (operation === 'drawing') await call('post', '/projects/'+b.id+'/pattern-copy/drawing')
        .attach('file', Buffer.from('new drawing'), { filename: 'drawing.pkdrawing', contentType: 'application/octet-stream' }).expect(201);
      else await call('delete', '/projects/'+b.id+'/pattern-copy/drawing').expect(204);
      const saved = await snapshot(b.id);
      const stale = await call('patch', '/projects/'+b.id, body);
      evidence.push({ case: 'pattern-'+operation, request: body, response: stale.body, status: stale.status, saved, final: await snapshot(b.id) });
      expect(stale.status).toBe(409);
      expect(await snapshot(b.id)).toEqual(saved);
    });
  }

  for (const operation of ['upload', 'delete'] as const) {
    it(`preserves committed drawing bytes if dedicated ${operation} SQL rolls back`, async () => {
      const b = await create(), body = variant(b, 'A');
      await call('patch', '/projects/'+b.id, body).expect(200);
      await call('post', '/projects/'+b.id+'/pattern-copy/drawing')
        .attach('file', Buffer.from('committed bytes'), { filename: 'drawing.pkdrawing', contentType: 'application/octet-stream' }).expect(201);
      const before = await snapshot(b.id), oldKey = before.patternCopy!.drawingStorageKey!;
      failAfterPatternWrite = true;
      const response = operation === 'upload'
        ? await call('post', '/projects/'+b.id+'/pattern-copy/drawing')
          .attach('file', Buffer.from('uncommitted bytes'), { filename: 'drawing.pkdrawing', contentType: 'application/octet-stream' })
        : await call('delete', '/projects/'+b.id+'/pattern-copy/drawing');
      expect(response.status).toBe(500);
      expect(await snapshot(b.id)).toEqual(before);
      expect((await fs.readFile(join(storage, oldKey))).toString()).toBe('committed bytes');
      const files = (await fs.readdir(storage, { recursive: true })).filter(p =>
        p.startsWith('projects/'+owner+'/'+b.id+'/') && p.endsWith('.pkdrawing'));
      expect(files).toEqual([oldKey]);
      evidence.push({ case: 'drawing-'+operation+'-rollback', status: response.status, before, final: await snapshot(b.id), files });
    });
  }
  it('serializes duplicate instruction creates and rolls back the rejected parent version', async () => {
    const b = await create();
    const make = () => ({ id: randomUUID(), rowCounterId: b.rowCounter.id, rowNumber: 7, instructionText: 'Unique row', skillTags: '' });
    const results = await Promise.all([call('post', '/projects/'+b.id+'/row-instructions', make()), call('post', '/projects/'+b.id+'/row-instructions', make())]);
    expect(results.map(r => r.status).sort()).toEqual([201, 400]);
    const before = await snapshot(b.id);
    expect(before.rowInstructions.filter(i => !i.deletedAt)).toHaveLength(1);
    await call('delete', '/projects/'+b.id+'/row-instructions/'+randomUUID()).expect(404);
    expect(await snapshot(b.id)).toEqual(before);
    evidence.push({ case: 'duplicate-instruction-serialization-and-rejected-version-rollback', statuses: results.map(r => r.status), final: before });
  });

  it('preserves independent usage, photo and material links across whole saves', async () => {
    const b = await create();
    const yarn = await call('post', '/library/yarns', { name: 'Independent yarn', quantity: 10 }).expect(201);
    const needle = await call('post', '/library/needles', { name: 'Independent needle', needleType: 'Circular', size: '4mm' }).expect(201);
    const tool = await call('post', '/library/tools', { name: 'Independent tool', type: 'Other' }).expect(201);
    await call('post', '/projects/'+b.id+'/yarn-usages', { yarnId: yarn.body.id, quantityUsed: 2, memo: 'Keep usage' }).expect(201);
    await call('post', '/projects/'+b.id+'/progress-photos').field('caption', 'Keep photo')
      .attach('file', Buffer.from('QA image bytes'), { filename: 'photo.png', contentType: 'image/png' }).expect(201);
    await call('post', '/library/projects/'+b.id+'/yarns/'+yarn.body.id).expect(201);
    await call('post', '/library/projects/'+b.id+'/needles/'+needle.body.id).expect(201);
    await call('post', '/library/projects/'+b.id+'/tools/'+tool.body.id).expect(201);
    const related = async () => ({
      usage: await db.projectYarnUsage.findMany({ where: { projectId: b.id } }),
      photo: await db.projectProgressPhoto.findMany({ where: { projectId: b.id } }),
      yarn: await db.yarn.findUnique({ where: { id: yarn.body.id } }),
      yarnLinks: await db.projectYarnLink.findMany({ where: { projectId: b.id } }),
      needleLinks: await db.projectNeedleLink.findMany({ where: { projectId: b.id } }),
      toolLinks: await db.projectToolLink.findMany({ where: { projectId: b.id } }),
    });
    const before = await related();
    await call('patch', '/projects/'+b.id, { ...b, memo: 'Whole save' }).expect(200);
    expect(await related()).toEqual(before);
    expect(before.yarn!.quantity).toBe(8);
    for (const photo of before.photo) await fs.access(join(storage, photo.storageKey));
    evidence.push({ case: 'independent-usage-photo-material-links-preserved', before, final: await related() });
  });

  for (const foreignOwner of [false, true]) for (const operation of ['instruction', 'session', 'whole-session'] as const) {
    it(`rejects ${operation} ID reuse from another project (foreign owner: ${foreignOwner}) without changing either project`, async () => {
      const victim = await create(), victimBody = variant(victim, 'A');
      await call('patch', '/projects/'+victim.id, victimBody).expect(200);
      if (foreignOwner) {
        const other = randomUUID();
        await db.userProfile.create({ data: { id: other, displayName: 'Scope victim' } });
        for (const table of ['project', 'rowCounter', 'rowInstruction', 'workSession', 'projectPatternCopy'] as const) {
          await (db[table] as any).updateMany({ where: table === 'project' ? { id: victim.id } : { projectId: victim.id }, data: { ownerId: other } });
        }
      }
      const b = await create(), before = await snapshot(b.id), victimBefore = await snapshot(victim.id);
      let response;
      if (operation === 'instruction') response = await call('post', '/projects/'+b.id+'/row-instructions',
        { ...victimBody.rowCounter.rowInstructions[0], rowCounterId: b.rowCounter.id });
      else if (operation === 'session') response = await call('post', '/projects/'+b.id+'/work-sessions',
        { ...victimBody.workSessions[0], projectId: b.id });
      else response = await call('patch', '/projects/'+b.id,
        { ...b, workSessions: [{ ...victimBody.workSessions[0], projectId: b.id }] });
      evidence.push({ case: 'cross-project-id-'+operation, foreignOwner, status: response.status, response: response.body, victimBefore, victimFinal: await snapshot(victim.id) });
      expect(response.status).toBe(404);
      expect(await snapshot(victim.id)).toEqual(victimBefore);
      expect(await snapshot(b.id)).toEqual(before);
    });
  }

});
