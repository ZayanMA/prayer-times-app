import 'dart:math' as math;

import 'lat_lng.dart';

const double _earthRadiusKm = 6371.0088;

double haversineKm(LatLng a, LatLng b) {
  final lat1 = _toRadians(a.latitude);
  final lat2 = _toRadians(b.latitude);
  final dLat = _toRadians(b.latitude - a.latitude);
  final dLng = _toRadians(b.longitude - a.longitude);

  final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1) * math.cos(lat2) * math.sin(dLng / 2) * math.sin(dLng / 2);
  return 2 * _earthRadiusKm * math.asin(math.min(1, math.sqrt(h)));
}

double haversineMiles(LatLng a, LatLng b) => haversineKm(a, b) * 0.621371;

double _toRadians(double degrees) => degrees * math.pi / 180;
