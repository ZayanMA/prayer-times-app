import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:prayer_times_core/core.dart';
import 'package:prayer_times_ui/ui.dart';

import '../../services/providers.dart';

class CelestialTodayScreen extends ConsumerStatefulWidget {
  const CelestialTodayScreen({super.key});

  @override
  ConsumerState<CelestialTodayScreen> createState() =>
      _CelestialTodayScreenState();
}

class _CelestialTodayScreenState extends ConsumerState<CelestialTodayScreen> {
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
    final gradient = CTokens.skyGradient(_now);

    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(gradient: gradient),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                elevation: 0,
                floating: true,
                automaticallyImplyLeading: false,
                surfaceTintColor: Colors.transparent,
                actions: [
                  if (mosque != null) ...[
                    IconButton(
                      icon: const Icon(Icons.flag_outlined,
                          color: Colors.white70, size: 20),
                      tooltip: 'Report wrong times',
                      onPressed: () =>
                          _reportWrongTimes(context, ref, mosque.id),
                    ),
                    IconButton(
                      icon: Icon(
                        favourites.contains(mosque.id)
                            ? Icons.star
                            : Icons.star_border,
                        color: favourites.contains(mosque.id)
                            ? CTokens.gold
                            : Colors.white70,
                        size: 20,
                      ),
                      onPressed: () => ref
                          .read(favouritesRepositoryProvider)
                          .toggle(mosque.id),
                    ),
                    IconButton(
                      icon: const Icon(Icons.swap_horiz,
                          color: Colors.white70, size: 20),
                      tooltip: 'Switch mosque',
                      onPressed: () => context.go('/find'),
                    ),
                  ],
                ],
              ),
              SliverToBoxAdapter(
                child: mosque == null
                    ? _CEmpty()
                    : _CBody(
                        mosque: mosque,
                        now: _now,
                        settings: settings,
                        ref: ref,
                        onSubmitPhoto: () =>
                            _submitPhoto(context, ref, mosque.id),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _reportWrongTimes(BuildContext context, WidgetRef ref, String mosqueId) {
    ref.read(feedbackRepositoryProvider).reportWrongTimes(
          mosqueId: mosqueId,
          date: _now.toIso8601String(),
        );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.black54,
        content: Text('Reported. Thank you.',
            style: CTokens.body(size: 13, color: Colors.white)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _submitPhoto(
      BuildContext context, WidgetRef ref, String mosqueId) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.camera);
    if (file == null || !context.mounted) return;

    final bytes = await file.readAsBytes();
    final base64 = base64Encode(bytes);
    try {
      await ref.read(feedbackRepositoryProvider).submitPhoto(
            mosqueId: mosqueId,
            imageBase64: base64,
            mediaType: 'image/jpeg',
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.black54,
            content: Text('Photo submitted. Thank you!',
                style: CTokens.body(size: 13, color: Colors.white)),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.black54,
            content: Text("Couldn't submit photo. Please try again.",
                style: CTokens.body(size: 13, color: Colors.white)),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }
}

String base64Encode(List<int> bytes) {
  const chars =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
  final result = StringBuffer();
  for (var i = 0; i < bytes.length; i += 3) {
    final b0 = bytes[i];
    final b1 = i + 1 < bytes.length ? bytes[i + 1] : 0;
    final b2 = i + 2 < bytes.length ? bytes[i + 2] : 0;
    result.write(chars[(b0 >> 2) & 63]);
    result.write(chars[((b0 << 4) | (b1 >> 4)) & 63]);
    result.write(
        i + 1 < bytes.length ? chars[((b1 << 2) | (b2 >> 6)) & 63] : '=');
    result.write(i + 2 < bytes.length ? chars[b2 & 63] : '=');
  }
  return result.toString();
}

class _CEmpty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(22),
      child: Text(
        'Pick a mosque from Find to begin.',
        style: CTokens.body(size: 14, color: CTokens.ink70),
      ),
    );
  }
}

