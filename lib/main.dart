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

  // Catch any Flutter framework errors so they print instead of silently showing white
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    print('=== FLUTTER ERROR ===');
    print(details.exceptionAsString());
    print(details.stack);
  };

  // Custom error widget so build errors show a red screen with text instead of white
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.red,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Text(
              'BUILD ERROR:\n${details.exceptionAsString()}',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ),
      ),
    );
  };

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

  print('[MAIN] starting Firebase init...');
  await FirebaseConfig.initialize();
  print('[MAIN] Firebase init done');

  print('[MAIN] calling runApp...');
  runApp(
    const ProviderScope(
      child: OTWApp(),
    ),
  );
  print('[MAIN] runApp called');

  // Notifications - init after first frame so a hang can't block the UI
  if (!kIsWeb) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService().initialize().then((_) {
        print('[MAIN] notification init done');
      }).catchError((e) {
        print('Notification service init failed: $e');
      });
    });
  }

  // Radar init after first frame so UI paints immediately
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
       defaultTargetPlatform == TargetPlatform.android)) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('[MAIN] post-frame: starting Radar init...');
      RadarConfig.initialize().then((_) {
        print('[MAIN] Radar init done');
      }).catchError((e) {
        print('Radar init failed: $e');
      });
    });
  }
}
