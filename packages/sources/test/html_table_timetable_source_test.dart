import 'dart:io';

import 'package:prayer_times_sources/web_table/html_table_timetable_source.dart';
import 'package:test/test.dart';

void main() {
  test('parses timetable rows from captured HTML table fixture', () {
    final fixture = File('test/fixtures/html_table_timetable.html').readAsStringSync();
    final source = HtmlTableTimetableSource(
      mosqueId: 'example-mosque',
      uri: Uri.parse('https://example.test/timetable'),
      displayName: 'Example Mosque',
      clock: () => DateTime(2026, 4, 24, 12),
    );

    final timetable = source.parseHtml(
      fixture,
      from: DateTime(2026, 4, 24),
      to: DateTime(2026, 4, 24),
    );

    expect(timetable.mosqueId, 'example-mosque');
    expect(timetable.days, hasLength(1));
    final day = timetable.days.single;
    expect(day.date, DateTime(2026, 4, 24));
    expect(day.prayerTimes.fajr, DateTime(2026, 4, 24, 4, 12));
    expect(day.prayerTimes.sunrise, DateTime(2026, 4, 24, 5, 44));
    expect(day.prayerTimes.dhuhr, DateTime(2026, 4, 24, 13, 6));
    expect(day.prayerTimes.asr, DateTime(2026, 4, 24, 18));
    expect(day.prayerTimes.maghrib, DateTime(2026, 4, 24, 20, 20));
    expect(day.prayerTimes.isha, DateTime(2026, 4, 24, 21, 35));
  });
}
