import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prayer_times_core/core.dart';
import 'package:prayer_times_ui/ui.dart';

import '../../services/providers.dart';
import 'visual_style_section.dart';

class CalligraphicSettingsScreen extends ConsumerWidget {
  const CalligraphicSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final ctrl = ref.read(settingsProvider.notifier);

    return Scaffold(
      backgroundColor: BTokens.bg,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PREFERENCES',
                    style: BTokens.body(size: 10, color: BTokens.gold, letterSpacing: 2.4)),
                const SizedBox(height: 4),
                Text('Settings', style: BTokens.display(size: 38, italic: true)),
              ],
            ),
          ),

          // Visual Style
          _BSection(
            label: 'Visual Style',
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: VisualStyleSection(
                  current: settings.designDirection,
                  onChanged: (dir) =>
                      ctrl.update(settings.copyWith(designDirection: dir)),
                  isCalligraphic: true,
                ),
              ),
            ],
          ),

          // Notifications
          _BSection(
            label: 'Notifications',
            children: [
              for (final entry in {
                'Fajr': settings.notifications.fajr,
                'Dhuhr': settings.notifications.dhuhr,
                'Asr': settings.notifications.asr,
                'Maghrib': settings.notifications.maghrib,
                'Isha': settings.notifications.isha,
              }.entries)
                _BRow(
                  label: entry.key,
                  control: _BSwitch(
                    on: entry.value,
                    onToggle: (v) {
                      final notif = switch (entry.key) {
                        'Fajr' => settings.notifications.copyWith(fajr: v),
                        'Dhuhr' => settings.notifications.copyWith(dhuhr: v),
                        'Asr' => settings.notifications.copyWith(asr: v),
                        'Maghrib' =>
                          settings.notifications.copyWith(maghrib: v),
                        _ => settings.notifications.copyWith(isha: v),
                      };
                      ctrl.update(settings.copyWith(notifications: notif));
                    },
                  ),
                ),
              _BRow(
                label: 'Notify before',
                value: '${settings.notifications.minutesBefore} min',
              ),
              _BRow(
                label: 'Adhan sound',
                control: _BSwitch(
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
          _BSection(
            label: 'Display',
            children: [
              _BRow(
                label: 'Theme',
                value: switch (settings.themeMode) {
                  AppThemeMode.system => 'System',
                  AppThemeMode.light => 'Light',
                  AppThemeMode.dark => 'Dark',
                },
              ),
              _BRow(
                label: 'Time format',
                value: settings.timeFormat == TimeFormat.h24
                    ? '24-hour'
                    : '12-hour',
              ),
            ],
          ),

          // Calculation
          _BSection(
            label: 'Calculation',
            children: [
              _BRow(label: 'Method', value: 'Muslim World League'),
              _BRow(
                label: 'Asr juristic',
                value: settings.asrMethod == AsrMethod.standard
                    ? 'Standard'
                    : 'Hanafi',
              ),
            ],
          ),

          // Location
          _BSection(
            label: 'Location',
            children: [
              _BRow(
                label: 'Use device location',
                control: _BSwitch(
                  on: settings.useDeviceLocation,
                  onToggle: (v) =>
                      ctrl.update(settings.copyWith(useDeviceLocation: v)),
                ),
              ),
              _BRow(
                label: 'Manual location',
                value: settings.manualLocation?.label ?? 'Not set',
              ),
            ],
          ),

          const SizedBox(height: 28),
        ],
      ),
    );
  }
}

class _BSection extends StatelessWidget {
  const _BSection({required this.label, required this.children});
  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Transform.rotate(
                angle: math.pi / 4,
                child: Container(
                  width: 5,
                  height: 5,
                  color: BTokens.gold,
                ),
              ),
              const SizedBox(width: 10),
              Text(label, style: BTokens.display(size: 18, italic: true)),
            ],
          ),
          Container(
            margin: const EdgeInsets.only(top: 8),
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [BTokens.gold.withValues(alpha: 0.5), Colors.transparent],
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _BRow extends StatelessWidget {
  const _BRow({required this.label, this.value, this.control});
  final String label;
  final String? value;
  final Widget? control;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: BTokens.ink20)),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: BTokens.body(size: 13))),
          if (value != null)
            Text(value!, style: BTokens.body(size: 12, color: BTokens.ink60)),
          if (control != null) ...[
            const SizedBox(width: 10),
            control!,
          ],
        ],
      ),
    );
  }
}

class _BSwitch extends StatelessWidget {
  const _BSwitch({required this.on, required this.onToggle});
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
                color: on ? BTokens.gold : BTokens.ink20,
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
                  color: on ? BTokens.bg : BTokens.ink60,
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
