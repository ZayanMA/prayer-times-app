import 'source.dart';

class SourceRegistry {
  SourceRegistry({required Iterable<MosqueTimetableSource> sources})
      : _sources = {
          for (final source in sources) source.mosqueId: source,
        };

  final Map<String, MosqueTimetableSource> _sources;

  MosqueTimetableSource? sourceFor(String mosqueId) => _sources[mosqueId];

  bool supports(String mosqueId) => _sources.containsKey(mosqueId);
}
