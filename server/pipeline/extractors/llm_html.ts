import Anthropic from '@anthropic-ai/sdk';
import * as cheerio from 'cheerio';
import { dayTimetableSchema, type TimetableFeed, type MosqueRecord } from '../schema.ts';
import { z } from 'zod';

const MODEL = process.env.ANTHROPIC_MODEL ?? 'claude-haiku-4-5-20251001';
const MAX_INPUT_CHARS = 24000;

const extractionSchema = z.object({
  days: z.array(dayTimetableSchema).min(1).max(40),
  notes: z.string().optional(),
});

const TOOL: Anthropic.Tool = {
  name: 'submit_timetable',
  description:
    'Return the parsed mosque prayer timetable. Times must be 24-hour HH:MM. Dates must be YYYY-MM-DD.',
  input_schema: {
    type: 'object',
    additionalProperties: false,
    properties: {
      days: {
        type: 'array',
        minItems: 1,
        maxItems: 40,
        items: {
          type: 'object',
          additionalProperties: false,
          required: ['date', 'fajr', 'sunrise', 'dhuhr', 'asr', 'maghrib', 'isha'],
          properties: {
            date: { type: 'string', pattern: '^\\d{4}-\\d{2}-\\d{2}$' },
            fajr: { type: 'string', pattern: '^([01]\\d|2[0-3]):[0-5]\\d$' },
            sunrise: { type: 'string', pattern: '^([01]\\d|2[0-3]):[0-5]\\d$' },
            dhuhr: { type: 'string', pattern: '^([01]\\d|2[0-3]):[0-5]\\d$' },
            asr: { type: 'string', pattern: '^([01]\\d|2[0-3]):[0-5]\\d$' },
            maghrib: { type: 'string', pattern: '^([01]\\d|2[0-3]):[0-5]\\d$' },
            isha: { type: 'string', pattern: '^([01]\\d|2[0-3]):[0-5]\\d$' },
            fajrJamaat: { type: 'string' },
            dhuhrJamaat: { type: 'string' },
            asrJamaat: { type: 'string' },
            maghribJamaat: { type: 'string' },
            ishaJamaat: { type: 'string' },
          },
        },
      },
      notes: { type: 'string' },
    },
    required: ['days'],
  },
};

export interface LlmHtmlOptions {
  fetchImpl?: typeof fetch;
  anthropicApiKey?: string;
}

export async function extractWithLlm(
  mosque: MosqueRecord,
  opts: LlmHtmlOptions = {},
): Promise<TimetableFeed> {
  const f = opts.fetchImpl ?? fetch;
  const apiKey = opts.anthropicApiKey ?? process.env.ANTHROPIC_API_KEY;
  if (!apiKey) {
    throw new Error('llm-html: ANTHROPIC_API_KEY not configured');
  }

  const res = await f(mosque.websiteUrl, {
    headers: { 'User-Agent': 'prayer-times-app/1.0' },
    redirect: 'follow',
  });
  if (!res.ok) throw new Error(`llm-html: HTTP ${res.status} fetching ${mosque.websiteUrl}`);
  const html = await res.text();
  const text = htmlToText(html).slice(0, MAX_INPUT_CHARS);

  const client = new Anthropic({ apiKey });
  const today = new Date().toISOString().slice(0, 10);

  const response = await client.messages.create({
    model: MODEL,
    max_tokens: 4096,
    tool_choice: { type: 'tool', name: TOOL.name },
    tools: [TOOL],
    messages: [
      {
        role: 'user',
        content: [
          {
            type: 'text',
            text:
              `You are extracting prayer times from a UK mosque website.\n` +
              `Mosque: ${mosque.name}\n` +
              `Today: ${today}\n` +
              `Return the prayer schedule starting from today (or the closest published date) for as many days as the page lists, up to 40 days.\n` +
              `If only today is listed, return one day. If no schedule is parseable, call the tool with an empty days array (not allowed) — instead, do not call the tool.\n` +
              `Times must be 24-hour HH:MM (UK local time).\n` +
              `Page content follows:\n\n` +
              text,
          },
        ],
      },
    ],
  });

  const toolUse = response.content.find(
    (block): block is Anthropic.ToolUseBlock => block.type === 'tool_use',
  );
  if (!toolUse) {
    throw new Error('llm-html: model did not return a tool call');
  }

  const parsed = extractionSchema.parse(toolUse.input);

  const fetchedAt = new Date();
  const expiresAt = new Date(fetchedAt.getTime() + 24 * 60 * 60 * 1000);

  return {
    mosqueId: mosque.id,
    sourceKind: 'webTable',
    fetchedAt: fetchedAt.toISOString(),
    expiresAt: expiresAt.toISOString(),
    validFrom: parsed.days[0]!.date,
    validTo: parsed.days[parsed.days.length - 1]!.date,
    confidence: 'published',
    lane: 'llm-html',
    days: parsed.days,
  };
}

function htmlToText(html: string): string {
  const $ = cheerio.load(html);
  $('script, style, noscript, header, footer, nav').remove();
  return $.root().text().replace(/\s+/g, ' ').trim();
}
