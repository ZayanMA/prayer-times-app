import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prayer_times_core/core.dart';

import '../../services/providers.dart';
import 'almanac_today.dart';
import 'calligraphic_today.dart';
import 'celestial_today.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dir = ref.watch(
      settingsProvider.select((s) => s.designDirection),
    );
    return switch (dir) {
      AppDesignDirection.almanac      => const AlmanacTodayScreen(),
      AppDesignDirection.calligraphic => const CalligraphicTodayScreen(),
      AppDesignDirection.celestial    => const CelestialTodayScreen(),
    };
  }
}
