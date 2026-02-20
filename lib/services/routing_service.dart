import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/radar_config.dart';
import '../models/route_model.dart';
import '../models/location_model.dart';

class RoutingService {
  static final RoutingService _instance = RoutingService._internal();
  factory RoutingService() => _instance;
  RoutingService._internal();

  Future<RouteModel?> getRoute({
    required LocationModel origin,
    required LocationModel destination,
    String mode = 'car',
    String units = 'imperial',
  }) async {
    try {
      final uri = Uri.parse(
        'https://api.radar.io/v1/route/distance'
        '?origin=${origin.latitude},${origin.longitude}'
        '&destination=${destination.latitude},${destination.longitude}'
        '&modes=$mode'
        '&units=$units'
        '&geometry=polyline',
      );

      final response = await http.get(uri, headers: {
        'Authorization': RadarConfig.publishableKey,
      });

      if (response.statusCode != 200) {
        print('[RoutingService] API error ${response.statusCode}: ${response.body}');
        return null;
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final routes = json['routes'] as Map<String, dynamic>?;
      if (routes == null) return null;

      final route = routes[mode] as Map<String, dynamic>?;
      if (route == null) return null;

      final distance = route['distance'] as Map<String, dynamic>?;
      final duration = route['duration'] as Map<String, dynamic>?;
      final geometry = route['geometry'] as Map<String, dynamic>?;

      String polyline = '';
      if (geometry != null) {
        if (geometry['polyline'] is String) {
          polyline = geometry['polyline'] as String;
        }
      }

      return RouteModel(
        totalDistance: (distance?['value'] as num?)?.toDouble() ?? 0,
        totalDuration: (duration?['value'] as num?)?.toInt() ?? 0,
        polyline: polyline,
        origin: origin,
        destination: destination,
        units: units,
        calculatedAt: DateTime.now(),
      );
    } catch (e) {
      print('[RoutingService] getRoute error: $e');
      return null;
    }
  }

  /// Full turn-by-turn directions via OSRM with street names & maneuvers.
  /// Falls back to Radar [getRoute] if OSRM is unavailable.
  Future<RouteModel?> getDirections({
    required LocationModel origin,
    required LocationModel destination,
  }) async {
    try {
      final uri = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${origin.longitude},${origin.latitude};'
        '${destination.longitude},${destination.latitude}'
        '?overview=full&geometries=polyline6&steps=true',
      );

      final response =
          await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        return getRoute(origin: origin, destination: destination);
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['code'] != 'Ok') {
        return getRoute(origin: origin, destination: destination);
      }

      final routes = json['routes'] as List?;
      if (routes == null || routes.isEmpty) {
        return getRoute(origin: origin, destination: destination);
      }

      final route = routes[0] as Map<String, dynamic>;
      final geometry = route['geometry'] as String? ?? '';
      final distance = (route['distance'] as num?)?.toDouble() ?? 0;
      final duration = (route['duration'] as num?)?.toInt() ?? 0;

      final legs = route['legs'] as List? ?? [];
      final allSteps = <RouteStep>[];

      for (final leg in legs) {
        final steps =
            (leg as Map<String, dynamic>)['steps'] as List? ?? [];
        for (int si = 0; si < steps.length; si++) {
          final s = steps[si] as Map<String, dynamic>;
          final maneuver =
              s['maneuver'] as Map<String, dynamic>? ?? {};
          final maneuverType = maneuver['type'] as String? ?? 'straight';
          final modifier = maneuver['modifier'] as String? ?? '';
          final name = s['name'] as String? ?? '';
          final stepDistance =
              (s['distance'] as num?)?.toDouble() ?? 0;
          final stepDuration = (s['duration'] as num?)?.toInt() ?? 0;
          final location =
              maneuver['location'] as List? ?? [0.0, 0.0];

          LocationModel endLoc;
          if (si + 1 < steps.length) {
            final nextMan =
                (steps[si + 1] as Map<String, dynamic>)['maneuver']
                    as Map<String, dynamic>? ?? {};
            final nLoc = nextMan['location'] as List? ?? [0.0, 0.0];
            endLoc = LocationModel(
              latitude: (nLoc[1] as num).toDouble(),
              longitude: (nLoc[0] as num).toDouble(),
            );
          } else {
            endLoc = destination;
          }

          allSteps.add(RouteStep(
            instruction:
                _buildInstruction(maneuverType, modifier, name),
            maneuver: _mapManeuver(maneuverType, modifier),
            distance: stepDistance * 3.28084,
            duration: stepDuration,
            startLocation: LocationModel(
              latitude: (location[1] as num).toDouble(),
              longitude: (location[0] as num).toDouble(),
            ),
            endLocation: endLoc,
            streetName: name.isNotEmpty ? name : null,
          ));
        }
      }

      return RouteModel(
        totalDistance: distance,
        totalDuration: duration,
        polyline: geometry,
        origin: origin,
        destination: destination,
        legs: [
          RouteLeg(
            distance: distance,
            duration: duration,
            origin: origin,
            destination: destination,
            steps: allSteps,
          )
        ],
      );
    } catch (e) {
      print(
          '[RoutingService] getDirections error: $e — falling back to Radar');
      return getRoute(origin: origin, destination: destination);
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

  static String _buildInstruction(
      String type, String modifier, String name) {
    final street = name.isNotEmpty ? ' on $name' : '';
    switch (type) {
      case 'depart':
        return name.isNotEmpty ? 'Head$street' : 'Head toward destination';
      case 'arrive':
        return 'Arrive at destination';
      case 'turn':
        if (modifier.contains('slight left')) return 'Bear left$street';
        if (modifier.contains('slight right')) return 'Bear right$street';
        if (modifier.contains('left')) return 'Turn left$street';
        if (modifier.contains('right')) return 'Turn right$street';
        return 'Continue$street';
      case 'new name':
      case 'continue':
        return 'Continue$street';
      case 'merge':
        return 'Merge$street';
      case 'fork':
        if (modifier.contains('left')) return 'Keep left$street';
        if (modifier.contains('right')) return 'Keep right$street';
        return 'Continue$street';
      case 'roundabout':
      case 'rotary':
        return 'Enter roundabout$street';
      case 'end of road':
        if (modifier.contains('left')) return 'Turn left$street';
        if (modifier.contains('right')) return 'Turn right$street';
        return 'Continue$street';
      default:
        return 'Continue$street';
    }
  }

  static String _mapManeuver(String type, String modifier) {
    if (type == 'depart') return 'depart';
    if (type == 'arrive') return 'arrive';
    if (type == 'roundabout' || type == 'rotary') return 'roundabout';
    if (modifier.contains('uturn')) return 'uturn';
    if (modifier.contains('slight left')) return 'slight-left';
    if (modifier.contains('slight right')) return 'slight-right';
    if (modifier.contains('left')) return 'turn-left';
    if (modifier.contains('right')) return 'turn-right';
    return 'straight';
  }
}
