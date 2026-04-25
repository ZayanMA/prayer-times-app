import {
  Coordinates,
  CalculationMethod,
  PrayerTimes,
  Madhab,
} from 'adhan';
import type { DayTimetable } from '../schema.ts';
import { parseHhMm } from '../util/dates.ts';

export interface ValidationIssue {
  date: string;
  prayer: string;
  extracted: string;
  computed: string;
  diffMinutes: number;
}

export interface ValidationReport {
  ok: boolean;
  issues: ValidationIssue[];
}

const MAX_DRIFT_MINUTES = 60;

const PRAYERS = ['fajr', 'sunrise', 'dhuhr', 'asr', 'maghrib', 'isha'] as const;
type PrayerName = (typeof PRAYERS)[number];

export interface ValidationOptions {
  latitude: number;
  longitude: number;
  madhab?: 'standard' | 'hanafi';
  calculationMethod?: 'muslimWorldLeague' | 'egyptian' | 'karachi' | 'ummAlQura';
  maxDriftMinutes?: number;
}

export function validateAstronomical(
  days: DayTimetable[],
  opts: ValidationOptions,
): ValidationReport {
  const issues: ValidationIssue[] = [];
  const coords = new Coordinates(opts.latitude, opts.longitude);
  const params = methodFor(opts.calculationMethod ?? 'muslimWorldLeague');
  params.madhab =
    (opts.madhab ?? 'standard') === 'hanafi' ? Madhab.Hanafi : Madhab.Shafi;
  const drift = opts.maxDriftMinutes ?? MAX_DRIFT_MINUTES;

  for (const day of days) {
    const [yyyy, mm, dd] = day.date.split('-').map((s) => parseInt(s, 10));
    const dateObj = new Date(Date.UTC(yyyy!, mm! - 1, dd!));
    const computed = new PrayerTimes(coords, dateObj, params);

    for (const prayer of PRAYERS) {
      const extractedRaw = day[prayer];
      if (!extractedRaw) continue;
      const { hour, minute } = parseHhMm(extractedRaw);
      // Treat extracted time as local UK time (BST/GMT inferred from date).
      const extractedDate = new Date(
        Date.UTC(yyyy!, mm! - 1, dd!, hour, minute),
      );
      const computedDate = readPrayer(computed, prayer);
      const diffMinutes = Math.abs(
        (extractedDate.getTime() - computedDate.getTime()) / 60000,
      );
      if (diffMinutes > drift) {
        issues.push({
          date: day.date,
          prayer,
          extracted: extractedRaw,
          computed: formatTime(computedDate),
          diffMinutes: Math.round(diffMinutes),
        });
      }
    }
  }

  return { ok: issues.length === 0, issues };
}

function methodFor(method: NonNullable<ValidationOptions['calculationMethod']>) {
  switch (method) {
    case 'egyptian':
      return CalculationMethod.Egyptian();
    case 'karachi':
      return CalculationMethod.Karachi();
    case 'ummAlQura':
      return CalculationMethod.UmmAlQura();
    case 'muslimWorldLeague':
    default:
      return CalculationMethod.MuslimWorldLeague();
  }
}

function readPrayer(p: PrayerTimes, name: PrayerName): Date {
  switch (name) {
    case 'fajr':
      return p.fajr;
    case 'sunrise':
      return p.sunrise;
    case 'dhuhr':
      return p.dhuhr;
    case 'asr':
      return p.asr;
    case 'maghrib':
      return p.maghrib;
    case 'isha':
      return p.isha;
  }
}

function formatTime(d: Date): string {
  const hh = d.getUTCHours().toString().padStart(2, '0');
  const mm = d.getUTCMinutes().toString().padStart(2, '0');
  return `${hh}:${mm}`;
}
