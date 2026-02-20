import 'package:flutter_radar/flutter_radar.dart';

enum TrackingPreset {
  stopped,
  efficient,
  responsive,
  continuous,
}

class RadarAutocompleteResult {
  final String formattedAddress;
  final String addressLabel;
  final String? placeLabel;
  final double latitude;
  final double longitude;
  final String? city;
  final String? state;
  final String? stateCode;
  final String? postalCode;
  final String? countryCode;
  final String? layer;

  const RadarAutocompleteResult({
    required this.formattedAddress,
    required this.addressLabel,
    this.placeLabel,
    required this.latitude,
    required this.longitude,
    this.city,
    this.state,
    this.stateCode,
    this.postalCode,
    this.countryCode,
    this.layer,
  });

  String get displayTitle => placeLabel ?? addressLabel;

  String get displaySubtitle {
    final parts = <String>[];
    if (placeLabel != null && addressLabel.isNotEmpty) parts.add(addressLabel);
    if (city != null && city!.isNotEmpty) parts.add(city!);
    if (stateCode != null && stateCode!.isNotEmpty) parts.add(stateCode!);
    if (postalCode != null && postalCode!.isNotEmpty) parts.add(postalCode!);
    return parts.join(', ');
  }

  factory RadarAutocompleteResult.fromMap(Map<String, dynamic> map) {
    return RadarAutocompleteResult(
      formattedAddress: map['formattedAddress'] as String? ?? '',
      addressLabel: map['addressLabel'] as String? ?? '',
      placeLabel: map['placeLabel'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      city: map['city'] as String?,
      state: map['state'] as String?,
      stateCode: map['stateCode'] as String?,
      postalCode: map['postalCode'] as String?,
      countryCode: map['countryCode'] as String?,
      layer: map['layer'] as String?,
    );
  }
}

class RadarService {
  static final RadarService _instance = RadarService._internal();
  factory RadarService() => _instance;
  RadarService._internal();

  bool _isTracking = false;
  bool get isTracking => _isTracking;

  Future<void> setUserId(String heroId) async {
    await Radar.setUserId(heroId);
  }

  Future<void> setMetadata({
    required bool isOnline,
    required bool isVerified,
    List<String>? servicesOffered,
    String? currentJobId,
  }) async {
    final meta = <String, dynamic>{
      'userType': 'hero',
      'isOnline': isOnline,
      'isVerified': isVerified,
      'servicesOffered': servicesOffered ?? [],
    };
    if (currentJobId != null) {
      meta['currentJobId'] = currentJobId;
    }
    await Radar.setMetadata(meta);
  }

  Future<String> requestPermissions({bool background = true}) async {
    final status = await Radar.requestPermissions(background);
    return status ?? 'UNKNOWN';
  }

  Future<String> getPermissionStatus() async {
    final status = await Radar.getPermissionsStatus();
    return status ?? 'UNKNOWN';
  }

  Future<void> startTracking(TrackingPreset preset) async {
    switch (preset) {
      case TrackingPreset.stopped:
        await stopTracking();
        break;
      case TrackingPreset.efficient:
        await Radar.startTracking('efficient');
        _isTracking = true;
        break;
      case TrackingPreset.responsive:
        await Radar.startTracking('responsive');
        _isTracking = true;
        break;
      case TrackingPreset.continuous:
        await Radar.startTracking('continuous');
        _isTracking = true;
        break;
    }
  }

  Future<void> stopTracking() async {
    await Radar.stopTracking();
    _isTracking = false;
  }

  Future<Map<String, dynamic>?> getCurrentLocation() async {
    try {
      final result = await Radar.getLocation('high');
      if (result == null) return null;
      return Map<String, dynamic>.from(result);
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> trackOnce() async {
    try {
      final result = await Radar.trackOnce();
      if (result == null) return null;
      return Map<String, dynamic>.from(result);
    } catch (e) {
      return null;
    }
  }

  Future<List<RadarAutocompleteResult>> autocomplete({
    required String query,
    double? nearLatitude,
    double? nearLongitude,
    int limit = 8,
    String? countryCode,
    List<String>? layers,
  }) async {
    try {
      Map<String, dynamic>? near;
      if (nearLatitude != null && nearLongitude != null) {
        near = {'latitude': nearLatitude, 'longitude': nearLongitude};
      }

      final result = await Radar.autocomplete(
        query: query,
        near: near,
        limit: limit,
        country: countryCode,
        layers: layers,
      );

      if (result == null) return [];

      final addresses = result['addresses'] as List? ?? [];
      return addresses
          .whereType<Map>()
          .map((a) => RadarAutocompleteResult.fromMap(
                Map<String, dynamic>.from(a),
              ))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<String?> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final result = await Radar.reverseGeocode(
        location: {'latitude': latitude, 'longitude': longitude},
      );
      if (result == null) return null;

      final addresses = result['addresses'] as List?;
      if (addresses != null && addresses.isNotEmpty) {
        final first = Map<String, dynamic>.from(addresses.first as Map);
        return first['formattedAddress'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getDistance({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    String mode = 'car',
    String units = 'imperial',
  }) async {
    try {
      final result = await Radar.getDistance(
        origin: {'latitude': originLat, 'longitude': originLng},
        destination: {'latitude': destLat, 'longitude': destLng},
        modes: [mode],
        units: units,
      );
      if (result == null) return null;
      return Map<String, dynamic>.from(result);
    } catch (e) {
      return null;
    }
  }
}
