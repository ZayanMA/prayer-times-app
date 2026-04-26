import 'dart:convert';
import 'dart:io';

import 'package:prayer_times_core/core.dart';
import 'package:prayer_times_sources/pdf/pdf_timetable_source.dart';
import 'package:prayer_times_sources/source.dart';
import 'package:prayer_times_sources/web_table/html_table_timetable_source.dart';

Future<void> main(List<String> args) async {
  final root = args.isEmpty ? Directory.current : Directory(args.first);
  final configFile = File('${root.path}/server/source_config/mosques.json');
  final outputDirectory = Directory('${root.path}/server/catalog/v1');
  final timetableDirectory = Directory('${outputDirectory.path}/timetables');

  if (!configFile.existsSync()) {
    stderr.writeln('Missing source config: ${configFile.path}');
    exitCode = 1;
    return;
  }

  outputDirectory.createSync(recursive: true);
  timetableDirectory.createSync(recursive: true);

  final config =
      jsonDecode(configFile.readAsStringSync()) as Map<String, dynamic>;
  final mosqueConfigs =
      (config['mosques'] as List<dynamic>).cast<Map<String, dynamic>>();
  final now = DateTime.now().toUtc();

  final catalog = {
    'generatedAt': now.toIso8601String(),
    'mosques': [
      for (final mosque in mosqueConfigs)
        {
          'id': mosque['id'],
          'name': mosque['name'],
          'slug': mosque['slug'],
          'area': mosque['area'],
          'city': mosque['city'],
          'websiteUrl': mosque['websiteUrl'],
          if (mosque['sourceUrl'] != null) 'sourceUrl': mosque['sourceUrl'],
          'sourceKind': mosque['sourceKind'],
          if (mosque['sourceStatus'] != null)
            'sourceStatus': mosque['sourceStatus'],
          if (mosque['verifiedAt'] != null) 'verifiedAt': mosque['verifiedAt'],
          'updatedAt': mosque['updatedAt'],
          'isActive': mosque['isActive'] ?? true,
          if (mosque['latitude'] != null) 'latitude': mosque['latitude'],
          if (mosque['longitude'] != null) 'longitude': mosque['longitude'],
          if (mosque['postcode'] != null) 'postcode': mosque['postcode'],
          if (mosque['addressLine'] != null)
            'addressLine': mosque['addressLine'],
          if (mosque['facilities'] != null) 'facilities': mosque['facilities'],
          if (mosque['contact'] != null) 'contact': mosque['contact'],
          if (mosque['lastScrapeError'] != null)
            'lastScrapeError': mosque['lastScrapeError'],
        },
    ],
  };

  File('${outputDirectory.path}/mosques.json').writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(catalog),
  );

  for (final mosque in mosqueConfigs) {
    if (mosque['isActive'] == false) {
      continue;
    }

    final source = _sourceFor(mosque);
    if (source == null) {
      stderr.writeln(
          'No implemented source for ${mosque['id']}; skipping timetable.');
      continue;
    }

    try {
      final today = DateTime.now();
      final timetable = await source.fetch(
        from: today,
        to: today.add(const Duration(days: 31)),
      );
      final fetchedAt = (timetable.fetchedAt ?? DateTime.now()).toUtc();
      final feed = {
        'mosqueId': timetable.mosqueId,
        'sourceKind': source.kind.name,
        'fetchedAt': fetchedAt.toIso8601String(),
        'expiresAt': fetchedAt.add(const Duration(days: 1)).toIso8601String(),
        'validFrom': _date(timetable.days.first.date),
        'validTo': _date(timetable.days.last.date),
        'days': [
          for (final day in timetable.days) _dayToJson(day),
        ],
      };
      File('${timetableDirectory.path}/${source.mosqueId}.json')
          .writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(feed),
      );
    } catch (error) {
      stderr
          .writeln('Failed to generate timetable for ${mosque['id']}: $error');
    }
  }
}

MosqueTimetableSource? _sourceFor(Map<String, dynamic> mosque) {
  final id = mosque['id'] as String;
  final name = mosque['name'] as String? ?? id;
  final sourceKind = SourceKind.values.byName(mosque['sourceKind'] as String);
  final sourceUrl = Uri.parse(mosque['sourceUrl'] as String);

  return switch (sourceKind) {
    SourceKind.webTable => HtmlTableTimetableSource(
        mosqueId: id,
        uri: sourceUrl,
        displayName: name,
      ),
    SourceKind.pdf => PdfTimetableSource(
        mosqueId: id,
        uri: sourceUrl,
        displayName: name,
      ),
    _ => null,
  };
}

Map<String, Object?> _dayToJson(DailyTimetable day) {
  final times = day.prayerTimes;
  return {
    'date': _date(day.date),
    'fajr': _time(times.fajr),
    'sunrise': _time(times.sunrise),
    'dhuhr': _time(times.dhuhr),
    'asr': _time(times.asr),
    'maghrib': _time(times.maghrib),
    'isha': _time(times.isha),
    if (times.fajrJamaat != null) 'fajrJamaat': _time(times.fajrJamaat!),
    if (times.dhuhrJamaat != null) 'dhuhrJamaat': _time(times.dhuhrJamaat!),
    if (times.asrJamaat != null) 'asrJamaat': _time(times.asrJamaat!),
    if (times.maghribJamaat != null)
      'maghribJamaat': _time(times.maghribJamaat!),
    if (times.ishaJamaat != null) 'ishaJamaat': _time(times.ishaJamaat!),
  };
}

String _date(DateTime value) => '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';

String _time(DateTime value) => '${value.hour.toString().padLeft(2, '0')}:'
    '${value.minute.toString().padLeft(2, '0')}';
