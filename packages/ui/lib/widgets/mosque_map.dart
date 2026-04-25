import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:prayer_times_core/core.dart';

import '../theme/tokens.dart';

class MosqueMap extends StatelessWidget {
  const MosqueMap({
    super.key,
    required this.mosques,
    this.userLocation,
    this.onMosqueTap,
    this.tileUrl =
        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    this.attribution = '© OpenStreetMap contributors',
  });

  final List<Mosque> mosques;
  final LatLng? userLocation;
  final ValueChanged<Mosque>? onMosqueTap;
  final String tileUrl;
  final String attribution;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initialCenter = _initialCenter();
    final markers = <Marker>[
      for (final mosque in mosques)
        if (mosque.location != null)
          Marker(
            point: ll.LatLng(
              mosque.location!.latitude,
              mosque.location!.longitude,
            ),
            width: 36,
            height: 36,
            child: GestureDetector(
              onTap: onMosqueTap == null ? null : () => onMosqueTap!(mosque),
              child: const _MosquePin(),
            ),
          ),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: FlutterMap(
        options: MapOptions(
          initialCenter: initialCenter,
          initialZoom: userLocation == null ? 6.2 : 12,
          minZoom: 4,
          maxZoom: 18,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: tileUrl,
            userAgentPackageName: 'com.prayer_times_app',
            maxNativeZoom: 19,
          ),
          MarkerClusterLayerWidget(
            options: MarkerClusterLayerOptions(
              maxClusterRadius: 60,
              size: const Size(44, 44),
              markers: markers,
              builder: (context, markers) {
                return Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    markers.length.toString(),
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                );
              },
            ),
          ),
          if (userLocation != null)
            MarkerLayer(
              markers: [
                Marker(
                  point: ll.LatLng(
                    userLocation!.latitude,
                    userLocation!.longitude,
                  ),
                  width: 22,
                  height: 22,
                  child: const _UserDot(),
                ),
              ],
            ),
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Text(
                  attribution,
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  ll.LatLng _initialCenter() {
    if (userLocation != null) {
      return ll.LatLng(userLocation!.latitude, userLocation!.longitude);
    }
    // UK centroid fallback.
    return const ll.LatLng(54.5, -3.0);
  }
}

class _MosquePin extends StatelessWidget {
  const _MosquePin();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(Icons.mosque, color: Colors.white, size: 18),
    );
  }
}

class _UserDot extends StatelessWidget {
  const _UserDot();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiary,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
    );
  }
}
