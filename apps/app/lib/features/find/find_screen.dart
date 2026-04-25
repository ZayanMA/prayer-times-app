import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prayer_times_core/core.dart';
import 'package:prayer_times_ui/ui.dart';

import '../../services/providers.dart';

class FindScreen extends ConsumerStatefulWidget {
  const FindScreen({super.key});

  @override
  ConsumerState<FindScreen> createState() => _FindScreenState();
}

enum _ViewMode { list, map }

class _FindScreenState extends ConsumerState<FindScreen> {
  String _query = '';
  _ViewMode _mode = _ViewMode.list;

  @override
  Widget build(BuildContext context) {
    final mosques = ref.watch(mosquesProvider);
    final favourites =
        ref.watch(favouriteIdsProvider).valueOrNull ?? const <String>[];
    final userLocation = ref.watch(userLocationProvider).valueOrNull;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          title: const Text('Find a mosque'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: SegmentedButton<_ViewMode>(
                showSelectedIcon: false,
                style: SegmentedButton.styleFrom(
                  minimumSize: const Size(0, 44),
                ),
                segments: const [
                  ButtonSegment(
                    value: _ViewMode.list,
                    icon: Icon(Icons.view_list),
                  ),
                  ButtonSegment(
                    value: _ViewMode.map,
                    icon: Icon(Icons.map_outlined),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: (selected) =>
                    setState(() => _mode = selected.first),
              ),
            ),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          sliver: SliverToBoxAdapter(
            child: TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search mosques, areas, postcodes',
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() => _query = ''),
                      ),
              ),
            ),
          ),
        ),
        mosques.when(
          loading: () => const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => const SliverFillRemaining(
            child: Center(child: Text('Could not load mosques.')),
          ),
          data: (items) {
            final filtered = _filtered(items, userLocation);
            if (_mode == _ViewMode.map) {
              return SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  child: SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.7,
                    child: MosqueMap(
                      mosques: filtered.map((e) => e.mosque).toList(),
                      userLocation: userLocation,
                      onMosqueTap: (mosque) =>
                          _showMosqueSheet(context, mosque),
                    ),
                  ),
                ),
              );
            }

            if (filtered.isEmpty) {
              return const SliverFillRemaining(
                hasScrollBody: false,
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
              sliver: SliverList.separated(
                itemCount: filtered.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final entry = filtered[index];
                  return MosqueTile(
                    mosque: entry.mosque,
                    isFavourite: favourites.contains(entry.mosque.id),
                    distanceKm: entry.distanceKm,
                    onTap: () => _showMosqueSheet(context, entry.mosque),
                    onFavouriteToggle: () => ref
                        .read(favouritesRepositoryProvider)
                        .toggle(entry.mosque.id),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  List<_MosqueEntry> _filtered(List<Mosque> mosques, LatLng? userLocation) {
    final query = _query.trim().toLowerCase();
    final entries = mosques.where((m) => m.isActive).map((m) {
      final distance = (userLocation != null && m.location != null)
          ? haversineKm(userLocation, m.location!)
          : null;
      return _MosqueEntry(mosque: m, distanceKm: distance);
    }).where((entry) {
      if (query.isEmpty) return true;
      final m = entry.mosque;
      return m.name.toLowerCase().contains(query) ||
          m.area.toLowerCase().contains(query) ||
          m.city.toLowerCase().contains(query) ||
          (m.postcode?.toLowerCase().contains(query) ?? false);
    }).toList();

    if (userLocation != null) {
      entries.sort((a, b) {
        final ad = a.distanceKm ?? double.infinity;
        final bd = b.distanceKm ?? double.infinity;
        return ad.compareTo(bd);
      });
    } else {
      entries.sort((a, b) => a.mosque.name.compareTo(b.mosque.name));
    }
    return entries;
  }

  void _showMosqueSheet(BuildContext context, Mosque mosque) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => _MosqueDetailSheet(mosque: mosque),
    );
  }
}

class _MosqueDetailSheet extends ConsumerWidget {
  const _MosqueDetailSheet({required this.mosque});
  final Mosque mosque;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favourites =
        ref.watch(favouriteIdsProvider).valueOrNull ?? const <String>[];
    final isFavourite = favourites.contains(mosque.id);
    final theme = Theme.of(context);
    final addressParts = <String>[
      if (mosque.addressLine != null) mosque.addressLine!,
      if (mosque.city.isNotEmpty && mosque.city != 'Unknown') mosque.city,
      if (mosque.postcode != null) mosque.postcode!,
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(mosque.name, style: theme.textTheme.titleLarge),
          if (addressParts.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              addressParts.join(' · '),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.schedule),
                  label: const Text('View today'),
                  onPressed: () async {
                    await ref
                        .read(activeMosqueIdProvider.notifier)
                        .setActiveMosque(mosque.id);
                    if (context.mounted) Navigator.of(context).pop();
                    if (context.mounted) context.go('/');
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FilledButton.tonalIcon(
                  icon: Icon(
                    isFavourite ? Icons.favorite : Icons.favorite_border,
                  ),
                  label: Text(isFavourite ? 'Favourited' : 'Favourite'),
                  onPressed: () => ref
                      .read(favouritesRepositoryProvider)
                      .toggle(mosque.id),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MosqueEntry {
  const _MosqueEntry({required this.mosque, this.distanceKm});
  final Mosque mosque;
  final double? distanceKm;
}
