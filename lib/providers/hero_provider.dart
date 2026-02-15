import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/hero_model.dart';
import '../models/job_model.dart';
import '../models/location_model.dart';
import '../services/firestore_service.dart';
import '../services/realtime_db_service.dart';
import '../services/location_service.dart';
import '../services/radar_service.dart';

class HeroState {
  final HeroModel? hero;
  final JobModel? activeJob;
  final LocationModel? currentLocation;
  final bool isOnline;
  final bool isLoading;
  final String? error;

  const HeroState({
    this.hero,
    this.activeJob,
    this.currentLocation,
    this.isOnline = false,
    this.isLoading = false,
    this.error,
  });

  HeroState copyWith({
    HeroModel? hero,
    JobModel? activeJob,
    LocationModel? currentLocation,
    bool? isOnline,
    bool? isLoading,
    String? error,
  }) {
    return HeroState(
      hero: hero ?? this.hero,
      activeJob: activeJob ?? this.activeJob,
      currentLocation: currentLocation ?? this.currentLocation,
      isOnline: isOnline ?? this.isOnline,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class HeroNotifier extends StateNotifier<HeroState> {
  final String heroId;
  final FirestoreService _firestore;
  final RealtimeDbService _realtimeDb;
  final LocationService _locationService;
  final RadarService _radarService;

  StreamSubscription? _heroSub;
  StreamSubscription? _jobSub;
  StreamSubscription? _locationSub;

  HeroNotifier({
    required this.heroId,
    required FirestoreService firestore,
    required RealtimeDbService realtimeDb,
    required LocationService locationService,
    required RadarService radarService,
  })  : _firestore = firestore,
        _realtimeDb = realtimeDb,
        _locationService = locationService,
        _radarService = radarService,
        super(const HeroState(isLoading: true)) {
    _initialize();
  }

  void _initialize() {
    _heroSub = _firestore.watchHero(heroId).listen((hero) {
      if (hero != null) {
        state = state.copyWith(
          hero: hero,
          isOnline: hero.status.isOnline,
          isLoading: false,
        );
      }
    });

    _jobSub = _firestore.watchActiveHeroJob(heroId).listen((job) {
      state = state.copyWith(activeJob: job);
      _locationService.setCurrentJob(job?.id);
    });

    _locationSub = _locationService.locationStream.listen((location) {
      state = state.copyWith(currentLocation: location);
    });
  }

  Future<void> goOnline() async {
    try {
      state = state.copyWith(isLoading: true);
      final hasPermission = await _locationService.requestPermissions();
      if (!hasPermission) {
        state = state.copyWith(
          isLoading: false,
          error: 'Location permission required to go online',
        );
        return;
      }
      await _firestore.updateHeroStatus(heroId, isOnline: true);
      await _realtimeDb.setupPresence(heroId);
      await _locationService.startHeroTracking(
        heroId: heroId,
        preset: TrackingPreset.efficient,
      );
      state = state.copyWith(isOnline: true, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to go online: $e',
      );
    }
  }

  Future<void> goOffline() async {
    try {
      state = state.copyWith(isLoading: true);
      await _firestore.updateHeroStatus(heroId, isOnline: false);
      await _realtimeDb.goOffline(heroId);
      await _locationService.stopTracking();
      state = state.copyWith(isOnline: false, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to go offline: $e',
      );
    }
  }

  Future<bool> acceptJob(String jobId) async {
    try {
      state = state.copyWith(isLoading: true);
      final success = await _firestore.acceptJob(jobId, heroId);
      if (success) {
        await _locationService.startHeroTracking(
          heroId: heroId,
          jobId: jobId,
          preset: TrackingPreset.continuous,
        );
      }
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to accept job: $e',
      );
      return false;
    }
  }

  Future<void> updateJobStatus(String status) async {
    if (state.activeJob == null) return;
    try {
      await _firestore.updateJobStatus(state.activeJob!.id, status);
      if (status == 'completed' || status == 'cancelled') {
        await _locationService.startHeroTracking(
          heroId: heroId,
          preset:
              state.isOnline ? TrackingPreset.efficient : TrackingPreset.stopped,
        );
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to update status: $e');
    }
  }

  @override
  void dispose() {
    _heroSub?.cancel();
    _jobSub?.cancel();
    _locationSub?.cancel();
    super.dispose();
  }
}

final heroProvider =
    StateNotifierProvider.family<HeroNotifier, HeroState, String>(
  (ref, heroId) => HeroNotifier(
    heroId: heroId,
    firestore: FirestoreService(),
    realtimeDb: RealtimeDbService(),
    locationService: LocationService(),
    radarService: RadarService(),
  ),
);
