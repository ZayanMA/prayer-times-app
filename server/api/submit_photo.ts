import type { VercelRequest, VercelResponse } from '@vercel/node';
import * as path from 'node:path';
import { promises as fs } from 'node:fs';
import { mosqueRecordSchema } from '../pipeline/schema.ts';
import { extractFromPhoto, type ImageMediaType } from '../pipeline/vision/llm_photo.ts';
import { validateAstronomical } from '../pipeline/validators/astronomical.ts';
import { readCanonical, writeCanonical } from '../pipeline/canonical_writer.ts';

const CATALOG_DIR = path.resolve(process.cwd(), 'catalog', 'v1');
const MAX_BODY_BYTES = 10 * 1024 * 1024; // 10 MB

const ALLOWED_MEDIA_TYPES: ImageMediaType[] = [
  'image/jpeg',
  'image/png',
  'image/gif',
  'image/webp',
];

async function loadMosque(id: string) {
  const file = path.join(CATALOG_DIR, 'mosques.json');
  const raw = await fs.readFile(file, 'utf8');
  const parsed = JSON.parse(raw) as { mosques: unknown[] };
  const found = parsed.mosques.find((m) => (m as { id: string }).id === id);
  if (!found) return null;
  return mosqueRecordSchema.parse(found);
}

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method !== 'POST') {
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }

  const apiKey = process.env.ANTHROPIC_API_KEY;
  if (!apiKey) {
    res.status(503).json({ error: 'Photo submission unavailable' });
    return;
  }

  let body: { mosqueId?: unknown; imageBase64?: unknown; mediaType?: unknown };
  try {
    body = req.body as typeof body;
  } catch {
    res.status(400).json({ error: 'Invalid JSON body' });
    return;
  }

  const { mosqueId, imageBase64, mediaType } = body;

  if (typeof mosqueId !== 'string' || !mosqueId) {
    res.status(400).json({ error: 'mosqueId required' });
    return;
  }
  if (typeof imageBase64 !== 'string' || !imageBase64) {
    res.status(400).json({ error: 'imageBase64 required' });
    return;
  }
  if (typeof mediaType !== 'string' || !ALLOWED_MEDIA_TYPES.includes(mediaType as ImageMediaType)) {
    res.status(400).json({ error: `mediaType must be one of: ${ALLOWED_MEDIA_TYPES.join(', ')}` });
    return;
  }

  // Rough size guard: base64 expands by ~33%
  if (imageBase64.length > MAX_BODY_BYTES * 1.4) {
    res.status(413).json({ error: 'Image too large (max 10 MB)' });
    return;
  }

  const mosque = await loadMosque(mosqueId);
  if (!mosque) {
    res.status(404).json({ error: 'Mosque not found' });
    return;
  }

  let feed;
  try {
    feed = await extractFromPhoto(mosque, imageBase64, mediaType as ImageMediaType, { anthropicApiKey: apiKey });
  } catch (err) {
    res.status(422).json({ error: (err as Error).message });
    return;
  }

  // Validate against astronomical bounds if coordinates available
  if (mosque.latitude != null && mosque.longitude != null) {
    const report = validateAstronomical(feed.days, {
      latitude: mosque.latitude,
      longitude: mosque.longitude,
      maxDriftMinutes: 60,
    });
    if (!report.ok) {
      res.status(422).json({
        error: 'Extracted times failed astronomical validation',
        issues: report.issues.slice(0, 5),
      });
      return;
    }
  }

  // Check if we already have a verified/published feed — don't downgrade confidence
  const existing = await readCanonical(mosqueId, { catalogDir: CATALOG_DIR });
  if (existing && (existing.confidence === 'verified' || existing.confidence === 'published')) {
    // Keep the existing high-confidence feed; record submission but don't overwrite
    res.status(200).json({
      status: 'noted',
      message: 'A published timetable already exists for this mosque. Your submission has been noted.',
    });
    return;
  }

  await writeCanonical(feed, { catalogDir: CATALOG_DIR });

  res.status(200).json({
    status: 'accepted',
    mosqueId,
    days: feed.days.length,
    confidence: feed.confidence,
    validFrom: feed.validFrom,
    validTo: feed.validTo,
  });
}
