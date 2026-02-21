import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../firebase_options.dart';

class FirebaseConfig {
  static late FirebaseApp app;
  static late FirebaseAuth auth;
  static late FirebaseFirestore firestore;
  static late FirebaseDatabase realtimeDb;
  static late FirebaseMessaging messaging;

  static Future<void> initialize() async {
    app = await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    auth = FirebaseAuth.instance;
    firestore = FirebaseFirestore.instance;
    realtimeDb = FirebaseDatabase.instance;
    messaging = FirebaseMessaging.instance;

    // Persistence settings not supported on web
    if (!kIsWeb) {
      firestore.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );

      try {
        realtimeDb.setPersistenceEnabled(true);
        realtimeDb.setPersistenceCacheSizeBytes(10000000);
      } catch (e) {
        debugPrint('Realtime DB persistence setup failed: $e');
      }
    }

    await _requestNotificationPermissions();
  }

  static Future<void> _requestNotificationPermissions() async {
    try {
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      debugPrint('Notification permission: ${settings.authorizationStatus}');
    } catch (e) {
      // Notifications may not be supported on macOS debug builds
      debugPrint('Notification permission request failed: $e');
    }
  }

  static Future<String?> getFCMToken() async {
    return await messaging.getToken();
  }
}
