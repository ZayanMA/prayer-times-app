import { promises as fs } from 'node:fs';
import * as path from 'node:path';
import { mosqueRecordSchema, type MosqueRecord } from './schema.ts';
import { runPipeline } from './pipeline.ts';
import { writeCanonical } from './canonical_writer.ts';

interface Options {
  catalogDir: string;
  mosqueIds: string[];
  enableLlm: boolean;
}

function parseArgs(argv: string[]): Options {
  const args: Record<string, string> = {};
  const positional: string[] = [];
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i]!;
    if (a.startsWith('--')) {
      const [key, valueInline] = a.slice(2).split('=', 2);
      const value = valueInline ?? argv[++i] ?? 'true';
      args[key!] = value;
    } else {
      positional.push(a);
    }
  }

  return {
    catalogDir:
      args['catalog'] ??
      path.resolve(process.cwd(), '..', 'server', 'catalog', 'v1'),
    mosqueIds: positional,
    enableLlm: args['llm'] === 'true' || args['llm'] === '1',
  };
}

async function loadCatalog(catalogDir: string): Promise<MosqueRecord[]> {
  const file = path.join(catalogDir, 'mosques.json');
  const raw = await fs.readFile(file, 'utf8');
  const parsed = JSON.parse(raw) as { mosques: unknown[] };
  return parsed.mosques.map((m) => mosqueRecordSchema.parse(m));
}

async function main() {
  const opts = parseArgs(process.argv.slice(2));
  const catalog = await loadCatalog(opts.catalogDir);
  const targets = opts.mosqueIds.length
    ? catalog.filter((m) => opts.mosqueIds.includes(m.id))
    : catalog;

  if (targets.length === 0) {
    console.error(`No mosques matched: ${opts.mosqueIds.join(', ')}`);
    process.exitCode = 1;
    return;
  }

  let success = 0;
  let failure = 0;
  for (const mosque of targets) {
    process.stdout.write(`→ ${mosque.id} (${mosque.name})\n`);
    try {
      const result = await runPipeline(mosque, { enableLlm: opts.enableLlm });
      if (result.ok) {
        await writeCanonical(result.feed, { catalogDir: opts.catalogDir });
        const days = result.feed.days.length;
        process.stdout.write(
          `  ✓ ${result.lane} → ${days} day(s), confidence=${result.feed.confidence}\n`,
        );
        success++;
      } else {
        process.stdout.write(`  ✗ ${result.reason}\n`);
        for (const attempt of result.attempts) {
          process.stdout.write(`    ${attempt.lane}: ${attempt.error}\n`);
        }
        failure++;
      }
    } catch (err) {
      process.stdout.write(
        `  ✗ unexpected: ${(err as Error).message}\n`,
      );
      failure++;
    }
  }

  process.stdout.write(
    `\n${success} succeeded, ${failure} failed of ${targets.length}\n`,
  );
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
