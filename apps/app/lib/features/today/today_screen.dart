import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:prayer_times_core/core.dart';
import 'package:prayer_times_ui/ui.dart';

import '../../services/providers.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mosques = ref.watch(mosquesProvider);
    final mosque = ref.watch(activeMosqueProvider);
    final settings = ref.watch(settingsProvider);
    final favourites =
        ref.watch(favouriteIdsProvider).valueOrNull ?? const <String>[];

    return mosques.when(
      loading: () => const _Frame(child: _Loading()),
      error: (error, _) =>
          const _Frame(child: _Error('Could not load mosques.')),
      data: (items) {
        if (items.isEmpty) {
          return const _Frame(child: _Empty(message: 'No mosques available.'));
        }
        if (mosque == null) {
          return const _Frame(
            child: _Empty(message: 'Pick a mosque from Find to begin.'),
          );
        }

        final isFavourite = favourites.contains(mosque.id);
        final timetable = ref.watch(todayTimetableProvider(mosque.id));
        final use24h = settings.timeFormat == TimeFormat.h24;

        return _Frame(
          actions: [
            IconButton(
              tooltip: isFavourite ? 'Remove favourite' : 'Add favourite',
              onPressed: () => ref
                  .read(favouritesRepositoryProvider)
                  .toggle(mosque.id),
              icon: Icon(
                isFavourite ? Icons.favorite : Icons.favorite_border,
                color: isFavourite ? Theme.of(context).colorScheme.primary : null,
              ),
            ),
            IconButton(
              tooltip: 'Change mosque',
              onPressed: () => context.go('/find'),
              icon: const Icon(Icons.swap_horiz),
            ),
          ],
          child: timetable.when(
            loading: () => const _Loading(),
            error: (_, __) => const _Error('Could not load times.'),
            data: (day) {
              if (day == null) {
                return _UnavailableState(
                  mosque: mosque,
                  onEnableEstimates: () => ref
                      .read(settingsProvider.notifier)
                      .update(settings.copyWith(showEstimatedTimes: true)),
                );
              }
              return _TodayBody(
                mosque: mosque,
                day: day,
                use24h: use24h,
              );
            },
          ),
        );
      },
    );
  }
}

class _Frame extends StatelessWidget {
  const _Frame({required this.child, this.actions = const []});
  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          title: const Text('Today'),
          actions: actions,
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          sliver: SliverToBoxAdapter(child: child),
        ),
      ],
    );
  }
}

class _TodayBody extends StatelessWidget {
  const _TodayBody({
    required this.mosque,
    required this.day,
    required this.use24h,
  });

  final Mosque mosque;
  final DailyTimetable day;
  final bool use24h;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('EEEE d MMMM');
    final timeFormat = use24h ? DateFormat.Hm() : DateFormat('h:mm a');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NextPrayerHero(
          day: day,
          previousIsha: null,
          use24h: use24h,
          mosqueName: mosque.name,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(dateFormat.format(day.date), style: theme.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.xs),
        Text(
          mosque.addressLine != null
              ? '${mosque.addressLine}, ${mosque.city}'
              : '${mosque.area}, ${mosque.city}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Prayer',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Text(
                        'Begins',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (day.prayerTimes.entries.any(
                          (e) => e.jamaat != null)) ...[
                        const SizedBox(width: AppSpacing.lg),
                        Text(
                          'Jamaat',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Divider(height: 1),
                for (var i = 0; i < day.prayerTimes.entries.length; i++) ...[
                  _PrayerLine(
                    entry: day.prayerTimes.entries[i],
                    timeFormat: timeFormat,
                  ),
                  if (i < day.prayerTimes.entries.length - 1)
                    const Divider(
                      height: 1,
                      indent: AppSpacing.md,
                      endIndent: AppSpacing.md,
                    ),
                ],
              ],
            ),
          ),
        ),
        if (day.isCalculated) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            'Estimated times — this mosque does not publish a timetable.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }
}

class _PrayerLine extends StatelessWidget {
  const _PrayerLine({required this.entry, required this.timeFormat});
  final PrayerTimeEntry entry;
  final DateFormat timeFormat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(entry.name, style: theme.textTheme.titleMedium),
          ),
          Text(
            timeFormat.format(entry.begins),
            style: theme.textTheme.titleMedium?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
              fontWeight: FontWeight.w600,
            ),
          ),
          if (entry.jamaat != null) ...[
            const SizedBox(width: AppSpacing.lg),
            Text(
              timeFormat.format(entry.jamaat!),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _UnavailableState extends StatelessWidget {
  const _UnavailableState({
    required this.mosque,
    required this.onEnableEstimates,
  });

  final Mosque mosque;
  final VoidCallback onEnableEstimates;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.schedule_outlined,
                size: 40,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Prayer times unavailable',
                style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(
                '${mosque.name} hasn\'t published a timetable we can read yet.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.tonalIcon(
              icon: const Icon(Icons.functions),
              label: const Text('Show estimated times instead'),
              onPressed: onEnableEstimates,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Estimates are calculated from the mosque\'s coordinates.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: CircularProgressIndicator(),
        ),
      );
}

class _Empty extends StatelessWidget {
  const _Empty({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(48),
        child: Center(child: Text(message)),
      );
}

class _Error extends StatelessWidget {
  const _Error(this.message);
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(48),
        child: Center(child: Text(message)),
      );
}
