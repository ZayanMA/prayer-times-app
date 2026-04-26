import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prayer_times_core/core.dart';
import 'package:prayer_times_ui/ui.dart';

import '../../services/providers.dart';
import 'visual_style_section.dart';

class CelestialSettingsScreen extends ConsumerStatefulWidget {
  const CelestialSettingsScreen({super.key});

  @override
  ConsumerState<CelestialSettingsScreen> createState() =>
      _CelestialSettingsScreenState();
}

class _CelestialSettingsScreenState
    extends ConsumerState<CelestialSettingsScreen> {
  DateTime _now = DateTime.now();
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 5),
        (_) => setState(() => _now = DateTime.now()));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final ctrl = ref.read(settingsProvider.notifier);
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
          body: ListView(
            padding: EdgeInsets.zero,
            children: [
              const SizedBox(height: 60),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Preferences',
                        style: CTokens.body(size: 11, color: CTokens.ink70)),
                    const SizedBox(height: 2),
                    Text('Settings',
                        style: CTokens.serif(size: 36, w: FontWeight.w300)),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Visual Style section
              _CFrostedSection(
                label: 'VISUAL STYLE',
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: VisualStyleSection(
                      current: settings.designDirection,
                      onChanged: (dir) =>
                          ctrl.update(settings.copyWith(designDirection: dir)),
                      isCelestial: true,
                    ),
                  ),
                ],
              ),

              // Notifications
              _CFrostedSection(
                label: 'NOTIFICATIONS',
                children: [
                  for (final entry in {
                    'Fajr': settings.notifications.fajr,
                    'Dhuhr': settings.notifications.dhuhr,
                    'Asr': settings.notifications.asr,
                    'Maghrib': settings.notifications.maghrib,
                    'Isha': settings.notifications.isha,
                  }.entries)
                    _CRow(
                      label: entry.key,
                      isFirst: entry.key == 'Fajr',
                      control: _CSwitch(
                        on: entry.value,
                        onToggle: (v) {
                          final notif = switch (entry.key) {
                            'Fajr' => settings.notifications.copyWith(fajr: v),
                            'Dhuhr' =>
                              settings.notifications.copyWith(dhuhr: v),
                            'Asr' => settings.notifications.copyWith(asr: v),
                            'Maghrib' =>
                              settings.notifications.copyWith(maghrib: v),
                            _ => settings.notifications.copyWith(isha: v),
                          };
                          ctrl.update(settings.copyWith(notifications: notif));
                        },
                      ),
                    ),
                  _CRow(
                    label: 'Notify before',
                    value: '${settings.notifications.minutesBefore} min',
                    isFirst: false,
                  ),
                  _CRow(
                    label: 'Adhan sound',
                    isFirst: false,
                    control: _CSwitch(
                      on: settings.notifications.adhanSound,
                      onToggle: (v) => ctrl.update(settings.copyWith(
                        notifications:
                            settings.notifications.copyWith(adhanSound: v),
                      )),
                    ),
                  ),
                ],
              ),

              // Display
              _CFrostedSection(
                label: 'DISPLAY',
                children: [
                  _CRow(
                    label: 'Theme',
                    value: switch (settings.themeMode) {
                      AppThemeMode.system => 'System',
                      AppThemeMode.light => 'Light',
                      AppThemeMode.dark => 'Dark',
                    },
                    isFirst: true,
                  ),
                  _CRow(
                    label: 'Time format',
                    value: settings.timeFormat == TimeFormat.h24 ? '24h' : '12h',
                    isFirst: false,
                  ),
                ],
              ),

              // Calculation
              _CFrostedSection(
                label: 'CALCULATION',
                children: [
                  _CRow(
                    label: 'Method',
                    value: 'Muslim World League',
                    isFirst: true,
                  ),
                  _CRow(
                    label: 'Asr juristic',
                    value: settings.asrMethod == AsrMethod.standard
                        ? 'Standard'
                        : 'Hanafi',
                    isFirst: false,
                  ),
                ],
              ),

              // Location
              _CFrostedSection(
                label: 'LOCATION',
                children: [
                  _CRow(
                    label: 'Use device location',
                    isFirst: true,
                    control: _CSwitch(
                      on: settings.useDeviceLocation,
                      onToggle: (v) =>
                          ctrl.update(settings.copyWith(useDeviceLocation: v)),
                    ),
                  ),
                  _CRow(
                    label: 'Manual location',
                    value: settings.manualLocation?.label ?? 'Not set',
                    isFirst: false,
                  ),
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }
}

class _CFrostedSection extends StatelessWidget {
  const _CFrostedSection({required this.label, required this.children});
  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 6, bottom: 8),
            child: Text(
              label,
              style: CTokens.body(size: 10, color: CTokens.ink70, letterSpacing: 2.4),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                child: Column(children: children),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CRow extends StatelessWidget {
  const _CRow({
    required this.label,
    required this.isFirst,
    this.value,
    this.control,
  });
  final String label;
  final bool isFirst;
  final String? value;
  final Widget? control;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: isFirst
            ? null
            : const Border(
                top: BorderSide(color: Color(0x1AFFFFFF)),
              ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: CTokens.body(size: 13)),
          ),
          if (value != null)
            Text(value!, style: CTokens.body(size: 12, color: CTokens.ink70)),
          if (control != null) ...[
            const SizedBox(width: 8),
            control!,
          ],
        ],
      ),
    );
  }
}

class _CSwitch extends StatelessWidget {
  const _CSwitch({required this.on, required this.onToggle});
  final bool on;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onToggle(!on),
      child: SizedBox(
        width: 32,
        height: 18,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: on ? CTokens.gold : Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(9),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              left: on ? 16 : 2,
              top: 2,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
