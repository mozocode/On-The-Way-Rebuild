import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/location_model.dart';
import '../models/job_model.dart';
import '../services/realtime_db_service.dart';
import '../services/firestore_service.dart';
import '../utils/location_interpolation.dart';

class TrackingState {
  final LocationModel? heroLocation;
  final LocationModel? displayLocation;
  final int? etaMinutes;
  final double? etaDistance;
  final String? routePolyline;
  final bool isLoading;
  final String? error;

  const TrackingState({
    this.heroLocation,
    this.displayLocation,
    this.etaMinutes,
    this.etaDistance,
    this.routePolyline,
    this.isLoading = false,
    this.error,
  });

  TrackingState copyWith({
    LocationModel? heroLocation,
    LocationModel? displayLocation,
    int? etaMinutes,
    double? etaDistance,
    String? routePolyline,
    bool? isLoading,
    String? error,
  }) {
    return TrackingState(
      heroLocation: heroLocation ?? this.heroLocation,
      displayLocation: displayLocation ?? this.displayLocation,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      etaDistance: etaDistance ?? this.etaDistance,
      routePolyline: routePolyline ?? this.routePolyline,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class TrackingNotifier extends StateNotifier<TrackingState> {
  final RealtimeDbService _realtimeDb;
  final FirestoreService _firestore;
  final String jobId;

  StreamSubscription? _realtimeLocationSub;
  StreamSubscription? _firestoreJobSub;
  Timer? _animationTimer;
  LocationModel? _previousLocation;

  TrackingNotifier({
    required this.jobId,
    required RealtimeDbService realtimeDb,
    required FirestoreService firestore,
  })  : _realtimeDb = realtimeDb,
        _firestore = firestore,
        super(const TrackingState(isLoading: true)) {
    _initialize();
  }

  void _initialize() {
    _realtimeLocationSub =
        _realtimeDb.watchJobTracking(jobId).listen(_handleRealtimeUpdate);
    _firestoreJobSub = _firestore.watchJob(jobId).listen(_handleFirestoreUpdate);
  }

  void _handleRealtimeUpdate(Map<String, dynamic>? data) {
    if (data == null) return;
    final heroLocationData = data['heroLocation'];
    if (heroLocationData == null) return;

    final newLocation = LocationModel(
      latitude: (heroLocationData['latitude'] as num).toDouble(),
      longitude: (heroLocationData['longitude'] as num).toDouble(),
      heading: (heroLocationData['heading'] as num?)?.toDouble(),
      speed: (heroLocationData['speed'] as num?)?.toDouble(),
      updatedAt: heroLocationData['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              heroLocationData['updatedAt'] as int)
          : DateTime.now(),
    );

    final etaData = data['eta'];
    _animateToLocation(newLocation);

    state = state.copyWith(
      heroLocation: newLocation,
      etaMinutes: etaData?['minutes'] as int?,
      etaDistance: (etaData?['distance'] as num?)?.toDouble(),
      isLoading: false,
    );
  }

  void _handleFirestoreUpdate(JobModel? job) {
    if (job == null) return;
    state = state.copyWith(routePolyline: job.tracking.routePolyline);
  }

  void _animateToLocation(LocationModel newLocation) {
    _animationTimer?.cancel();
    if (_previousLocation == null) {
      state = state.copyWith(displayLocation: newLocation);
      _previousLocation = newLocation;
      return;
    }
    const duration = Duration(milliseconds: 1000);
    const frameRate = Duration(milliseconds: 16);
    final startTime = DateTime.now();
    final from = _previousLocation!;

    _animationTimer = Timer.periodic(frameRate, (timer) {
      final elapsed = DateTime.now().difference(startTime);
      final progress =
          (elapsed.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
      final eased = 1 - pow(1 - progress, 3).toDouble();
      final interpolated =
          LocationInterpolation.interpolate(from, newLocation, eased);
      state = state.copyWith(displayLocation: interpolated);
      if (progress >= 1.0) {
        timer.cancel();
        _previousLocation = newLocation;
      }
    });
  }

  @override
  void dispose() {
    _realtimeLocationSub?.cancel();
    _firestoreJobSub?.cancel();
    _animationTimer?.cancel();
    super.dispose();
  }
}

final trackingProvider =
    StateNotifierProvider.family<TrackingNotifier, TrackingState, String>(
  (ref, jobId) => TrackingNotifier(
    jobId: jobId,
    realtimeDb: RealtimeDbService(),
    firestore: FirestoreService(),
  ),
);
