import { promises as fs } from 'node:fs';
import * as path from 'node:path';

interface MosqueRecord {
  id: string;
  name: string;
  city: string;
  area: string;
  websiteUrl?: string;
  sourceUrl?: string;
  contact?: { email?: string | null; phone?: string | null } | null;
}

async function main() {
  const mosqueId = process.argv[2];
  if (!mosqueId) {
    console.error('Usage: npm run outreach:draft -- <mosque-id>');
    process.exitCode = 1;
    return;
  }

  const catalogFile = path.resolve(process.cwd(), 'catalog', 'v1', 'mosques.json');
  const raw = await fs.readFile(catalogFile, 'utf8');
  const catalog = JSON.parse(raw) as { mosques: MosqueRecord[] };
  const mosque = catalog.mosques.find((entry) => entry.id === mosqueId);
  if (!mosque) {
    console.error(`Mosque not found: ${mosqueId}`);
    process.exitCode = 1;
    return;
  }

  console.log(renderEmail(mosque));
}

function renderEmail(mosque: MosqueRecord): string {
  const location = [mosque.area, mosque.city]
    .filter((value) => value && value !== 'Unknown')
    .join(', ');
  const knownSource = mosque.sourceUrl || mosque.websiteUrl || 'not known yet';

  return `Subject: Prayer timetable verification for ${mosque.name}

Assalamu alaikum,

I am building a UK mosque prayer-times app and would like to make sure ${mosque.name}${
    location ? ` in ${location}` : ''
  } is represented accurately.

Could you please confirm the following?

1. What is the official web page, PDF, API, or file we should use for your prayer timetable?
   Current source we have: ${knownSource}

2. Does that source include jama'ah/iqamah times as well as prayer start times?

3. How often is the timetable updated, and is there a separate Ramadan timetable source?

4. If you do not publish a timetable, which calculation method and Asr method should be used?

5. Do you have a women's prayer area, wheelchair access, and parking available?

6. May we cache and display your published prayer and jama'ah times in the app with attribution to your mosque?

We will use your official source for daily updates where possible, rather than asking for manual updates.

Jazakum Allahu khayran,
Prayer Times App
`;
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
