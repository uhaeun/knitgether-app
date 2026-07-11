import { Injectable, NotFoundException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  createReadStream,
  promises as fs,
  type ReadStream,
} from 'node:fs';
import { dirname, resolve } from 'node:path';

export type StoredPatternPdf = {
  storageKey: string;
  byteSize: number;
};

@Injectable()
export class LocalFileStorageService {
  private readonly rootDirectory: string;

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
  }): Promise<StoredPatternPdf> {
    const storageKey = [
      'projects',
      params.ownerId,
      params.projectId,
      'pattern-copies',
      params.copyId,
      'drawing.pkdrawing',
    ].join('/');
    const absolutePath = this.absolutePath(storageKey);

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

  private absolutePath(storageKey: string): string {
    const absolutePath = resolve(this.rootDirectory, storageKey);
    const rootPrefix = `${this.rootDirectory}/`;

    if (!absolutePath.startsWith(rootPrefix)) {
      throw new Error('Invalid storage key.');
    }

    return absolutePath;
  }
}