class _CBody extends StatelessWidget {
  const _CBody({
    required this.mosque,
    required this.now,
    required this.settings,
    required this.ref,
    required this.onSubmitPhoto,
  });

  final Mosque mosque;
  final DateTime now;
  final AppSettings settings;
  final WidgetRef ref;
  final VoidCallback onSubmitPhoto;

  @override
  Widget build(BuildContext context) {
    final timetable = ref.watch(todayTimetableProvider(mosque.id));
    final use24h = settings.timeFormat == TimeFormat.h24;
    final hijri = HijriCalendar.fromDate(now);
    final timeFormat = use24h ? DateFormat.Hm() : DateFormat('h:mm a');
    final dayStr = DateFormat('EEEE · d MMMM').format(now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header date/area row
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dayStr,
                      style: CTokens.body(size: 11, color: CTokens.ink70)),
                  Text(
                    '${hijri.hDay} ${hijri.longMonthName} ${hijri.hYear} AH',
                    style: CTokens.body(size: 10, color: CTokens.ink40),
                  ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${mosque.area}, ${mosque.city}',
                      style: CTokens.body(size: 11, color: CTokens.ink70)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        timetable.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(22),
            child: CircularProgressIndicator(color: Colors.white54),
          ),
          error: (_, __) => const SizedBox.shrink(),
          data: (day) {
            if (day == null) {
              return _CUnavailable(
                  mosque: mosque, onSubmitPhoto: onSubmitPhoto, ref: ref);
            }
            return _CTimetableContent(
              day: day,
              now: now,
              mosque: mosque,
              timeFormat: timeFormat,
              use24h: use24h,
            );
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _CTimetableContent extends StatelessWidget {
  const _CTimetableContent({
    required this.day,
    required this.now,
    required this.mosque,
    required this.timeFormat,
    required this.use24h,
  });

  final DailyTimetable day;
  final DateTime now;
  final Mosque mosque;
  final DateFormat timeFormat;
  final bool use24h;

  @override
  Widget build(BuildContext context) {
    final entries = day.prayerTimes.entries;

    PrayerTimeEntry? nextEntry;
    for (final e in entries) {
      if (e.name == 'Sunrise') continue;
      if (e.begins.isAfter(now)) {
        nextEntry = e;
        break;
      }
    }

    final diff = nextEntry?.begins.difference(now);
    final countdown = diff != null ? _fmtCountdown(diff) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Hero countdown
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 0),
          child: Column(
            children: [
              if (nextEntry != null) ...[
                Text(
                  'NEXT — ${nextEntry.name.toUpperCase()}',
                  style: CTokens.body(
                      size: 10, color: CTokens.ink70, letterSpacing: 2.8),
                ),
                const SizedBox(height: 6),
                Text(
                  countdown ?? '—',
                  style: CTokens.serif(size: 84, w: FontWeight.w300).copyWith(
                    shadows: [
                      const Shadow(blurRadius: 30, color: Color(0x4D000000)),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(children: [
                    TextSpan(
                      text: 'at ',
                      style: CTokens.body(size: 12, color: CTokens.ink70),
                    ),
                    TextSpan(
                      text: timeFormat.format(nextEntry.begins),
                      style: CTokens.mono(size: 12),
                    ),
                    if (nextEntry.jamaat != null) ...[
                      TextSpan(
                        text: " · jamā'ah ",
                        style: CTokens.body(size: 12, color: CTokens.ink70),
                      ),
                      TextSpan(
                        text: timeFormat.format(nextEntry.jamaat!),
                        style: CTokens.mono(size: 12),
                      ),
                    ],
                  ]),
                ),
              ] else
                Text(
                  "Today's prayers complete",
                  style: CTokens.serif(size: 24, w: FontWeight.w300),
                ),
            ],
          ),
        ),

        // Sun arc
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: SunArc(
            prayers: entries,
            now: now,
            use24h: use24h,
            height: 200,
          ),
        ),

        // Frosted timetable card
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('TODAY',
                            style: CTokens.body(
                                size: 10,
                                color: CTokens.ink70,
                                letterSpacing: 2.4)),
                        Text(mosque.name,
                            style:
                                CTokens.body(size: 10, color: CTokens.ink40)),
                      ],
                    ),
                    ...entries.where((e) => e.name != 'Sunrise').map((p) {
                      final isNext = p == nextEntry;
                      final passed = !isNext && p.begins.isBefore(now);
                      final beginsStr = timeFormat.format(p.begins);
                      final jamaatStr =
                          p.jamaat != null ? timeFormat.format(p.jamaat!) : '—';

                      return Opacity(
                        opacity: passed ? 0.5 : 1.0,
                        child: Container(
                          height: 40,
                          decoration: const BoxDecoration(
                            border: Border(
                              top: BorderSide(color: Color(0x1AFFFFFF)),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: isNext
                                      ? CTokens.gold
                                      : Colors.white.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  p.name,
                                  style: CTokens.serif(
                                      size: 17, w: FontWeight.w400),
                                ),
                              ),
                              SizedBox(
                                width: 70,
                                child: Text(
                                  beginsStr,
                                  textAlign: TextAlign.right,
                                  style: CTokens.mono(size: 13),
                                ),
                              ),
                              SizedBox(
                                width: 70,
                                child: Text(
                                  jamaatStr,
                                  textAlign: TextAlign.right,
                                  style: CTokens.mono(
                                      size: 12, color: CTokens.ink70),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Mosque footer
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('FROM',
                      style: CTokens.body(size: 10, color: CTokens.ink40)),
                  Text(mosque.name, style: CTokens.serif(size: 16)),
                ],
              ),
              const Spacer(),
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(999),
                child: InkWell(
                  onTap: () => context.go('/find'),
                  borderRadius: BorderRadius.circular(999),
                  hoverColor: Colors.white.withValues(alpha: 0.12),
                  splashColor: Colors.white.withValues(alpha: 0.2),
                  focusColor: Colors.white.withValues(alpha: 0.12),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      'Switch ⇄',
                      style: CTokens.body(size: 11, color: CTokens.ink70),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _fmtCountdown(Duration d) {
    if (d.isNegative) return 'now';
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h == 0 && m == 0) return '<1m';
    if (h == 0) return '${m}m';
    return '${h}h ${m.toString().padLeft(2, '0')}m';
  }
}

class _CUnavailable extends StatelessWidget {
  const _CUnavailable({
    required this.mosque,
    required this.onSubmitPhoto,
    required this.ref,
  });

  final Mosque mosque;
  final VoidCallback onSubmitPhoto;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Prayer times unavailable',
                    style: CTokens.serif(size: 20, w: FontWeight.w400)),
                const SizedBox(height: 8),
                Text(
                  'This mosque hasn\'t published a timetable yet.',
                  style: CTokens.body(size: 12, color: CTokens.ink70),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _CPillBtn(
                        label: '📷 Submit a photo',
                        filled: true,
                        onTap: onSubmitPhoto,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _CPillBtn(
                        label: '≈ Show estimates',
                        filled: false,
                        onTap: () {
                          final settings = ref.read(settingsProvider);
                          ref.read(settingsProvider.notifier).update(
                                settings.copyWith(showEstimatedTimes: true),
                              );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CPillBtn extends StatelessWidget {
  const _CPillBtn(
      {required this.label, required this.filled, required this.onTap});
  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: filled
              ? Colors.white.withValues(alpha: 0.9)
              : Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(999),
          border: filled
              ? null
              : Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: CTokens.body(
            size: 12,
            color: filled ? const Color(0xFF1A1A3A) : Colors.white,
          ),
        ),
      ),
    );
  }
}
