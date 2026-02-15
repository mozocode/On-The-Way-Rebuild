import 'package:flutter_radar/flutter_radar.dart';

enum TrackingPreset {
  stopped,
  efficient,
  responsive,
  continuous,
}

class RadarService {
  static final RadarService _instance = RadarService._internal();
  factory RadarService() => _instance;
  RadarService._internal();

  bool _isTracking = false;
  bool get isTracking => _isTracking;

  Future<void> setUserId(String heroId) async {
    await Radar.setUserId(heroId);
  }

  Future<void> setMetadata({
    required bool isOnline,
    required bool isVerified,
    List<String>? servicesOffered,
    String? currentJobId,
  }) async {
    await Radar.setMetadata({
      'userType': 'hero',
      'isOnline': isOnline,
      'isVerified': isVerified,
      'servicesOffered': servicesOffered ?? [],
      'currentJobId': currentJobId,
    });
  }

  Future<String> requestPermissions({bool background = true}) async {
    final status = await Radar.requestPermissions(background);
    return status ?? 'UNKNOWN';
  }

  Future<String> getPermissionStatus() async {
    final status = await Radar.getPermissionsStatus();
    return status ?? 'UNKNOWN';
  }

  Future<void> startTracking(TrackingPreset preset) async {
    switch (preset) {
      case TrackingPreset.stopped:
        await stopTracking();
        break;
      case TrackingPreset.efficient:
        await Radar.startTracking('efficient');
        _isTracking = true;
        break;
      case TrackingPreset.responsive:
        await Radar.startTracking('responsive');
        _isTracking = true;
        break;
      case TrackingPreset.continuous:
        await Radar.startTracking('continuous');
        _isTracking = true;
        break;
    }
  }

  Future<void> stopTracking() async {
    await Radar.stopTracking();
    _isTracking = false;
  }

  Future<Map<String, dynamic>?> getCurrentLocation() async {
    try {
      final result = await Radar.getLocation('high');
      if (result == null) return null;
      return Map<String, dynamic>.from(result);
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> trackOnce() async {
    try {
      final result = await Radar.trackOnce();
      if (result == null) return null;
      return Map<String, dynamic>.from(result);
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getDistance({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    String mode = 'car',
    String units = 'imperial',
  }) async {
    try {
      final result = await Radar.getDistance(
        origin: {'latitude': originLat, 'longitude': originLng},
        destination: {'latitude': destLat, 'longitude': destLng},
        modes: [mode],
        units: units,
      );
      if (result == null) return null;
      return Map<String, dynamic>.from(result);
    } catch (e) {
      return null;
    }
  }
}
