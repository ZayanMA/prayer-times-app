import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prayer_times_core/core.dart';

import '../../services/providers.dart';
import 'almanac_find.dart';
import 'calligraphic_find.dart';
import 'celestial_find.dart';

class FindScreen extends ConsumerWidget {
  const FindScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dir = ref.watch(
      settingsProvider.select((s) => s.designDirection),
    );
    return switch (dir) {
      AppDesignDirection.almanac      => const AlmanacFindScreen(),
      AppDesignDirection.calligraphic => const CalligraphicFindScreen(),
      AppDesignDirection.celestial    => const CelestialFindScreen(),
    };
  }
}
