import type { VercelRequest, VercelResponse } from '@vercel/node';
import * as path from 'node:path';
import { promises as fs } from 'node:fs';
import { mosqueRecordSchema } from '../../pipeline/schema.ts';
import { runPipeline } from '../../pipeline/pipeline.ts';
import { readCanonical, writeCanonical } from '../../pipeline/canonical_writer.ts';

const CATALOG_DIR = path.resolve(process.cwd(), 'catalog', 'v1');

async function loadMosque(id: string) {
  const file = path.join(CATALOG_DIR, 'mosques.json');
  const raw = await fs.readFile(file, 'utf8');
  const parsed = JSON.parse(raw) as { mosques: unknown[] };
  const found = parsed.mosques.find((m) => (m as { id: string }).id === id);
  if (!found) return null;
  return mosqueRecordSchema.parse(found);
}

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method !== 'GET') {
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }

  const id = req.query['id'];
  if (typeof id !== 'string' || !id) {
    res.status(400).json({ error: 'Missing mosque id' });
    return;
  }

  // Serve existing canonical file if still fresh
  const existing = await readCanonical(id, { catalogDir: CATALOG_DIR });
  if (existing) {
    const expires = new Date(existing.expiresAt).getTime();
    if (expires > Date.now()) {
      res.setHeader('Cache-Control', 'public, max-age=21600, stale-while-revalidate=86400');
      res.setHeader('Content-Type', 'application/json');
      res.status(200).json(existing);
      return;
    }
  }

  const mosque = await loadMosque(id);
  if (!mosque) {
    res.status(404).json({ error: 'Mosque not found' });
    return;
  }

  const enableLlm = process.env.ANTHROPIC_API_KEY !== undefined;
  const result = await runPipeline(mosque, { enableLlm });

  if (!result.ok) {
    // Serve stale data rather than a hard 404 if we have it
    if (existing) {
      res.setHeader('Cache-Control', 'public, max-age=3600, stale-while-revalidate=86400');
      res.setHeader('Content-Type', 'application/json');
      res.status(200).json(existing);
      return;
    }
    res.status(404).json({ error: 'Timetable unavailable', attempts: result.attempts });
    return;
  }

  await writeCanonical(result.feed, { catalogDir: CATALOG_DIR });
  res.setHeader('Cache-Control', 'public, max-age=21600, stale-while-revalidate=86400');
  res.setHeader('Content-Type', 'application/json');
  res.status(200).json(result.feed);
}
