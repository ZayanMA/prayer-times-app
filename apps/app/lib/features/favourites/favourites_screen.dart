import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prayer_times_core/core.dart';

import '../../services/providers.dart';
import 'almanac_favourites.dart';
import 'calligraphic_favourites.dart';
import 'celestial_favourites.dart';

class FavouritesScreen extends ConsumerWidget {
  const FavouritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dir = ref.watch(
      settingsProvider.select((s) => s.designDirection),
    );
    return switch (dir) {
      AppDesignDirection.almanac      => const AlmanacFavouritesScreen(),
      AppDesignDirection.calligraphic => const CalligraphicFavouritesScreen(),
      AppDesignDirection.celestial    => const CelestialFavouritesScreen(),
    };
  }
}
