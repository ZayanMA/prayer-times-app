import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prayer_times_core/core.dart';
import 'package:prayer_times_ui/ui.dart';

import '../../services/providers.dart';

class CalligraphicFavouritesScreen extends ConsumerWidget {
  const CalligraphicFavouritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favMosques = ref.watch(favouriteMosquesProvider);
    final userLocation = ref.watch(userLocationProvider).valueOrNull;

    return Scaffold(
      backgroundColor: BTokens.bg,
      body: favMosques.when(
        loading: () => Center(
          child: Text('Loading...', style: BTokens.body(size: 13, color: BTokens.ink60)),
        ),
        error: (_, __) => const SizedBox.shrink(),
        data: (mosques) {
          if (mosques.isEmpty) return _BEmptyFavourites();
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SAVED',
                        style: BTokens.body(size: 10, color: BTokens.gold, letterSpacing: 2.4)),
                    const SizedBox(height: 4),
                    Text('Favourites', style: BTokens.display(size: 38, italic: true)),
                  ],
                ),
              ),
              // Cards
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Column(
                  children: mosques.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final m = entry.value;
                    final distance = (userLocation != null && m.location != null)
                        ? haversineKm(userLocation, m.location!)
                        : null;

                    return GestureDetector(
                      onTap: () async {
                        await ref
                            .read(activeMosqueIdProvider.notifier)
                            .setActiveMosque(m.id);
                        if (context.mounted) context.go('/');
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: BTokens.bgAlt,
                          border: Border.all(color: BTokens.ink20),
                        ),
                        child: Stack(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(m.name,
                                    style: BTokens.display(size: 19, italic: true)),
                                const SizedBox(height: 4),
                                Text(
                                  '${m.area.toUpperCase()} · ${distance != null ? "${distance.toStringAsFixed(1)} km" : ""}',
                                  style: BTokens.body(
                                      size: 10,
                                      color: BTokens.ink40,
                                      letterSpacing: 1.0),
                                ),
                                const SizedBox(height: 12),
                                IntrinsicHeight(
                                  child: Row(
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text("NEXT — ASR",
                                              style: BTokens.body(
                                                  size: 9,
                                                  color: BTokens.ink40,
                                                  letterSpacing: 2.0)),
                                          Text(
                                            '—',
                                            style: BTokens.display(
                                                size: 22, color: BTokens.gold)
                                                .copyWith(fontFeatures: const [
                                              FontFeature.tabularFigures()
                                            ]),
                                          ),
                                        ],
                                      ),
                                      Container(
                                          width: 1,
                                          color: BTokens.ink20,
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 16)),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text("JAMĀ'AH",
                                              style: BTokens.body(
                                                  size: 9,
                                                  color: BTokens.ink40,
                                                  letterSpacing: 2.0)),
                                          Text(
                                            '—',
                                            style: BTokens.display(size: 22)
                                                .copyWith(fontFeatures: const [
                                              FontFeature.tabularFigures()
                                            ]),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            // № badge top-right
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Text(
                                '№ ${(idx + 1).toString().padLeft(2, '0')}',
                                style: BTokens.display(
                                    size: 11,
                                    italic: true,
                                    color: BTokens.gold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 28),
            ],
          );
        },
      ),
    );
  }
}

class _BEmptyFavourites extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SAVED',
              style: BTokens.body(size: 10, color: BTokens.gold, letterSpacing: 2.4)),
          const SizedBox(height: 4),
          Text('Favourites', style: BTokens.display(size: 38, italic: true)),
          const SizedBox(height: 24),
          Text(
            'Find a mosque and tap ✦ to save it here.',
            style: BTokens.body(size: 13, color: BTokens.ink60),
          ),
        ],
      ),
    );
  }
}
