import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:prayer_times_core/core.dart';

import '../theme/tokens.dart';

class NextPrayerHero extends StatefulWidget {
  const NextPrayerHero({
    super.key,
    required this.day,
    required this.previousIsha,
    required this.use24h,
    required this.mosqueName,
  });

  final DailyTimetable day;
  final DateTime? previousIsha;
  final bool use24h;
  final String mosqueName;

  @override
  State<NextPrayerHero> createState() => _NextPrayerHeroState();
}

class _NextPrayerHeroState extends State<NextPrayerHero> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final entries = _entriesFor(widget.day);
    final (current, next) = _currentAndNext(entries, _now);
    final gradient = AppGradients.heroForTime(_now, dark: isDark);
    final timeFormat = widget.use24h ? DateFormat.Hm() : DateFormat('h:mm a');

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.xl),
      child: Container(
        decoration: BoxDecoration(gradient: gradient),
        padding: const EdgeInsets.all(AppSpacing.lg),
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.mosqueName,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (next != null) ...[
              const Text(
                'Next prayer',
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                next.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _countdown(next.begins.difference(_now)),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'at ${timeFormat.format(next.begins)}',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ] else ...[
              const Text(
                "Today's prayers complete",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (current != null) ...[
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.circle,
                        color: Colors.white, size: 8),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Currently ${current.name}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<PrayerTimeEntry> _entriesFor(DailyTimetable day) {
    return day.prayerTimes.entries
        .where((entry) => entry.name != 'Sunrise')
        .toList();
  }

  (PrayerTimeEntry?, PrayerTimeEntry?) _currentAndNext(
    List<PrayerTimeEntry> entries,
    DateTime now,
  ) {
    PrayerTimeEntry? current;
    PrayerTimeEntry? next;
    for (final entry in entries) {
      if (entry.begins.isAfter(now)) {
        next = entry;
        break;
      }
      current = entry;
    }
    return (current, next);
  }

  String _countdown(Duration d) {
    if (d.isNegative) return 'now';
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    if (hours == 0 && minutes == 0) return 'in <1 minute';
    if (hours == 0) return 'in ${minutes}m';
    return 'in ${hours}h ${minutes}m';
  }
}
