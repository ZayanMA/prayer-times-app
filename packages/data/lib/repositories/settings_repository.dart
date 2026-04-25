import 'dart:async';

import 'package:prayer_times_core/core.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository {
  SettingsRepository(this._preferences);

  final SharedPreferences _preferences;
  final StreamController<AppSettings> _controller =
      StreamController<AppSettings>.broadcast();

  static const _kThemeMode = 'settings.themeMode';
  static const _kTimeFormat = 'settings.timeFormat';
  static const _kCalcMethod = 'settings.calcMethod';
  static const _kAsrMethod = 'settings.asrMethod';
  static const _kUseDeviceLocation = 'settings.useDeviceLocation';
  static const _kManualLocLabel = 'settings.manualLocation.label';
  static const _kManualLocLat = 'settings.manualLocation.lat';
  static const _kManualLocLng = 'settings.manualLocation.lng';
  static const _kNotifFajr = 'settings.notif.fajr';
  static const _kNotifDhuhr = 'settings.notif.dhuhr';
  static const _kNotifAsr = 'settings.notif.asr';
  static const _kNotifMaghrib = 'settings.notif.maghrib';
  static const _kNotifIsha = 'settings.notif.isha';
  static const _kNotifMinutes = 'settings.notif.minutesBefore';
  static const _kNotifAdhan = 'settings.notif.adhanSound';
  static const _kShowEstimated = 'settings.showEstimatedTimes';

  AppSettings read() {
    final manualLat = _preferences.getDouble(_kManualLocLat);
    final manualLng = _preferences.getDouble(_kManualLocLng);
    final manualLabel = _preferences.getString(_kManualLocLabel);
    final manual = (manualLat != null && manualLng != null)
        ? ManualLocation(
            label: manualLabel ?? '',
            latitude: manualLat,
            longitude: manualLng,
          )
        : null;

    return AppSettings(
      themeMode: _enumFromName(
        AppThemeMode.values,
        _preferences.getString(_kThemeMode),
        AppThemeMode.system,
      ),
      timeFormat: _enumFromName(
        TimeFormat.values,
        _preferences.getString(_kTimeFormat),
        TimeFormat.h24,
      ),
      calculationMethod: _enumFromName(
        CalculationMethod.values,
        _preferences.getString(_kCalcMethod),
        CalculationMethod.muslimWorldLeague,
      ),
      asrMethod: _enumFromName(
        AsrMethod.values,
        _preferences.getString(_kAsrMethod),
        AsrMethod.standard,
      ),
      useDeviceLocation: _preferences.getBool(_kUseDeviceLocation) ?? true,
      manualLocation: manual,
      notifications: NotificationPreferences(
        fajr: _preferences.getBool(_kNotifFajr) ?? true,
        dhuhr: _preferences.getBool(_kNotifDhuhr) ?? true,
        asr: _preferences.getBool(_kNotifAsr) ?? true,
        maghrib: _preferences.getBool(_kNotifMaghrib) ?? true,
        isha: _preferences.getBool(_kNotifIsha) ?? true,
        minutesBefore: _preferences.getInt(_kNotifMinutes) ?? 10,
        adhanSound: _preferences.getBool(_kNotifAdhan) ?? false,
      ),
      showEstimatedTimes: _preferences.getBool(_kShowEstimated) ?? false,
    );
  }

  Stream<AppSettings> watch() async* {
    yield read();
    yield* _controller.stream;
  }

  Future<void> save(AppSettings settings) async {
    await _preferences.setString(_kThemeMode, settings.themeMode.name);
    await _preferences.setString(_kTimeFormat, settings.timeFormat.name);
    await _preferences.setString(_kCalcMethod, settings.calculationMethod.name);
    await _preferences.setString(_kAsrMethod, settings.asrMethod.name);
    await _preferences.setBool(_kUseDeviceLocation, settings.useDeviceLocation);

    final manual = settings.manualLocation;
    if (manual != null) {
      await _preferences.setString(_kManualLocLabel, manual.label);
      await _preferences.setDouble(_kManualLocLat, manual.latitude);
      await _preferences.setDouble(_kManualLocLng, manual.longitude);
    } else {
      await _preferences.remove(_kManualLocLabel);
      await _preferences.remove(_kManualLocLat);
      await _preferences.remove(_kManualLocLng);
    }

    final n = settings.notifications;
    await _preferences.setBool(_kNotifFajr, n.fajr);
    await _preferences.setBool(_kNotifDhuhr, n.dhuhr);
    await _preferences.setBool(_kNotifAsr, n.asr);
    await _preferences.setBool(_kNotifMaghrib, n.maghrib);
    await _preferences.setBool(_kNotifIsha, n.isha);
    await _preferences.setInt(_kNotifMinutes, n.minutesBefore);
    await _preferences.setBool(_kNotifAdhan, n.adhanSound);
    await _preferences.setBool(_kShowEstimated, settings.showEstimatedTimes);

    _controller.add(settings);
  }

  Future<void> dispose() => _controller.close();

  T _enumFromName<T extends Enum>(List<T> values, String? name, T fallback) {
    if (name == null) return fallback;
    for (final v in values) {
      if (v.name == name) return v;
    }
    return fallback;
  }
}
