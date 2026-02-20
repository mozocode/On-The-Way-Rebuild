import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/location_model.dart';
import 'radar_service.dart';
import 'realtime_db_service.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  final RadarService _radarService = RadarService();
  final RealtimeDbService _realtimeDbService = RealtimeDbService();

  StreamSubscription<Position>? _positionSubscription;
  final _locationController = StreamController<LocationModel>.broadcast();

  Stream<LocationModel> get locationStream => _locationController.stream;
  LocationModel? _currentLocation;
  LocationModel? get currentLocation => _currentLocation;

  String? _currentHeroId;
  String? _currentJobId;

  Future<bool> requestPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) {
      await openAppSettings();
      return false;
    }

    await _radarService.requestPermissions(background: true);
    return true;
  }

  Future<LocationModel?> getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _currentLocation = LocationModel(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        heading: position.heading,
        speed: position.speed,
        altitude: position.altitude,
        updatedAt: DateTime.now(),
      );
      return _currentLocation;
    } catch (e) {
      return null;
    }
  }

  Future<void> startHeroTracking({
    required String heroId,
    String? jobId,
    TrackingPreset preset = TrackingPreset.continuous,
  }) async {
    _currentHeroId = heroId;
    _currentJobId = jobId;

    try {
      await _radarService.setUserId(heroId);
      await _radarService.setMetadata(
        isOnline: true,
        isVerified: true,
        currentJobId: jobId,
      );
      await _radarService.startTracking(preset);
    } catch (e) {
      print('[LocationService] Radar tracking setup error: $e');
    }

    _positionSubscription?.cancel();
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      final location = LocationModel(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        heading: position.heading,
        speed: position.speed,
        altitude: position.altitude,
        updatedAt: DateTime.now(),
      );
      _currentLocation = location;
      _locationController.add(location);
      _updateRealtimeLocation(location);
    });
  }

  void _updateRealtimeLocation(LocationModel location) {
    if (_currentHeroId == null) return;
    _realtimeDbService.updateHeroLocation(_currentHeroId!, location);
    if (_currentJobId != null) {
      _realtimeDbService.updateJobTracking(
        _currentJobId!,
        heroLocation: location,
      );
    }
  }

  void setCurrentJob(String? jobId) {
    _currentJobId = jobId;
    if (_currentHeroId != null) {
      _radarService.setMetadata(
        isOnline: true,
        isVerified: true,
        currentJobId: jobId,
      );
    }
  }

  Future<void> stopTracking() async {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    await _radarService.stopTracking();
    if (_currentHeroId != null) {
      await _realtimeDbService.removeHeroLocation(_currentHeroId!);
    }
    if (_currentJobId != null) {
      await _realtimeDbService.removeJobTracking(_currentJobId!);
    }
    _currentHeroId = null;
    _currentJobId = null;
  }

  double calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  double calculateBearing(
      double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.bearingBetween(lat1, lon1, lat2, lon2);
  }

  void dispose() {
    _positionSubscription?.cancel();
    _locationController.close();
  }
}
