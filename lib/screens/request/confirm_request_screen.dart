import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../models/location_model.dart';
import '../../providers/job_provider.dart';
import '../../services/payment_service.dart';
import '../../widgets/common/step_progress_indicator.dart';
import '../customer/tracking_screen.dart';

class ConfirmRequestScreen extends ConsumerStatefulWidget {
  final String serviceType;
  final String serviceLabel;
  final String vehicleInfo;
  final String address;
  final double latitude;
  final double longitude;
  final String notes;

  const ConfirmRequestScreen({
    super.key,
    required this.serviceType,
    required this.serviceLabel,
    required this.vehicleInfo,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.notes,
  });

  @override
  ConsumerState<ConfirmRequestScreen> createState() => _ConfirmRequestScreenState();
}

class _ConfirmRequestScreenState extends ConsumerState<ConfirmRequestScreen> {
  bool _priorityMatch = false;
  bool _isSubmitting = false;
  final _paymentService = PaymentService();

  double get _total {
    final pricing = _paymentService.calculatePrice(
      serviceType: widget.serviceType,
      distanceMiles: 5.0,
      isPriority: _priorityMatch,
    );
    return pricing.total / 100.0;
  }

  bool get _isLateNight {
    final hour = DateTime.now().hour;
    return hour >= 22 || hour < 6;
  }

  Future<void> _submitRequest() async {
    setState(() => _isSubmitting = true);

    final notifier = ref.read(jobCreationProvider.notifier);
    notifier.setServiceType(widget.serviceType);
    notifier.setPickupLocation(
      LocationModel(latitude: widget.latitude, longitude: widget.longitude),
      widget.address,
      notes: widget.notes.isNotEmpty ? widget.notes : null,
    );

    final jobId = await notifier.createJob();

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (jobId != null) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => CustomerTrackingScreen(jobId: jobId),
        ),
        (route) => route.isFirst,
      );
    } else {
      final error = ref.read(jobCreationProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Failed to submit request'),
          backgroundColor: Colors.red,
        ),
      );
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
                  const StepProgressIndicator(currentStep: 3),
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
                      'Confirm your request',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 20),

                    // Service price card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      decoration: BoxDecoration(
                        color: AppTheme.brandGreen.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.settings, size: 40, color: AppTheme.brandGreen),
                          const SizedBox(height: 8),
                          Text(
                            widget.serviceLabel,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '\$${_total.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.brandGreen,
                            ),
                          ),
                          if (_isLateNight) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.warning_amber, size: 14, color: Colors.orange[700]),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Late Night',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.orange[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Priority Match
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.bolt, color: Colors.amber, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Priority Match',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  'Skip the line - get matched first',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _priorityMatch,
                            onChanged: (v) => setState(() => _priorityMatch = v),
                            activeColor: AppTheme.brandGreen,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Service Location
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.location_on, size: 18, color: AppTheme.brandGreen),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Service Location',
                                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.address,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Vehicle
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.directions_car, size: 18, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Vehicle',
                                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.vehicleInfo,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Payment Method
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Payment Method',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        GestureDetector(
                          onTap: () {
                            // TODO: Change payment method
                          },
                          child: Text(
                            'Change',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.brandGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppTheme.brandGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.credit_card, color: AppTheme.brandGreen, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Visa •••• 4242',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  'Expires 1/2027',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Total
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '\$${_total.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                        ),
                      ],
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
                  onPressed: _isSubmitting ? null : _submitRequest,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Confirm & Request Hero', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
