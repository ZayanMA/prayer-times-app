import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:prayer_times_core/core.dart';

part 'database.g.dart';

@DataClassName('MosqueRow')
class Mosques extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get slug => text().unique()();
  TextColumn get area => text()();
  TextColumn get city => text()();
  TextColumn get websiteUrl => text()();
  TextColumn get sourceKind => text()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('FavouriteRow')
class Favourites extends Table {
  TextColumn get mosqueId => text().references(Mosques, #id)();
  DateTimeColumn get addedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {mosqueId};
}

@DataClassName('TimetableDayRow')
class TimetableDays extends Table {
  TextColumn get mosqueId => text().references(Mosques, #id)();
  DateTimeColumn get date => dateTime()();
  DateTimeColumn get fajr => dateTime()();
  DateTimeColumn get sunrise => dateTime()();
  DateTimeColumn get dhuhr => dateTime()();
  DateTimeColumn get asr => dateTime()();
  DateTimeColumn get maghrib => dateTime()();
  DateTimeColumn get isha => dateTime()();
  DateTimeColumn get fajrJamaat => dateTime().nullable()();
  DateTimeColumn get dhuhrJamaat => dateTime().nullable()();
  DateTimeColumn get asrJamaat => dateTime().nullable()();
  DateTimeColumn get maghribJamaat => dateTime().nullable()();
  DateTimeColumn get ishaJamaat => dateTime().nullable()();
  BoolColumn get isCalculated => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {mosqueId, date};
}

@DataClassName('SourceCacheRow')
class SourceCaches extends Table {
  TextColumn get mosqueId => text().references(Mosques, #id)();
  TextColumn get sourceKind => text()();
  TextColumn get etag => text().nullable()();
  DateTimeColumn get fetchedAt => dateTime()();
  DateTimeColumn get expiresAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {mosqueId};
}

@DriftDatabase(tables: [Mosques, Favourites, TimetableDays, SourceCaches])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  factory AppDatabase.openFile(File file) {
    return AppDatabase(NativeDatabase.createInBackground(file));
  }

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (migrator, from, to) async {
          if (from < 2) {
            await migrator.addColumn(mosques, mosques.updatedAt);
            await migrator.addColumn(mosques, mosques.isActive);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}

Mosque mosqueFromRow(MosqueRow row) {
  return Mosque(
    id: row.id,
    name: row.name,
    slug: row.slug,
    area: row.area,
    city: row.city,
    websiteUrl: Uri.parse(row.websiteUrl),
    sourceKind: SourceKind.values.byName(row.sourceKind),
    updatedAt: row.updatedAt,
    isActive: row.isActive,
  );
}

DailyTimetable timetableDayFromRow(TimetableDayRow row) {
  return DailyTimetable(
    date: DateTime(row.date.year, row.date.month, row.date.day),
    mosqueId: row.mosqueId,
    isCalculated: row.isCalculated,
    prayerTimes: PrayerTimes(
      fajr: row.fajr,
      sunrise: row.sunrise,
      dhuhr: row.dhuhr,
      asr: row.asr,
      maghrib: row.maghrib,
      isha: row.isha,
      fajrJamaat: row.fajrJamaat,
      dhuhrJamaat: row.dhuhrJamaat,
      asrJamaat: row.asrJamaat,
      maghribJamaat: row.maghribJamaat,
      ishaJamaat: row.ishaJamaat,
    ),
  );
}
