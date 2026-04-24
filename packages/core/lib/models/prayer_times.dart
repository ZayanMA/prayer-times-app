class PrayerTimes {
  const PrayerTimes({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    this.fajrJamaat,
    this.dhuhrJamaat,
    this.asrJamaat,
    this.maghribJamaat,
    this.ishaJamaat,
  });

  final DateTime fajr;
  final DateTime sunrise;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime maghrib;
  final DateTime isha;
  final DateTime? fajrJamaat;
  final DateTime? dhuhrJamaat;
  final DateTime? asrJamaat;
  final DateTime? maghribJamaat;
  final DateTime? ishaJamaat;

  List<PrayerTimeEntry> get entries => [
        PrayerTimeEntry('Fajr', fajr, jamaat: fajrJamaat),
        PrayerTimeEntry('Sunrise', sunrise),
        PrayerTimeEntry('Dhuhr', dhuhr, jamaat: dhuhrJamaat),
        PrayerTimeEntry('Asr', asr, jamaat: asrJamaat),
        PrayerTimeEntry('Maghrib', maghrib, jamaat: maghribJamaat),
        PrayerTimeEntry('Isha', isha, jamaat: ishaJamaat),
      ];
}

class PrayerTimeEntry {
  const PrayerTimeEntry(this.name, this.begins, {this.jamaat});

  final String name;
  final DateTime begins;
  final DateTime? jamaat;
}
