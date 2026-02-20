import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../config/theme.dart';
import '../../models/location_model.dart';

class LocationPickerResult {
  final LocationModel location;
  final String address;

  const LocationPickerResult({required this.location, required this.address});
}

class LocationPickerScreen extends StatefulWidget {
  final String title;

  const LocationPickerScreen({super.key, this.title = 'Set Location'});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final _searchController = TextEditingController();
  List<_PlaceResult> _results = [];
  bool _searching = false;
  bool _locating = false;
  String? _error;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchAddress(String query) async {
    if (query.trim().length < 3) {
      setState(() => _results = []);
      return;
    }

    setState(() {
      _searching = true;
      _error = null;
    });

    try {
      final locations = await locationFromAddress(query);
      final results = <_PlaceResult>[];

      for (final loc in locations.take(5)) {
        final placemarks = await placemarkFromCoordinates(
            loc.latitude, loc.longitude);
        final pm = placemarks.isNotEmpty ? placemarks.first : null;
        final address = pm != null
            ? [pm.street, pm.locality, pm.administrativeArea, pm.postalCode]
                .where((s) => s != null && s.isNotEmpty)
                .join(', ')
            : '${loc.latitude.toStringAsFixed(4)}, ${loc.longitude.toStringAsFixed(4)}';

        results.add(_PlaceResult(
          address: address,
          latitude: loc.latitude,
          longitude: loc.longitude,
        ));
      }

      setState(() {
        _results = results;
        _searching = false;
      });
    } catch (e) {
      setState(() {
        _searching = false;
        _error = 'Could not find that address';
      });
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _locating = true;
      _error = null;
    });

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final placemarks = await placemarkFromCoordinates(
          position.latitude, position.longitude);
      final pm = placemarks.isNotEmpty ? placemarks.first : null;
      final address = pm != null
          ? [pm.street, pm.locality, pm.administrativeArea, pm.postalCode]
              .where((s) => s != null && s.isNotEmpty)
              .join(', ')
          : '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';

      if (mounted) {
        Navigator.pop(
          context,
          LocationPickerResult(
            location: LocationModel(
              latitude: position.latitude,
              longitude: position.longitude,
              accuracy: position.accuracy,
            ),
            address: address,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _locating = false;
        _error = 'Could not get your location';
      });
    }
  }

  void _selectResult(_PlaceResult result) {
    Navigator.pop(
      context,
      LocationPickerResult(
        location: LocationModel(
          latitude: result.latitude,
          longitude: result.longitude,
        ),
        address: result.address,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search address...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _results = []);
                        },
                      )
                    : null,
              ),
              onChanged: _searchAddress,
            ),
          ),

          // Current location button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: InkWell(
              onTap: _locating ? null : _useCurrentLocation,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.brandGreen.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.my_location,
                        color: AppTheme.brandGreen, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _locating
                            ? 'Getting your location...'
                            : 'Use current location',
                        style: TextStyle(
                          color: AppTheme.brandGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (_locating)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ),
            ),
          ),

          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_error!,
                  style: const TextStyle(color: Colors.red, fontSize: 14)),
            ),

          if (_searching)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _results.length,
              itemBuilder: (context, i) {
                final r = _results[i];
                return ListTile(
                  leading: const Icon(Icons.location_on_outlined),
                  title: Text(r.address, maxLines: 2, overflow: TextOverflow.ellipsis),
                  onTap: () => _selectResult(r),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceResult {
  final String address;
  final double latitude;
  final double longitude;

  const _PlaceResult({
    required this.address,
    required this.latitude,
    required this.longitude,
  });
}
