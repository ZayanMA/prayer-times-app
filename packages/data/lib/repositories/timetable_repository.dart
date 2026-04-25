import 'package:drift/drift.dart';
import 'package:prayer_times_core/core.dart';

import '../database/database.dart';
import '../remote/remote_catalog_client.dart';

class TimetableRepository {
  TimetableRepository(
    this._database, {
    RemoteCatalogClient? remoteCatalogClient,
    CalculationFallback? fallback,
  })  : _remoteCatalogClient = remoteCatalogClient,
        _fallback = fallback ??
            const CalculationFallback(latitude: 51.509865, longitude: -0.118092);

  final AppDatabase _database;
  final RemoteCatalogClient? _remoteCatalogClient;
  final CalculationFallback _fallback;

  Stream<DailyTimetable?> watchDay(String mosqueId, DateTime date) {
    final day = _normaliseDay(date);
    final query = _database.select(_database.timetableDays)
      ..where(
        (table) => table.mosqueId.equals(mosqueId) & table.date.equals(day),
      );
    return query.watchSingleOrNull().map(
          (row) => row == null ? null : timetableDayFromRow(row),
        );
  }

  Future<DailyTimetable> getOrRefreshDay(String mosqueId, DateTime date) async {
    final cached = await _cachedDay(mosqueId, date);
    final cacheExpired = await _isCacheExpired(mosqueId);
    if (cached != null && !cacheExpired) {
      return cached.copyWith(isStale: false);
    }

    final client = _remoteCatalogClient;
    if (client != null) {
      try {
        final feed = await client.fetchTimetable(mosqueId);
        await saveRemoteTimetable(feed);
        final refreshed = await _cachedDay(mosqueId, date);
        if (refreshed != null) {
          return refreshed.copyWith(isStale: await _isCacheExpired(mosqueId));
        }
      } catch (_) {
        if (cached != null) {
          return cached.copyWith(isStale: true);
        }
      }
    } else if (cached != null) {
      return cached.copyWith(isStale: true);
    }

    final fallbackDay = _fallback.calculateDay(date: date, mosqueId: mosqueId);
    await saveDay(fallbackDay);
    return fallbackDay;
  }

  Future<void> saveRemoteTimetable(RemoteTimetableFeed feed) {
    return saveTimetable(
      feed.timetable,
      feed.sourceKind,
      feed.expiresAt,
    );
  }

  Future<void> saveTimetable(
    Timetable timetable,
    SourceKind sourceKind,
    DateTime expiresAt,
  ) async {
    await _database.transaction(() async {
      for (final day in timetable.days) {
        await saveDay(day);
      }
      final fetchedAt = timetable.fetchedAt ?? DateTime.now();
      await _database.into(_database.sourceCaches).insertOnConflictUpdate(
            SourceCachesCompanion.insert(
              mosqueId: timetable.mosqueId,
              sourceKind: sourceKind.name,
              fetchedAt: fetchedAt,
              expiresAt: expiresAt,
            ),
          );
    });
  }

  Future<void> saveDay(DailyTimetable day) {
    final times = day.prayerTimes;
    return _database.into(_database.timetableDays).insertOnConflictUpdate(
          TimetableDaysCompanion.insert(
            mosqueId: day.mosqueId,
            date: _normaliseDay(day.date),
            fajr: times.fajr,
            sunrise: times.sunrise,
            dhuhr: times.dhuhr,
            asr: times.asr,
            maghrib: times.maghrib,
            isha: times.isha,
            fajrJamaat: Value(times.fajrJamaat),
            dhuhrJamaat: Value(times.dhuhrJamaat),
            asrJamaat: Value(times.asrJamaat),
            maghribJamaat: Value(times.maghribJamaat),
            ishaJamaat: Value(times.ishaJamaat),
            isCalculated: Value(day.isCalculated),
            updatedAt: DateTime.now(),
          ),
        );
  }

  Future<DailyTimetable?> _cachedDay(String mosqueId, DateTime date) async {
    final day = _normaliseDay(date);
    final query = _database.select(_database.timetableDays)
      ..where(
        (table) => table.mosqueId.equals(mosqueId) & table.date.equals(day),
      );
    final row = await query.getSingleOrNull();
    return row == null ? null : timetableDayFromRow(row);
  }

  Future<bool> _isCacheExpired(String mosqueId) async {
    final query = _database.select(_database.sourceCaches)
      ..where((table) => table.mosqueId.equals(mosqueId));
    final cache = await query.getSingleOrNull();
    return cache == null || cache.expiresAt.isBefore(DateTime.now());
  }

  DateTime _normaliseDay(DateTime date) => DateTime(date.year, date.month, date.day);
}
