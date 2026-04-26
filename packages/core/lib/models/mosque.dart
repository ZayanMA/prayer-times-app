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
    this.sourceUrl,
    this.sourceStatus,
    this.verifiedAt,
    this.latitude,
    this.longitude,
    this.postcode,
    this.addressLine,
    this.womensFacilities,
    this.wheelchairAccess,
    this.parking,
    this.contactEmail,
    this.contactPhone,
    this.lastScrapeError,
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
  final Uri? sourceUrl;
  final String? sourceStatus;
  final DateTime? verifiedAt;
  final double? latitude;
  final double? longitude;
  final String? postcode;
  final String? addressLine;
  final bool? womensFacilities;
  final bool? wheelchairAccess;
  final bool? parking;
  final String? contactEmail;
  final String? contactPhone;
  final String? lastScrapeError;

  bool get hasLocation => latitude != null && longitude != null;

  LatLng? get location => hasLocation ? LatLng(latitude!, longitude!) : null;
}
