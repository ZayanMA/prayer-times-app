import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:prayer_times_core/core.dart';
import 'package:prayer_times_ui/ui.dart';

import '../../services/providers.dart';

class AlmanacTodayScreen extends ConsumerStatefulWidget {
  const AlmanacTodayScreen({super.key});

  @override
  ConsumerState<AlmanacTodayScreen> createState() => _AlmanacTodayScreenState();
}

class _AlmanacTodayScreenState extends ConsumerState<AlmanacTodayScreen> {
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
      return _AFrame(
        child: Center(
          child: Text(
            'Pick a mosque from Find to begin.',
            style: ATokens.mono(size: 12, color: ATokens.ink60),
          ),
        ),
      );
    }

    final timetable = ref.watch(todayTimetableProvider(mosque.id));
    final use24h = settings.timeFormat == TimeFormat.h24;
    final isFav = favourites.contains(mosque.id);

    return _AFrame(
      actions: [
        _AIconBtn(
          icon: Icons.flag_outlined,
          tooltip: 'Report wrong times',
          onPressed: () => _reportWrongTimes(context, ref, mosque.id),
        ),
        _AIconBtn(
          icon: isFav ? Icons.star : Icons.star_border,
          tooltip: isFav ? 'Remove favourite' : 'Add favourite',
          onPressed: () =>
              ref.read(favouritesRepositoryProvider).toggle(mosque.id),
        ),
        _AIconBtn(
          icon: Icons.swap_horiz,
          tooltip: 'Switch mosque',
          onPressed: () => context.go('/find'),
        ),
      ],
      child: timetable.when(
        loading: () => Center(
          child: Text('Loading...',
              style: ATokens.mono(size: 11, color: ATokens.ink60)),
        ),
        error: (_, __) => Center(
          child: Text('Error loading timetable.',
              style: ATokens.mono(size: 11, color: ATokens.accent)),
        ),
        data: (day) {
          if (day == null) {
            return _AUnavailable(mosque: mosque, ref: ref);
          }
          return _ABody(
            mosque: mosque,
            day: day,
            use24h: use24h,
            now: _now,
          );
        },
      ),
    );
  }

  void _reportWrongTimes(BuildContext context, WidgetRef ref, String mosqueId) {
    ref.read(feedbackRepositoryProvider).reportWrongTimes(
          mosqueId: mosqueId,
          date: DateTime.now().toIso8601String(),
        );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: ATokens.paperAlt,
        content: Text('Reported. Thank you.',
            style: ATokens.mono(size: 11, color: ATokens.ink)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _AFrame extends StatelessWidget {
  const _AFrame({required this.child, this.actions});
  final Widget child;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ATokens.paper,
      appBar: AppBar(
        backgroundColor: ATokens.paper,
        foregroundColor: ATokens.ink,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: actions,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: ATokens.ink20),
        ),
      ),
      body: child,
    );
  }
}

class _AIconBtn extends StatelessWidget {
  const _AIconBtn({required this.icon, required this.onPressed, this.tooltip});
  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: ATokens.ink, size: 18),
      tooltip: tooltip,
      onPressed: onPressed,
    );
  }
}

