import * as cheerio from 'cheerio';
import type { DayTimetable, TimetableFeed } from '../schema.ts';
import { isoDate } from '../util/dates.ts';

export interface MawaqitDetection {
  slug: string;
  url: string;
}

const MAWAQIT_HOST_PATTERN =
  /https?:\/\/(?:www\.)?mawaqit\.net\/(?:[a-z]{2}\/)?([a-z0-9-]+)/i;

/**
 * Detect a Mawaqit slug embedded on a mosque's homepage.
 * Looks at iframe src and anchor href first, then falls back to any URL match
 * in the document.
 */
export function detectMawaqitInHtml(
  html: string,
  baseUrl?: string,
): MawaqitDetection | null {
  const $ = cheerio.load(html);

  // 1. iframes
  for (const el of $('iframe').toArray()) {
    const src = $(el).attr('src');
    if (!src) continue;
    const hit = matchMawaqit(src);
    if (hit) return hit;
  }

  // 2. anchors
  for (const el of $('a[href*="mawaqit"]').toArray()) {
    const href = $(el).attr('href');
    if (!href) continue;
    const hit = matchMawaqit(href);
    if (hit) return hit;
  }

  // 3. raw text fallback
  const fallbackHit = matchMawaqit(html);
  if (fallbackHit) return fallbackHit;

  // 4. baseUrl itself if it points at mawaqit.net (rare but handle)
  if (baseUrl) {
    const hit = matchMawaqit(baseUrl);
    if (hit) return hit;
  }

  return null;
}

function matchMawaqit(input: string): MawaqitDetection | null {
  const m = MAWAQIT_HOST_PATTERN.exec(input);
  if (!m) return null;
  const slug = m[1]!;
  // exclude well-known non-mosque path segments
  if (
    [
      'find',
      'login',
      'register',
      'mosque',
      'about',
      'contact',
      'api',
      'static',
      'assets',
      'images',
      'js',
      'css',
    ].includes(slug)
  ) {
    return null;
  }
  return {
    slug,
    url: `https://mawaqit.net/en/${slug}`,
  };
}

interface MawaqitConfData {
  name?: string;
  latitude?: number;
  longitude?: number;
  /** today only: [fajr, dhuhr, asr, maghrib, isha] */
  times?: unknown;
  /** optional sunrise for today */
  shuruq?: unknown;
  /** 12-month array, keys "1".."31" → array of 6 times */
  calendar?: unknown;
}

const CONFDATA_PATTERN = /var\s+confData\s*=\s*(\{[\s\S]*?\});\s*\n/;

function extractConfData(html: string): MawaqitConfData {
  const match = CONFDATA_PATTERN.exec(html);
  if (!match) {
    throw new Error('mawaqit: confData not found on page');
  }
  const literal = match[1]!;
  // Mawaqit emits this as a JS object literal (JSON-shaped). Evaluate safely.
  try {
    // eslint-disable-next-line @typescript-eslint/no-implied-eval, no-new-func
    const fn = new Function(`return (${literal});`);
    return fn() as MawaqitConfData;
  } catch (err) {
    throw new Error(`mawaqit: failed to parse confData: ${(err as Error).message}`);
  }
}

export interface MawaqitFetchOptions {
  fetchImpl?: typeof fetch;
}

export async function fetchMawaqitTimetable(
  mosqueId: string,
  detection: MawaqitDetection,
  opts: MawaqitFetchOptions = {},
): Promise<TimetableFeed> {
  const f = opts.fetchImpl ?? fetch;
  const res = await f(detection.url, {
    headers: { 'User-Agent': 'prayer-times-app/1.0 (+https://example.com)' },
  });
  if (!res.ok) {
    throw new Error(`mawaqit: HTTP ${res.status} for ${detection.url}`);
  }
  const html = await res.text();
  const confData = extractConfData(html);

  const days = mawaqitConfDataToDays(confData);
  if (days.length === 0) {
    throw new Error('mawaqit: calendar returned no days');
  }

  const fetchedAt = new Date();
  const expiresAt = new Date(fetchedAt.getTime() + 24 * 60 * 60 * 1000);

  return {
    mosqueId,
    sourceKind: 'remoteCanonical',
    fetchedAt: fetchedAt.toISOString(),
    expiresAt: expiresAt.toISOString(),
    validFrom: days[0]!.date,
    validTo: days[days.length - 1]!.date,
    confidence: 'published',
    lane: `mawaqit:${detection.slug}`,
    days,
  };
}

export function mawaqitConfDataToDays(conf: MawaqitConfData): DayTimetable[] {
  const calendar = Array.isArray(conf.calendar) ? conf.calendar : [];
  const year = new Date().getUTCFullYear();
  const days: DayTimetable[] = [];

  for (let monthIdx = 0; monthIdx < calendar.length; monthIdx++) {
    const monthEntry = calendar[monthIdx];
    if (!monthEntry || typeof monthEntry !== 'object') continue;
    const monthMap = monthEntry as Record<string, unknown>;

    for (const [dayKey, value] of Object.entries(monthMap)) {
      const dayNum = parseInt(dayKey, 10);
      if (!Number.isFinite(dayNum)) continue;
      if (!Array.isArray(value)) continue;

      // Mawaqit calendar entries: [fajr, shuruq, dhuhr, asr, maghrib, isha]
      const [fajr, shuruq, dhuhr, asr, maghrib, isha] = value as unknown[];
      if (
        typeof fajr !== 'string' ||
        typeof shuruq !== 'string' ||
        typeof dhuhr !== 'string' ||
        typeof asr !== 'string' ||
        typeof maghrib !== 'string' ||
        typeof isha !== 'string'
      ) {
        continue;
      }

      const date = new Date(Date.UTC(year, monthIdx, dayNum));
      days.push({
        date: isoDate(date),
        fajr: normalize(fajr),
        sunrise: normalize(shuruq),
        dhuhr: normalize(dhuhr),
        asr: normalize(asr),
        maghrib: normalize(maghrib),
        isha: normalize(isha),
      });
    }
  }

  days.sort((a, b) => a.date.localeCompare(b.date));
  return days;
}

function normalize(time: string): string {
  // "4:30" → "04:30"
  const m = /^(\d{1,2}):(\d{2})$/.exec(time.trim());
  if (!m) return time.trim();
  const hh = m[1]!.padStart(2, '0');
  return `${hh}:${m[2]}`;
}
