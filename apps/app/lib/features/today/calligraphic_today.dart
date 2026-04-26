import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:prayer_times_core/core.dart';
import 'package:prayer_times_ui/ui.dart';

import '../../services/providers.dart';

const _arabicNames = {
  'Fajr': 'الفجر',
  'Sunrise': 'الشروق',
  'Dhuhr': 'الظهر',
  'Asr': 'العصر',
  'Maghrib': 'المغرب',
  'Isha': 'العشاء',
};

class CalligraphicTodayScreen extends ConsumerStatefulWidget {
  const CalligraphicTodayScreen({super.key});

  @override
  ConsumerState<CalligraphicTodayScreen> createState() =>
      _CalligraphicTodayScreenState();
}

class _CalligraphicTodayScreenState
    extends ConsumerState<CalligraphicTodayScreen> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30),
        (_) => setState(() => _now = DateTime.now()));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mosque = ref.watch(activeMosqueProvider);
    final settings = ref.watch(settingsProvider);
    final favourites =
        ref.watch(favouriteIdsProvider).valueOrNull ?? const <String>[];

    if (mosque == null) {
      return _BFrame(
        child: Center(
          child: Text(
            'Pick a mosque from Find to begin.',
            style: BTokens.body(size: 14, color: BTokens.ink60),
          ),
        ),
      );
    }

    final timetable = ref.watch(todayTimetableProvider(mosque.id));
    final use24h = settings.timeFormat == TimeFormat.h24;
    final isFav = favourites.contains(mosque.id);

    return _BFrame(
      actions: [
        IconButton(
          icon: Icon(Icons.flag_outlined, color: BTokens.ink60, size: 20),
          tooltip: 'Report wrong times',
          onPressed: () {
            ref.read(feedbackRepositoryProvider).reportWrongTimes(
                  mosqueId: mosque.id,
                  date: DateTime.now().toIso8601String(),
                );
          },
        ),
        IconButton(
          icon: Icon(
            isFav ? Icons.star : Icons.star_border,
            color: isFav ? BTokens.gold : BTokens.ink60,
            size: 20,
          ),
          onPressed: () =>
              ref.read(favouritesRepositoryProvider).toggle(mosque.id),
        ),
      ],
      child: timetable.when(
        loading: () => Center(
          child: Text('Loading...',
              style: BTokens.body(size: 13, color: BTokens.ink60)),
        ),
        error: (_, __) => const SizedBox.shrink(),
        data: (day) {
          if (day == null) {
            return _BUnavailable(mosque: mosque, ref: ref);
          }
          return _BBody(
            mosque: mosque,
            day: day,
            use24h: use24h,
            now: _now,
          );
        },
      ),
    );
  }
}

class _BFrame extends StatelessWidget {
  const _BFrame({required this.child, this.actions});
  final Widget child;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BTokens.bg,
      appBar: AppBar(
        backgroundColor: BTokens.bg,
        foregroundColor: BTokens.ink,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: actions,
        surfaceTintColor: Colors.transparent,
      ),
      body: child,
    );
  }
}

class _BBody extends StatelessWidget {
  const _BBody({
    required this.mosque,
    required this.day,
    required this.use24h,
    required this.now,
  });

  final Mosque mosque;
  final DailyTimetable day;
  final bool use24h;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final hijri = HijriCalendar.fromDate(now);
    final entries = day.prayerTimes.entries;
    final timeFormat = use24h ? DateFormat.Hm() : DateFormat('h:mm a');

    PrayerTimeEntry? nextEntry;
    for (final e in entries) {
      if (e.name == 'Sunrise') continue;
      if (e.begins.isAfter(now)) {
        nextEntry = e;
        break;
      }
    }

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _BHeader(hijri: hijri, now: now, mosque: mosque),
        if (nextEntry != null)
          _BHero(
              next: nextEntry,
              now: now,
              use24h: use24h,
              timeFormat: timeFormat),
        _BOrnamentalRule(),
        _BPrayerTable(
            entries: entries, now: now, use24h: use24h, timeFormat: timeFormat),
        _BMosqueFooter(mosque: mosque),
        const SizedBox(height: 28),
      ],
    );
  }
}

class _BHeader extends StatelessWidget {
  const _BHeader({
    required this.hijri,
    required this.now,
    required this.mosque,
  });

