import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prayer_times_ui/ui.dart';

import 'features/home/home_screen.dart';
import 'features/mosques/mosques_screen.dart';
import 'features/settings/settings_screen.dart';

final _routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          final location = state.uri.path;
          final selectedIndex = switch (location) {
            '/mosques' => 1,
            '/settings' => 2,
            _ => 0,
          };

          return AppAdaptiveScaffold(
            selectedIndex: selectedIndex,
            destinations: const [
              AdaptiveDestination(icon: Icons.schedule, label: 'Today'),
              AdaptiveDestination(icon: Icons.search, label: 'Mosques'),
              AdaptiveDestination(icon: Icons.settings, label: 'Settings'),
            ],
            onDestinationSelected: (index) {
              context.go(switch (index) {
                1 => '/mosques',
                2 => '/settings',
                _ => '/',
              });
            },
            body: child,
          );
        },
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/mosques',
            builder: (context, state) => const MosquesScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
});

class PrayerTimesApp extends ConsumerWidget {
  const PrayerTimesApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Prayer Times',
      theme: AppTheme.light(),
      routerConfig: ref.watch(_routerProvider),
    );
  }
}
