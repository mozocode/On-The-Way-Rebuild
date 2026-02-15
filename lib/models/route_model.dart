import 'location_model.dart';

class RouteStep {
  final String instruction;
  final String maneuver;
  final double distance;
  final int duration;
  final LocationModel startLocation;
  final LocationModel endLocation;
  final String? streetName;
  final int? exitNumber;

  const RouteStep({
    required this.instruction,
    required this.maneuver,
    required this.distance,
    required this.duration,
    required this.startLocation,
    required this.endLocation,
    this.streetName,
    this.exitNumber,
  });
}

class RouteLeg {
  final double distance;
  final int duration;
  final LocationModel origin;
  final LocationModel destination;
  final List<RouteStep> steps;

  const RouteLeg({
    required this.distance,
    required this.duration,
    required this.origin,
    required this.destination,
    this.steps = const [],
  });
}

class RouteModel {
  final double totalDistance;
  final int totalDuration;
  final String polyline;
  final LocationModel origin;
  final LocationModel destination;
  final List<RouteLeg> legs;
  final String? units;
  final DateTime? calculatedAt;

  const RouteModel({
    required this.totalDistance,
    required this.totalDuration,
    required this.polyline,
    required this.origin,
    required this.destination,
    this.legs = const [],
    this.units,
    this.calculatedAt,
  });

  double get distanceInMiles => totalDistance / 1609.34;
  double get distanceInKm => totalDistance / 1000;
  int get durationInMinutes => (totalDuration / 60).round();

  String get formattedDuration {
    final minutes = durationInMinutes;
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (remainingMinutes == 0) return '$hours hr';
    return '$hours hr $remainingMinutes min';
  }
}
