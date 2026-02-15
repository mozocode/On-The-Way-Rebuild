import 'package:flutter_radar/flutter_radar.dart';

class RadarConfig {
  /// Replace with your Radar publishable key from https://dashboard.radar.com
  static const String publishableKey = 'prj_live_pk_xxxxxxxxxxxxx';

  static Future<void> initialize() async {
    await Radar.initialize(publishableKey);
    Radar.setLogLevel('info');
    Radar.onEvents(_handleRadarEvents);
    Radar.onLocation(_handleLocationUpdate);
    Radar.onClientLocation(_handleClientLocation);
    Radar.onError(_handleError);
  }

  static void _handleRadarEvents(Map result) {
    final events = result['events'] as List?;
    if (events != null) {
      for (final event in events) {
        final type = event['type'];
        if (type == 'user.entered_geofence') {
          _handleGeofenceEntered(event);
        } else if (type == 'user.exited_geofence') {
          _handleGeofenceExited(event);
        }
      }
    }
  }

  static void _handleLocationUpdate(Map result) {}
  static void _handleClientLocation(Map result) {}

  static void _handleError(Map result) {
    print('Radar error: $result');
  }

  static void _handleGeofenceEntered(dynamic event) {
    final geofence = event['geofence'];
    final tag = geofence?['tag'];
    if (tag == 'job_pickup' || tag == 'job_destination') {
      // Trigger arrival handling via provider/service
    }
  }

  static void _handleGeofenceExited(dynamic event) {}
}
