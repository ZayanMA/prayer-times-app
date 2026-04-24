enum SourceKind {
  webTable,
  pdf,
  image,
  remoteCanonical,
  manual,
  calculated,
}

extension SourceKindLabel on SourceKind {
  String get label {
    switch (this) {
      case SourceKind.webTable:
        return 'Web table';
      case SourceKind.pdf:
        return 'PDF';
      case SourceKind.image:
        return 'Image';
      case SourceKind.remoteCanonical:
        return 'Remote';
      case SourceKind.manual:
        return 'Manual';
      case SourceKind.calculated:
        return 'Calculated';
    }
  }
}
