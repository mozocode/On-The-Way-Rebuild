import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode, defaultTargetPlatform, TargetPlatform, debugPrint, FlutterError;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'config/firebase_config.dart';
import 'config/radar_config.dart';
import 'services/notification_service.dart';
import 'app.dart';

void main() async {
  runZonedGuarded(() async {
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

    if (!kIsWeb) {
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(kReleaseMode);
    }

    Stripe.publishableKey = 'pk_test_51RIW2nS8Lxsn5EMQtRTyEHivKJFEIcs5adFkMY69SCGAEqhUdWMmQRqAQHWhuVmG8i2LfmZQlnSEeAXYoqGnOsMF00arZnX9mD';

    ErrorWidget.builder = (FlutterErrorDetails details) {
      if (kReleaseMode) {
        return const SizedBox.shrink();
      }
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

    runApp(
      const ProviderScope(
        child: OTWApp(),
      ),
    );

    if (!kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        NotificationService().initialize().catchError((e) {
          debugPrint('Notification service init failed: $e');
        });
      });
    }

    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
         defaultTargetPlatform == TargetPlatform.android)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        RadarConfig.initialize().catchError((e) {
          debugPrint('Radar init failed: $e');
        });
      });
    }
  }, (error, stack) {
    if (!kIsWeb) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    }
  });
}
