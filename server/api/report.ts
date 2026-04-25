import type { VercelRequest, VercelResponse } from '@vercel/node';
import * as path from 'node:path';
import { promises as fs } from 'node:fs';

const CATALOG_DIR = path.resolve(process.cwd(), 'catalog', 'v1');
const REPORTS_FILE = path.join(CATALOG_DIR, 'reports.json');

interface ReportEntry {
  mosqueId: string;
  date: string;
  lane: string;
  reportedAt: string;
  userAgent?: string;
}

interface ReportsStore {
  reports: ReportEntry[];
}

async function loadReports(): Promise<ReportsStore> {
  try {
    const raw = await fs.readFile(REPORTS_FILE, 'utf8');
    return JSON.parse(raw) as ReportsStore;
  } catch {
    return { reports: [] };
  }
}

async function saveReports(store: ReportsStore): Promise<void> {
  await fs.mkdir(path.dirname(REPORTS_FILE), { recursive: true });
  await fs.writeFile(REPORTS_FILE, JSON.stringify(store, null, 2), 'utf8');
}

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method !== 'POST') {
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }

  let body: { mosqueId?: unknown; date?: unknown; lane?: unknown };
  try {
    body = req.body as typeof body;
  } catch {
    res.status(400).json({ error: 'Invalid JSON body' });
    return;
  }

  const { mosqueId, date, lane } = body;

  if (typeof mosqueId !== 'string' || !mosqueId) {
    res.status(400).json({ error: 'mosqueId required' });
    return;
  }
  if (date !== undefined && typeof date !== 'string') {
    res.status(400).json({ error: 'date must be a string (YYYY-MM-DD)' });
    return;
  }
  if (lane !== undefined && typeof lane !== 'string') {
    res.status(400).json({ error: 'lane must be a string' });
    return;
  }

  const entry: ReportEntry = {
    mosqueId,
    date: typeof date === 'string' ? date : new Date().toISOString().slice(0, 10),
    lane: typeof lane === 'string' ? lane : 'unknown',
    reportedAt: new Date().toISOString(),
    userAgent: req.headers['user-agent'],
  };

  const store = await loadReports();
  store.reports.push(entry);

  // Check escalation threshold: 3 reports for same mosque in last 7 days
  const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString();
  const recentForMosque = store.reports.filter(
    (r) => r.mosqueId === mosqueId && r.reportedAt >= sevenDaysAgo,
  );

  await saveReports(store);

  const shouldEscalate = recentForMosque.length >= 3;

  if (shouldEscalate) {
    // In a production system this would enqueue the mosque for pipeline re-run.
    // For now we log it — the nightly cron will pick it up.
    console.log(`[report] Escalation threshold reached for mosque ${mosqueId} (${recentForMosque.length} reports in 7 days)`);
  }

  res.status(200).json({
    status: 'received',
    mosqueId,
    recentReports: recentForMosque.length,
    escalated: shouldEscalate,
  });
}
