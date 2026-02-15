import 'package:flutter/material.dart';

/// Placeholder for custom hero marker widget.
/// Use BitmapDescriptor.defaultMarkerWithHue or custom asset in tracking_screen.
class HeroMarker extends StatelessWidget {
  const HeroMarker({super.key});

  @override
  Widget build(BuildContext context) {
    return const Icon(Icons.directions_car, color: Colors.green, size: 40);
  }
}
