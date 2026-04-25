import 'package:prayer_times_core/core.dart';

import '../source.dart';

class PdfTimetableSource implements MosqueTimetableSource {
  const PdfTimetableSource({
    required this.mosqueId,
    required this.uri,
    String? displayName,
  }) : displayName = displayName ?? mosqueId;

  @override
  final String mosqueId;

  final Uri uri;
  final String displayName;

  @override
  SourceKind get kind => SourceKind.pdf;

  @override
  Duration get freshness => const Duration(days: 1);

  @override
  Future<Timetable> fetch({DateTime? from, DateTime? to}) {
    // TODO: Implement configurable PDF text extraction once PDF fixtures are
    // available for each supported parser layout.
    throw SourceFetchException(
      '$displayName PDF parsing is deferred for the MVP.',
    );
  }
}
