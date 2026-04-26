import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:prayer_times_core/core.dart';

class RemoteCatalogClient {
  RemoteCatalogClient({
    required Uri baseUri,
    http.Client? client,
  })  : _baseUri = _normaliseBaseUri(baseUri),
        _client = client ?? http.Client();

  final Uri _baseUri;
  final http.Client _client;

  Future<List<Mosque>> fetchMosques() async {
    final json = await _getJson(_baseUri.resolve('mosques.json'));
    final records = switch (json) {
      {'mosques': final List<dynamic> mosques} => mosques,
      final List<dynamic> mosques => mosques,
      _ => throw const RemoteCatalogException('Invalid mosque catalog shape.'),
    };

    return records
        .map((record) => _parseMosque(_asMap(record, 'mosque')))
        .toList();
  }

  Future<RemoteTimetableFeed> fetchTimetable(String mosqueId) async {
    try {
      final json =
          await _getJson(_baseUri.resolve('timetables/$mosqueId.json'));
      return _parseTimetableFeed(_asMap(json, 'timetable feed'));
    } on RemoteCatalogException {
      final json =
          await _getJson(_baseUri.resolve('/api/timetables/$mosqueId'));
      return _parseTimetableFeed(_asMap(json, 'timetable feed'));
    }
  }

  Future<dynamic> _getJson(Uri uri) async {
    final response = await _client.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw RemoteCatalogException(
        'Remote catalog returned HTTP ${response.statusCode} for $uri.',
      );
    }

