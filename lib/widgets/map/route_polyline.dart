import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../utils/polyline_decoder.dart';

class RoutePolylineBuilder {
  /// Build a set of polylines (shadow + main) from an encoded polyline string.
  static Set<Polyline> build(
    String encoded, {
    Color color = const Color(0xFFDC143C),
    Color shadowColor = const Color(0xFF8B0000),
    int width = 5,
    int shadowWidth = 8,
    int precision = 6,
  }) {
    if (encoded.isEmpty) return {};

    final points = PolylineDecoder.decode(encoded, precision: precision);
    if (points.isEmpty) return {};

    return {
      Polyline(
        polylineId: const PolylineId('route_shadow'),
        points: points,
        color: shadowColor,
        width: shadowWidth,
      ),
      Polyline(
        polylineId: const PolylineId('route'),
        points: points,
        color: color,
        width: width,
      ),
    };
  }
}
