import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prayer_times_core/core.dart';
import 'package:prayer_times_ui/ui.dart';

import '../../services/providers.dart';

class CelestialFavouritesScreen extends ConsumerStatefulWidget {
  const CelestialFavouritesScreen({super.key});

  @override
  ConsumerState<CelestialFavouritesScreen> createState() =>
      _CelestialFavouritesScreenState();
}

class _CelestialFavouritesScreenState
    extends ConsumerState<CelestialFavouritesScreen> {
  DateTime _now = DateTime.now();
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 5),
        (_) => setState(() => _now = DateTime.now()));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final favMosques = ref.watch(favouriteMosquesProvider);
    final userLocation = ref.watch(userLocationProvider).valueOrNull;
    final gradient = CTokens.skyGradient(_now);

    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(gradient: gradient),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: favMosques.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: Colors.white54),
            ),
            error: (_, __) => const SizedBox.shrink(),
            data: (mosques) {
              if (mosques.isEmpty) {
                return ListView(
                  padding: const EdgeInsets.fromLTRB(22, 60, 22, 24),
                  children: [
                    Text('Saved', style: CTokens.body(size: 11, color: CTokens.ink70)),
                    const SizedBox(height: 2),
                    Text('Favourites', style: CTokens.serif(size: 36, w: FontWeight.w300)),
                    const SizedBox(height: 24),
                    Text(
                      'Find a mosque and tap ★ to save it here.',
                      style: CTokens.body(size: 14, color: CTokens.ink70),
                    ),
                  ],
                );
              }

              return ListView(
                padding: EdgeInsets.zero,
                children: [
                  const SizedBox(height: 60),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 0, 22, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Saved', style: CTokens.body(size: 11, color: CTokens.ink70)),
                        const SizedBox(height: 2),
                        Text('Favourites', style: CTokens.serif(size: 36, w: FontWeight.w300)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    child: Column(
                      children: mosques.map((m) {
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
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(22),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.18),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.baseline,
                                        textBaseline: TextBaseline.alphabetic,
                                        children: [
                                          Text(m.name,
                                              style: CTokens.serif(
                                                  size: 18, w: FontWeight.w400)),
                                          if (distance != null)
                                            Text(
                                              '${distance.toStringAsFixed(1)} km',
                                              style: CTokens.body(
                                                  size: 10, color: CTokens.ink70),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text('NEXT',
                                                  style: CTokens.body(
                                                      size: 9,
                                                      color: CTokens.ink40,
                                                      letterSpacing: 2.0)),
                                              Text('Asr',
                                                  style: CTokens.serif(
                                                      size: 22,
                                                      color: CTokens.gold,
                                                      w: FontWeight.w300)),
                                            ],
                                          ),
                                          const SizedBox(width: 18),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text('BEGINS',
                                                  style: CTokens.body(
                                                      size: 9,
                                                      color: CTokens.ink40,
                                                      letterSpacing: 2.0)),
                                              Text('—',
                                                  style: CTokens.mono(size: 18)),
                                            ],
                                          ),
                                          const SizedBox(width: 18),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text("JAMĀ'AH",
                                                  style: CTokens.body(
                                                      size: 9,
                                                      color: CTokens.ink40,
                                                      letterSpacing: 2.0)),
                                              Text('—',
                                                  style: CTokens.mono(
                                                      size: 18,
                                                      color: CTokens.ink70)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
