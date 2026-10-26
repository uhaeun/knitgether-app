import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  createReadStream,
  promises as fs,
  type ReadStream,
} from 'node:fs';
import { dirname, resolve } from 'node:path';
import { createHash, randomUUID } from 'node:crypto';

export type StoredPatternPdf = {
  storageKey: string;
  byteSize: number;
};

@Injectable()
export class LocalFileStorageService {
  private readonly rootDirectory: string;
  private readonly logger = new Logger(LocalFileStorageService.name);

  constructor(configService: ConfigService) {
    const configuredRoot = configService.get<string>('FILE_STORAGE_ROOT')?.trim();
    this.rootDirectory = resolve(process.cwd(), configuredRoot || './storage');
  }

  async savePatternPdf(params: {
    ownerId: string;
    patternId: string;
    fileId: string;
    buffer: Buffer;
  }): Promise<StoredPatternPdf> {
    const storageKey = [
      'patterns',
      params.ownerId,
      params.patternId,
      `${params.fileId}.pdf`,
    ].join('/');
    const absolutePath = this.absolutePath(storageKey);

    await fs.mkdir(dirname(absolutePath), { recursive: true });
    await fs.writeFile(absolutePath, params.buffer);

    return {
      storageKey,
      byteSize: params.buffer.byteLength,
    };
  }

  async saveProjectPatternDrawing(params: {
    ownerId: string;
    projectId: string;
    copyId: string;
    buffer: Buffer;
    fileId?: string;
  }): Promise<StoredPatternPdf> {
    const storageKey = [
      'projects',
      params.ownerId,
      params.projectId,
      'pattern-copies',
      params.copyId,
      params.fileId ? `${params.fileId}.pkdrawing` : 'drawing.pkdrawing',
    ].join('/');
    const absolutePath = this.absolutePath(storageKey);

    await this.queueProjectPatternRemoval(storageKey);
    await fs.mkdir(dirname(absolutePath), { recursive: true });
    await fs.writeFile(absolutePath, params.buffer);

    return {
      storageKey,
      byteSize: params.buffer.byteLength,
    };
  }

  async saveProjectPatternCopyPdf(params: {
    ownerId: string;
    projectId: string;
    copyId: string;
    fileId: string;
    buffer: Buffer;
  }): Promise<StoredPatternPdf> {
    const storageKey = [
      'projects',
      params.ownerId,
      params.projectId,
      'pattern-copies',
      params.copyId,
      `${params.fileId}.pdf`,
    ].join('/');
    const absolutePath = this.absolutePath(storageKey);

    // Persist intent before materialization so a crash/write failure is recoverable.
    await this.queueProjectPatternRemoval(storageKey);
    await fs.mkdir(dirname(absolutePath), { recursive: true });
    await fs.writeFile(absolutePath, params.buffer);

    return {
      storageKey,
      byteSize: params.buffer.byteLength,
    };
  }

  async saveProjectProgressPhoto(params: {
    ownerId: string;
    projectId: string;
    photoId: string;
    fileName: string;
    buffer: Buffer;
  }): Promise<StoredPatternPdf> {
    const storageKey = [
      'projects',
      params.ownerId,
      params.projectId,
      'progress-photos',
      params.photoId,
      params.fileName.replace(/[^a-zA-Z0-9._-]/g, '_'),
    ].join('/');
    const absolutePath = this.absolutePath(storageKey);

    await fs.mkdir(dirname(absolutePath), { recursive: true });
    await fs.writeFile(absolutePath, params.buffer);

    return {
      storageKey,
      byteSize: params.buffer.byteLength,
    };
  }

  async saveLibraryItemPhoto(params: {
    ownerId: string;
    itemKind: 'yarns' | 'needles' | 'tools';
    itemId: string;
    fileId: string;
    fileName: string;
    buffer: Buffer;
  }): Promise<StoredPatternPdf> {
    const storageKey = [
      'library',
      params.ownerId,
      params.itemKind,
      params.itemId,
      `${params.fileId}-${params.fileName.replace(/[^a-zA-Z0-9._-]/g, '_')}`,
    ].join('/');
    const absolutePath = this.absolutePath(storageKey);

    await fs.mkdir(dirname(absolutePath), { recursive: true });
    await fs.writeFile(absolutePath, params.buffer);

    return {
      storageKey,
      byteSize: params.buffer.byteLength,
    };
  }

  async readFile(storageKey: string): Promise<Buffer> {
    return fs.readFile(this.absolutePath(storageKey));
  }

  async assertExists(storageKey: string): Promise<void> {
    try {
      await fs.access(this.absolutePath(storageKey));
    } catch {
      throw new NotFoundException({
        code: 'PATTERN_FILE_NOT_FOUND',
        message: 'Pattern file not found.',
      });
    }
  }

  openReadStream(storageKey: string): ReadStream {
    return createReadStream(this.absolutePath(storageKey));
  }

  async remove(storageKey: string | null | undefined): Promise<void> {
    if (!storageKey) {
      return;
    }

    try {
      await fs.unlink(this.absolutePath(storageKey));
    } catch (error) {
      const nodeError = error as NodeJS.ErrnoException;
      if (nodeError.code !== 'ENOENT') {
        throw error;
      }
    }
  }

  private removalMarker(storageKey: string): string {
    this.absolutePath(storageKey);
    if (!/^projects\/[^/]+\/[^/]+\/pattern-copies\/[^/]+\/[^/]+$/.test(storageKey)) {
      throw new Error('Not a project pattern file key.');
    }
    const digest = createHash('sha256').update(storageKey).digest('hex');
    return resolve(this.rootDirectory, '.pattern-cleanup', digest + '.json');
  }

  async queueProjectPatternRemoval(storageKey: string): Promise<void> {
    const marker = this.removalMarker(storageKey);
    await fs.mkdir(dirname(marker), { recursive: true });
    const temporary = marker + '.' + randomUUID() + '.tmp';
    try {
      await fs.writeFile(temporary, JSON.stringify({ storageKey, queuedAt: Date.now() }), { flag: 'wx', flush: true });
      await fs.rename(temporary, marker);
    } finally {
      await fs.rm(temporary, { force: true });
    }
  }

  async pendingProjectPatternRemovals(before: number): Promise<string[]> {
    const directory = resolve(this.rootDirectory, '.pattern-cleanup');
    let names: string[];
    try { names = await fs.readdir(directory); }
    catch (error) {
      if ((error as NodeJS.ErrnoException).code === 'ENOENT') return [];
      throw error;
    }
    const keys: string[] = [];
    for (const name of names) {
      if (!/^[a-f0-9]{64}\.json$/.test(name)) continue;
      try {
        const entry = JSON.parse(await fs.readFile(resolve(directory, name), 'utf8'));
        if (typeof entry.storageKey === 'string' && Number.isFinite(entry.queuedAt) && entry.queuedAt <= before &&
            this.removalMarker(entry.storageKey) === resolve(directory, name)) keys.push(entry.storageKey);
      } catch (error) {
        // One damaged marker must not prevent unrelated cleanup jobs.
        this.logger.warn(`Cannot read pattern cleanup marker ${name}: ${String(error)}`);
      }
    }
    return keys;
  }

  async completeProjectPatternRemoval(storageKey: string): Promise<void> {
    await fs.rm(this.removalMarker(storageKey), { force: true });
  }

  private absolutePath(storageKey: string): string {
    const absolutePath = resolve(this.rootDirectory, storageKey);
    const rootPrefix = `${this.rootDirectory}/`;

    if (!absolutePath.startsWith(rootPrefix)) {
      throw new Error('Invalid storage key.');
    }

    return absolutePath;
  }
}
