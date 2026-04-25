import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prayer_times_core/core.dart';
import 'package:prayer_times_data/data.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'location_service.dart';

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

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final repo = SettingsRepository(ref.watch(sharedPreferencesProvider));
  ref.onDispose(repo.dispose);
  return repo;
});

final settingsProvider =
    StateNotifierProvider<SettingsController, AppSettings>((ref) {
  return SettingsController(ref.watch(settingsRepositoryProvider));
});

class SettingsController extends StateNotifier<AppSettings> {
  SettingsController(this._repository) : super(_repository.read());

  final SettingsRepository _repository;

  Future<void> update(AppSettings settings) async {
    state = settings;
    await _repository.save(settings);
  }
}

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

final userLocationProvider = FutureProvider<LatLng?>((ref) async {
  final settings = ref.watch(settingsProvider);
  final manual = settings.manualLocation;
  if (!settings.useDeviceLocation && manual != null) {
    return LatLng(manual.latitude, manual.longitude);
  }
  if (!settings.useDeviceLocation) return null;
  final detected = await ref.watch(locationServiceProvider).currentPosition();
  if (detected != null) return detected;
  if (manual != null) return LatLng(manual.latitude, manual.longitude);
  return null;
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

final activeMosqueProvider = Provider<Mosque?>((ref) {
  final id = ref.watch(activeMosqueIdProvider);
  final mosques = ref.watch(mosquesProvider).valueOrNull ?? const [];
  if (id == null) return mosques.isEmpty ? null : mosques.first;
  for (final mosque in mosques) {
    if (mosque.id == id) return mosque;
  }
  return mosques.isEmpty ? null : mosques.first;
});

/// Today's timetable for any mosque, or `null` when the mosque has no
/// published timetable and the user has not opted into estimated times.
/// Reads cache first; refreshes on demand only when cache is stale or
/// missing — non-favourite, non-active mosques are fetched lazily.
final todayTimetableProvider =
    FutureProvider.family<DailyTimetable?, String>((ref, mosqueId) {
  final repo = ref.watch(timetableRepositoryProvider);
  final allowEstimation =
      ref.watch(settingsProvider.select((s) => s.showEstimatedTimes));
  return repo.getOrRefreshDay(
    mosqueId,
    DateTime.now(),
    allowEstimation: allowEstimation,
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
