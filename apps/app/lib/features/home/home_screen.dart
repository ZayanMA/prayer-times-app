import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:prayer_times_core/core.dart';
import 'package:prayer_times_ui/ui.dart';

import '../../services/providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mosques = ref.watch(mosquesProvider);
    final activeMosqueId = ref.watch(activeMosqueIdProvider);

    return mosques.when(
      loading: () => const _PageFrame(child: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) => _PageFrame(
        child: _ErrorState(message: 'Unable to load mosques: $error'),
      ),
      data: (items) {
        if (items.isEmpty) {
          return const _PageFrame(
            child: _EmptyState(message: 'No mosques are available yet.'),
          );
        }

        final mosque = items.firstWhere(
          (item) => item.id == activeMosqueId,
          orElse: () => items.first,
        );
        final timetable = ref.watch(todayTimetableProvider(mosque.id));

        return _PageFrame(
          title: mosque.name,
          subtitle: '${mosque.area}, ${mosque.city}',
          child: timetable.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => _ErrorState(
              message: 'Unable to load today\'s times: $error',
            ),
            data: (day) => _TodayPanel(mosque: mosque, day: day),
          ),
        );
      },
    );
  }
}

class _TodayPanel extends StatelessWidget {
  const _TodayPanel({
    required this.mosque,
    required this.day,
  });

  final Mosque mosque;
  final DailyTimetable day;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('EEEE d MMMM');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            Chip(
              avatar: Icon(
                day.isCalculated
                    ? Icons.functions
                    : day.isStale
                        ? Icons.warning_amber_outlined
                        : Icons.verified_outlined,
                size: 18,
              ),
              label: Text(
                day.isCalculated
                    ? 'Calculated fallback'
                    : day.isStale
                        ? 'Stale mosque times'
                        : mosque.sourceKind.label,
              ),
            ),
            Chip(
              avatar: const Icon(Icons.today_outlined, size: 18),
              label: Text(dateFormat.format(day.date)),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Card(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Prayer',
                        style: theme.textTheme.labelLarge,
                      ),
                    ),
                    Text('Begins', style: theme.textTheme.labelLarge),
                    if (day.prayerTimes.entries.any((entry) => entry.jamaat != null)) ...[
                      const SizedBox(width: AppSpacing.md),
                      Text('Jamaat', style: theme.textTheme.labelLarge),
                    ],
                  ],
                ),
              ),
              const Divider(height: 1),
              for (final entry in day.prayerTimes.entries) PrayerRow(entry: entry),
            ],
          ),
        ),
      ],
    );
  }
}

class _PageFrame extends StatelessWidget {
  const _PageFrame({
    this.title = 'Today',
    this.subtitle,
    required this.child,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          sliver: SliverToBoxAdapter(child: child),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(message));
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(message, textAlign: TextAlign.center));
  }
}
