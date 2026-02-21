import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/route_model.dart';
import '../models/location_model.dart';
import '../models/job_model.dart';
import '../services/routing_service.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../services/realtime_db_service.dart';

class NavigationState {
  final RouteModel? route;
  final RouteStep? currentStep;
  final int currentStepIndex;
  final List<RouteStep> steps;
  final double? remainingStepDistance;
  final String? routePolyline;
  final int? etaMinutes;
  final double? etaDistance;
  final LocationModel? currentLocation;
  final LocationModel? destination;
  final bool isNavigating;
  final bool isLoading;
  final String? error;

  const NavigationState({
    this.route,
    this.currentStep,
    this.currentStepIndex = 0,
    this.steps = const [],
    this.remainingStepDistance,
    this.routePolyline,
    this.etaMinutes,
    this.etaDistance,
    this.currentLocation,
    this.destination,
    this.isNavigating = false,
    this.isLoading = false,
    this.error,
  });

  NavigationState copyWith({
    RouteModel? route,
    RouteStep? currentStep,
    int? currentStepIndex,
    List<RouteStep>? steps,
    double? remainingStepDistance,
    String? routePolyline,
    int? etaMinutes,
    double? etaDistance,
    LocationModel? currentLocation,
    LocationModel? destination,
    bool? isNavigating,
    bool? isLoading,
    String? error,
    bool clearStep = false,
  }) {
    return NavigationState(
      route: route ?? this.route,
      currentStep: clearStep ? null : (currentStep ?? this.currentStep),
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      steps: steps ?? this.steps,
      remainingStepDistance:
          remainingStepDistance ?? this.remainingStepDistance,
      routePolyline: routePolyline ?? this.routePolyline,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      etaDistance: etaDistance ?? this.etaDistance,
      currentLocation: currentLocation ?? this.currentLocation,
      destination: destination ?? this.destination,
      isNavigating: isNavigating ?? this.isNavigating,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class NavigationNotifier extends StateNotifier<NavigationState> {
  final String jobId;
  final RoutingService _routingService;
  final FirestoreService _firestoreService;
  final LocationService _locationService;
  final RealtimeDbService _realtimeDbService;

  StreamSubscription? _locationSub;
  StreamSubscription? _jobSub;
  Timer? _routeRefreshTimer;
  bool _isFetching = false;
  DateTime? _lastRouteFetch;

  static const _rerouteThresholdMeters = 50.0;
  static const _routeRefreshSeconds = 20;
  static const _minFetchIntervalSeconds = 8;

  NavigationNotifier({
    required this.jobId,
    required RoutingService routingService,
    required FirestoreService firestoreService,
    required LocationService locationService,
    required RealtimeDbService realtimeDbService,
  })  : _routingService = routingService,
        _firestoreService = firestoreService,
        _locationService = locationService,
        _realtimeDbService = realtimeDbService,
        super(const NavigationState(isLoading: true)) {
    _initialize();
  }

  void _initialize() {
    _jobSub = _firestoreService.watchJob(jobId).listen((job) {
      if (job != null) _updateDestination(job);
    });
    _locationSub = _locationService.locationStream.listen((location) {
      final hadLocation = state.currentLocation != null;
      state = state.copyWith(currentLocation: location);
      if (!hadLocation && state.destination != null) {
        _fetchRoute();
      } else if (state.isNavigating) {
        _checkDeviationAndReroute(location);
        _advanceStep(location);
      }
    });
    _bootstrapLocation();
  }

  Future<void> _bootstrapLocation() async {
    if (state.currentLocation != null) return;
    final loc = _locationService.currentLocation ??
        await _locationService.getCurrentLocation();
    if (loc != null && state.currentLocation == null) {
      state = state.copyWith(currentLocation: loc);
      if (state.destination != null) _fetchRoute();
    }
  }

  void _updateDestination(JobModel job) {
    LocationModel? destination;
    if (job.status == JobStatus.assigned || job.status == JobStatus.enRoute) {
      destination = job.pickup.location;
    } else if (job.destination != null) {
      destination = job.destination!.location;
    } else {
      destination = job.pickup.location;
    }
    final cur = state.destination;
    final changed = cur == null ||
        destination == null ||
        cur.latitude != destination.latitude ||
        cur.longitude != destination.longitude;
    if (changed) {
      state = state.copyWith(destination: destination);
      _fetchRoute();
    }
  }

  Future<void> startNavigation() async {
    state = state.copyWith(isNavigating: true);
    await _fetchRoute();
    _startRouteRefreshTimer();
  }

  void _startRouteRefreshTimer() {
    _routeRefreshTimer?.cancel();
    _routeRefreshTimer = Timer.periodic(
      const Duration(seconds: _routeRefreshSeconds),
      (_) {
        if (state.isNavigating) _fetchRoute();
      },
    );
  }

  // ── Deviation detection & auto-reroute ─────────────────────────────────

  void _checkDeviationAndReroute(LocationModel location) {
    if (!state.isNavigating || state.routePolyline == null) return;
    if (_lastRouteFetch != null) {
      final elapsed = DateTime.now().difference(_lastRouteFetch!).inSeconds;
      if (elapsed < _minFetchIntervalSeconds) return;
    }
    final deviation = _distanceToRoute(location, state.routePolyline!);
    if (deviation > _rerouteThresholdMeters) {
      debugPrint('[NAV] Off-route by ${deviation.round()}m — rerouting');
      _fetchRoute();
    }
  }

  double _distanceToRoute(LocationModel location, String polyline) {
    final coords = _decodePolylineFlat(polyline);
    if (coords.length < 4) return double.infinity;

    double minDist = double.infinity;
    for (int i = 0; i < coords.length - 2; i += 2) {
      final d = _pointToSegmentDistance(
        location.latitude,
        location.longitude,
        coords[i],
        coords[i + 1],
        coords[i + 2],
        coords[i + 3],
      );
      if (d < minDist) minDist = d;
    }
    return minDist;
  }

  static double _pointToSegmentDistance(
    double pLat,
    double pLng,
    double aLat,
    double aLng,
    double bLat,
    double bLng,
  ) {
    final dxAb = bLng - aLng;
    final dyAb = bLat - aLat;
    if (dxAb == 0 && dyAb == 0) {
      return _haversine(pLat, pLng, aLat, aLng);
    }
    var t = ((pLng - aLng) * dxAb + (pLat - aLat) * dyAb) /
        (dxAb * dxAb + dyAb * dyAb);
    t = t.clamp(0.0, 1.0);
    final projLat = aLat + t * dyAb;
    final projLng = aLng + t * dxAb;
    return _haversine(pLat, pLng, projLat, projLng);
  }

  static double _haversine(
      double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000.0;
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) *
            cos(_toRad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  static double _toRad(double deg) => deg * pi / 180;

  // ── Step advancement ──────────────────────────────────────────────────

  void _advanceStep(LocationModel location) {
    final steps = state.steps;
    if (steps.isEmpty) return;
    var idx = state.currentStepIndex;
    if (idx >= steps.length) return;

    final step = steps[idx];
    final distToManeuver = _haversine(
      location.latitude,
      location.longitude,
      step.startLocation.latitude,
      step.startLocation.longitude,
    );

    state = state.copyWith(
        remainingStepDistance: distToManeuver * 3.28084);

    if (distToManeuver < 30 && idx < steps.length - 1) {
      idx++;
      state = state.copyWith(
        currentStepIndex: idx,
        currentStep: steps[idx],
      );
    }
  }

  // ── Route fetching ─────────────────────────────────────────────────────

  Future<void> _fetchRoute() async {
    if (_isFetching) return;
    final currentLocation =
        state.currentLocation ?? _locationService.currentLocation;
    final destination = state.destination;
    if (currentLocation == null || destination == null) return;

    _isFetching = true;
    _lastRouteFetch = DateTime.now();
    try {
      state = state.copyWith(isLoading: true, error: null);

      RouteModel? route;
      if (state.isNavigating) {
        route = await _routingService.getDirections(
          origin: currentLocation,
          destination: destination,
        );
      } else {
        route = await _routingService.getRoute(
          origin: currentLocation,
          destination: destination,
        );
      }

      if (route == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Could not calculate route',
        );
        return;
      }

      List<RouteStep> steps = [];
      if (state.isNavigating) {
        if (route.legs.isNotEmpty && route.legs.first.steps.isNotEmpty) {
          steps = route.legs.first.steps;
        } else if (route.polyline.isNotEmpty) {
          steps = _deriveStepsFromPolyline(route.polyline);
        }
      }

      // Display the upcoming maneuver (skip depart step if possible)
      RouteStep? displayStep;
      int displayIdx = 0;
      if (steps.length > 1) {
        displayIdx = 1;
        displayStep = steps[1];
      } else if (steps.isNotEmpty) {
        displayStep = steps.first;
      }

      state = state.copyWith(
        route: route,
        routePolyline: route.polyline,
        etaMinutes: route.durationInMinutes,
        etaDistance: route.distanceInMiles,
        isLoading: false,
        steps: steps,
        currentStep: displayStep,
        currentStepIndex: displayIdx,
      );

      await _firestoreService.updateJobTracking(jobId, {
        'routePolyline': route.polyline,
        'etaMinutes': route.durationInMinutes,
        'etaDistance': route.distanceInMiles,
      });
      try {
        await _realtimeDbService.updateJobTracking(
          jobId,
          heroLocation: currentLocation,
          etaMinutes: route.durationInMinutes,
          etaDistance: route.distanceInMiles,
        );
      } catch (_) {}
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error fetching route: $e',
      );
    } finally {
      _isFetching = false;
    }
  }

  /// Fallback: derive synthetic steps from polyline geometry.
  List<RouteStep> _deriveStepsFromPolyline(String polyline) {
    final coords = _decodePolylineFlat(polyline);
    if (coords.length < 4) return [];

    final steps = <RouteStep>[];
    double prevBearing =
        _bearing(coords[0], coords[1], coords[2], coords[3]);

    steps.add(RouteStep(
      instruction: 'Head toward destination',
      maneuver: 'depart',
      distance:
          _haversine(coords[0], coords[1], coords[2], coords[3]) * 3.28084,
      duration: 0,
      startLocation:
          LocationModel(latitude: coords[0], longitude: coords[1]),
      endLocation:
          LocationModel(latitude: coords[2], longitude: coords[3]),
    ));

    double accumDist = 0;
    int segStart = 0;

    for (int i = 2; i < coords.length - 2; i += 2) {
      final lat1 = coords[i], lng1 = coords[i + 1];
      final lat2 = coords[i + 2], lng2 = coords[i + 3];
      final bearing = _bearing(lat1, lng1, lat2, lng2);
      final segDist = _haversine(lat1, lng1, lat2, lng2);
      accumDist += segDist;

      final bearingDiff = _normalizeBearing(bearing - prevBearing);
      if (bearingDiff.abs() > 35 && accumDist > 20) {
        final maneuver = bearingDiff > 0 ? 'turn-right' : 'turn-left';
        final instruction = bearingDiff > 0 ? 'Turn right' : 'Turn left';
        steps.add(RouteStep(
          instruction: instruction,
          maneuver: maneuver,
          distance: accumDist * 3.28084,
          duration: 0,
          startLocation: LocationModel(
              latitude: coords[segStart], longitude: coords[segStart + 1]),
          endLocation: LocationModel(latitude: lat2, longitude: lng2),
        ));
        accumDist = 0;
        segStart = i;
      }
      prevBearing = bearing;
    }

    final lastLat = coords[coords.length - 2];
    final lastLng = coords[coords.length - 1];
    steps.add(RouteStep(
      instruction: 'Arrive at destination',
      maneuver: 'arrive',
      distance: accumDist * 3.28084,
      duration: 0,
      startLocation: LocationModel(
          latitude: coords[max(0, coords.length - 4)],
          longitude: coords[max(1, coords.length - 3)]),
      endLocation: LocationModel(latitude: lastLat, longitude: lastLng),
    ));

    return steps;
  }

  static double _bearing(
      double lat1, double lon1, double lat2, double lon2) {
    final dLon = _toRad(lon2 - lon1);
    final y = sin(dLon) * cos(_toRad(lat2));
    final x = cos(_toRad(lat1)) * sin(_toRad(lat2)) -
        sin(_toRad(lat1)) * cos(_toRad(lat2)) * cos(dLon);
    return atan2(y, x) * 180 / pi;
  }

  static double _normalizeBearing(double b) {
    while (b > 180) b -= 360;
    while (b < -180) b += 360;
    return b;
  }

  List<double> _decodePolylineFlat(String encoded, {int precision = 6}) {
    if (encoded.isEmpty) return [];
    try {
      final result = <double>[];
      int index = 0, lat = 0, lng = 0;
      final factor = pow(10, precision).toInt();
      while (index < encoded.length) {
        int shift = 0, r = 0, byte;
        do {
          byte = encoded.codeUnitAt(index++) - 63;
          r |= (byte & 0x1f) << shift;
          shift += 5;
        } while (byte >= 0x20 && index < encoded.length);
        lat += (r & 1) != 0 ? ~(r >> 1) : (r >> 1);
        shift = 0;
        r = 0;
        if (index >= encoded.length) break;
        do {
          byte = encoded.codeUnitAt(index++) - 63;
          r |= (byte & 0x1f) << shift;
          shift += 5;
        } while (byte >= 0x20 && index < encoded.length);
        lng += (r & 1) != 0 ? ~(r >> 1) : (r >> 1);
        result.add(lat / factor);
        result.add(lng / factor);
      }
      return result;
    } catch (e) {
      debugPrint('[NAV] polyline decode error: $e');
      return [];
    }
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    _jobSub?.cancel();
    _routeRefreshTimer?.cancel();
    super.dispose();
  }
}

final navigationProvider =
    StateNotifierProvider.family<NavigationNotifier, NavigationState, String>(
  (ref, jobId) => NavigationNotifier(
    jobId: jobId,
    routingService: RoutingService(),
    firestoreService: FirestoreService(),
    locationService: LocationService(),
    realtimeDbService: RealtimeDbService(),
  ),
);
