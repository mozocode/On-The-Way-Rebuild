import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/theme.dart';
import '../../models/job_model.dart';
import '../../models/service_type_model.dart';
import '../../utils/formatters.dart';

class JobDetailsScreen extends StatelessWidget {
  final JobModel job;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  const JobDetailsScreen({
    super.key,
    required this.job,
    this.onAccept,
    this.onDecline,
  });

  static const _dark = Color(0xFF1A1A2E);
  static const _cardDark = Color(0xFF222236);
  static const _dimText = Color(0xFF8E8E9E);
  static const _accentBlue = Color(0xFF3B82F6);

  String _shortAddress(JobAddress? addr) {
    if (addr == null) return 'Unknown';
    if (addr.street != null && addr.city != null) {
      return '${addr.street}, ${addr.city}';
    }
    return addr.formatted;
  }

  @override
  Widget build(BuildContext context) {
    final service = ServiceTypes.getById(job.serviceType);
    final serviceName = service?.name ?? job.serviceType.replaceAll('_', ' ');
    final payout = Formatters.currency(job.pricing.total);
    final heroPayout = job.pricing.heroPayout.totalPayout > 0
        ? job.pricing.heroPayout.formattedPayout
        : Formatters.currency(job.pricing.total - job.pricing.serviceFee);
    final hasDestination = job.destination != null;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _dark,
        body: SafeArea(
          child: Column(
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Job Details',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Service badge + sub-type
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _cardDark,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_serviceIcon(job.serviceType), color: Colors.white, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  serviceName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (job.serviceSubType != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.brandGreen.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                job.serviceSubType!.replaceAll('_', ' '),
                                style: TextStyle(
                                  color: AppTheme.brandGreen,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Big price
                      Text(
                        payout,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 44,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.5,
                        ),
                      ),

                      const SizedBox(height: 6),

                      // Rating + verified
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 18),
                          const SizedBox(width: 4),
                          const Text(
                            '5.0',
                            style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.verified, color: _accentBlue, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'Verified',
                            style: TextStyle(color: _accentBlue, fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Route card
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: _cardDark,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          children: [
                            // Pickup
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    if (hasDestination)
                                      Container(width: 2, height: 36, color: Colors.white24),
                                  ],
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          if (job.tracking.etaMinutes != null || job.tracking.etaDistance != null)
                                            Text(
                                              [
                                                if (job.tracking.etaMinutes != null) '${job.tracking.etaMinutes} min',
                                                if (job.tracking.etaDistance != null)
                                                  '(${job.tracking.etaDistance!.toStringAsFixed(1)} mi)',
                                              ].join(' '),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            )
                                          else
                                            const Text(
                                              'Pickup',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _shortAddress(job.pickup.address),
                                        style: const TextStyle(color: _dimText, fontSize: 13),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (job.pickup.notes != null && job.pickup.notes!.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'Note: ${job.pickup.notes}',
                                          style: TextStyle(color: Colors.amber.shade300, fontSize: 12),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            // Destination
                            if (hasDestination) ...[
                              const SizedBox(height: 6),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: Colors.transparent,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Destination',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _shortAddress(job.destination!.address),
                                          style: const TextStyle(color: _dimText, fontSize: 13),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Customer card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _cardDark,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: Colors.white12,
                              backgroundImage: job.customer.photoUrl != null
                                  ? NetworkImage(job.customer.photoUrl!)
                                  : null,
                              child: job.customer.photoUrl == null
                                  ? const Icon(Icons.person, color: Colors.white54)
                                  : null,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    job.customer.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (job.customer.phone != null)
                                    Text(
                                      Formatters.phoneNumber(job.customer.phone!),
                                      style: const TextStyle(color: _dimText, fontSize: 13),
                                    ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chat_bubble_outline, color: Colors.white38, size: 22),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Earnings breakdown
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: _cardDark,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Earnings Breakdown',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 14),
                            _EarningsRow('Base', job.pricing.basePrice),
                            if (job.pricing.heroTravelFee > 0)
                              _EarningsRow(
                                'Travel (${job.pricing.heroTravelMiles.toStringAsFixed(1)} mi)',
                                job.pricing.heroTravelFee,
                              ),
                            if (job.pricing.heroTravelFee == 0 && job.pricing.mileagePrice > 0)
                              _EarningsRow('Mileage', job.pricing.mileagePrice),
                            if (job.pricing.towingDistanceFee > 0)
                              _EarningsRow(
                                'Towing (${job.pricing.towingDistanceMiles.toStringAsFixed(1)} mi)',
                                job.pricing.towingDistanceFee,
                              ),
                            if (job.pricing.priorityFee > 0)
                              _EarningsRow('Priority', job.pricing.priorityFee),
                            if (job.pricing.winchFee > 0)
                              _EarningsRow('Winch', job.pricing.winchFee),
                            if (job.pricing.addOns.afterHoursFee > 0)
                              _EarningsRow('After Hours', job.pricing.addOns.afterHoursFee),
                            if (job.pricing.surgePricing.surgeAmount > 0)
                              _EarningsRow('Surge', job.pricing.surgePricing.surgeAmount),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 10),
                              child: Divider(color: Colors.white12, height: 1),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Your Payout',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  heroPayout,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18,
                                    color: AppTheme.brandGreen,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom action bar
              if (onAccept != null || onDecline != null)
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  color: _dark,
                  child: Row(
                    children: [
                      if (onDecline != null)
                        Expanded(
                          child: SizedBox(
                            height: 54,
                            child: OutlinedButton(
                              onPressed: onDecline,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Decline',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ),
                      if (onDecline != null && onAccept != null)
                        const SizedBox(width: 12),
                      if (onAccept != null)
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: 54,
                            child: ElevatedButton(
                              onPressed: onAccept,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _accentBlue,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Accept',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _serviceIcon(String id) {
    switch (id) {
      case 'flat_tire':
        return Icons.circle_outlined;
      case 'dead_battery':
        return Icons.battery_0_bar;
      case 'lockout':
        return Icons.key;
      case 'fuel_delivery':
        return Icons.local_gas_station;
      case 'towing':
        return Icons.local_shipping;
      case 'transportation':
        return Icons.directions_car;
      default:
        return Icons.build;
    }
  }
}

class _EarningsRow extends StatelessWidget {
  final String label;
  final int amount;

  const _EarningsRow(this.label, this.amount);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF8E8E9E), fontSize: 14)),
          Text(Formatters.currency(amount), style: const TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }
}
