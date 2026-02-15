import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the app is showing the Hero dashboard (Go Online, jobs) or the Customer view (services grid).
/// Heroes see the customer view by default and can switch to Hero Mode from the menu.
final heroViewModeProvider = StateProvider<bool>((ref) => false);
