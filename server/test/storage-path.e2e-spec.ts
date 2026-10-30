import { ConfigService } from '@nestjs/config';
import { promises as fs } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, posix, win32 } from 'node:path';
import { LocalFileStorageService } from '../src/storage/local-file-storage.service';
import { resolveStoragePath } from '../src/storage/storage-path';

describe.each([
  ['POSIX', posix, '/qa/storage'],
  ['Windows drive', win32, 'C:\\qa\\storage'],
  ['Windows UNC', win32, '\\\\fileserver\\share\\storage'],
] as const)('%s storage boundary', (_name, paths, root) => {
  it.each(['projects/owner/project/pattern.pdf', 'projects/owner/도안.pdf', '..inside/file.pdf'])
  ('accepts a file within the configured root: %s', key => {
    expect(resolveStoragePath(root, key, paths)).toBe(paths.resolve(root, key));
  });

  it.each(['', '.', '..', '../outside.pdf', '../storage-other/file.pdf', '../../outside.pdf'])
  ('rejects a directory or escape outside the root: %s', key => {
    expect(() => resolveStoragePath(root, key, paths)).toThrow('Invalid storage key.');
  });
});

describe('Windows-specific storage paths', () => {
  it.each(['..\\outside.pdf', 'D:\\outside.pdf', '\\\\other\\share\\outside.pdf', 'C:\\qa\\storage-other\\file.pdf'])
  ('rejects an escape or another volume: %s', key => {
    expect(() => resolveStoragePath('C:\\qa\\storage', key, win32)).toThrow('Invalid storage key.');
  });
});

describe('Local file storage on the host filesystem', () => {
  let root: string;
  let service: LocalFileStorageService;
  beforeEach(async () => {
    root = await fs.mkdtemp(join(tmpdir(), 'knitgether-storage-path-'));
    service = new LocalFileStorageService(new ConfigService({ FILE_STORAGE_ROOT: root }));
  });
  afterEach(async () => { await fs.rm(root, { recursive: true, force: true }); });

  it('round-trips PDF bytes, checks presence, and removes only the stored file', async () => {
    const bytes = Buffer.from('%PDF-1.4\nQA storage boundary');
    const stored = await service.savePatternPdf({ ownerId: 'owner', patternId: 'pattern', fileId: 'file', buffer: bytes });
    await expect(service.assertExists(stored.storageKey)).resolves.toBeUndefined();
    expect(await service.readFile(stored.storageKey)).toEqual(bytes);
    await service.remove(stored.storageKey);
    await expect(service.assertExists(stored.storageKey)).rejects.toThrow();
  });

  it('does not read or delete a file beside the storage root', async () => {
    const outside = root + '-outside.pdf';
    await fs.writeFile(outside, 'must survive');
    try {
      await expect(service.readFile('../' + outside.split(/[\\/]/).pop())).rejects.toThrow('Invalid storage key.');
      await expect(service.remove('../' + outside.split(/[\\/]/).pop())).rejects.toThrow('Invalid storage key.');
      expect(await fs.readFile(outside, 'utf8')).toBe('must survive');
    } finally { await fs.rm(outside, { force: true }); }
  });
});
