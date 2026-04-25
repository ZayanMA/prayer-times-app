import { promises as fs } from 'node:fs';
import * as path from 'node:path';
import type { TimetableFeed } from './schema.ts';
import { timetableFeedSchema } from './schema.ts';

export interface WriteOptions {
  /** absolute path to server/catalog/v1 (or wherever we host canonical JSON) */
  catalogDir: string;
}

export async function writeCanonical(
  feed: TimetableFeed,
  opts: WriteOptions,
): Promise<string> {
  const validated = timetableFeedSchema.parse(feed);
  const dir = path.join(opts.catalogDir, 'timetables');
  await fs.mkdir(dir, { recursive: true });
  const file = path.join(dir, `${validated.mosqueId}.json`);
  await fs.writeFile(file, JSON.stringify(validated, null, 2), 'utf8');
  return file;
}

export async function readCanonical(
  mosqueId: string,
  opts: WriteOptions,
): Promise<TimetableFeed | null> {
  const file = path.join(opts.catalogDir, 'timetables', `${mosqueId}.json`);
  try {
    const raw = await fs.readFile(file, 'utf8');
    return timetableFeedSchema.parse(JSON.parse(raw));
  } catch (err) {
    if ((err as NodeJS.ErrnoException).code === 'ENOENT') return null;
    throw err;
  }
}
