import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../widgets/common/step_progress_indicator.dart';
import 'confirm_request_screen.dart';

class RideOptionsScreen extends StatefulWidget {
  final String serviceType;
  final String serviceLabel;
  final String address;
  final double latitude;
  final double longitude;
  final String destinationAddress;
  final double destinationLatitude;
  final double destinationLongitude;
  final int totalSteps;

  const RideOptionsScreen({
    super.key,
    required this.serviceType,
    required this.serviceLabel,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.destinationAddress,
    required this.destinationLatitude,
    required this.destinationLongitude,
    this.totalSteps = 3,
  });

  @override
  State<RideOptionsScreen> createState() => _RideOptionsScreenState();
}

class _RideOptionsScreenState extends State<RideOptionsScreen> {
  String? _selectedRideType;
  int _extraStops = 0;
  final _instructionsController = TextEditingController();

  static const _rideTypes = [
    _RideType(
      id: 'standard',
      title: 'Standard',
      subtitle: 'Everyday rides, everyday prices',
    ),
    _RideType(
      id: 'suv_xl',
      title: 'SUV/XL',
      subtitle: 'Extra space for groups',
    ),
    _RideType(
      id: 'luxury',
      title: 'Luxury',
      subtitle: 'Premium vehicles, premium experience',
    ),
  ];

  @override
  void dispose() {
    _instructionsController.dispose();
    super.dispose();
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
                      currentStep: 2, totalSteps: widget.totalSteps),
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
                      'Choose your ride',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      'Select Ride Type',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),

                    ..._rideTypes.map((type) {
                      final isSelected = _selectedRideType == type.id;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _selectedRideType = type.id),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.brandGreen
                                    : const Color(0xFFE8E8E8),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        type.title,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        type.subtitle,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  Container(
                                    width: 26,
                                    height: 26,
                                    decoration: BoxDecoration(
                                      color: AppTheme.brandGreen,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.check,
                                        color: Colors.white, size: 16),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 24),

                    // Extra Stops
                    const Text(
                      'Extra Stops (+\$6 each)',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _counterButton(
                          icon: Icons.remove,
                          onTap: _extraStops > 0
                              ? () => setState(() => _extraStops--)
                              : null,
                        ),
                        SizedBox(
                          width: 48,
                          child: Text(
                            '$_extraStops',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                        ),
                        _counterButton(
                          icon: Icons.add,
                          onTap: _extraStops < 5
                              ? () => setState(() => _extraStops++)
                              : null,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Special Instructions
                    const Text(
                      'Special Instructions (Optional)',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _instructionsController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Any special requests for your driver...',
                          hintStyle:
                              TextStyle(color: Colors.grey[400], fontSize: 14),
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

            // Continue button
            Container(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _selectedRideType != null ? _onContinue : null,
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

  Widget _counterButton({required IconData icon, VoidCallback? onTap}) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: enabled ? AppTheme.brandGreen : Colors.grey[300]!,
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: enabled ? AppTheme.brandGreen : Colors.grey[300],
        ),
      ),
    );
  }

  void _onContinue() {
    final rideLabel = _rideTypes
        .firstWhere((t) => t.id == _selectedRideType)
        .title;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConfirmRequestScreen(
          serviceType: widget.serviceType,
          serviceLabel: widget.serviceLabel,
          vehicleInfo: '',
          address: widget.address,
          latitude: widget.latitude,
          longitude: widget.longitude,
          notes: _instructionsController.text.trim(),
          totalSteps: widget.totalSteps,
          destinationAddress: widget.destinationAddress,
          destinationLatitude: widget.destinationLatitude,
          destinationLongitude: widget.destinationLongitude,
          rideType: rideLabel,
          extraStops: _extraStops,
        ),
      ),
    );
  }
}

class _RideType {
  final String id;
  final String title;
  final String subtitle;

  const _RideType({
    required this.id,
    required this.title,
    required this.subtitle,
  });
}
