import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../config/theme.dart';
import '../../widgets/common/step_progress_indicator.dart';
import 'confirm_request_screen.dart';

class LocationScreen extends StatefulWidget {
  final String serviceType;
  final String serviceLabel;
  final String vehicleInfo;

  const LocationScreen({
    super.key,
    required this.serviceType,
    required this.serviceLabel,
    required this.vehicleInfo,
  });

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  String _address = '';
  double? _latitude;
  double? _longitude;
  bool _isLocating = false;
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permission denied')),
            );
          }
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions permanently denied. Enable in Settings.')),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      String formattedAddress = '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final parts = <String>[
            if (p.street != null && p.street!.isNotEmpty) p.street!,
            if (p.locality != null && p.locality!.isNotEmpty) p.locality!,
            if (p.administrativeArea != null && p.administrativeArea!.isNotEmpty) p.administrativeArea!,
            if (p.postalCode != null && p.postalCode!.isNotEmpty) p.postalCode!,
          ];
          if (parts.isNotEmpty) formattedAddress = parts.join(', ');
        }
      } catch (_) {}

      if (mounted) {
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
          _address = formattedAddress;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get location: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.arrow_back, size: 24),
                      ),
                      Expanded(
                        child: Text(
                          widget.serviceLabel,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 24),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const StepProgressIndicator(currentStep: 2),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Where are you?',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 20),

                    // Service Location
                    const Text(
                      'Service Location',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: _address.isNotEmpty ? AppTheme.brandGreen : Colors.grey[400],
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _address.isNotEmpty ? _address : 'No location set',
                              style: TextStyle(
                                fontSize: 14,
                                color: _address.isNotEmpty ? Colors.black87 : Colors.grey[400],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Use current location
                    GestureDetector(
                      onTap: _isLocating ? null : _useCurrentLocation,
                      child: Row(
                        children: [
                          if (_isLocating)
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.brandGreen,
                              ),
                            )
                          else
                            Icon(Icons.near_me, size: 16, color: AppTheme.brandGreen),
                          const SizedBox(width: 6),
                          Text(
                            _isLocating ? 'Getting location...' : 'Use current location',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.brandGreen,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Additional Notes
                    const Text(
                      'Additional Notes (Optional)',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),

                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _notesController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Add any details to help the Hero find you...',
                          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom button
            Container(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _address.isNotEmpty && _latitude != null
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ConfirmRequestScreen(
                                serviceType: widget.serviceType,
                                serviceLabel: widget.serviceLabel,
                                vehicleInfo: widget.vehicleInfo,
                                address: _address,
                                latitude: _latitude!,
                                longitude: _longitude!,
                                notes: _notesController.text,
                              ),
                            ),
                          );
                        }
                      : null,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
