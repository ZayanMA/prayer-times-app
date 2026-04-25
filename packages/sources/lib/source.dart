import 'package:prayer_times_core/core.dart';

abstract class MosqueTimetableSource {
  String get mosqueId;
  SourceKind get kind;
  Duration get freshness;

  Future<Timetable> fetch({DateTime? from, DateTime? to});
}

class SourceFetchException implements Exception {
  const SourceFetchException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() {
    if (cause == null) {
      return 'SourceFetchException: $message';
    }
    return 'SourceFetchException: $message ($cause)';
  }
}
