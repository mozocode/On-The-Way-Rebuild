import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/firebase_config.dart';
import 'config/radar_config.dart';
import 'services/notification_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  }

  await FirebaseConfig.initialize();

  // Radar SDK only supports iOS and Android
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
       defaultTargetPlatform == TargetPlatform.android)) {
    try {
      await RadarConfig.initialize();
    } catch (e) {
      print('Radar init failed: $e');
    }
  }

  // Notifications - skip on web
  if (!kIsWeb) {
    try {
      await NotificationService().initialize();
    } catch (e) {
      print('Notification service init failed: $e');
    }
  }

  runApp(
    const ProviderScope(
      child: OTWApp(),
    ),
  );
}
