import { z } from 'zod';

// "HH:MM" 24h
const timeSchema = z
  .string()
  .regex(/^([01]\d|2[0-3]):[0-5]\d$/, 'must be HH:MM');

const optionalTime = timeSchema.optional().or(z.literal(''));

export const dayTimetableSchema = z.object({
  date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'must be YYYY-MM-DD'),
  fajr: timeSchema,
  sunrise: timeSchema,
  dhuhr: timeSchema,
  asr: timeSchema,
  maghrib: timeSchema,
  isha: timeSchema,
  fajrJamaat: optionalTime,
  dhuhrJamaat: optionalTime,
  asrJamaat: optionalTime,
  maghribJamaat: optionalTime,
  ishaJamaat: optionalTime,
});

export type DayTimetable = z.infer<typeof dayTimetableSchema>;

export const sourceKindSchema = z.enum([
  'webTable',
  'pdf',
  'image',
  'remoteCanonical',
  'manual',
  'calculated',
]);

export const confidenceSchema = z.enum(['verified', 'published', 'pending']);
export type Confidence = z.infer<typeof confidenceSchema>;

export const timetableFeedSchema = z.object({
  mosqueId: z.string(),
  sourceKind: sourceKindSchema,
  fetchedAt: z.string(),
  expiresAt: z.string(),
  validFrom: z.string().optional(),
  validTo: z.string().optional(),
  confidence: confidenceSchema.optional(),
  lane: z.string().optional(),
  days: z.array(dayTimetableSchema).min(1),
});

export type TimetableFeed = z.infer<typeof timetableFeedSchema>;

export const mosqueRecordSchema = z.object({
  id: z.string(),
  name: z.string(),
  slug: z.string(),
  area: z.string(),
  city: z.string(),
  websiteUrl: z.string(),
  sourceKind: sourceKindSchema,
  updatedAt: z.string(),
  isActive: z.boolean(),
  latitude: z.number().nullable().optional(),
  longitude: z.number().nullable().optional(),
  postcode: z.string().nullable().optional(),
  addressLine: z.string().nullable().optional(),
  platformHint: z.string().nullable().optional(),
});

export type MosqueRecord = z.infer<typeof mosqueRecordSchema>;
