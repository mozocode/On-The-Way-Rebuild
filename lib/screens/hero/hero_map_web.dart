import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

/// Web-only: full-screen map via iframe (OpenStreetMap) so Hero dashboard always shows a map when MapLibre fails.
class HeroWebMap extends StatefulWidget {
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
  State<HeroWebMap> createState() => _HeroWebMapState();
}

class _HeroWebMapState extends State<HeroWebMap> {
  static int _nextId = 0;
  late final String _viewType;

  @override
  void initState() {
    super.initState();
    _viewType = 'otw_hero_web_map_${_nextId++}';
    _registerView();
  }

  void _registerView() {
    final lat = widget.lat;
    final lng = widget.lng;
    // OpenStreetMap embed: bbox is minLon,minLat,maxLon,maxLat (roughly zoom 12 area)
    final delta = 0.02;
    final bbox = '${lng - delta},${lat - delta},${lng + delta},${lat + delta}';
    final embedUrl = 'https://www.openstreetmap.org/export/embed.html?bbox=$bbox&layer=mapnik&marker=$lat%2C$lng';

    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId, {Object? params}) {
        final iframe = html.IFrameElement()
          ..src = embedUrl
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%'
          ..setAttribute('allowfullscreen', 'true');
        return iframe;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewType);
  }
}