class _ABody extends StatelessWidget {
  const _ABody({
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

    // Find next/current prayer
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
        _AHeader(hijri: hijri, now: now, mosque: mosque),
        _ANextPrayer(
            next: nextEntry, now: now, use24h: use24h, timeFormat: timeFormat),
        _APrayerTable(
            entries: entries, now: now, use24h: use24h, timeFormat: timeFormat),
        _AMosqueFooter(mosque: mosque),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _AHeader extends StatelessWidget {
  const _AHeader({
    required this.hijri,
    required this.now,
    required this.mosque,
  });
  final HijriCalendar hijri;
  final DateTime now;
  final Mosque mosque;

  @override
  Widget build(BuildContext context) {
    final dayStr = DateFormat('EEE · dd MMM yyyy').format(now).toUpperCase();
    final timeStr = DateFormat.Hm().format(now);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: ATokens.rule, width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Vol. ${hijri.hYear} — № ${hijri.hDay}',
                style: ATokens.mono(
                    size: 9, color: ATokens.ink60, letterSpacing: 1.8),
              ),
              Text(
                '${hijri.hDay} ${hijri.longMonthName} ${hijri.hYear}',
                style: ATokens.mono(
                    size: 9, color: ATokens.ink60, letterSpacing: 1.8),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  mosque.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ATokens.serif(size: 24, italic: true),
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(dayStr,
                      style: ATokens.mono(size: 9, color: ATokens.ink60)),
                  Text(timeStr,
                      style: ATokens.mono(size: 11, color: ATokens.ink)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ANextPrayer extends StatelessWidget {
  const _ANextPrayer({
    required this.next,
    required this.now,
    required this.use24h,
    required this.timeFormat,
  });
  final PrayerTimeEntry? next;
  final DateTime now;
  final bool use24h;
  final DateFormat timeFormat;

  @override
  Widget build(BuildContext context) {
    if (next == null) {
      return Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: ATokens.rule)),
        ),
        child: Text(
          "TODAY'S PRAYERS COMPLETE",
          style:
              ATokens.mono(size: 11, color: ATokens.ink60, letterSpacing: 1.8),
        ),
      );
    }

    final diff = next!.begins.difference(now);
    final countdown = _fmtCountdown(diff);
    final beginsStr = timeFormat.format(next!.begins);
    final jamaatStr =
        next!.jamaat != null ? timeFormat.format(next!.jamaat!) : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: ATokens.rule)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NEXT — IN ${countdown.toUpperCase()}',
            style:
                ATokens.mono(size: 9, color: ATokens.ink60, letterSpacing: 1.8),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                next!.name,
                style: ATokens.serif(size: 64, letterSpacing: -1.5),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    beginsStr,
                    style: ATokens.mono(size: 30).copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  if (jamaatStr != null)
                    Text(
                      "JAMĀ'AH $jamaatStr",
                      style: ATokens.mono(size: 10, color: ATokens.ink60),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ADayStrip(now: now, entries: const []),
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

class _ADayStrip extends StatelessWidget {
  const _ADayStrip({required this.now, required this.entries});
  final DateTime now;
  final List<PrayerTimeEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final h in ['00', '06', '12', '18', '24'])
              Text(h, style: ATokens.mono(size: 9, color: ATokens.ink40)),
          ],
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 14,
          child: CustomPaint(
            size: const Size(double.infinity, 14),
            painter: _DayStripPainter(now: now, entries: entries),
          ),
        ),
      ],
    );
  }
}

class _DayStripPainter extends CustomPainter {
  _DayStripPainter({required this.now, required this.entries});
  final DateTime now;
  final List<PrayerTimeEntry> entries;

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = ATokens.paperAlt;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final borderPaint = Paint()
      ..color = ATokens.rule
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), borderPaint);

    final nowFrac = (now.hour + now.minute / 60.0) / 24.0;
    final nowPaint = Paint()..color = ATokens.accent;
    final nowX = nowFrac * size.width;
    canvas.drawRect(Rect.fromLTWH(nowX - 1, -4, 2, size.height + 4), nowPaint);
  }

  @override
  bool shouldRepaint(_DayStripPainter old) => old.now != now;
}

