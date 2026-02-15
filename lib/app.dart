import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/view_mode_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/customer/customer_home_screen.dart';
import 'screens/hero/hero_home_screen.dart';

class OTWApp extends ConsumerWidget {
  const OTWApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    // Show splash while Firebase auth initializes
    if (!authState.isInitialized) {
      return MaterialApp(
        title: 'OTW - On The Way',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const _SplashScreen(),
      );
    }

    // Everyone sees the customer view by default (services grid). Heroes can switch to Hero Mode from the menu.
    final showHeroDashboard = ref.watch(heroViewModeProvider);
    Widget home;
    if (!authState.isAuthenticated) {
      home = const LoginScreen();
    } else if (authState.isHero && showHeroDashboard) {
      home = const HeroHomeScreen();
    } else {
      home = const CustomerHomeScreen();
    }

    return MaterialApp(
      title: 'OTW - On The Way',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      debugShowCheckedModeBanner: false,
      home: home,
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'OTW - On The Way',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Loading...',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
