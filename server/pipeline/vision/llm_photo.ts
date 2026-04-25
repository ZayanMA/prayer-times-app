import Anthropic from '@anthropic-ai/sdk';
import { dayTimetableSchema, type TimetableFeed, type MosqueRecord } from '../schema.ts';
import { z } from 'zod';

const MODEL = process.env.ANTHROPIC_MODEL ?? 'claude-haiku-4-5-20251001';

const extractionSchema = z.object({
  days: z.array(dayTimetableSchema).min(1).max(60),
  notes: z.string().optional(),
});

const TOOL: Anthropic.Tool = {
  name: 'submit_timetable',
  description:
    'Return the parsed mosque prayer timetable from the photo. Times must be 24-hour HH:MM. Dates must be YYYY-MM-DD.',
  input_schema: {
    type: 'object',
    additionalProperties: false,
    properties: {
      days: {
        type: 'array',
        minItems: 1,
        maxItems: 60,
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

export interface LlmPhotoOptions {
  anthropicApiKey?: string;
}

export type ImageMediaType = 'image/jpeg' | 'image/png' | 'image/gif' | 'image/webp';

export async function extractFromPhoto(
  mosque: MosqueRecord,
  imageBase64: string,
  mediaType: ImageMediaType,
  opts: LlmPhotoOptions = {},
): Promise<TimetableFeed> {
  const apiKey = opts.anthropicApiKey ?? process.env.ANTHROPIC_API_KEY;
  if (!apiKey) {
    throw new Error('llm-photo: ANTHROPIC_API_KEY not configured');
  }

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
            type: 'image',
            source: { type: 'base64', media_type: mediaType, data: imageBase64 },
          },
          {
            type: 'text',
            text:
              `You are extracting prayer times from a photo of a printed mosque timetable.\n` +
              `Mosque: ${mosque.name}\n` +
              `Today: ${today}\n` +
              `Extract ALL days visible in the photo — typically a monthly or weekly poster.\n` +
              `If dates are not year-qualified, assume ${today.slice(0, 7)} (current month).\n` +
              `Times must be 24-hour HH:MM (UK local time).\n` +
              `If Jamaat times are shown separately, include them in the corresponding *Jamaat fields.\n` +
              `Only include days whose data is clearly legible — skip blurry rows.`,
          },
        ],
      },
    ],
  });

  const toolUse = response.content.find(
    (block): block is Anthropic.ToolUseBlock => block.type === 'tool_use',
  );
  if (!toolUse) {
    throw new Error('llm-photo: model did not return a tool call — image may be unreadable');
  }

  const parsed = extractionSchema.parse(toolUse.input);

  const fetchedAt = new Date();
  // Photo submissions are valid for 35 days (cover a monthly poster)
  const expiresAt = new Date(fetchedAt.getTime() + 35 * 24 * 60 * 60 * 1000);

  return {
    mosqueId: mosque.id,
    sourceKind: 'image',
    fetchedAt: fetchedAt.toISOString(),
    expiresAt: expiresAt.toISOString(),
    validFrom: parsed.days[0]!.date,
    validTo: parsed.days[parsed.days.length - 1]!.date,
    confidence: 'pending',
    lane: 'photo',
    days: parsed.days,
  };
}
