import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/view_mode_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/customer/customer_home_screen.dart';
import 'screens/hero/hero_home_screen.dart';

class OTWApp extends ConsumerWidget {
  const OTWApp({super.key});

  static final navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final showHeroDashboard = ref.watch(heroViewModeProvider);
    final themeMode = ref.watch(themeModeProvider);

    print('[APP] build: isInitialized=${authState.isInitialized}, isAuthenticated=${authState.isAuthenticated}, isHero=${authState.isHero}, showHero=$showHeroDashboard');

    // Single MaterialApp; only the home widget changes so we never swap the root (avoids white screen on iOS).
    Widget home;
    if (!authState.isInitialized) {
      home = const _SplashScreen();
    } else if (!authState.isAuthenticated) {
      home = const LoginScreen();
    } else if (authState.isHero && showHeroDashboard) {
      home = const HeroHomeScreen();
    } else {
      home = const CustomerHomeScreen();
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
