import { detectMawaqitInHtml, type MawaqitDetection } from './extractors/mawaqit.ts';

export type PlatformDetection =
  | { lane: 'mawaqit'; detection: MawaqitDetection }
  | { lane: 'unknown' };

/**
 * Inspect a mosque homepage and decide which Lane 1 adapter to use.
 * Falls back to "unknown" when no aggregator pattern is found.
 */
export async function detectPlatform(
  websiteUrl: string,
  opts: { fetchImpl?: typeof fetch } = {},
): Promise<PlatformDetection> {
  const f = opts.fetchImpl ?? fetch;
  let html: string;
  try {
    const res = await f(websiteUrl, {
      headers: { 'User-Agent': 'prayer-times-app/1.0 (+https://example.com)' },
      redirect: 'follow',
    });
    if (!res.ok) return { lane: 'unknown' };
    html = await res.text();
  } catch {
    return { lane: 'unknown' };
  }

  const mawaqit = detectMawaqitInHtml(html, websiteUrl);
  if (mawaqit) return { lane: 'mawaqit', detection: mawaqit };

  return { lane: 'unknown' };
}
