import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../config/theme.dart';
import '../../models/location_model.dart';
import '../../services/radar_service.dart';

class LocationPickerResult {
  final LocationModel location;
  final String address;

  const LocationPickerResult({required this.location, required this.address});
}

class LocationPickerScreen extends StatefulWidget {
  final String title;
  final double? nearLatitude;
  final double? nearLongitude;

  const LocationPickerScreen({
    super.key,
    this.title = 'Set Location',
    this.nearLatitude,
    this.nearLongitude,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final _searchController = TextEditingController();
  final _radarService = RadarService();
  final _focusNode = FocusNode();

  List<RadarAutocompleteResult> _results = [];
  bool _searching = false;
  bool _locating = false;
  String? _error;
  Timer? _debounce;

  double? _userLat;
  double? _userLng;

  @override
  void initState() {
    super.initState();
    _initUserLocation();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _initUserLocation() async {
    if (widget.nearLatitude != null && widget.nearLongitude != null) {
      _userLat = widget.nearLatitude;
      _userLng = widget.nearLongitude;
      return;
    }
    try {
      final position = await Geolocator.getLastKnownPosition();
      if (position != null && mounted) {
        setState(() {
          _userLat = position.latitude;
          _userLng = position.longitude;
        });
      }
    } catch (_) {}
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();

    if (query.trim().length < 2) {
      setState(() {
        _results = [];
        _searching = false;
        _error = null;
      });
      return;
    }

    setState(() => _searching = true);

    _debounce = Timer(const Duration(milliseconds: 300), () {
      _performSearch(query.trim());
    });
  }

  Future<void> _performSearch(String query) async {
    if (!mounted) return;

    setState(() {
      _searching = true;
      _error = null;
    });

    final results = await _radarService.autocomplete(
      query: query,
      nearLatitude: _userLat,
      nearLongitude: _userLng,
      limit: 8,
      countryCode: 'US',
    );

    if (!mounted) return;

    setState(() {
      _results = results;
      _searching = false;
      if (results.isEmpty && query.length >= 3) {
        _error = 'No results found';
      }
    });
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _locating = true;
      _error = null;
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locating = false;
            _error = 'Location permission denied';
          });
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locating = false;
          _error = 'Location permissions permanently denied. Enable in Settings.';
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      String address =
          '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';

      final reverseAddress = await _radarService.reverseGeocode(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      if (reverseAddress != null && reverseAddress.isNotEmpty) {
        address = reverseAddress;
      }

      if (mounted) {
        Navigator.pop(
          context,
          LocationPickerResult(
            location: LocationModel(
              latitude: position.latitude,
              longitude: position.longitude,
              accuracy: position.accuracy,
              address: address,
            ),
            address: address,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locating = false;
          _error = 'Could not get your location';
        });
      }
    }
  }

  void _selectResult(RadarAutocompleteResult result) {
    Navigator.pop(
      context,
      LocationPickerResult(
        location: LocationModel(
          latitude: result.latitude,
          longitude: result.longitude,
          address: result.formattedAddress,
        ),
        address: result.formattedAddress,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Search header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TextField(
                        controller: _searchController,
                        focusNode: _focusNode,
                        autofocus: true,
                        textInputAction: TextInputAction.search,
                        style: const TextStyle(fontSize: 15),
                        decoration: InputDecoration(
                          hintText: 'Search address or place...',
                          hintStyle: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 15,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.grey[500],
                            size: 20,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? GestureDetector(
                                  onTap: () {
                                    _searchController.clear();
                                    setState(() {
                                      _results = [];
                                      _error = null;
                                    });
                                    _focusNode.requestFocus();
                                  },
                                  child: Icon(
                                    Icons.close,
                                    color: Colors.grey[500],
                                    size: 18,
                                  ),
                                )
                              : null,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 12),
                          filled: false,
                        ),
                        onChanged: _onSearchChanged,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: Color(0xFFE0E0E0)),

            // Current location button
            Container(
              color: Colors.white,
              child: InkWell(
                onTap: _locating ? null : _useCurrentLocation,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppTheme.brandGreen.withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.my_location,
                          color: AppTheme.brandGreen,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Use current location',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.brandGreen,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              'GPS location',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_locating)
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.brandGreen,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            const Divider(height: 1, color: Color(0xFFE0E0E0)),

            // Error message
            if (_error != null)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                color: Colors.red.shade50,
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 16, color: Colors.red.shade400),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Loading indicator
            if (_searching)
              const Padding(
                padding: EdgeInsets.only(top: 20),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),

            // Results list
            Expanded(
              child: _results.isEmpty && !_searching
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: _results.length,
                      separatorBuilder: (_, __) => const Divider(
                        height: 1,
                        indent: 68,
                        color: Color(0xFFF0F0F0),
                      ),
                      itemBuilder: (context, i) =>
                          _buildResultTile(_results[i]),
                    ),
            ),

            // Powered by Radar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.radar, size: 14, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text(
                      'Powered by Radar',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    if (_searchController.text.isNotEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        children: [
          Icon(Icons.search, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            'Search for an address or place name',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultTile(RadarAutocompleteResult result) {
    final bool isPlace = result.placeLabel != null;

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () => _selectResult(result),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isPlace ? Icons.place : Icons.location_on_outlined,
                  color: Colors.grey[600],
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.displayTitle,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (result.displaySubtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        result.displaySubtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[500],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.north_west, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
