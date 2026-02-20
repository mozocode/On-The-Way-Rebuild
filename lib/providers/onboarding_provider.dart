import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _onboardingCompleteKey = 'onboarding_complete';

final onboardingCompleteProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_onboardingCompleteKey) ?? false;
});

final completeOnboardingProvider = Provider((ref) {
  return () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompleteKey, true);
    ref.invalidate(onboardingCompleteProvider);
  };
});

final onboardingPageIndexProvider = StateProvider<int>((ref) => 0);
