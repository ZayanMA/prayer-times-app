import '../geo/lat_lng.dart';
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
    required this.updatedAt,
    this.isActive = true,
    this.latitude,
    this.longitude,
    this.postcode,
    this.addressLine,
  });

  final String id;
  final String name;
  final String slug;
  final String area;
  final String city;
  final Uri websiteUrl;
  final SourceKind sourceKind;
  final DateTime updatedAt;
  final bool isActive;
  final double? latitude;
  final double? longitude;
  final String? postcode;
  final String? addressLine;

  bool get hasLocation => latitude != null && longitude != null;

  LatLng? get location =>
      hasLocation ? LatLng(latitude!, longitude!) : null;
}
