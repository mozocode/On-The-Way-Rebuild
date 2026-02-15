import 'dart:convert';
import 'package:flutter/services.dart';

/// Loads vehicle database (years, colors, makes, models) from JSON asset.
class VehicleDataLoader {
  static Map<String, dynamic>? _raw;
  static List<String>? _years;
  static List<String>? _colors;
  static List<String>? _makeNames;
  static Map<String, List<String>>? _modelsByMake;

  static Future<void> ensureLoaded() async {
    if (_raw != null) return;
    final jsonStr = await rootBundle.loadString('assets/data/vehicle_data.json');
    _raw = jsonDecode(jsonStr) as Map<String, dynamic>;

    _years = List<String>.from(_raw!['years'] as List);
    _colors = List<String>.from(_raw!['colors'] as List);

    final makesMap = _raw!['makes'] as Map<String, dynamic>;
    _makeNames = [];
    _modelsByMake = {};

    for (final e in makesMap.entries) {
      final v = e.value;
      if (v is! Map<String, dynamic>) continue;
      // Car/truck makes have "models" array
      if (v.containsKey('models') && v['models'] is List) {
        final make = e.key as String;
        _makeNames!.add(make);
        _modelsByMake![make] = List<String>.from(
          (v['models'] as List).map((x) => x.toString()),
        );
      }
    }
    _makeNames!.sort();
  }

  static List<String> get years => _years ?? [];
  static List<String> get colors => _colors ?? [];
  static List<String> get makeNames => _makeNames ?? [];
  static List<String> modelsForMake(String make) => _modelsByMake?[make] ?? [];
}
