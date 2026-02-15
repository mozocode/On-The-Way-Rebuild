import 'dart:math';
import '../models/location_model.dart';

class LocationInterpolation {
  static LocationModel interpolate(
    LocationModel from,
    LocationModel to,
    double progress,
  ) {
    return LocationModel(
      latitude: from.latitude + (to.latitude - from.latitude) * progress,
      longitude: from.longitude + (to.longitude - from.longitude) * progress,
      heading: _interpolateHeading(from.heading, to.heading, progress),
      speed: to.speed,
      accuracy: to.accuracy,
      altitude: to.altitude,
      updatedAt: to.updatedAt,
    );
  }

  static double? _interpolateHeading(double? from, double? to, double progress) {
    if (from == null || to == null) return to;
    double delta = to - from;
    if (delta > 180) delta -= 360;
    if (delta < -180) delta += 360;
    return (from + delta * progress + 360) % 360;
  }
}
