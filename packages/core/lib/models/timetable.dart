import 'prayer_times.dart';

class Timetable {
  const Timetable({
    required this.mosqueId,
    required this.days,
    this.fetchedAt,
  });

  final String mosqueId;
  final List<DailyTimetable> days;
  final DateTime? fetchedAt;

  DailyTimetable? dayFor(DateTime date) {
    final target = DateTime(date.year, date.month, date.day);
    for (final day in days) {
      if (DateTime(day.date.year, day.date.month, day.date.day) == target) {
        return day;
      }
    }
    return null;
  }
}

class DailyTimetable {
  const DailyTimetable({
    required this.date,
    required this.mosqueId,
    required this.prayerTimes,
    this.isCalculated = false,
  });

  final DateTime date;
  final String mosqueId;
  final PrayerTimes prayerTimes;
  final bool isCalculated;
}
