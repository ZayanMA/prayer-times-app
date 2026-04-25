import 'package:adhan/adhan.dart' as adhan;

import '../models/prayer_times.dart';
import '../models/timetable.dart';

class CalculationFallback {
  const CalculationFallback({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;

  DailyTimetable calculateDay({
    required DateTime date,
    required String mosqueId,
  }) {
    final coordinates = adhan.Coordinates(latitude, longitude);
    final params = adhan.CalculationMethod.muslim_world_league.getParameters();
    params.madhab = adhan.Madhab.hanafi;
    final prayerTimes = adhan.PrayerTimes(
      coordinates,
      adhan.DateComponents(date.year, date.month, date.day),
      params,
    );

    return DailyTimetable(
      date: DateTime(date.year, date.month, date.day),
      mosqueId: mosqueId,
      isCalculated: true,
      isStale: false,
      prayerTimes: PrayerTimes(
        fajr: prayerTimes.fajr,
        sunrise: prayerTimes.sunrise,
        dhuhr: prayerTimes.dhuhr,
        asr: prayerTimes.asr,
        maghrib: prayerTimes.maghrib,
        isha: prayerTimes.isha,
      ),
    );
  }
}
