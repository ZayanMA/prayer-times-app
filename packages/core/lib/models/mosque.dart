import 'source_kind.dart';

class Mosque {
  const Mosque({
    required this.id,
    required this.name,
    required this.slug,
    required this.area,
    required this.city,
    required this.websiteUrl,
    required this.sourceKind,
  });

  final String id;
  final String name;
  final String slug;
  final String area;
  final String city;
  final Uri websiteUrl;
  final SourceKind sourceKind;
}
