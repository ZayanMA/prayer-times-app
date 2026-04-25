import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prayer_times_ui/ui.dart';

import '../../services/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favouriteMosques = ref.watch(favouriteMosquesProvider);
    final activeMosqueId = ref.watch(activeMosqueIdProvider);

    return CustomScrollView(
      slivers: [
        const SliverAppBar(
          pinned: true,
          title: Text('Settings'),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          sliver: favouriteMosques.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stackTrace) => SliverFillRemaining(
              child: Center(child: Text('Unable to load favourites: $error')),
            ),
            data: (mosques) {
              if (mosques.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text('Favourite a mosque before choosing an active mosque.'),
                  ),
                );
              }

              return SliverList.builder(
                itemCount: (mosques.length + 1) * 2 - 1,
                itemBuilder: (context, index) {
                  if (index.isOdd) {
                    return const SizedBox(height: AppSpacing.sm);
                  }

                  final itemIndex = index ~/ 2;
                  if (itemIndex == 0) {
                    return Text(
                      'Active mosque',
                      style: Theme.of(context).textTheme.titleLarge,
                    );
                  }

                  final mosque = mosques[itemIndex - 1];
                  final selected = mosque.id == activeMosqueId;
                  return MosqueTile(
                    mosque: mosque,
                    isFavourite: true,
                    onFavouriteToggle: () {},
                    onTap: () => ref
                        .read(activeMosqueIdProvider.notifier)
                        .setActiveMosque(mosque.id),
                    trailing: IconButton(
                      tooltip: selected ? 'Active mosque' : 'Set active mosque',
                      onPressed: selected
                          ? null
                          : () => ref
                              .read(activeMosqueIdProvider.notifier)
                              .setActiveMosque(mosque.id),
                      icon: Icon(
                        selected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
