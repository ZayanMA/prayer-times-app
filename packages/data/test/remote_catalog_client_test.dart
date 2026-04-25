import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:prayer_times_core/core.dart';
import 'package:prayer_times_data/data.dart';
import 'package:test/test.dart';

void main() {
  test('parses mosque catalog without source URLs', () async {
    final client = RemoteCatalogClient(
      baseUri: Uri.parse('https://example.test/catalog/v1/'),
      client: MockClient((request) async {
        expect(request.url.path, '/catalog/v1/mosques.json');
        return http.Response('''
{
  "mosques": [
    {
      "id": "example-mosque",
      "name": "Example Mosque",
      "slug": "example-mosque",
      "area": "Example Area",
      "city": "Example City",
      "websiteUrl": "https://example.test/",
      "sourceKind": "webTable",
      "updatedAt": "2026-04-24T00:00:00Z",
      "isActive": true
    }
  ]
}
''', 200);
      }),
    );

    final mosques = await client.fetchMosques();

    expect(mosques, hasLength(1));
    expect(mosques.single.id, 'example-mosque');
    expect(mosques.single.sourceKind, SourceKind.webTable);
    expect(mosques.single.websiteUrl.toString(), 'https://example.test/');
  });

  test('parses daily timetable feed and expiry', () async {
    final client = RemoteCatalogClient(
      baseUri: Uri.parse('https://example.test/catalog/v1/'),
      client: MockClient((request) async {
        expect(
          request.url.path,
          '/catalog/v1/timetables/example-mosque.json',
        );
        return http.Response('''
{
  "mosqueId": "example-mosque",
  "sourceKind": "webTable",
  "fetchedAt": "2026-04-24T00:00:00Z",
  "expiresAt": "2026-04-25T00:00:00Z",
  "days": [
    {
      "date": "2026-04-24",
      "fajr": "04:12",
      "sunrise": "05:44",
      "dhuhr": "13:06",
      "asr": "18:00",
      "maghrib": "20:20",
      "isha": "21:35"
    }
  ]
}
''', 200);
      }),
    );

    final feed = await client.fetchTimetable('example-mosque');

    expect(feed.sourceKind, SourceKind.webTable);
    expect(feed.expiresAt, DateTime.parse('2026-04-25T00:00:00Z'));
    expect(feed.timetable.days.single.prayerTimes.fajr, DateTime(2026, 4, 24, 4, 12));
  });
}
