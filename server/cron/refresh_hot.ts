import type { VercelRequest, VercelResponse } from '@vercel/node';
import * as path from 'node:path';
import { promises as fs } from 'node:fs';
import { mosqueRecordSchema, type MosqueRecord } from '../pipeline/schema.ts';
import { runPipeline } from '../pipeline/pipeline.ts';
import { readCanonical, writeCanonical } from '../pipeline/canonical_writer.ts';

const CATALOG_DIR = path.resolve(process.cwd(), 'catalog', 'v1');
const REPORTS_FILE = path.join(CATALOG_DIR, 'reports.json');

async function loadAllMosques(): Promise<MosqueRecord[]> {
  const file = path.join(CATALOG_DIR, 'mosques.json');
  const raw = await fs.readFile(file, 'utf8');
  const parsed = JSON.parse(raw) as { mosques: unknown[] };
  return parsed.mosques.map((m) => mosqueRecordSchema.parse(m));
}

async function getEscalatedMosqueIds(): Promise<Set<string>> {
  const ids = new Set<string>();
  try {
    const raw = await fs.readFile(REPORTS_FILE, 'utf8');
    const store = JSON.parse(raw) as { reports: Array<{ mosqueId: string; reportedAt: string }> };
    const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString();
    const counts = new Map<string, number>();
    for (const r of store.reports) {
      if (r.reportedAt >= sevenDaysAgo) {
        counts.set(r.mosqueId, (counts.get(r.mosqueId) ?? 0) + 1);
      }
    }
    for (const [id, count] of counts) {
      if (count >= 3) ids.add(id);
    }
  } catch {
    // no reports file yet
  }
  return ids;
}

/** A "hot" mosque: has been accessed recently (proxy: has a timetable file that expires within 2 days). */
async function isHot(mosqueId: string): Promise<boolean> {
  const feed = await readCanonical(mosqueId, { catalogDir: CATALOG_DIR });
  if (!feed) return false;
  const expires = new Date(feed.expiresAt).getTime();
  const twoDays = 2 * 24 * 60 * 60 * 1000;
  return expires < Date.now() + twoDays;
}

export default async function handler(_req: VercelRequest, res: VercelResponse) {
  const enableLlm = process.env.ANTHROPIC_API_KEY !== undefined;
  const mosques = await loadAllMosques();
  const escalated = await getEscalatedMosqueIds();

  const targets: MosqueRecord[] = [];
  for (const mosque of mosques) {
    if (escalated.has(mosque.id) || (await isHot(mosque.id))) {
      targets.push(mosque);
    }
  }

  let success = 0;
  let failure = 0;

  for (const mosque of targets) {
    try {
      const result = await runPipeline(mosque, { enableLlm });
      if (result.ok) {
        await writeCanonical(result.feed, { catalogDir: CATALOG_DIR });
        success++;
      } else {
        failure++;
        console.warn(`[cron] ${mosque.id} failed: ${result.reason}`);
      }
    } catch (err) {
      failure++;
      console.error(`[cron] ${mosque.id} unexpected:`, err);
    }
  }

  res.status(200).json({
    processed: targets.length,
    success,
    failure,
  });
}