class _APrayerTable extends StatelessWidget {
  const _APrayerTable({
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
    // Find next
    PrayerTimeEntry? nextEntry;
    for (final e in entries) {
      if (e.name == 'Sunrise') continue;
      if (e.begins.isAfter(now)) {
        nextEntry = e;
        break;
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              SizedBox(
                width: 24,
                child: Text('№',
                    style: ATokens.mono(
                        size: 9, color: ATokens.ink60, letterSpacing: 1.6)),
              ),
              Expanded(
                child: Text('Prayer',
                    style: ATokens.mono(
                        size: 9, color: ATokens.ink60, letterSpacing: 1.6)),
              ),
              SizedBox(
                width: 70,
                child: Text('Begins',
                    textAlign: TextAlign.right,
                    style: ATokens.mono(
                        size: 9, color: ATokens.ink60, letterSpacing: 1.6)),
              ),
              SizedBox(
                width: 70,
                child: Text("Jamā'ah",
                    textAlign: TextAlign.right,
                    style: ATokens.mono(
                        size: 9, color: ATokens.ink60, letterSpacing: 1.6)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(height: 2, color: ATokens.rule),
          ...entries.asMap().entries.map((entry) {
            final idx = entry.key;
            final p = entry.value;
            final isNext = p == nextEntry;
            final passed = !isNext && p.begins.isBefore(now);
            final fgColor = passed ? ATokens.ink40 : ATokens.ink;
            final bgColor = isNext ? ATokens.paperAlt : Colors.transparent;
            final beginsStr = timeFormat.format(p.begins);
            final jamaatStr =
                p.jamaat != null ? timeFormat.format(p.jamaat!) : '—';

            return Container(
              height: 36,
              color: bgColor,
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    child: Text(
                      (idx + 1).toString().padLeft(2, '0'),
                      style: ATokens.mono(size: 10, color: ATokens.ink40),
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          p.name.toLowerCase(),
                          style: ATokens.mono(size: 13, color: fgColor),
                        ),
                        if (isNext) ...[
                          const SizedBox(width: 8),
                          Text(
                            '● NEXT',
                            style: ATokens.mono(
                                size: 9,
                                color: ATokens.accent,
                                letterSpacing: 1.8),
                          ),
                        ] else if (passed) ...[
                          const SizedBox(width: 8),
                          Text(
                            'PASSED',
                            style: ATokens.mono(
                                size: 9,
                                color: ATokens.ink40,
                                letterSpacing: 1.8),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 70,
                    child: Text(
                      beginsStr,
                      textAlign: TextAlign.right,
                      style: ATokens.mono(size: 13, color: fgColor).copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                        decoration: passed ? TextDecoration.lineThrough : null,
                        decorationColor: ATokens.ink40,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 70,
                    child: Text(
                      jamaatStr,
                      textAlign: TextAlign.right,
                      style:
                          ATokens.mono(size: 13, color: ATokens.ink60).copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          Container(height: 2, color: ATokens.rule),
        ],
      ),
    );
  }
}

class _AMosqueFooter extends StatelessWidget {
  const _AMosqueFooter({required this.mosque});
  final Mosque mosque;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('MOSQUE',
              style: ATokens.mono(
                  size: 9, color: ATokens.ink60, letterSpacing: 1.6)),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(mosque.name, style: ATokens.serif(size: 16)),
                    Text(
                      '${mosque.area}, ${mosque.city}',
                      style: ATokens.mono(size: 11, color: ATokens.ink60),
                    ),
                  ],
                ),
              ),
              _AOutlinedBtn(
                label: 'Switch ›',
                onPressed: () => context.go('/find'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AOutlinedBtn extends StatelessWidget {
  const _AOutlinedBtn({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        hoverColor: ATokens.ink20,
        splashColor: ATokens.ink20,
        focusColor: ATokens.ink20,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: ATokens.rule),
          ),
          child: Text(
            label,
            style: ATokens.mono(size: 10, letterSpacing: 1.6),
          ),
        ),
      ),
    );
  }
}

class _AUnavailable extends StatelessWidget {
  const _AUnavailable({required this.mosque, required this.ref});
  final Mosque mosque;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PRAYER TIMES UNAVAILABLE',
            style:
                ATokens.mono(size: 9, color: ATokens.ink60, letterSpacing: 1.8),
          ),
          const SizedBox(height: 8),
          Text(
            mosque.name,
            style: ATokens.serif(size: 18, italic: true),
          ),
          const SizedBox(height: 4),
          Text(
            'This mosque has not published a timetable.',
            style: ATokens.mono(size: 11, color: ATokens.ink60),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _AOutlinedBtn(label: 'SUBMIT A PHOTO', onPressed: () {}),
              const SizedBox(width: 8),
              _AOutlinedBtn(
                label: '≈ ESTIMATES',
                onPressed: () {
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