  final HijriCalendar hijri;
  final DateTime now;
  final Mosque mosque;

  @override
  Widget build(BuildContext context) {
    final dayStr = DateFormat('EEE · dd MMM').format(now).toUpperCase();
    final hijriStr = '${hijri.hDay} ${hijri.longMonthName} ${hijri.hYear}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(dayStr,
                  style: BTokens.body(
                      size: 10, color: BTokens.gold, letterSpacing: 2.4)),
              const SizedBox(height: 2),
              Text(hijriStr,
                  style: BTokens.display(
                      size: 11, italic: true, color: BTokens.ink60)),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(mosque.name,
                  style: BTokens.body(size: 11, color: BTokens.ink60)),
            ],
          ),
        ],
      ),
    );
  }
}

class _BHero extends StatelessWidget {
  const _BHero({
    required this.next,
    required this.now,
    required this.use24h,
    required this.timeFormat,
  });

  final PrayerTimeEntry next;
  final DateTime now;
  final bool use24h;
  final DateFormat timeFormat;

  @override
  Widget build(BuildContext context) {
    final diff = next.begins.difference(now);
    final countdown = _fmtCountdown(diff);
    final arabic = _arabicNames[next.name] ?? '';
    final beginsStr = timeFormat.format(next.begins);
    final jamaatStr =
        next.jamaat != null ? timeFormat.format(next.jamaat!) : '—';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
      child: Column(
        children: [
          Text(
            'The next prayer',
            style: BTokens.body(
                size: 9, color: BTokens.goldDim, letterSpacing: 3.6),
          ),
          const SizedBox(height: 4),
          // Arabic letterform hero — 180px Amiri with gold glow
          Text(
            arabic,
            textDirection: TextDirection.rtl,
            style: BTokens.arabic(size: 180, color: BTokens.gold).copyWith(
              height: 1,
              shadows: [
                Shadow(
                    blurRadius: 60,
                    color: BTokens.gold.withValues(alpha: 0.25)),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // Prayer name in 38px Cormorant italic
          Text(
            next.name,
            style: BTokens.display(size: 38, italic: true),
          ),
          const SizedBox(height: 14),
          // Info row: BEGINS | IN | JAMĀ'AH
          IntrinsicHeight(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _InfoCol(label: 'BEGINS', value: beginsStr),
                Container(
                    width: 1,
                    height: 36,
                    color: BTokens.ink20,
                    margin: const EdgeInsets.symmetric(horizontal: 12)),
                _InfoCol(
                    label: 'IN', value: countdown, valueColor: BTokens.gold),
                Container(
                    width: 1,
                    height: 36,
                    color: BTokens.ink20,
                    margin: const EdgeInsets.symmetric(horizontal: 12)),
                _InfoCol(label: "JAMĀ'AH", value: jamaatStr),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmtCountdown(Duration d) {
    if (d.isNegative) return 'now';
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h == 0) return '${m}m';
    return '${h}h ${m.toString().padLeft(2, '0')}m';
  }
}

class _InfoCol extends StatelessWidget {
  const _InfoCol({required this.label, required this.value, this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: BTokens.body(
                size: 9, color: BTokens.ink40, letterSpacing: 2.0)),
        const SizedBox(height: 2),
        Text(
          value,
          style: BTokens.display(size: 28, color: valueColor ?? BTokens.ink)
              .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
        ),
      ],
    );
  }
}

class _BOrnamentalRule extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    BTokens.gold.withValues(alpha: 0.6),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Transform.rotate(
            angle: math.pi / 4,
            child: Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 10),
              color: BTokens.gold,
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    BTokens.gold.withValues(alpha: 0.6),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BPrayerTable extends StatelessWidget {
  const _BPrayerTable({
    required this.entries,
    required this.now,
    required this.use24h,
    required this.timeFormat,
  });

  final List<PrayerTimeEntry> entries;
  final DateTime now;
  final bool use24h;
  final DateFormat timeFormat;

  @override
  Widget build(BuildContext context) {
    PrayerTimeEntry? nextEntry;
    for (final e in entries) {
      if (e.name == 'Sunrise') continue;
      if (e.begins.isAfter(now)) {
        nextEntry = e;
        break;
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        children: entries.map((p) {
          final isNext = p == nextEntry;
          final passed = !isNext && p.begins.isBefore(now);
          final arabic = _arabicNames[p.name] ?? '';
          final beginsStr = timeFormat.format(p.begins);
          final jamaatStr =
              p.jamaat != null ? timeFormat.format(p.jamaat!) : '·';

          return Opacity(
            opacity: passed ? 0.42 : 1.0,
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: BTokens.ink20),
                ),
              ),
              child: Row(
                children: [
                  // Arabic glyph
                  SizedBox(
                    width: 40,
                    child: Text(
                      arabic,
                      textDirection: TextDirection.rtl,
                      style: BTokens.arabic(
                          size: 22,
                          color: isNext ? BTokens.gold : BTokens.ink60),
                    ),
                  ),
                  // English name
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          p.name,
                          style: BTokens.display(
                              size: 17,
                              italic: true,
                              color: isNext ? BTokens.gold : BTokens.ink),
                        ),
                        if (isNext) ...[
                          const SizedBox(width: 10),
                          Text(
                            'NOW',
                            style: BTokens.body(
                                size: 9,
                                color: BTokens.gold,
                                letterSpacing: 2.0),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Begins
                  SizedBox(
                    width: 70,
                    child: Text(
                      beginsStr,
                      textAlign: TextAlign.right,
                      style: BTokens.body(
                              size: 14,
                              color: passed ? BTokens.ink40 : BTokens.ink)
                          .copyWith(fontFeatures: const [
                        FontFeature.tabularFigures()
                      ]),
                    ),
                  ),
                  // Jamaat
                  SizedBox(
                    width: 70,
                    child: Text(
                      jamaatStr,
                      textAlign: TextAlign.right,
                      style: BTokens.body(size: 14, color: BTokens.ink60)
                          .copyWith(fontFeatures: const [
                        FontFeature.tabularFigures()
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _BMosqueFooter extends StatelessWidget {
  const _BMosqueFooter({required this.mosque});
  final Mosque mosque;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('FROM',
                    style: BTokens.body(
                        size: 9, color: BTokens.gold, letterSpacing: 2.0)),
                Text(mosque.name,
                    style: BTokens.display(size: 17, italic: true)),
                Text('${mosque.area}, ${mosque.city}',
                    style: BTokens.body(size: 10, color: BTokens.ink40)),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.go('/find'),
              hoverColor: BTokens.gold.withValues(alpha: 0.12),
              splashColor: BTokens.gold.withValues(alpha: 0.18),
              focusColor: BTokens.gold.withValues(alpha: 0.12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: BTokens.goldDim),
                ),
                child: Text(
                  'SWITCH',
                  style: BTokens.body(
                      size: 10, color: BTokens.gold, letterSpacing: 2.0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BUnavailable extends StatelessWidget {
  const _BUnavailable({required this.mosque, required this.ref});
  final Mosque mosque;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Prayer times unavailable',
              style: BTokens.body(
                  size: 9, color: BTokens.gold, letterSpacing: 2.4)),
          const SizedBox(height: 12),
          Text(mosque.name, style: BTokens.display(size: 26, italic: true)),
          const SizedBox(height: 4),
          Text(
            'This mosque has not published a timetable.',
            style: BTokens.body(size: 12, color: BTokens.ink60),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _BGoldBtn(
                label: 'SUBMIT A PHOTO',
                filled: true,
                onTap: () {},
              ),
              const SizedBox(width: 8),
              _BGoldBtn(
                label: '≈ ESTIMATES',
                filled: false,
                onTap: () {
                  final settings = ref.read(settingsProvider);
                  ref.read(settingsProvider.notifier).update(
                        settings.copyWith(showEstimatedTimes: true),
                      );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BGoldBtn extends StatelessWidget {
  const _BGoldBtn(
      {required this.label, required this.filled, required this.onTap});
  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: filled ? BTokens.gold : Colors.transparent,
          border: Border.all(color: BTokens.goldDim),
        ),
        child: Text(
          label,
          style: BTokens.body(
              size: 10,
              color: filled ? BTokens.bg : BTokens.gold,
              letterSpacing: 2.0),
        ),
      ),
    );
  }
}
