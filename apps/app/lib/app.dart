import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prayer_times_core/core.dart';
import 'package:prayer_times_ui/ui.dart';

import 'features/favourites/favourites_screen.dart';
import 'features/find/find_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/today/today_screen.dart';
import 'services/providers.dart';

final _routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          final location = state.uri.path;
          final selectedIndex = switch (location) {
            '/find' => 1,
            '/favourites' => 2,
            '/settings' => 3,
            _ => 0,
          };

          return AppAdaptiveScaffold(
            selectedIndex: selectedIndex,
            destinations: const [
              AdaptiveDestination(icon: Icons.mosque_outlined, label: 'Today'),
              AdaptiveDestination(icon: Icons.explore_outlined, label: 'Find'),
              AdaptiveDestination(
                icon: Icons.favorite_outline,
                label: 'Favourites',
              ),
              AdaptiveDestination(icon: Icons.tune, label: 'Settings'),
            ],
            onDestinationSelected: (index) {
              context.go(switch (index) {
                1 => '/find',
                2 => '/favourites',
                3 => '/settings',
                _ => '/',
              });
            },
            body: child,
          );
        },
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: TodayScreen(),
            ),
          ),
          GoRoute(
            path: '/find',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: FindScreen(),
            ),
          ),
          GoRoute(
            path: '/favourites',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: FavouritesScreen(),
            ),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsScreen(),
            ),
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
    final settings = ref.watch(settingsProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Prayer Times',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: switch (settings.themeMode) {
        AppThemeMode.system => ThemeMode.system,
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
      },
      routerConfig: ref.watch(_routerProvider),
    );
  }
}
