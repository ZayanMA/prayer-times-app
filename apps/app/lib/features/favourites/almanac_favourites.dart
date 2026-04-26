import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prayer_times_core/core.dart';
import 'package:prayer_times_ui/ui.dart';

import '../../services/providers.dart';

class AlmanacFavouritesScreen extends ConsumerWidget {
  const AlmanacFavouritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favMosques = ref.watch(favouriteMosquesProvider);
    final userLocation = ref.watch(userLocationProvider).valueOrNull;

    return Scaffold(
      backgroundColor: ATokens.paper,
      body: favMosques.when(
        loading: () => Center(
          child: Text('Loading...', style: ATokens.mono(size: 11, color: ATokens.ink60)),
        ),
        error: (_, __) => Center(
          child: Text('Error.', style: ATokens.mono(size: 11, color: ATokens.accent)),
        ),
        data: (mosques) {
          if (mosques.isEmpty) {
            return _AEmptyFavourites();
          }
          return _AFavouritesBody(
            mosques: mosques,
            userLocation: userLocation,
            ref: ref,
          );
        },
      ),
    );
  }
}

class _AFavouritesBody extends StatelessWidget {
  const _AFavouritesBody({
    required this.mosques,
    required this.userLocation,
    required this.ref,
  });

  final List<Mosque> mosques;
  final LatLng? userLocation;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: ATokens.rule, width: 2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SECTION 03',
                  style: ATokens.mono(size: 9, color: ATokens.ink60, letterSpacing: 1.8)),
              const SizedBox(height: 4),
              Text('My mosques', style: ATokens.serif(size: 28, italic: true)),
              const SizedBox(height: 2),
              Text(
                '${mosques.length} ENTRIES · TAP TO COMPARE',
                style: ATokens.mono(size: 10, color: ATokens.ink60),
              ),
            ],
          ),
        ),
        // Comparison table header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('MOSQUE',
                        style: ATokens.mono(size: 9, color: ATokens.ink60, letterSpacing: 1.4)),
                  ),
                  for (final label in ['FAJR', 'DHUHR', 'ASR', 'MAGH'])
                    SizedBox(
                      width: 52,
                      child: Text(label,
                          textAlign: TextAlign.right,
                          style: ATokens.mono(size: 9, color: ATokens.ink60, letterSpacing: 1.4)),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Container(height: 2, color: ATokens.rule),
              ...mosques.map((m) {
                final dist = (userLocation != null && m.location != null)
                    ? haversineKm(userLocation!, m.location!)
                    : null;
                return InkWell(
                  onTap: () async {
                    await ref
                        .read(activeMosqueIdProvider.notifier)
                        .setActiveMosque(m.id);
                    if (context.mounted) context.go('/');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: ATokens.ink20)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(m.name, style: ATokens.serif(size: 13)),
                              Text(
                                '${dist != null ? "${dist.toStringAsFixed(1)} km · " : ""}${m.area}, ${m.city}',
                                style: ATokens.mono(size: 9, color: ATokens.ink60),
                              ),
                            ],
                          ),
                        ),
                        // Placeholder prayer times — real timetable data not loaded here
                        for (final _ in List.generate(4, (_) => 0))
                          SizedBox(
                            width: 52,
                            child: Text(
                              '—',
                              textAlign: TextAlign.right,
                              style: ATokens.mono(size: 11, color: ATokens.ink60),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _AEmptyFavourites extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(0, 14, 0, 10),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: ATokens.rule, width: 2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SECTION 03',
                    style: ATokens.mono(size: 9, color: ATokens.ink60, letterSpacing: 1.8)),
                const SizedBox(height: 4),
                Text('My mosques', style: ATokens.serif(size: 28, italic: true)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('0 ENTRIES', style: ATokens.mono(size: 9, color: ATokens.ink60, letterSpacing: 1.8)),
          const SizedBox(height: 8),
          Text(
            'Find a mosque and tap ★ to keep it here.',
            style: ATokens.mono(size: 12, color: ATokens.ink60),
          ),
        ],
      ),
    );
  }
}
