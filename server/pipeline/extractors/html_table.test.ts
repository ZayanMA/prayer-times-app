import test from 'node:test';
import assert from 'node:assert/strict';
import { parseHtmlTimetable } from './html_table.ts';

test('parses current-day prayer block with iqamah times', () => {
  const days = parseHtmlTimetable(`
    <main>
      <p>2026-04-25</p>
      <p>Prayer Begins Iqamah</p>
      <p>Fajr 3:36 AM 5:15 AM</p>
      <p>Sunrise 5:51 AM</p>
      <p>Zuhr 1:04 PM 1:30 PM</p>
      <p>Asr 6:04 PM 6:15 PM</p>
      <p>Maghrib 8:19 PM 8:19 PM</p>
      <p>Isha 9:53 PM 10:00 PM</p>
    </main>
  `);

  assert.deepEqual(days, [
    {
      date: '2026-04-25',
      fajr: '03:36',
      fajrJamaat: '05:15',
      sunrise: '05:51',
      dhuhr: '13:04',
      dhuhrJamaat: '13:30',
      asr: '18:04',
      asrJamaat: '18:15',
      maghrib: '20:19',
      maghribJamaat: '20:19',
      isha: '21:53',
      ishaJamaat: '22:00',
    },
  ]);
});

test('parses dated HTML table rows', () => {
  const days = parseHtmlTimetable(`
    <table>
      <tr>
        <th>Date</th><th>Subh</th><th>Shuruq</th><th>Duhr</th>
        <th>Asr</th><th>Maghrib</th><th>Isha</th>
      </tr>
      <tr>
        <td>Sunday, March 1, 2026</td>
        <td>05:17</td><td>06:50</td><td>12:23</td>
        <td>15:10</td><td>17:50</td><td>19:14</td>
      </tr>
    </table>
  `);

  assert.equal(days.length, 1);
  assert.equal(days[0]!.date, '2026-03-01');
  assert.equal(days[0]!.fajr, '05:17');
  assert.equal(days[0]!.isha, '19:14');
});
