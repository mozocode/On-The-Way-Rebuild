import 'dart:math';

class DistanceCalculator {
  static const double _earthRadiusMiles = 3958.8;
  static const double _earthRadiusKm = 6371.0;
  static const double _metersPerMile = 1609.34;

  /// Haversine distance between two lat/lng points in meters.
  static double distanceInMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return _earthRadiusKm * c * 1000;
  }

  static double distanceInMiles(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return distanceInMeters(lat1, lon1, lat2, lon2) / _metersPerMile;
  }

  static double distanceInKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return distanceInMeters(lat1, lon1, lat2, lon2) / 1000;
  }

  /// Bearing from point 1 to point 2 in degrees (0-360).
  static double bearing(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final dLon = _toRadians(lon2 - lon1);
    final y = sin(dLon) * cos(_toRadians(lat2));
    final x = cos(_toRadians(lat1)) * sin(_toRadians(lat2)) -
        sin(_toRadians(lat1)) * cos(_toRadians(lat2)) * cos(dLon);
    return (_toDegrees(atan2(y, x)) + 360) % 360;
  }

  static double metersToMiles(double meters) => meters / _metersPerMile;

  static double milesToMeters(double miles) => miles * _metersPerMile;

  static double _toRadians(double degrees) => degrees * pi / 180;

  static double _toDegrees(double radians) => radians * 180 / pi;
}
