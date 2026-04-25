import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prayer_times_core/core.dart';
import 'package:prayer_times_ui/ui.dart';

import '../../services/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);

    return CustomScrollView(
      slivers: [
        const SliverAppBar(
          pinned: true,
          title: Text('Settings'),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate.fixed([
              _SectionTitle('Notifications'),
              _Section(
                children: [
                  _NotifSwitch(
                    label: 'Fajr',
                    value: settings.notifications.fajr,
                    onChanged: (v) => controller.update(settings.copyWith(
                      notifications:
                          settings.notifications.copyWith(fajr: v),
                    )),
                  ),
                  _NotifSwitch(
                    label: 'Dhuhr',
                    value: settings.notifications.dhuhr,
                    onChanged: (v) => controller.update(settings.copyWith(
                      notifications:
                          settings.notifications.copyWith(dhuhr: v),
                    )),
                  ),
                  _NotifSwitch(
                    label: 'Asr',
                    value: settings.notifications.asr,
                    onChanged: (v) => controller.update(settings.copyWith(
                      notifications:
                          settings.notifications.copyWith(asr: v),
                    )),
                  ),
                  _NotifSwitch(
                    label: 'Maghrib',
                    value: settings.notifications.maghrib,
                    onChanged: (v) => controller.update(settings.copyWith(
                      notifications:
                          settings.notifications.copyWith(maghrib: v),
                    )),
                  ),
                  _NotifSwitch(
                    label: 'Isha',
                    value: settings.notifications.isha,
                    onChanged: (v) => controller.update(settings.copyWith(
                      notifications:
                          settings.notifications.copyWith(isha: v),
                    )),
                  ),
                  ListTile(
                    title: const Text('Notify me'),
                    subtitle: Text(
                      '${settings.notifications.minutesBefore} minutes before',
                    ),
                    trailing: SizedBox(
                      width: 200,
                      child: Slider(
                        value: settings.notifications.minutesBefore.toDouble(),
                        min: 0,
                        max: 30,
                        divisions: 30,
                        label: '${settings.notifications.minutesBefore} min',
                        onChanged: (v) => controller.update(settings.copyWith(
                          notifications: settings.notifications
                              .copyWith(minutesBefore: v.round()),
                        )),
                      ),
                    ),
                  ),
                  SwitchListTile(
                    title: const Text('Adhan sound'),
                    subtitle: const Text('Play full adhan instead of a chime'),
                    value: settings.notifications.adhanSound,
                    onChanged: (v) => controller.update(settings.copyWith(
                      notifications:
                          settings.notifications.copyWith(adhanSound: v),
                    )),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _SectionTitle('Display'),
              _Section(
                children: [
                  ListTile(
                    title: const Text('Theme'),
                    subtitle: Text(_themeLabel(settings.themeMode)),
                    trailing: DropdownButton<AppThemeMode>(
                      value: settings.themeMode,
                      onChanged: (mode) {
                        if (mode == null) return;
                        controller.update(settings.copyWith(themeMode: mode));
                      },
                      items: const [
                        DropdownMenuItem(
                          value: AppThemeMode.system,
                          child: Text('System'),
                        ),
                        DropdownMenuItem(
                          value: AppThemeMode.light,
                          child: Text('Light'),
                        ),
                        DropdownMenuItem(
                          value: AppThemeMode.dark,
                          child: Text('Dark'),
                        ),
                      ],
                    ),
                  ),
                  ListTile(
                    title: const Text('Time format'),
                    subtitle: Text(
                      settings.timeFormat == TimeFormat.h24
                          ? '24-hour (13:30)'
                          : '12-hour (1:30 PM)',
                    ),
                    trailing: SegmentedButton<TimeFormat>(
                      segments: const [
                        ButtonSegment(
                          value: TimeFormat.h24,
                          label: Text('24h'),
                        ),
                        ButtonSegment(
                          value: TimeFormat.h12,
                          label: Text('12h'),
                        ),
                      ],
                      selected: {settings.timeFormat},
                      onSelectionChanged: (s) => controller.update(
                        settings.copyWith(timeFormat: s.first),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _SectionTitle('Calculation (fallback)'),
              _Section(
                children: [
                  SwitchListTile(
                    title: const Text('Show estimated times'),
                    subtitle: const Text(
                      'When a mosque has no published timetable, show '
                      'astronomical estimates instead of "unavailable".',
                    ),
                    value: settings.showEstimatedTimes,
                    onChanged: (v) => controller.update(
                      settings.copyWith(showEstimatedTimes: v),
                    ),
                  ),
                  ListTile(
                    title: const Text('Method'),
                    subtitle: Text(_calcLabel(settings.calculationMethod)),
                    trailing: DropdownButton<CalculationMethod>(
                      value: settings.calculationMethod,
                      onChanged: (m) {
                        if (m == null) return;
                        controller.update(
                          settings.copyWith(calculationMethod: m),
                        );
                      },
                      items: [
                        for (final m in CalculationMethod.values)
                          DropdownMenuItem(
                            value: m,
                            child: Text(_calcLabel(m)),
                          ),
                      ],
                    ),
                  ),
                  ListTile(
                    title: const Text('Asr juristic method'),
                    trailing: SegmentedButton<AsrMethod>(
                      segments: const [
                        ButtonSegment(
                          value: AsrMethod.standard,
                          label: Text('Standard'),
                        ),
                        ButtonSegment(
                          value: AsrMethod.hanafi,
                          label: Text('Hanafi'),
                        ),
                      ],
                      selected: {settings.asrMethod},
                      onSelectionChanged: (s) => controller.update(
                        settings.copyWith(asrMethod: s.first),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _SectionTitle('Location'),
              _Section(
                children: [
                  SwitchListTile(
                    title: const Text('Use device location'),
                    subtitle: const Text(
                      'Required to sort mosques by distance.',
                    ),
                    value: settings.useDeviceLocation,
                    onChanged: (v) => controller.update(
                      settings.copyWith(useDeviceLocation: v),
                    ),
                  ),
                  ListTile(
                    title: const Text('Manual location'),
                    subtitle: Text(
                      settings.manualLocation == null
                          ? 'Not set'
                          : '${settings.manualLocation!.label} '
                              '(${settings.manualLocation!.latitude.toStringAsFixed(2)}, '
                              '${settings.manualLocation!.longitude.toStringAsFixed(2)})',
                    ),
                    trailing: TextButton(
                      onPressed: () => _editManualLocation(context, ref),
                      child: const Text('Edit'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _SectionTitle('About'),
              _Section(
                children: const [
                  ListTile(
                    title: Text('Mosque locations'),
                    subtitle: Text(
                      '© OpenStreetMap contributors, ODbL.\n'
                      'See openstreetmap.org/copyright',
                    ),
                  ),
                  ListTile(
                    title: Text('Map tiles'),
                    subtitle: Text('© OpenStreetMap contributors'),
                  ),
                ],
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Future<void> _editManualLocation(BuildContext context, WidgetRef ref) async {
    final settings = ref.read(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);
    final labelController = TextEditingController(
      text: settings.manualLocation?.label ?? '',
    );
    final latController = TextEditingController(
      text: settings.manualLocation?.latitude.toString() ?? '',
    );
    final lngController = TextEditingController(
      text: settings.manualLocation?.longitude.toString() ?? '',
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Manual location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelController,
              decoration: const InputDecoration(labelText: 'Label (e.g. Home)'),
            ),
            TextField(
              controller: latController,
              decoration: const InputDecoration(labelText: 'Latitude'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: lngController,
              decoration: const InputDecoration(labelText: 'Longitude'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              controller.update(
                settings.copyWith(clearManualLocation: true),
              );
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final lat = double.tryParse(latController.text.trim());
              final lng = double.tryParse(lngController.text.trim());
              if (lat == null || lng == null) {
                Navigator.of(dialogContext).pop();
                return;
              }
              controller.update(
                settings.copyWith(
                  manualLocation: ManualLocation(
                    label: labelController.text.trim(),
                    latitude: lat,
                    longitude: lng,
                  ),
                ),
              );
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  String _themeLabel(AppThemeMode mode) => switch (mode) {
        AppThemeMode.system => 'Follow system',
        AppThemeMode.light => 'Light',
        AppThemeMode.dark => 'Dark',
      };

  String _calcLabel(CalculationMethod method) => switch (method) {
        CalculationMethod.muslimWorldLeague => 'Muslim World League',
        CalculationMethod.egyptian => 'Egyptian',
        CalculationMethod.karachi => 'Karachi',
        CalculationMethod.ummAlQura => 'Umm al-Qura',
        CalculationMethod.northAmerica => 'North America (ISNA)',
        CalculationMethod.moonsightingCommittee => 'Moonsighting Committee',
        CalculationMethod.kuwait => 'Kuwait',
        CalculationMethod.qatar => 'Qatar',
        CalculationMethod.singapore => 'Singapore',
        CalculationMethod.turkey => 'Turkey',
      };
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.xs,
      ),
      child: Text(
        text.toUpperCase(),
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              const Divider(height: 1, indent: AppSpacing.md, endIndent: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}

class _NotifSwitch extends StatelessWidget {
  const _NotifSwitch({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(label),
      value: value,
      onChanged: onChanged,
    );
  }
}
