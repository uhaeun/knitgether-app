import * as path from 'node:path';

type Paths = Pick<typeof path, 'resolve' | 'relative' | 'isAbsolute' | 'sep'>;

/** Resolve a storage key within a local root using the host's path rules. */
export function resolveStoragePath(root: string, key: string, paths: Paths = path): string {
  const absolute = paths.resolve(root, key);
  const relative = paths.relative(root, absolute);
  if (!relative || relative === '..' || relative.startsWith(`..${paths.sep}`) || paths.isAbsolute(relative)) {
    throw new Error('Invalid storage key.');
  }
  return absolute;
}