    try {
      return jsonDecode(response.body);
    } catch (error) {
      throw RemoteCatalogException(
          'Remote catalog returned invalid JSON.', error);
    }
  }

  Mosque _parseMosque(Map<String, dynamic> json) {
    final websiteRaw = json['websiteUrl'] as String?;
    final sourceRaw = json['sourceUrl'] as String?;
    final facilities = _optionalMap(json['facilities']);
    final contact = _optionalMap(json['contact']);
    return Mosque(
      id: _requiredString(json, 'id'),
      name: _requiredString(json, 'name'),
      slug: _requiredString(json, 'slug'),
      area: _requiredString(json, 'area'),
      city: _requiredString(json, 'city'),
      websiteUrl: Uri.parse(
        websiteRaw == null || websiteRaw.isEmpty ? 'about:blank' : websiteRaw,
      ),
      sourceKind: _parseSourceKind(_requiredString(json, 'sourceKind')),
      updatedAt: _parseDateTime(_requiredString(json, 'updatedAt')),
      isActive: json['isActive'] as bool? ?? true,
      sourceUrl:
          sourceRaw == null || sourceRaw.isEmpty ? null : Uri.parse(sourceRaw),
      sourceStatus: _toNullableString(json['sourceStatus']),
      verifiedAt: _toNullableDateTime(json['verifiedAt']),
      latitude: _toNullableDouble(json['latitude']),
      longitude: _toNullableDouble(json['longitude']),
      postcode: _toNullableString(json['postcode']),
      addressLine: _toNullableString(json['addressLine']),
      womensFacilities: _toNullableBool(
            json['womensFacilities'],
          ) ??
          _toNullableBool(facilities?['women']),
      wheelchairAccess: _toNullableBool(
            json['wheelchairAccess'],
          ) ??
          _toNullableBool(facilities?['wheelchairAccess']),
      parking: _toNullableBool(json['parking']) ??
          _toNullableBool(facilities?['parking']),
      contactEmail: _toNullableString(json['contactEmail']) ??
          _toNullableString(contact?['email']),
      contactPhone: _toNullableString(json['contactPhone']) ??
          _toNullableString(contact?['phone']),
      lastScrapeError: _toNullableString(json['lastScrapeError']),
    );
  }

  double? _toNullableDouble(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String && value.isNotEmpty) return double.tryParse(value);
    return null;
  }

  String? _toNullableString(Object? value) {
    if (value == null) return null;
    if (value is String) return value.isEmpty ? null : value;
    return value.toString();
  }

  bool? _toNullableBool(Object? value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is String) {
      final normalised = value.toLowerCase().trim();
      if (normalised == 'true' || normalised == 'yes') return true;
      if (normalised == 'false' || normalised == 'no') return false;
    }
    return null;
  }

  DateTime? _toNullableDateTime(Object? value) {
    if (value == null) return null;
    if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
    return null;
  }

  Map<String, dynamic>? _optionalMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.cast<String, dynamic>();
    return null;
  }

  RemoteTimetableFeed _parseTimetableFeed(Map<String, dynamic> json) {
    final mosqueId = _requiredString(json, 'mosqueId');
    final sourceKind = _parseSourceKind(_requiredString(json, 'sourceKind'));
    final fetchedAt = _parseDateTime(_requiredString(json, 'fetchedAt'));
    final expiresAt = json['expiresAt'] == null
        ? fetchedAt.add(const Duration(days: 1))
        : _parseDateTime(_requiredString(json, 'expiresAt'));
    final daysJson = _asList(json['days'], 'days');

    return RemoteTimetableFeed(
      sourceKind: sourceKind,
      expiresAt: expiresAt,
      confidence: _toNullableString(json['confidence']),
      lane: _toNullableString(json['lane']),
      timetable: Timetable(
        mosqueId: mosqueId,
        fetchedAt: fetchedAt,
        confidence: _toNullableString(json['confidence']),
        lane: _toNullableString(json['lane']),
        days: daysJson
            .map((dayJson) => _parseDay(mosqueId, _asMap(dayJson, 'day')))
            .toList(),
      ),
    );
  }

  DailyTimetable _parseDay(String mosqueId, Map<String, dynamic> json) {
    final date = _parseDate(_requiredString(json, 'date'));
    return DailyTimetable(
      date: date,
      mosqueId: mosqueId,
      isCalculated: false,
      isStale: false,
      prayerTimes: PrayerTimes(
        fajr: _parseTime(date, _requiredString(json, 'fajr')),
        sunrise: _parseTime(date, _requiredString(json, 'sunrise')),
        dhuhr: _parseTime(date, _requiredString(json, 'dhuhr')),
        asr: _parseTime(date, _requiredString(json, 'asr')),
        maghrib: _parseTime(date, _requiredString(json, 'maghrib')),
        isha: _parseTime(date, _requiredString(json, 'isha')),
        fajrJamaat: _parseOptionalTime(date, json['fajrJamaat']),
        dhuhrJamaat: _parseOptionalTime(date, json['dhuhrJamaat']),
        asrJamaat: _parseOptionalTime(date, json['asrJamaat']),
        maghribJamaat: _parseOptionalTime(date, json['maghribJamaat']),
        ishaJamaat: _parseOptionalTime(date, json['ishaJamaat']),
      ),
    );
  }

  SourceKind _parseSourceKind(String value) {
    try {
      return SourceKind.values.byName(value);
    } catch (_) {
      throw RemoteCatalogException('Unknown source kind "$value".');
    }
  }

  DateTime _parseDateTime(String value) => DateTime.parse(value);

  DateTime _parseDate(String value) {
    final parsed = DateTime.parse(value);
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  DateTime _parseTime(DateTime date, String value) {
    final parts = value.split(':');
    if (parts.length != 2) {
      throw RemoteCatalogException('Invalid time "$value".');
    }
    return DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  DateTime? _parseOptionalTime(DateTime date, Object? value) {
    if (value == null || value == '') {
      return null;
    }
    if (value is! String) {
      throw RemoteCatalogException('Invalid optional time "$value".');
    }
    return _parseTime(date, value);
  }

  String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String || value.isEmpty) {
      throw RemoteCatalogException('Missing required string "$key".');
    }
    return value;
  }

  Map<String, dynamic> _asMap(Object? value, String label) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    throw RemoteCatalogException('Invalid $label object.');
  }

  List<dynamic> _asList(Object? value, String label) {
    if (value is List<dynamic>) {
      return value;
    }
    throw RemoteCatalogException('Invalid $label list.');
  }

  static Uri _normaliseBaseUri(Uri uri) {
    final text = uri.toString();
    return text.endsWith('/') ? uri : Uri.parse('$text/');
  }
}

class RemoteTimetableFeed {
  const RemoteTimetableFeed({
    required this.timetable,
    required this.sourceKind,
    required this.expiresAt,
    this.confidence,
    this.lane,
    this.lastError,
  });

  final Timetable timetable;
  final SourceKind sourceKind;
  final DateTime expiresAt;
  final String? confidence;
  final String? lane;
  final String? lastError;
}

class RemoteCatalogException implements Exception {
  const RemoteCatalogException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() {
    if (cause == null) {
      return 'RemoteCatalogException: $message';
    }
    return 'RemoteCatalogException: $message ($cause)';
  }
}
