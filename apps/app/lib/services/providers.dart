import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prayer_times_core/core.dart';
import 'package:prayer_times_data/data.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _activeMosqueKey = 'active_mosque_id';
const _catalogBaseUrl = String.fromEnvironment(
  'CATALOG_BASE_URL',
  defaultValue: 'http://localhost:8080/catalog/v1/',
);

final databaseProvider = Provider<AppDatabase>((ref) {
  throw StateError('databaseProvider must be overridden at app startup.');
});

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw StateError('sharedPreferencesProvider must be overridden at app startup.');
});

final remoteCatalogClientProvider = Provider<RemoteCatalogClient>((ref) {
  return RemoteCatalogClient(baseUri: Uri.parse(_catalogBaseUrl));
});

final mosqueRepositoryProvider = Provider<MosqueRepository>((ref) {
  return MosqueRepository(
    ref.watch(databaseProvider),
    remoteCatalogClient: ref.watch(remoteCatalogClientProvider),
  );
});

final favouritesRepositoryProvider = Provider<FavouritesRepository>((ref) {
  return FavouritesRepository(ref.watch(databaseProvider));
});

final timetableRepositoryProvider = Provider<TimetableRepository>((ref) {
  return TimetableRepository(
    ref.watch(databaseProvider),
    remoteCatalogClient: ref.watch(remoteCatalogClientProvider),
  );
});

final mosquesProvider = StreamProvider<List<Mosque>>((ref) {
  final repository = ref.watch(mosqueRepositoryProvider);
  unawaited(repository.syncRemoteCatalog().catchError((_) {}));
  return repository.watchMosques();
});

final favouriteIdsProvider = StreamProvider<List<String>>((ref) {
  return ref.watch(favouritesRepositoryProvider).watchFavouriteIds();
});

final favouriteMosquesProvider = StreamProvider<List<Mosque>>((ref) {
  return ref.watch(favouritesRepositoryProvider).watchFavouriteMosques();
});

final activeMosqueIdProvider =
    StateNotifierProvider<ActiveMosqueController, String?>((ref) {
  return ActiveMosqueController(ref.watch(sharedPreferencesProvider));
});

final todayTimetableProvider =
    FutureProvider.family<DailyTimetable, String>((ref, mosqueId) {
  return ref.watch(timetableRepositoryProvider).getOrRefreshDay(
        mosqueId,
        DateTime.now(),
      );
});

class ActiveMosqueController extends StateNotifier<String?> {
  ActiveMosqueController(this._preferences)
      : super(_preferences.getString(_activeMosqueKey));

  final SharedPreferences _preferences;

  Future<void> setActiveMosque(String mosqueId) async {
    state = mosqueId;
    await _preferences.setString(_activeMosqueKey, mosqueId);
  }
}
