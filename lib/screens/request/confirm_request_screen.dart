import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../models/location_model.dart';
import '../../providers/job_provider.dart';
import '../../widgets/common/step_progress_indicator.dart';
import '../../widgets/pricing/price_breakdown_card.dart';
import '../../widgets/pricing/promo_code_input.dart';
import '../customer/tracking_screen.dart';
import '../menu/payment_methods_screen.dart';

class ConfirmRequestScreen extends ConsumerStatefulWidget {
  final String serviceType;
  final String serviceLabel;
  final String vehicleInfo;
  final String address;
  final double latitude;
  final double longitude;
  final String notes;
  final String? subType;
  final int totalSteps;
  final String? destinationAddress;
  final double? destinationLatitude;
  final double? destinationLongitude;
  final String? rideType;
  final int extraStops;

  const ConfirmRequestScreen({
    super.key,
    required this.serviceType,
    required this.serviceLabel,
    required this.vehicleInfo,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.notes,
    this.subType,
    this.totalSteps = 3,
    this.destinationAddress,
    this.destinationLatitude,
    this.destinationLongitude,
    this.rideType,
    this.extraStops = 0,
  });

  @override
  ConsumerState<ConfirmRequestScreen> createState() => _ConfirmRequestScreenState();
}

class _ConfirmRequestScreenState extends ConsumerState<ConfirmRequestScreen> {
  bool _isSubmitting = false;
  String? _cardBrand;
  String? _cardLast4;
  int? _cardExpMonth;
  int? _cardExpYear;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(jobCreationProvider.notifier);
      notifier.setServiceType(widget.serviceType, subType: widget.subType);
      notifier.setPickupLocation(
        LocationModel(latitude: widget.latitude, longitude: widget.longitude),
        widget.address,
        notes: widget.notes.isNotEmpty ? widget.notes : null,
      );
      if (widget.destinationLatitude != null && widget.destinationLongitude != null) {
        notifier.setDestinationLocation(
          LocationModel(latitude: widget.destinationLatitude!, longitude: widget.destinationLongitude!),
          widget.destinationAddress ?? '',
        );
      }
    });
    _loadDefaultCard();
  }

  Future<void> _loadDefaultCard() async {
    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable('listPaymentMethods')
          .call({});
      final methods = result.data['paymentMethods'] as List?;
      if (methods != null && methods.isNotEmpty && mounted) {
        final card = methods.first;
        setState(() {
          _cardBrand = card['brand'] as String?;
          _cardLast4 = card['last4'] as String?;
          _cardExpMonth = card['expMonth'] as int?;
          _cardExpYear = card['expYear'] as int?;
        });
      }
    } catch (_) {}
  }

  bool get _isLateNight {
    final hour = DateTime.now().hour;
    return hour >= 22 || hour < 6;
  }

  Widget _buildInfoRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  String _formatSubType(String subType) {
    return subType.split('+').map((s) {
      return s.replaceAll('_', ' ').split(' ').map((w) {
        if (w.isEmpty) return w;
        return '${w[0].toUpperCase()}${w.substring(1)}';
      }).join(' ');
    }).join(' + ');
  }

  Future<void> _submitRequest() async {
    setState(() => _isSubmitting = true);

    final jobId = await ref.read(jobCreationProvider.notifier).createJob();

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
    final jobState = ref.watch(jobCreationProvider);
    final pricing = jobState.pricing;
    final total = pricing != null ? pricing.total / 100.0 : 0.0;

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
                  StepProgressIndicator(
                    currentStep: widget.totalSteps,
                    totalSteps: widget.totalSteps,
                  ),
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
                          if (jobState.isPriceLoading)
                            const SizedBox(
                              width: 24, height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
                            Text(
                              '\$${total.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.brandGreen,
                              ),
                            ),
                          if (pricing != null && pricing.hasSurge) ...[
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
                                  Icon(Icons.trending_up, size: 14, color: Colors.orange[700]),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Surge ${pricing.surgePricing.formattedMultiplier}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.orange[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else if (_isLateNight) ...[
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
                            value: jobState.isPriority,
                            onChanged: (v) =>
                                ref.read(jobCreationProvider.notifier).setPriority(v),
                            activeColor: AppTheme.brandGreen,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Promo code
                    const PromoCodeInput(),

                    const SizedBox(height: 20),

                    // Price breakdown (expandable)
                    if (pricing != null) PriceBreakdownCard(pricing: pricing),

                    const SizedBox(height: 20),

                    // Pickup
                    _buildInfoRow(
                      icon: Icons.location_on,
                      iconColor: AppTheme.brandGreen,
                      label: widget.destinationAddress != null ? 'Pickup' : 'Service Location',
                      value: widget.address,
                    ),

                    // Destination (towing only)
                    if (widget.destinationAddress != null) ...[
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        icon: Icons.flag,
                        iconColor: Colors.red,
                        label: 'Destination',
                        value: widget.destinationAddress!,
                      ),
                    ],

                    // Vehicle (hidden for transportation)
                    if (widget.vehicleInfo.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        icon: Icons.directions_car,
                        iconColor: Colors.grey[600]!,
                        label: 'Vehicle',
                        value: widget.vehicleInfo,
                      ),
                    ],

                    // Services (when subType is set)
                    if (widget.subType != null && widget.subType!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        icon: Icons.build,
                        iconColor: Colors.grey[600]!,
                        label: 'Services',
                        value: _formatSubType(widget.subType!),
                      ),
                    ],

                    // Ride Type (transportation only)
                    if (widget.rideType != null) ...[
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        icon: Icons.directions_car,
                        iconColor: Colors.grey[600]!,
                        label: 'Ride Type',
                        value: widget.rideType!,
                      ),
                    ],

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
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PaymentMethodsScreen(),
                              ),
                            );
                            _loadDefaultCard();
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
                                Text(
                                  _cardLast4 != null
                                      ? '${(_cardBrand ?? 'Card')[0].toUpperCase()}${(_cardBrand ?? 'card').substring(1)} •••• $_cardLast4'
                                      : 'No card on file',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  _cardLast4 != null
                                      ? 'Expires $_cardExpMonth/$_cardExpYear'
                                      : 'Tap Change to add one',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                ),
                              ],
                            ),
                          ),
                        ],
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
                  onPressed: (_isSubmitting || jobState.isPriceLoading)
                      ? null
                      : _submitRequest,
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
                            Text('Confirm & Request Hero',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
