import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prayer_times_core/core.dart';

import '../../services/providers.dart';
import 'almanac_settings.dart';
import 'calligraphic_settings.dart';
import 'celestial_settings.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dir = ref.watch(
      settingsProvider.select((s) => s.designDirection),
    );
    return switch (dir) {
      AppDesignDirection.almanac      => const AlmanacSettingsScreen(),
      AppDesignDirection.calligraphic => const CalligraphicSettingsScreen(),
      AppDesignDirection.celestial    => const CelestialSettingsScreen(),
    };
  }
}
