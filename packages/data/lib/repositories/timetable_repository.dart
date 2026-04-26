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
        _defaultFallback = fallback ??
            const CalculationFallback(latitude: 54.5, longitude: -3.0);

  final AppDatabase _database;
  final RemoteCatalogClient? _remoteCatalogClient;
  final CalculationFallback _defaultFallback;

  Future<CalculationFallback> _fallbackFor(String mosqueId) async {
    final row = await _mosqueRow(mosqueId);
    if (row?.latitude != null && row?.longitude != null) {
      return CalculationFallback(
        latitude: row!.latitude!,
        longitude: row.longitude!,
      );
    }
    return _defaultFallback;
  }

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

  /// Returns today's published timetable for the mosque, refreshing from the
  /// remote catalog when stale.
  ///
  /// Returns `null` when the mosque does not publish a timetable we can
  /// retrieve. When [allowEstimation] is true, falls back to astronomical
  /// calculation using the mosque's coordinates instead of returning null.
  Future<DailyTimetable?> getOrRefreshDay(
    String mosqueId,
    DateTime date, {
    bool allowEstimation = false,
  }) async {
    final mosqueRow = await _mosqueRow(mosqueId);
    final sourceKind = mosqueRow == null
        ? null
        : SourceKind.values.byName(mosqueRow.sourceKind);
    final hasPublishedSource =
        sourceKind != null && sourceKind != SourceKind.calculated;

    if (hasPublishedSource) {
      final cached = await _cachedDay(mosqueId, date);
      final cacheExpired = await _isCacheExpired(mosqueId);
      if (cached != null && !cacheExpired && !cached.isCalculated) {
        return cached.copyWith(isStale: false);
      }

      final client = _remoteCatalogClient;
      if (client != null) {
        try {
          final feed = await client.fetchTimetable(mosqueId);
          await saveRemoteTimetable(feed);
          final refreshed = await _cachedDay(mosqueId, date);
          if (refreshed != null) {
            return refreshed.copyWith(
              isStale: await _isCacheExpired(mosqueId),
            );
          }
        } catch (_) {
          if (cached != null && !cached.isCalculated) {
            return cached.copyWith(isStale: true);
          }
        }
      } else if (cached != null && !cached.isCalculated) {
        return cached.copyWith(isStale: true);
      }
    }

    if (!allowEstimation) return null;

    final fallback = await _fallbackFor(mosqueId);
    final fallbackDay = fallback.calculateDay(date: date, mosqueId: mosqueId);
    await saveDay(fallbackDay);
    return fallbackDay;
  }

  Future<MosqueRow?> _mosqueRow(String mosqueId) {
    final query = _database.select(_database.mosques)
      ..where((table) => table.id.equals(mosqueId));
    return query.getSingleOrNull();
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
              confidence: Value(timetable.confidence),
              lane: Value(timetable.lane),
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

  DateTime _normaliseDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}
