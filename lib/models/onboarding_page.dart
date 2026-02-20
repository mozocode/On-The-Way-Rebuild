import 'package:flutter/material.dart';

class OnboardingPage {
  final String imagePath;
  final String title;
  final String subtitle;
  final Color backgroundColor;

  const OnboardingPage({
    required this.imagePath,
    required this.title,
    required this.subtitle,
    this.backgroundColor = Colors.white,
  });
}

const List<OnboardingPage> onboardingPages = [
  OnboardingPage(
    imagePath: 'assets/images/onboarding_1_welcome.png',
    title: 'Welcome to On The Way',
    subtitle:
        'Your neighborhood heroes are ready to help with roadside assistance, towing, and more.',
  ),
  OnboardingPage(
    imagePath: 'assets/images/onboarding_2_request.png',
    title: 'Request Help in Seconds',
    subtitle:
        'Tell us what you need, set your location, and we\'ll find the perfect hero nearby.',
  ),
  OnboardingPage(
    imagePath: 'assets/images/onboarding_3_tracking.png',
    title: 'Track Your Hero Live',
    subtitle:
        'Watch your hero\'s journey in real-time on the map. Know exactly when they\'ll arrive.',
  ),
  OnboardingPage(
    imagePath: 'assets/images/onboarding_4_complete.png',
    title: 'Safe & Secure Service',
    subtitle:
        'Rate your hero, tip if you\'d like, and enjoy peace of mind with every job.',
  ),
];
