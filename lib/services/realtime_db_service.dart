import 'package:firebase_database/firebase_database.dart';
import '../config/firebase_config.dart';
import '../models/location_model.dart';

class RealtimeDbService {
  static final RealtimeDbService _instance = RealtimeDbService._internal();
  factory RealtimeDbService() => _instance;
  RealtimeDbService._internal();

  FirebaseDatabase get _db => FirebaseConfig.realtimeDb;

  DatabaseReference heroLocationRef(String heroId) =>
      _db.ref('heroLocations/$heroId');

  Future<void> updateHeroLocation(String heroId, LocationModel location) async {
    await heroLocationRef(heroId).set({
      'heroId': heroId,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'accuracy': location.accuracy,
      'heading': location.heading,
      'speed': location.speed,
      'altitude': location.altitude,
      'source': 'flutter_radar',
      'updatedAt': ServerValue.timestamp,
      'expiresAt': ServerValue.timestamp,
    });
  }

  Stream<LocationModel?> watchHeroLocation(String heroId) {
    return heroLocationRef(heroId).onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return null;
      return LocationModel.fromRealtimeDb(data);
    });
  }

  Future<LocationModel?> getHeroLocation(String heroId) async {
    final snapshot = await heroLocationRef(heroId).get();
    if (!snapshot.exists) return null;
    final data = snapshot.value as Map<dynamic, dynamic>;
    return LocationModel.fromRealtimeDb(data);
  }

  Future<void> removeHeroLocation(String heroId) async {
    await heroLocationRef(heroId).remove();
  }

  DatabaseReference presenceRef(String heroId) => _db.ref('presence/$heroId');

  Future<void> setupPresence(String heroId) async {
    final ref = presenceRef(heroId);
    await ref.set({
      'online': true,
      'lastSeen': ServerValue.timestamp,
    });
    await ref.onDisconnect().set({
      'online': false,
      'lastSeen': ServerValue.timestamp,
    });
  }

  Stream<bool> watchHeroOnline(String heroId) {
    return presenceRef(heroId).child('online').onValue.map((event) {
      return event.snapshot.value as bool? ?? false;
    });
  }

  Future<void> goOffline(String heroId) async {
    await presenceRef(heroId).set({
      'online': false,
      'lastSeen': ServerValue.timestamp,
    });
  }

  DatabaseReference typingRef(String jobId, String userId) =>
      _db.ref('typing/$jobId/$userId');

  Future<void> setTyping(String jobId, String userId, bool isTyping) async {
    if (isTyping) {
      await typingRef(jobId, userId).set({
        'isTyping': true,
        'timestamp': ServerValue.timestamp,
      });
      await typingRef(jobId, userId).onDisconnect().remove();
    } else {
      await typingRef(jobId, userId).remove();
    }
  }

  Stream<Map<String, bool>> watchTyping(String jobId) {
    return _db.ref('typing/$jobId').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return <String, bool>{};
      return data.map((key, value) {
        final isTyping = (value as Map?)?['isTyping'] as bool? ?? false;
        return MapEntry(key.toString(), isTyping);
      });
    });
  }

  DatabaseReference jobTrackingRef(String jobId) =>
      _db.ref('jobTracking/$jobId');

  Future<void> updateJobTracking(
    String jobId, {
    required LocationModel heroLocation,
    int? etaMinutes,
    double? etaDistance,
  }) async {
    await jobTrackingRef(jobId).update({
      'heroLocation': {
        'latitude': heroLocation.latitude,
        'longitude': heroLocation.longitude,
        'heading': heroLocation.heading,
        'speed': heroLocation.speed,
        'updatedAt': ServerValue.timestamp,
      },
      if (etaMinutes != null)
        'eta': {
          'minutes': etaMinutes,
          'distance': etaDistance,
          'updatedAt': ServerValue.timestamp,
        },
    });
  }

  Stream<Map<String, dynamic>?> watchJobTracking(String jobId) {
    return jobTrackingRef(jobId).onValue.map((event) {
      return event.snapshot.value as Map<String, dynamic>?;
    });
  }

  Future<void> removeJobTracking(String jobId) async {
    await jobTrackingRef(jobId).remove();
  }
}
