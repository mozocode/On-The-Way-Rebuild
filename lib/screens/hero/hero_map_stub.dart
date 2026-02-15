import 'package:flutter/material.dart';

/// Stub for non-web: HeroWebMap is only used on web. On mobile we use MapLibreMap.
class HeroWebMap extends StatelessWidget {
  final double lat;
  final double lng;
  final double zoom;

  const HeroWebMap({
    super.key,
    required this.lat,
    required this.lng,
    this.zoom = 12.0,
  });

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
