import * as cheerio from 'cheerio';
import type { DayTimetable, MosqueRecord, TimetableFeed } from '../schema.ts';

const TIME_RE = /\b([01]?\d|2[0-3])[:.]([0-5]\d)\b(?:\s*([AP]M))?/gi;

export async function fetchHtmlTimetable(
  mosque: MosqueRecord,
  opts: { fetchImpl?: typeof fetch } = {},
): Promise<TimetableFeed> {
  const sourceUrl = mosque.sourceUrl || mosque.websiteUrl;
  if (!sourceUrl) {
    throw new Error('html-table: no source URL');
  }

  const f = opts.fetchImpl ?? fetch;
  const res = await f(sourceUrl, {
    headers: { 'User-Agent': 'prayer-times-app/1.0 (+https://example.com)' },
    redirect: 'follow',
  });
  if (!res.ok) {
    throw new Error(`html-table: HTTP ${res.status} for ${sourceUrl}`);
  }

  const html = await res.text();
  const days = parseHtmlTimetable(html);
  if (days.length === 0) {
    throw new Error('html-table: no timetable rows found');
  }

  const fetchedAt = new Date();
  const expiresAt = new Date(fetchedAt.getTime() + 12 * 60 * 60 * 1000);

  return {
    mosqueId: mosque.id,
    sourceKind: 'webTable',
    fetchedAt: fetchedAt.toISOString(),
    expiresAt: expiresAt.toISOString(),
    validFrom: days[0]!.date,
    validTo: days[days.length - 1]!.date,
    confidence: 'published',
    lane: 'html-table',
    days,
  };
}

export function parseHtmlTimetable(html: string): DayTimetable[] {
  const $ = cheerio.load(html);
  const tableDays = parseRows($);
  if (tableDays.length > 0) return tableDays;
  const daily = parseSingleDay($);
  return daily ? [daily] : [];
}

function parseRows($: cheerio.CheerioAPI): DayTimetable[] {
  const days: DayTimetable[] = [];

  for (const row of $('tr').toArray()) {
    const cells = $(row)
      .children('td,th')
      .toArray()
      .map((cell) => clean($(cell).text()))
      .filter(Boolean);
    if (cells.length < 2) continue;

    const date = parseDate(cells.slice(0, 4).join(' ')) ?? parseDate(cells[0]!);
    if (!date) continue;

    const times = cells.flatMap(extractTimes);
    if (times.length < 6) continue;

    days.push({
      date,
      fajr: times[0]!,
      sunrise: times[1]!,
      dhuhr: times[2]!,
      asr: times[3]!,
      maghrib: times[4]!,
      isha: times[5]!,
    });
  }

  return sortUnique(days);
}

function parseSingleDay($: cheerio.CheerioAPI): DayTimetable | null {
  const lines = $.root()
    .text()
    .split(/\n+/)
    .map(clean)
    .filter(Boolean);
  const dateLine = lines.find((line) => /\b\d{4}-\d{2}-\d{2}\b/.test(line));
  const date = dateLine?.match(/\b\d{4}-\d{2}-\d{2}\b/)?.[0];
  if (!date) return null;

  const prayerLines = new Map<string, string[]>();
  for (const line of lines) {
    const match = /^(Fajr|Sunrise|Zuhr|Dhuhr|Asr|Maghrib|Isha)\b/i.exec(line);
    if (!match) continue;
    const key = normalPrayerName(match[1]!);
    const times = extractTimes(line);
    if (times.length > 0) prayerLines.set(key, times);
  }

  const fajr = prayerLines.get('fajr')?.[0];
  const sunrise = prayerLines.get('sunrise')?.[0];
  const dhuhr = prayerLines.get('dhuhr')?.[0];
  const asr = prayerLines.get('asr')?.[0];
  const maghrib = prayerLines.get('maghrib')?.[0];
  const isha = prayerLines.get('isha')?.[0];
  if (!fajr || !sunrise || !dhuhr || !asr || !maghrib || !isha) {
    return null;
  }

  return {
    date,
    fajr,
    sunrise,
    dhuhr,
    asr,
    maghrib,
    isha,
    fajrJamaat: prayerLines.get('fajr')?.[1],
    dhuhrJamaat: prayerLines.get('dhuhr')?.[1],
    asrJamaat: prayerLines.get('asr')?.[1],
    maghribJamaat: prayerLines.get('maghrib')?.[1],
    ishaJamaat: prayerLines.get('isha')?.[1],
  };
}

function extractTimes(text: string): string[] {
  return Array.from(text.matchAll(TIME_RE), (match) =>
    normalizeTime(match[1]!, match[2]!, match[3]),
  );
}

function normalizeTime(hourRaw: string, minute: string, marker?: string): string {
  let hour = parseInt(hourRaw, 10);
  if (marker) {
    const ampm = marker.toUpperCase();
    if (ampm === 'PM' && hour < 12) hour += 12;
    if (ampm === 'AM' && hour === 12) hour = 0;
  }
  return `${hour.toString().padStart(2, '0')}:${minute}`;
}

function parseDate(raw: string): string | null {
  const text = clean(raw).replace(/\b(\d+)(st|nd|rd|th)\b/gi, '$1');
  const directIso = text.match(/\b\d{4}-\d{2}-\d{2}\b/)?.[0];
  if (directIso) return directIso;

  const parsed = new Date(text);
  if (!Number.isNaN(parsed.getTime())) return isoDate(parsed);

  const withoutWeekday = text.replace(/^[A-Za-z]+,\s*/, '');
  const parsedWithoutWeekday = new Date(withoutWeekday);
  if (!Number.isNaN(parsedWithoutWeekday.getTime())) {
    return isoDate(parsedWithoutWeekday);
  }

  return null;
}

function isoDate(date: Date): string {
  const yyyy = date.getUTCFullYear().toString().padStart(4, '0');
  const mm = (date.getUTCMonth() + 1).toString().padStart(2, '0');
  const dd = date.getUTCDate().toString().padStart(2, '0');
  return `${yyyy}-${mm}-${dd}`;
}

function sortUnique(days: DayTimetable[]): DayTimetable[] {
  const byDate = new Map<string, DayTimetable>();
  for (const day of days) byDate.set(day.date, day);
  return Array.from(byDate.values()).sort((a, b) => a.date.localeCompare(b.date));
}

function normalPrayerName(value: string): string {
  const lower = value.toLowerCase();
  if (lower === 'zuhr') return 'dhuhr';
  return lower;
}

function clean(value: string): string {
  return value.replace(/\u00a0/g, ' ').replace(/\s+/g, ' ').trim();
}
