import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prayer_times_core/core.dart';
import 'package:prayer_times_ui/ui.dart';

import '../../services/providers.dart';
import 'visual_style_section.dart';

class AlmanacSettingsScreen extends ConsumerWidget {
  const AlmanacSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final ctrl = ref.read(settingsProvider.notifier);

    return Scaffold(
      backgroundColor: ATokens.paper,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: ATokens.rule, width: 2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('APPENDIX',
                    style: ATokens.mono(size: 9, color: ATokens.ink60, letterSpacing: 1.8)),
                const SizedBox(height: 4),
                Text('Settings', style: ATokens.serif(size: 28, italic: true)),
              ],
            ),
          ),

          // Visual Style section
          _ASection(
            title: 'Visual Style',
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: VisualStyleSection(
                  current: settings.designDirection,
                  onChanged: (dir) =>
                      ctrl.update(settings.copyWith(designDirection: dir)),
                  isAlmanac: true,
                ),
              ),
            ],
          ),

          // Notifications
          _ASection(
            title: 'Notifications',
            children: [
              for (final entry in {
                'Fajr': settings.notifications.fajr,
                'Dhuhr': settings.notifications.dhuhr,
                'Asr': settings.notifications.asr,
                'Maghrib': settings.notifications.maghrib,
                'Isha': settings.notifications.isha,
              }.entries)
                _ARow(
                  label: entry.key,
                  control: _ACheck(
                    on: entry.value,
                    onToggle: (v) {
                      final notif = switch (entry.key) {
                        'Fajr' => settings.notifications.copyWith(fajr: v),
                        'Dhuhr' => settings.notifications.copyWith(dhuhr: v),
                        'Asr' => settings.notifications.copyWith(asr: v),
                        'Maghrib' => settings.notifications.copyWith(maghrib: v),
                        _ => settings.notifications.copyWith(isha: v),
                      };
                      ctrl.update(settings.copyWith(notifications: notif));
                    },
                  ),
                ),
              _ARow(
                label: 'Notify before',
                value: '${settings.notifications.minutesBefore} min',
                control: _AStepper(
                  value: settings.notifications.minutesBefore,
                  onChanged: (v) => ctrl.update(settings.copyWith(
                    notifications:
                        settings.notifications.copyWith(minutesBefore: v),
                  )),
                ),
              ),
              _ARow(
                label: 'Adhan sound',
                control: _ACheck(
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
          _ASection(
            title: 'Display',
            children: [
              _ARow(
                label: 'Theme',
                control: _ASegment(
                  options: const ['SYS', 'LT', 'DK'],
                  active: settings.themeMode.index,
                  onChanged: (i) => ctrl.update(
                    settings.copyWith(themeMode: AppThemeMode.values[i]),
                  ),
                ),
              ),
              _ARow(
                label: 'Time format',
                control: _ASegment(
                  options: const ['24h', '12h'],
                  active: settings.timeFormat == TimeFormat.h24 ? 0 : 1,
                  onChanged: (i) => ctrl.update(
                    settings.copyWith(
                      timeFormat: i == 0 ? TimeFormat.h24 : TimeFormat.h12,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Calculation
          _ASection(
            title: 'Calculation (fallback)',
            children: [
              _ARow(
                label: 'Show estimates',
                control: _ACheck(
                  on: settings.showEstimatedTimes,
                  onToggle: (v) =>
                      ctrl.update(settings.copyWith(showEstimatedTimes: v)),
                ),
              ),
              _ARow(
                label: 'Asr juristic',
                control: _ASegment(
                  options: const ['STD', 'HNF'],
                  active: settings.asrMethod == AsrMethod.standard ? 0 : 1,
                  onChanged: (i) => ctrl.update(
                    settings.copyWith(
                      asrMethod: i == 0 ? AsrMethod.standard : AsrMethod.hanafi,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Location
          _ASection(
            title: 'Location',
            children: [
              _ARow(
                label: 'Use device location',
                control: _ACheck(
                  on: settings.useDeviceLocation,
                  onToggle: (v) =>
                      ctrl.update(settings.copyWith(useDeviceLocation: v)),
                ),
              ),
              _ARow(
                label: 'Manual location',
                value: settings.manualLocation?.label ?? 'Not set',
              ),
            ],
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _ASection extends StatelessWidget {
  const _ASection({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(),
              style: ATokens.mono(size: 9, color: ATokens.ink60, letterSpacing: 1.6)),
          const SizedBox(height: 6),
          Container(height: 2, color: ATokens.rule),
          ...children,
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ARow extends StatelessWidget {
  const _ARow({required this.label, this.value, this.control});
  final String label;
  final String? value;
  final Widget? control;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 36),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: ATokens.ink20)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: ATokens.serif(size: 13))),
          if (value != null)
            Text(value!, style: ATokens.mono(size: 11, color: ATokens.ink60)),
          if (control != null) ...[
            const SizedBox(width: 8),
            control!,
          ],
        ],
      ),
    );
  }
}

class _ACheck extends StatelessWidget {
  const _ACheck({required this.on, required this.onToggle});
  final bool on;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onToggle(!on),
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: on ? ATokens.ink : Colors.transparent,
          border: Border.all(color: ATokens.rule),
        ),
        child: on
            ? const Center(
                child: Text('✓',
                    style: TextStyle(color: ATokens.paper, fontSize: 12)))
            : null,
      ),
    );
  }
}

class _ASegment extends StatelessWidget {
  const _ASegment({
    required this.options,
    required this.active,
    required this.onChanged,
  });
  final List<String> options;
  final int active;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: ATokens.rule)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.asMap().entries.map((e) {
          final isActive = e.key == active;
          return GestureDetector(
            onTap: () => onChanged(e.key),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isActive ? ATokens.ink : Colors.transparent,
                border: e.key > 0
                    ? const Border(left: BorderSide(color: ATokens.rule))
                    : null,
              ),
              child: Text(
                e.value,
                style: ATokens.mono(
                    size: 10,
                    color: isActive ? ATokens.paper : ATokens.ink,
                    letterSpacing: 1.4),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _AStepper extends StatelessWidget {
  const _AStepper({required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: ATokens.rule)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepBtn(label: '−', onTap: () => onChanged((value - 1).clamp(0, 60))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: const BoxDecoration(
              border: Border.symmetric(
                  vertical: BorderSide(color: ATokens.rule)),
            ),
            child: Text(
              '$value',
              style: ATokens.mono(size: 11).copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          _StepBtn(label: '+', onTap: () => onChanged((value + 1).clamp(0, 60))),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 22,
        height: 22,
        child: Center(child: Text(label, style: ATokens.mono(size: 13, color: ATokens.ink))),
      ),
    );
  }
}
