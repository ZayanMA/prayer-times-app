import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:prayer_times_core/core.dart';

import '../source.dart';

class HtmlTableTimetableSource implements MosqueTimetableSource {
  HtmlTableTimetableSource({
    required this.mosqueId,
    required Uri uri,
    String? displayName,
    http.Client? client,
    DateTime Function()? clock,
  })  : _displayName = displayName ?? mosqueId,
        _client = client ?? http.Client(),
        _uri = uri,
        _clock = clock ?? DateTime.now;

  @override
  final String mosqueId;

  final String _displayName;
  final http.Client _client;
  final Uri _uri;
  final DateTime Function() _clock;

  @override
  SourceKind get kind => SourceKind.webTable;

  @override
  Duration get freshness => const Duration(hours: 12);

  @override
  Future<Timetable> fetch({DateTime? from, DateTime? to}) async {
    try {
      final response = await _client.get(_uri);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw SourceFetchException(
          '$_displayName returned HTTP ${response.statusCode}.',
        );
      }
      return parseHtml(response.body, from: from, to: to);
    } on SourceFetchException {
      rethrow;
    } catch (error) {
      throw SourceFetchException(
        'Unable to fetch $_displayName timetable.',
        error,
      );
    }
  }

  Timetable parseHtml(String body, {DateTime? from, DateTime? to}) {
    final document = html_parser.parse(body);
    final days = <DailyTimetable>[];
    final currentYear = _clock().year;

    for (final row in document.querySelectorAll('tr')) {
      final cells = row.children
          .where((element) => element.localName == 'td' || element.localName == 'th')
          .map((element) => _normalise(element.text))
          .where((text) => text.isNotEmpty)
          .toList();

      if (cells.length < 7) {
        continue;
      }

      final date = _parseDate(cells, currentYear);
      if (date == null || !_withinRange(date, from, to)) {
        continue;
      }

      final times = cells
          .expand((cell) => _timePattern
              .allMatches(cell)
              .map((match) => match.group(0))
              .whereType<String>())
          .toList();

      if (times.length < 6) {
        continue;
      }

      days.add(
        DailyTimetable(
          date: date,
          mosqueId: mosqueId,
          prayerTimes: PrayerTimes(
            fajr: _dateTime(date, times[0]),
            sunrise: _dateTime(date, times[1]),
            dhuhr: _dateTime(date, times[2]),
            asr: _dateTime(date, times[3]),
            maghrib: _dateTime(date, times[4]),
            isha: _dateTime(date, times[5]),
          ),
        ),
      );
    }

    if (days.isEmpty) {
      throw SourceFetchException(
        'No prayer timetable rows could be parsed from $_displayName.',
      );
    }

    days.sort((a, b) => a.date.compareTo(b.date));
    return Timetable(
      mosqueId: mosqueId,
      days: days,
      fetchedAt: _clock(),
    );
  }

  bool _withinRange(DateTime date, DateTime? from, DateTime? to) {
    final day = DateTime(date.year, date.month, date.day);
    final start = from == null ? null : DateTime(from.year, from.month, from.day);
    final end = to == null ? null : DateTime(to.year, to.month, to.day);
    if (start != null && day.isBefore(start)) {
      return false;
    }
    if (end != null && day.isAfter(end)) {
      return false;
    }
    return true;
  }

  DateTime? _parseDate(List<String> cells, int currentYear) {
    final candidates = <String>[
      if (cells.length >= 4) '${cells[0]} ${cells[1]} ${cells[2]} ${cells[3]}',
      if (cells.length >= 3) '${cells[0]} ${cells[1]} ${cells[2]}',
      if (cells.length >= 2) '${cells[0]} ${cells[1]}',
      cells.first,
    ];

    for (final candidate in candidates) {
      final cleaned = candidate
          .replaceAll(RegExp(r'(st|nd|rd|th)\b', caseSensitive: false), '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      final candidateDates = RegExp(r'\b\d{4}\b').hasMatch(cleaned)
          ? [cleaned]
          : [cleaned, '$cleaned $currentYear'];
      for (final candidateDate in candidateDates) {
        for (final format in _dateFormats) {
          try {
            final parsed = DateFormat(format).parseStrict(candidateDate);
            return DateTime(parsed.year, parsed.month, parsed.day);
          } catch (_) {
            continue;
          }
        }
      }
    }
    return null;
  }

  Iterable<String> get _dateFormats => [
        'd MMMM yyyy',
        'd MMM yyyy',
        'EEEE d MMMM yyyy',
        'EEE d MMM yyyy',
        'dd/MM/yyyy',
        'd/M/yyyy',
      ];

  DateTime _dateTime(DateTime date, String value) {
    final match = _timePattern.firstMatch(value);
    if (match == null) {
      throw SourceFetchException('Invalid prayer time "$value".');
    }
    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  String _normalise(String value) =>
      value.replaceAll('\u00a0', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
}

final _timePattern = RegExp(r'\b([01]?\d|2[0-3])[:.]([0-5]\d)\b');
