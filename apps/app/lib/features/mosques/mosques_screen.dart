import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prayer_times_ui/ui.dart';

import '../../services/providers.dart';

class MosquesScreen extends ConsumerStatefulWidget {
  const MosquesScreen({super.key});

  @override
  ConsumerState<MosquesScreen> createState() => _MosquesScreenState();
}

class _MosquesScreenState extends ConsumerState<MosquesScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final mosques = ref.watch(mosquesProvider);
    final favourites = ref.watch(favouriteIdsProvider).valueOrNull ?? const <String>[];

    return CustomScrollView(
      slivers: [
        const SliverAppBar(
          pinned: true,
          title: Text('Mosques'),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          sliver: SliverToBoxAdapter(
            child: TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: 'Search',
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ),
        mosques.when(
          loading: () => const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stackTrace) => SliverFillRemaining(
            child: Center(child: Text('Unable to load mosques: $error')),
          ),
          data: (items) {
            final query = _query.trim().toLowerCase();
            final filtered = items.where((mosque) {
              if (query.isEmpty) {
                return true;
              }
              return mosque.name.toLowerCase().contains(query) ||
                  mosque.area.toLowerCase().contains(query) ||
                  mosque.city.toLowerCase().contains(query);
            }).toList();

            if (filtered.isEmpty) {
              return const SliverFillRemaining(
                child: Center(child: Text('No mosques match your search.')),
              );
            }

            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              sliver: SliverList.builder(
                itemCount: filtered.length * 2 - 1,
                itemBuilder: (context, index) {
                  if (index.isOdd) {
                    return const SizedBox(height: AppSpacing.sm);
                  }

                  final mosque = filtered[index ~/ 2];
                  final isFavourite = favourites.contains(mosque.id);
                  return MosqueTile(
                    mosque: mosque,
                    isFavourite: isFavourite,
                    onTap: () async {
                      await ref
                          .read(activeMosqueIdProvider.notifier)
                          .setActiveMosque(mosque.id);
                      if (context.mounted) {
                        context.go('/');
                      }
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
