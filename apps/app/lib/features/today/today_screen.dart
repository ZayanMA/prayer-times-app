import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
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
              tooltip: 'Report wrong times',
              onPressed: () => _reportWrongTimes(context, ref, mosque.id),
              icon: const Icon(Icons.flag_outlined),
            ),
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
                  onSubmitPhoto: () => _submitPhoto(context, ref, mosque.id),
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

Future<void> _reportWrongTimes(
    BuildContext context, WidgetRef ref, String mosqueId) async {
  final repo = ref.read(feedbackRepositoryProvider);
  try {
    await repo.reportWrongTimes(
      mosqueId: mosqueId,
      date: DateTime.now().toIso8601String().substring(0, 10),
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thanks — we\'ll review this mosque\'s times.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not send report. Check your connection.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

Future<void> _submitPhoto(
    BuildContext context, WidgetRef ref, String mosqueId) async {
  final picker = ImagePicker();
  final XFile? file = await picker.pickImage(
    source: ImageSource.camera,
    imageQuality: 85,
    maxWidth: 2048,
  );
  if (file == null || !context.mounted) return;

  final bytes = await file.readAsBytes();
  final base64 = base64Encode(bytes);
  final ext = file.path.toLowerCase();
  final mediaType = ext.endsWith('.png') ? 'image/png' : 'image/jpeg';

  if (!context.mounted) return;

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const SimpleDialog(
      children: [
        Padding(
          padding: EdgeInsets.all(24),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Reading timetable…'),
            ],
          ),
        ),
      ],
    ),
  );

  try {
    final repo = ref.read(feedbackRepositoryProvider);
    final result = await repo.submitPhoto(
      mosqueId: mosqueId,
      imageBase64: base64,
      mediaType: mediaType,
    );

    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      if (result.success && result.status != 'noted') {
        ref.invalidate(todayTimetableProvider(mosqueId));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Done — ${result.days ?? 0} day(s) imported. Thanks!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (result.status == 'noted') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('A published timetable already exists.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? 'Could not read the timetable.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  } catch (_) {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not upload photo. Check your connection.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
    required this.onSubmitPhoto,
  });

  final Mosque mosque;
  final VoidCallback onEnableEstimates;
  final VoidCallback onSubmitPhoto;

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
            Text('Prayer times unavailable', style: theme.textTheme.titleLarge),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton.icon(
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Submit a photo'),
                  onPressed: onSubmitPhoto,
                ),
                const SizedBox(width: AppSpacing.md),
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.functions),
                  label: const Text('Show estimated times'),
                  onPressed: onEnableEstimates,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Photo a printed timetable on the wall to share times with everyone.',
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
