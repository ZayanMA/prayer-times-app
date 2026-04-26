import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prayer_times_core/core.dart';
import 'package:prayer_times_ui/ui.dart';

import '../../services/providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _step = 0;
  final _pageCtrl = PageController();

  void _next() {
    if (_step < 2) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      setState(() => _step++);
    } else {
      _complete();
    }
  }

  void _complete() {
    final settings = ref.read(settingsProvider);
    ref.read(settingsProvider.notifier).update(
          settings.copyWith(onboardingComplete: true),
        );
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final dir = ref.watch(settingsProvider.select((s) => s.designDirection));
    return switch (dir) {
      AppDesignDirection.almanac      => _buildAlmanac(),
      AppDesignDirection.calligraphic => _buildCalligraphic(),
      AppDesignDirection.celestial    => _buildCelestial(),
    };
  }

  // ── Direction A ───────────────────────────────────────────────
  Widget _buildAlmanac() {
    return Scaffold(
      backgroundColor: ATokens.paper,
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageCtrl,
              onPageChanged: (i) => setState(() => _step = i),
              children: [
                _AStep(
                  step: '01',
                  title: 'The\nAlmanac.',
                  subtitle:
                      'Your local mosque\'s published timetable, right in your pocket.',
                ),
                _AStep(
                  step: '02',
                  title: 'Pick your\nlocal mosque.',
                  subtitle:
                      'We\'ll keep its published timetable up to date. You can switch any time.',
                  showMosqueCard: true,
                  ref: ref,
                ),
                _AStep(
                  step: '03',
                  title: 'Stay\ninformed.',
                  subtitle:
                      'Enable notifications to get a reminder before each prayer.',
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: ATokens.rule)),
              color: ATokens.paper,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: List.generate(3, (i) => Container(
                    width: 14,
                    height: 2,
                    margin: const EdgeInsets.only(right: 6),
                    color: i == _step ? ATokens.ink : ATokens.ink20,
                  )),
                ),
                InkWell(
                  onTap: _next,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: ATokens.ink,
                      border: Border.all(color: ATokens.rule),
                    ),
                    child: Text(
                      _step < 2 ? 'CONTINUE ›' : 'BEGIN ›',
                      style: ATokens.mono(
                          size: 10,
                          color: ATokens.paper,
                          letterSpacing: 1.6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Direction B ───────────────────────────────────────────────
  Widget _buildCalligraphic() {
    return Scaffold(
      backgroundColor: BTokens.bg,
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageCtrl,
              onPageChanged: (i) => setState(() => _step = i),
              children: [
                _BOnboardStep(
                  label: 'WELCOME',
                  title: 'Stay close\nto your ',
                  goldWord: 'prayers.',
                  subtitle:
                      'One quiet place for your local mosque\'s timetable, '
                      "jamā'ah times, and gentle reminders.",
                ),
                _BOnboardStep(
                  label: 'STEP 02 / 03',
                  title: 'Pick your\nlocal ',
                  goldWord: 'mosque.',
                  subtitle:
                      "We'll keep its published timetable up to date.",
                  showMosqueCard: true,
                  ref: ref,
                ),
                _BOnboardStep(
                  label: 'STEP 03 / 03',
                  title: 'Gentle\n',
                  goldWord: 'reminders.',
                  subtitle:
                      'We\'ll notify you before each prayer, '
                      'so you\'re never caught unprepared.',
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(28, 14, 28, 32),
            color: BTokens.bg,
            child: Column(
              children: [
                GestureDetector(
                  onTap: _next,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    color: BTokens.gold,
                    child: Text(
                      _step < 2 ? 'CONTINUE' : 'BEGIN',
                      textAlign: TextAlign.center,
                      style: BTokens.body(
                          size: 12, color: BTokens.bg, letterSpacing: 2.4),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) {
                    return Transform.rotate(
                      angle: math.pi / 4,
                      child: Container(
                        width: 5,
                        height: 5,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        color: i == _step ? BTokens.gold : BTokens.ink20,
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Direction C ───────────────────────────────────────────────
  Widget _buildCelestial() {
    final gradient = CTokens.skyGradient(
        DateTime(2026, 4, 25, 14, 0)); // morning demo time

    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(gradient: gradient),
          ),
        ),
        // Sun glow
        Positioned(
          top: 60,
          right: -40,
          child: Container(
            width: 220,
            height: 220,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Colors.white, CTokens.gold, Colors.transparent],
                stops: [0, 0.4, 0.7],
              ),
            ),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _pageCtrl,
                  onPageChanged: (i) => setState(() => _step = i),
                  children: [
                    _COnboardStep(
                      label: 'WELCOME',
                      title: 'Follow the sun.\n',
                      goldLine: 'Five times a day.',
                      subtitle:
                          'Prayer times follow the sky\'s arc. '
                          "We'll show you where you are in the day.",
                    ),
                    _COnboardStep(
                      label: 'YOUR MOSQUE',
                      title: 'Find your\n',
                      goldLine: 'local mosque.',
                      subtitle:
                          "We'll keep its timetable up to date and notify you before each prayer.",
                      showMosqueCard: true,
                      ref: ref,
                    ),
                    _COnboardStep(
                      label: 'NOTIFICATIONS',
                      title: 'Gentle\n',
                      goldLine: 'reminders.',
                      subtitle:
                          "Enable notifications to be reminded before each ṣalāh.",
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 40),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: _next,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                _step < 2 ? 'Get started' : 'Begin',
                                textAlign: TextAlign.center,
                                style: CTokens.body(
                                    size: 14,
                                    color: const Color(0xFF1A1A3A)).copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (i) => Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: i == _step ? CTokens.gold : CTokens.ink20,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      )),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }
}

// ── Almanac step ───────────────────────────────────────────────────────────────
class _AStep extends StatelessWidget {
  const _AStep({
    required this.step,
    required this.title,
    required this.subtitle,
    this.showMosqueCard = false,
    this.ref,
  });
  final String step;
  final String title;
  final String subtitle;
  final bool showMosqueCard;
  final WidgetRef? ref;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('STEP $step / 03',
              style: ATokens.mono(size: 9, color: ATokens.ink60, letterSpacing: 1.8)),
          const Spacer(),
          Text(
            title,
            style: ATokens.serif(size: 56, italic: true, letterSpacing: -1)
                .copyWith(height: 1),
          ),
          const SizedBox(height: 18),
          Text(
            subtitle,
            style: ATokens.mono(size: 12, color: ATokens.ink60),
          ),
          if (showMosqueCard && ref != null) ...[
            const SizedBox(height: 24),
            _ANearestMosqueCard(ref: ref!),
          ],
          const Spacer(),
        ],
      ),
    );
  }
}

class _ANearestMosqueCard extends StatelessWidget {
  const _ANearestMosqueCard({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final mosques = ref.watch(mosquesProvider).valueOrNull ?? [];
    final first = mosques.isNotEmpty ? mosques.first : null;

    return Container(
      decoration: BoxDecoration(
        color: ATokens.paperAlt,
        border: Border.all(color: ATokens.rule),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: ATokens.rule)),
            ),
            child: Text('NEAREST · 1.2 KM',
                style: ATokens.mono(size: 10, color: ATokens.ink60, letterSpacing: 1.6)),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(first?.name ?? 'Manchester Central Mosque',
                    style: ATokens.serif(size: 18)),
                const SizedBox(height: 4),
                Text(first != null ? '${first.area}, ${first.city}' : 'Rusholme, Manchester',
                    style: ATokens.mono(size: 10, color: ATokens.ink60)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Calligraphic step ──────────────────────────────────────────────────────────
class _BOnboardStep extends StatelessWidget {
  const _BOnboardStep({
    required this.label,
    required this.title,
    required this.goldWord,
    required this.subtitle,
    this.showMosqueCard = false,
    this.ref,
  });
  final String label;
  final String title;
  final String goldWord;
  final String subtitle;
  final bool showMosqueCard;
  final WidgetRef? ref;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Bismillah watermark
        Positioned(
          top: 60,
          left: 0,
          right: 0,
          child: Center(
            child: Text(
              '﷽',
              textDirection: TextDirection.rtl,
              style: BTokens.arabic(size: 280, color: BTokens.gold)
                  .copyWith(height: 1)
                  .merge(TextStyle(color: BTokens.gold.withValues(alpha: 0.14))),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 40, 28, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: BTokens.body(size: 10, color: BTokens.gold, letterSpacing: 2.4)),
              const Spacer(),
              RichText(
                text: TextSpan(children: [
                  TextSpan(
                    text: title,
                    style: BTokens.display(size: 56, italic: true)
                        .copyWith(height: 1, letterSpacing: -1),
                  ),
                  TextSpan(
                    text: goldWord,
                    style: BTokens.display(
                        size: 56, italic: true, color: BTokens.gold)
                        .copyWith(height: 1, letterSpacing: -1),
                  ),
                ]),
              ),
              const SizedBox(height: 16),
              Text(
                subtitle,
                style: BTokens.body(size: 13, color: BTokens.ink60),
              ),
              if (showMosqueCard && ref != null) ...[
                const SizedBox(height: 24),
                _BBNearestMosqueCard(ref: ref!),
              ],
              const Spacer(),
            ],
          ),
        ),
      ],
    );
  }
}

class _BBNearestMosqueCard extends StatelessWidget {
  const _BBNearestMosqueCard({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final mosques = ref.watch(mosquesProvider).valueOrNull ?? [];
    final first = mosques.isNotEmpty ? mosques.first : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BTokens.bgAlt,
        border: Border.all(color: BTokens.ink20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('NEAREST',
              style: BTokens.body(size: 9, color: BTokens.gold, letterSpacing: 2.4)),
          const SizedBox(height: 8),
          Text(first?.name ?? 'Manchester Central Mosque',
              style: BTokens.display(size: 18, italic: true)),
          const SizedBox(height: 4),
          Text(first != null ? '${first.area}, ${first.city}' : 'Rusholme, Manchester',
              style: BTokens.body(size: 11, color: BTokens.ink60)),
        ],
      ),
    );
  }
}

// ── Celestial step ─────────────────────────────────────────────────────────────
class _COnboardStep extends StatelessWidget {
  const _COnboardStep({
    required this.label,
    required this.title,
    required this.goldLine,
    required this.subtitle,
    this.showMosqueCard = false,
    this.ref,
  });
  final String label;
  final String title;
  final String goldLine;
  final String subtitle;
  final bool showMosqueCard;
  final WidgetRef? ref;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 40, 28, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: CTokens.body(size: 11, color: CTokens.ink70, letterSpacing: 2.0)),
          const Spacer(),
          RichText(
            text: TextSpan(children: [
              TextSpan(
                text: title,
                style: CTokens.serif(size: 60, w: FontWeight.w300)
                    .copyWith(height: 1, letterSpacing: -2),
              ),
              TextSpan(
                text: goldLine,
                style: CTokens.serif(
                    size: 60, w: FontWeight.w300, color: CTokens.gold,
                    italic: true)
                    .copyWith(height: 1, letterSpacing: -2),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          Text(
            subtitle,
            style: CTokens.body(size: 13, color: CTokens.ink70),
          ),
          if (showMosqueCard && ref != null) ...[
            const SizedBox(height: 24),
            _CCNearestMosqueCard(ref: ref!),
          ],
          const Spacer(),
        ],
      ),
    );
  }
}

class _CCNearestMosqueCard extends StatelessWidget {
  const _CCNearestMosqueCard({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final mosques = ref.watch(mosquesProvider).valueOrNull ?? [];
    final first = mosques.isNotEmpty ? mosques.first : null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('NEAREST',
                  style: CTokens.body(size: 9, color: CTokens.ink70, letterSpacing: 2.4)),
              const SizedBox(height: 8),
              Text(first?.name ?? 'Manchester Central Mosque',
                  style: CTokens.serif(size: 18, w: FontWeight.w400)),
              const SizedBox(height: 4),
              Text(first != null ? '${first.area}, ${first.city}' : 'Rusholme, Manchester',
                  style: CTokens.body(size: 11, color: CTokens.ink70)),
            ],
          ),
        ),
      ),
    );
  }
}
