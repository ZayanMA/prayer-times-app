enum AppThemeMode { system, light, dark }

enum AppDesignDirection { almanac, calligraphic, celestial }

enum TimeFormat { h24, h12 }

enum CalculationMethod {
  muslimWorldLeague,
  egyptian,
  karachi,
  ummAlQura,
  northAmerica,
  moonsightingCommittee,
  kuwait,
  qatar,
  singapore,
  turkey,
}

enum AsrMethod { standard, hanafi }

class NotificationPreferences {
  const NotificationPreferences({
    this.fajr = true,
    this.dhuhr = true,
    this.asr = true,
    this.maghrib = true,
    this.isha = true,
    this.minutesBefore = 10,
    this.adhanSound = false,
  });

  final bool fajr;
  final bool dhuhr;
  final bool asr;
  final bool maghrib;
  final bool isha;
  final int minutesBefore;
  final bool adhanSound;

  NotificationPreferences copyWith({
    bool? fajr,
    bool? dhuhr,
    bool? asr,
    bool? maghrib,
    bool? isha,
    int? minutesBefore,
    bool? adhanSound,
  }) =>
      NotificationPreferences(
        fajr: fajr ?? this.fajr,
        dhuhr: dhuhr ?? this.dhuhr,
        asr: asr ?? this.asr,
        maghrib: maghrib ?? this.maghrib,
        isha: isha ?? this.isha,
        minutesBefore: minutesBefore ?? this.minutesBefore,
        adhanSound: adhanSound ?? this.adhanSound,
      );
}

class ManualLocation {
  const ManualLocation({
    required this.label,
    required this.latitude,
    required this.longitude,
  });

  final String label;
  final double latitude;
  final double longitude;
}

class AppSettings {
  const AppSettings({
    this.themeMode = AppThemeMode.system,
    this.timeFormat = TimeFormat.h24,
    this.calculationMethod = CalculationMethod.muslimWorldLeague,
    this.asrMethod = AsrMethod.standard,
    this.useDeviceLocation = true,
    this.manualLocation,
    this.notifications = const NotificationPreferences(),
    this.showEstimatedTimes = false,
    this.designDirection = AppDesignDirection.celestial,
    this.onboardingComplete = false,
  });

  final AppThemeMode themeMode;
  final TimeFormat timeFormat;
  final CalculationMethod calculationMethod;
  final AsrMethod asrMethod;
  final bool useDeviceLocation;
  final ManualLocation? manualLocation;
  final NotificationPreferences notifications;
  final bool showEstimatedTimes;
  final AppDesignDirection designDirection;
  final bool onboardingComplete;

  AppSettings copyWith({
    AppThemeMode? themeMode,
    TimeFormat? timeFormat,
    CalculationMethod? calculationMethod,
    AsrMethod? asrMethod,
    bool? useDeviceLocation,
    ManualLocation? manualLocation,
    bool clearManualLocation = false,
    NotificationPreferences? notifications,
    bool? showEstimatedTimes,
    AppDesignDirection? designDirection,
    bool? onboardingComplete,
  }) =>
      AppSettings(
        themeMode: themeMode ?? this.themeMode,
        timeFormat: timeFormat ?? this.timeFormat,
        calculationMethod: calculationMethod ?? this.calculationMethod,
        asrMethod: asrMethod ?? this.asrMethod,
        useDeviceLocation: useDeviceLocation ?? this.useDeviceLocation,
        manualLocation: clearManualLocation
            ? null
            : (manualLocation ?? this.manualLocation),
        notifications: notifications ?? this.notifications,
        showEstimatedTimes: showEstimatedTimes ?? this.showEstimatedTimes,
        designDirection: designDirection ?? this.designDirection,
        onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      );
}
