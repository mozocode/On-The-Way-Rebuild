import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/route_model.dart';
import '../models/location_model.dart';
import '../models/job_model.dart';
import '../services/routing_service.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';

class NavigationState {
  final RouteModel? route;
  final RouteStep? currentStep;
  final int currentStepIndex;
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
    String? routePolyline,
    int? etaMinutes,
    double? etaDistance,
    LocationModel? currentLocation,
    LocationModel? destination,
    bool? isNavigating,
    bool? isLoading,
    String? error,
  }) {
    return NavigationState(
      route: route ?? this.route,
      currentStep: currentStep ?? this.currentStep,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
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

  StreamSubscription? _locationSub;
  StreamSubscription? _jobSub;
  Timer? _routeRefreshTimer;

  NavigationNotifier({
    required this.jobId,
    required RoutingService routingService,
    required FirestoreService firestoreService,
    required LocationService locationService,
  })  : _routingService = routingService,
        _firestoreService = firestoreService,
        _locationService = locationService,
        super(const NavigationState(isLoading: true)) {
    _initialize();
  }

  void _initialize() {
    _jobSub = _firestoreService.watchJob(jobId).listen((job) {
      if (job != null) _updateDestination(job);
    });
    _locationSub = _locationService.locationStream.listen((location) {
      state = state.copyWith(currentLocation: location);
    });
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
    if (destination != state.destination) {
      state = state.copyWith(destination: destination);
      _fetchRoute();
    }
  }

  Future<void> startNavigation() async {
    state = state.copyWith(isNavigating: true);
    await _fetchRoute();
  }

  Future<void> _fetchRoute() async {
    final currentLocation =
        state.currentLocation ?? _locationService.currentLocation;
    final destination = state.destination;
    if (currentLocation == null || destination == null) return;
    try {
      state = state.copyWith(isLoading: true, error: null);
      final route = await _routingService.getRoute(
        origin: currentLocation,
        destination: destination,
      );
      if (route == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Could not calculate route',
        );
        return;
      }
      state = state.copyWith(
        route: route,
        routePolyline: route.polyline,
        etaMinutes: route.durationInMinutes,
        etaDistance: route.distanceInMiles,
        isLoading: false,
      );
      await _firestoreService.updateJobTracking(jobId, {
        'routePolyline': route.polyline,
        'etaMinutes': route.durationInMinutes,
        'etaDistance': route.distanceInMiles,
      });
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error fetching route: $e',
      );
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
  ),
);
