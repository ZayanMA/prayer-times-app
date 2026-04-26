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
  TextColumn get sourceUrl => text().nullable()();
  TextColumn get sourceStatus => text().nullable()();
  DateTimeColumn get verifiedAt => dateTime().nullable()();
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  TextColumn get postcode => text().nullable()();
  TextColumn get addressLine => text().nullable()();
  BoolColumn get womensFacilities => boolean().nullable()();
  BoolColumn get wheelchairAccess => boolean().nullable()();
  BoolColumn get parking => boolean().nullable()();
  TextColumn get contactEmail => text().nullable()();
  TextColumn get contactPhone => text().nullable()();
  TextColumn get lastScrapeError => text().nullable()();
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
  TextColumn get confidence => text().nullable()();
  TextColumn get lane => text().nullable()();
  TextColumn get lastError => text().nullable()();
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
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (migrator, from, to) async {
          if (from < 2) {
            await migrator.addColumn(mosques, mosques.updatedAt);
            await migrator.addColumn(mosques, mosques.isActive);
          }
          if (from < 3) {
            await migrator.addColumn(mosques, mosques.latitude);
            await migrator.addColumn(mosques, mosques.longitude);
            await migrator.addColumn(mosques, mosques.postcode);
            await migrator.addColumn(mosques, mosques.addressLine);
          }
          if (from < 4) {
            await migrator.addColumn(mosques, mosques.sourceUrl);
            await migrator.addColumn(mosques, mosques.sourceStatus);
            await migrator.addColumn(mosques, mosques.verifiedAt);
            await migrator.addColumn(mosques, mosques.womensFacilities);
            await migrator.addColumn(mosques, mosques.wheelchairAccess);
            await migrator.addColumn(mosques, mosques.parking);
            await migrator.addColumn(mosques, mosques.contactEmail);
            await migrator.addColumn(mosques, mosques.contactPhone);
            await migrator.addColumn(mosques, mosques.lastScrapeError);
            await migrator.addColumn(sourceCaches, sourceCaches.confidence);
            await migrator.addColumn(sourceCaches, sourceCaches.lane);
            await migrator.addColumn(sourceCaches, sourceCaches.lastError);
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
    sourceUrl: row.sourceUrl == null ? null : Uri.parse(row.sourceUrl!),
    sourceStatus: row.sourceStatus,
    verifiedAt: row.verifiedAt,
    latitude: row.latitude,
    longitude: row.longitude,
    postcode: row.postcode,
    addressLine: row.addressLine,
    womensFacilities: row.womensFacilities,
    wheelchairAccess: row.wheelchairAccess,
    parking: row.parking,
    contactEmail: row.contactEmail,
    contactPhone: row.contactPhone,
    lastScrapeError: row.lastScrapeError,
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
