import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../config/theme.dart';
import '../../services/radar_service.dart';
import '../../widgets/common/step_progress_indicator.dart';
import '../customer/location_picker_screen.dart';
import 'confirm_request_screen.dart';
import 'ride_options_screen.dart';

class LocationScreen extends StatefulWidget {
  final String serviceType;
  final String serviceLabel;
  final String? vehicleInfo;
  final String? subType;
  final int totalSteps;
  final bool isMotorcycle;
  final int? currentStep;

  const LocationScreen({
    super.key,
    required this.serviceType,
    required this.serviceLabel,
    this.vehicleInfo,
    this.subType,
    this.totalSteps = 3,
    this.isMotorcycle = false,
    this.currentStep,
  });

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  String _address = '';
  double? _latitude;
  double? _longitude;
  bool _isLocating = false;

  String _destinationAddress = '';
  double? _destLatitude;
  double? _destLongitude;

  final _notesController = TextEditingController();
  final _radarService = RadarService();

  bool get _isTowing => widget.serviceType == 'towing';
  bool get _isTransportation => widget.serviceType == 'winch_out';
  bool get _needsDestination => _isTowing || _isTransportation;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _openLocationPicker() async {
    final result = await Navigator.push<LocationPickerResult>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          title: 'Service Location',
          nearLatitude: _latitude,
          nearLongitude: _longitude,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _address = result.address;
        _latitude = result.location.latitude;
        _longitude = result.location.longitude;
      });
    }
  }

  Future<void> _openDestinationPicker() async {
    final result = await Navigator.push<LocationPickerResult>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          title: 'Destination',
          nearLatitude: _latitude,
          nearLongitude: _longitude,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _destinationAddress = result.address;
        _destLatitude = result.location.latitude;
        _destLongitude = result.location.longitude;
      });
    }
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
            const SnackBar(
                content: Text(
                    'Location permissions permanently denied. Enable in Settings.')),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      String formattedAddress =
          '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';

      final reverseAddress = await _radarService.reverseGeocode(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      if (reverseAddress != null && reverseAddress.isNotEmpty) {
        formattedAddress = reverseAddress;
      }

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

  bool get _canContinue {
    if (_address.isEmpty || _latitude == null) return false;
    if (_needsDestination &&
        (_destinationAddress.isEmpty || _destLatitude == null)) {
      return false;
    }
    return true;
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
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 24),
                    ],
                  ),
                  const SizedBox(height: 12),
                  StepProgressIndicator(
                    currentStep: widget.currentStep ??
                        (widget.totalSteps == 4 ? 3 : 2),
                    totalSteps: widget.totalSteps,
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _needsDestination
                    ? _buildDestinationLocationContent()
                    : _buildStandardLocationContent(),
              ),
            ),

            // Bottom button
            Container(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _canContinue ? _onContinue : null,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Continue',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
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

  Widget _buildDestinationLocationContent() {
    final heading = _isTransportation ? 'Where are you going?' : 'Where are you?';
    final pickupLabel = _isTransportation ? 'Pickup Location' : 'Current Location';
    final destPlaceholder = _isTransportation
        ? 'Where are you going?'
        : 'Where do you need your vehicle towed?';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          heading,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 20),

        Text(
          pickupLabel,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        _buildLocationField(
          address: _address,
          dotColor: AppTheme.brandGreen,
          placeholder: 'Search for your location...',
          onTap: _openLocationPicker,
          onClear: () => setState(() {
            _address = '';
            _latitude = null;
            _longitude = null;
          }),
        ),

        const SizedBox(height: 12),

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

        const SizedBox(height: 20),

        Padding(
          padding: const EdgeInsets.only(left: 6),
          child: Container(
            width: 2,
            height: 24,
            color: Colors.grey[300],
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'Destination',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        _buildLocationField(
          address: _destinationAddress,
          dotColor: Colors.red,
          placeholder: destPlaceholder,
          onTap: _openDestinationPicker,
          onClear: () => setState(() {
            _destinationAddress = '';
            _destLatitude = null;
            _destLongitude = null;
          }),
        ),
      ],
    );
  }

  Widget _buildLocationField({
    required String address,
    required Color dotColor,
    required String placeholder,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    final hasAddress = address.isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasAddress
                ? AppTheme.brandGreen.withAlpha(80)
                : const Color(0xFFE0E0E0),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                hasAddress ? address : placeholder,
                style: TextStyle(
                  fontSize: 14,
                  color: hasAddress ? Colors.black87 : Colors.grey[400],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (hasAddress)
              GestureDetector(
                onTap: onClear,
                child: Icon(Icons.close, size: 18, color: Colors.grey[400]),
              )
            else
              Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildStandardLocationContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Where are you?',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 20),

        const Text(
          'Service Location',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),

        GestureDetector(
          onTap: _openLocationPicker,
          child: Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _address.isNotEmpty
                    ? AppTheme.brandGreen.withAlpha(80)
                    : const Color(0xFFE0E0E0),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _address.isNotEmpty ? Icons.location_on : Icons.search,
                  color: _address.isNotEmpty
                      ? AppTheme.brandGreen
                      : Colors.grey[400],
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _address.isNotEmpty
                        ? _address
                        : 'Search for address...',
                    style: TextStyle(
                      fontSize: 14,
                      color: _address.isNotEmpty
                          ? Colors.black87
                          : Colors.grey[400],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_address.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _address = '';
                        _latitude = null;
                        _longitude = null;
                      });
                    },
                    child: Icon(Icons.close,
                        size: 18, color: Colors.grey[400]),
                  )
                else
                  Icon(Icons.chevron_right,
                      size: 20, color: Colors.grey[400]),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

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
    );
  }

  void _onContinue() {
    if (_isTransportation) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RideOptionsScreen(
            serviceType: widget.serviceType,
            serviceLabel: widget.serviceLabel,
            address: _address,
            latitude: _latitude!,
            longitude: _longitude!,
            destinationAddress: _destinationAddress,
            destinationLatitude: _destLatitude!,
            destinationLongitude: _destLongitude!,
            totalSteps: widget.totalSteps,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ConfirmRequestScreen(
            serviceType: widget.serviceType,
            serviceLabel: widget.serviceLabel,
            vehicleInfo: widget.vehicleInfo ?? '',
            address: _address,
            latitude: _latitude!,
            longitude: _longitude!,
            notes: _needsDestination ? '' : _notesController.text,
            subType: widget.subType,
            totalSteps: widget.totalSteps,
            destinationAddress:
                _needsDestination ? _destinationAddress : null,
            destinationLatitude: _destLatitude,
            destinationLongitude: _destLongitude,
          ),
        ),
      );
    }
  }
}
