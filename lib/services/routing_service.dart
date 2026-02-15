import '../models/route_model.dart';
import '../models/location_model.dart';
import 'radar_service.dart';

class RoutingService {
  static final RoutingService _instance = RoutingService._internal();
  factory RoutingService() => _instance;
  RoutingService._internal();

  final _radarService = RadarService();

  Future<RouteModel?> getRoute({
    required LocationModel origin,
    required LocationModel destination,
    String mode = 'car',
    String units = 'imperial',
  }) async {
    try {
      final result = await _radarService.getDistance(
        originLat: origin.latitude,
        originLng: origin.longitude,
        destLat: destination.latitude,
        destLng: destination.longitude,
        mode: mode,
        units: units,
      );
      if (result == null) return null;
      final route = result['routes']?[0];
      if (route == null) return null;
      final distance = route['distance'];
      final duration = route['duration'];
      return RouteModel(
        totalDistance: (distance?['value'] as num?)?.toDouble() ?? 0,
        totalDuration: duration?['value'] as int? ?? 0,
        polyline: route['geometry']?['polyline'] ?? '',
        origin: origin,
        destination: destination,
        units: distance?['units'] ?? 'metric',
        calculatedAt: DateTime.now(),
      );
    } catch (e) {
      return null;
    }
  }

  Future<int?> getETA({
    required LocationModel origin,
    required LocationModel destination,
    String mode = 'car',
  }) async {
    final route = await getRoute(
      origin: origin,
      destination: destination,
      mode: mode,
    );
    return route?.durationInMinutes;
  }
}
