import 'package:prayer_times_core/core.dart';

enum MosqueFindView { list, map }

enum MosqueFindFilter { nearest, published, favourites, southampton }

const mosqueFindFilters = <MosqueFindFilter>[
  MosqueFindFilter.nearest,
  MosqueFindFilter.published,
  MosqueFindFilter.favourites,
  MosqueFindFilter.southampton,
];

String mosqueFindFilterLabel(MosqueFindFilter filter) {
  return switch (filter) {
    MosqueFindFilter.nearest => 'NEAREST',
    MosqueFindFilter.published => 'TIMETABLED',
    MosqueFindFilter.favourites => 'FAVOURITES',
    MosqueFindFilter.southampton => 'SOUTHAMPTON',
  };
}

String mosqueLocationSummary(Mosque mosque) {
  final parts = <String>[];
  final area = mosque.area.trim();
  final city = mosque.city.trim();
  if (area.isNotEmpty && area.toLowerCase() != 'unknown') parts.add(area);
  if (city.isNotEmpty &&
      city.toLowerCase() != 'unknown' &&
      city.toLowerCase() != area.toLowerCase()) {
    parts.add(city);
  }
  if (mosque.postcode case final postcode?) {
    if (postcode.trim().isNotEmpty) parts.add(postcode.trim());
  }
  if (parts.isNotEmpty) return parts.join(', ');

  if (mosque.addressLine case final address?) {
    if (address.trim().isNotEmpty) return address.trim();
  }
  if (mosque.hasLocation) return 'Location on map';
  return 'Location unavailable';
}

String mosqueAddressSummary(Mosque mosque) {
  final parts = <String>[
    if (mosque.addressLine case final address?)
      if (address.trim().isNotEmpty) address.trim(),
    mosqueLocationSummary(mosque),
  ];
  return parts.toSet().join(', ');
}

List<Mosque> buildMosqueResults({
  required List<Mosque> mosques,
  required String query,
  required MosqueFindFilter filter,
  required List<String> favouriteIds,
  required LatLng? userLocation,
}) {
  final q = query.trim().toLowerCase();
  final results = mosques.where((mosque) {
    if (q.isNotEmpty && !_matchesQuery(mosque, q)) {
      return false;
    }

    return switch (filter) {
      MosqueFindFilter.nearest => true,
      MosqueFindFilter.published => mosque.sourceKind != SourceKind.calculated,
      MosqueFindFilter.favourites => favouriteIds.contains(mosque.id),
      MosqueFindFilter.southampton => _isSouthampton(mosque),
    };
  }).toList();

  if (filter == MosqueFindFilter.nearest && userLocation != null) {
    results.sort((a, b) {
      final aLocation = a.location;
      final bLocation = b.location;
      if (aLocation == null && bLocation == null) {
        return a.name.compareTo(b.name);
      }
      if (aLocation == null) return 1;
      if (bLocation == null) return -1;
      return haversineKm(userLocation, aLocation)
          .compareTo(haversineKm(userLocation, bLocation));
    });
    return results;
  }

  results.sort((a, b) => a.name.compareTo(b.name));
  return results;
}

bool _matchesQuery(Mosque mosque, String query) {
  return mosque.name.toLowerCase().contains(query) ||
      mosque.area.toLowerCase().contains(query) ||
      mosque.city.toLowerCase().contains(query) ||
      (mosque.addressLine?.toLowerCase().contains(query) ?? false) ||
      (mosque.postcode?.toLowerCase().contains(query) ?? false);
}

bool _isSouthampton(Mosque mosque) {
  final postcode = mosque.postcode?.toLowerCase() ?? '';
  return mosque.city.toLowerCase().contains('southampton') ||
      mosque.area.toLowerCase().contains('southampton') ||
      postcode.startsWith('so14') ||
      postcode.startsWith('so15') ||
      postcode.startsWith('so16') ||
      postcode.startsWith('so17') ||
      postcode.startsWith('so18') ||
      postcode.startsWith('so19');
}
