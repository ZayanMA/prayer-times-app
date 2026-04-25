import 'package:drift/drift.dart';
import 'package:prayer_times_core/core.dart';

import '../database/database.dart';

class FavouritesRepository {
  FavouritesRepository(this._database);

  final AppDatabase _database;

  Stream<List<String>> watchFavouriteIds() {
    final query = _database.select(_database.favourites)
      ..orderBy([(table) => OrderingTerm.asc(table.addedAt)]);
    return query.watch().map((rows) => rows.map((row) => row.mosqueId).toList());
  }

  Stream<List<Mosque>> watchFavouriteMosques() {
    final query = _database.select(_database.favourites).join([
      innerJoin(
        _database.mosques,
        _database.mosques.id.equalsExp(_database.favourites.mosqueId),
      ),
    ])
      ..orderBy([OrderingTerm.asc(_database.favourites.addedAt)]);

    return query.watch().map(
          (rows) => rows
              .map((row) => mosqueFromRow(row.readTable(_database.mosques)))
              .toList(),
        );
  }

  Future<bool> isFavourite(String mosqueId) async {
    final query = _database.select(_database.favourites)
      ..where((table) => table.mosqueId.equals(mosqueId));
    return (await query.getSingleOrNull()) != null;
  }

  Future<void> toggle(String mosqueId) async {
    final existing = await isFavourite(mosqueId);
    if (existing) {
      await (_database.delete(_database.favourites)
            ..where((table) => table.mosqueId.equals(mosqueId)))
          .go();
      return;
    }

    await _database.into(_database.favourites).insert(
          FavouritesCompanion.insert(
            mosqueId: mosqueId,
            addedAt: DateTime.now(),
          ),
        );
  }
}
