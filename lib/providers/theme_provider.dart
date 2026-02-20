import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Manages the app's theme mode: system, light, or dark.
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);
