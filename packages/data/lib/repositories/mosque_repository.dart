import 'package:drift/drift.dart';
import 'package:prayer_times_core/core.dart';

import '../database/database.dart';
import '../remote/remote_catalog_client.dart';

class MosqueRepository {
  MosqueRepository(
    this._database, {
    RemoteCatalogClient? remoteCatalogClient,
  }) : _remoteCatalogClient = remoteCatalogClient;

  final AppDatabase _database;
  final RemoteCatalogClient? _remoteCatalogClient;

  Stream<List<Mosque>> watchMosques() {
    final query = _database.select(_database.mosques)
      ..where((table) => table.isActive.equals(true))
      ..orderBy([(table) => OrderingTerm.asc(table.name)]);
    return query.watch().map((rows) => rows.map(mosqueFromRow).toList());
  }

  Stream<Mosque?> watchMosque(String mosqueId) {
    final query = _database.select(_database.mosques)
      ..where((table) => table.id.equals(mosqueId));
    return query.watchSingleOrNull().map(
          (row) => row == null ? null : mosqueFromRow(row),
        );
  }

  Future<Mosque?> getMosque(String mosqueId) async {
    final query = _database.select(_database.mosques)
      ..where((table) => table.id.equals(mosqueId));
    final row = await query.getSingleOrNull();
    return row == null ? null : mosqueFromRow(row);
  }

  Future<void> syncRemoteCatalog() async {
    final client = _remoteCatalogClient;
    if (client == null) {
      return;
    }

    final remoteMosques = await client.fetchMosques();
    await _database.transaction(() async {
      for (final mosque in remoteMosques) {
        await _database.into(_database.mosques).insertOnConflictUpdate(
              MosquesCompanion.insert(
                id: mosque.id,
                name: mosque.name,
                slug: mosque.slug,
                area: mosque.area,
                city: mosque.city,
                websiteUrl: mosque.websiteUrl.toString(),
                sourceKind: mosque.sourceKind.name,
                updatedAt: Value(mosque.updatedAt),
                isActive: Value(mosque.isActive),
              ),
            );
      }
    });
  }
}
