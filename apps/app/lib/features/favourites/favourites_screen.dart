import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prayer_times_core/core.dart';
import 'package:prayer_times_ui/ui.dart';

import '../../services/providers.dart';

class FavouritesScreen extends ConsumerWidget {
  const FavouritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favouriteMosques = ref.watch(favouriteMosquesProvider);
    final activeMosqueId = ref.watch(activeMosqueIdProvider);
    final userLocation = ref.watch(userLocationProvider).valueOrNull;

    return CustomScrollView(
      slivers: [
        const SliverAppBar(
          pinned: true,
          title: Text('Favourites'),
        ),
        favouriteMosques.when(
          loading: () => const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => const SliverFillRemaining(
            child: Center(child: Text('Could not load favourites.')),
          ),
          data: (mosques) {
            if (mosques.isEmpty) {
              return const SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyState(),
              );
            }
            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              sliver: SliverList.separated(
                itemCount: mosques.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final mosque = mosques[index];
                  final isActive = mosque.id == activeMosqueId;
                  final distance =
                      (userLocation != null && mosque.location != null)
                          ? haversineKm(userLocation, mosque.location!)
                          : null;
                  return MosqueTile(
                    mosque: mosque,
                    isFavourite: true,
                    distanceKm: distance,
                    trailing: IconButton(
                      tooltip: 'Remove favourite',
                      icon: Icon(
                        Icons.favorite,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      onPressed: () => ref
                          .read(favouritesRepositoryProvider)
                          .toggle(mosque.id),
                    ),
                    onTap: () async {
                      if (!isActive) {
                        await ref
                            .read(activeMosqueIdProvider.notifier)
                            .setActiveMosque(mosque.id);
                      }
                      if (context.mounted) context.go('/');
                    },
                    onFavouriteToggle: () => ref
                        .read(favouritesRepositoryProvider)
                        .toggle(mosque.id),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.favorite_outline,
              size: 56,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text('No favourites yet', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Find a mosque and tap the heart to keep it here for quick access.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
