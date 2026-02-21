import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/onboarding_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/view_mode_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/customer/customer_home_screen.dart';
import 'screens/hero/hero_home_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';

class OTWApp extends ConsumerWidget {
  const OTWApp({super.key});

  static final navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final showHeroDashboard = ref.watch(heroViewModeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final onboardingAsync = ref.watch(onboardingCompleteProvider);

    debugPrint('[APP] build: isInitialized=${authState.isInitialized}, isAuthenticated=${authState.isAuthenticated}');

    Widget home;
    if (!authState.isInitialized) {
      home = const _SplashScreen();
    } else {
      final onboardingDone = onboardingAsync.valueOrNull ?? false;
      if (!onboardingDone) {
        home = const OnboardingScreen();
      } else if (!authState.isAuthenticated) {
        home = const LoginScreen();
      } else if (authState.isHero && showHeroDashboard) {
        home = const HeroHomeScreen();
      } else {
        home = const CustomerHomeScreen();
      }
    }

    return MaterialApp(
      title: 'OTW - On The Way',
      navigatorKey: navigatorKey,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
      home: home,
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFFE3F2FD),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF1976D2)),
              SizedBox(height: 24),
              Text(
                'OTW - On The Way',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D47A1),
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Loading...',
                style: TextStyle(fontSize: 16, color: Color(0xFF1565C0)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
