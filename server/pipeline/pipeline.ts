import { fetchMawaqitTimetable, type MawaqitDetection } from './extractors/mawaqit.ts';
import { fetchHtmlTimetable } from './extractors/html_table.ts';
import { extractWithLlm } from './extractors/llm_html.ts';
import { detectPlatform } from './platform_detector.ts';
import {
  validateAstronomical,
  type ValidationOptions,
  type ValidationReport,
} from './validators/astronomical.ts';
import type { TimetableFeed, MosqueRecord } from './schema.ts';

export interface PipelineSuccess {
  ok: true;
  feed: TimetableFeed;
  validation: ValidationReport;
  lane: 'mawaqit' | 'html-table' | 'llm-html' | 'photo' | 'manual';
}

export interface PipelineFailure {
  ok: false;
  reason: string;
  attempts: Array<{ lane: string; error: string }>;
}

export type PipelineResult = PipelineSuccess | PipelineFailure;

export interface RunOptions {
  fetchImpl?: typeof fetch;
  enableLlm?: boolean;
  anthropicApiKey?: string;
  /** allow callers (tests, fixtures) to skip the network detection step */
  forceLane?: { lane: 'mawaqit'; detection: MawaqitDetection };
}

const VALIDATION_DRIFT_MINUTES = 60;

export async function runPipeline(
  mosque: MosqueRecord,
  opts: RunOptions = {},
): Promise<PipelineResult> {
  const attempts: Array<{ lane: string; error: string }> = [];

  // Lane 1 — aggregators
  const platform =
    opts.forceLane ??
    (mosque.websiteUrl
      ? await detectPlatform(mosque.websiteUrl, { fetchImpl: opts.fetchImpl })
      : { lane: 'unknown' as const });

  if (platform.lane === 'mawaqit') {
    try {
      const feed = await fetchMawaqitTimetable(mosque.id, platform.detection, {
        fetchImpl: opts.fetchImpl,
      });
      const validation = validateOrEmpty(feed, mosque);
      if (validation.ok) {
        return { ok: true, feed, validation, lane: 'mawaqit' };
      }
      attempts.push({
        lane: 'mawaqit',
        error: `validation failed: ${describeIssues(validation)}`,
      });
    } catch (err) {
      attempts.push({ lane: 'mawaqit', error: (err as Error).message });
    }
  }

  // Lane 2 — deterministic HTML table/current-day extractor
  if (mosque.sourceKind === 'webTable' || mosque.sourceUrl) {
    try {
      const feed = await fetchHtmlTimetable(mosque, {
        fetchImpl: opts.fetchImpl,
      });
      const validation = validateOrEmpty(feed, mosque);
      if (validation.ok) {
        return { ok: true, feed, validation, lane: 'html-table' };
      }
      attempts.push({
        lane: 'html-table',
        error: `validation failed: ${describeIssues(validation)}`,
      });
    } catch (err) {
      attempts.push({ lane: 'html-table', error: (err as Error).message });
    }
  }

  // Lane 3 — universal LLM HTML extractor
  if (opts.enableLlm && mosque.websiteUrl) {
    try {
      const feed = await extractWithLlm(mosque, {
        fetchImpl: opts.fetchImpl,
        anthropicApiKey: opts.anthropicApiKey,
      });
      const validation = validateOrEmpty(feed, mosque);
      if (validation.ok) {
        return { ok: true, feed, validation, lane: 'llm-html' };
      }
      attempts.push({
        lane: 'llm-html',
        error: `validation failed: ${describeIssues(validation)}`,
      });
    } catch (err) {
      attempts.push({ lane: 'llm-html', error: (err as Error).message });
    }
  }

  return {
    ok: false,
    reason:
      attempts.length === 0
        ? 'no extractor matched this mosque'
        : 'all extractors failed',
    attempts,
  };
}

function validateOrEmpty(
  feed: TimetableFeed,
  mosque: MosqueRecord,
): ValidationReport {
  if (mosque.latitude == null || mosque.longitude == null) {
    return { ok: true, issues: [] };
  }
  const validationOpts: ValidationOptions = {
    latitude: mosque.latitude,
    longitude: mosque.longitude,
    maxDriftMinutes: VALIDATION_DRIFT_MINUTES,
  };
  return validateAstronomical(feed.days, validationOpts);
}

function describeIssues(report: ValidationReport): string {
  return report.issues
    .slice(0, 3)
    .map(
      (issue) =>
        `${issue.date}/${issue.prayer} extracted=${issue.extracted} computed=${issue.computed} (${issue.diffMinutes}m off)`,
    )
    .join('; ');
}
