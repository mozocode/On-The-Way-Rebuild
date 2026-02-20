import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    final service = ServiceTypes.getById(job.serviceType);

    return Scaffold(
      appBar: AppBar(title: const Text('Job Details')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Service header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.brandGreen.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppTheme.brandGreen.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(_serviceIcon(job.serviceType),
                              color: AppTheme.brandGreen, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                service?.name ?? job.serviceType,
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              if (job.serviceSubType != null)
                                Text(
                                  job.serviceSubType!
                                      .replaceAll('_', ' ')
                                      .toUpperCase(),
                                  style: TextStyle(
                                      color: Colors.grey[600], fontSize: 13),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          Formatters.currency(job.pricing.total),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.brandGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Customer
                  const Text('Customer',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey[200],
                        backgroundImage: job.customer.photoUrl != null
                            ? NetworkImage(job.customer.photoUrl!)
                            : null,
                        child: job.customer.photoUrl == null
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      title: Text(job.customer.name),
                      subtitle: job.customer.phone != null
                          ? Text(Formatters.phoneNumber(job.customer.phone!))
                          : null,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Pickup
                  const Text('Pickup Location',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.location_on, color: Colors.red),
                      title: Text(
                        job.pickup.address?.formatted ?? 'Unknown',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: job.pickup.notes != null
                          ? Text('Note: ${job.pickup.notes}')
                          : null,
                    ),
                  ),

                  if (job.destination != null) ...[
                    const SizedBox(height: 20),
                    const Text('Destination',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    Card(
                      child: ListTile(
                        leading:
                            const Icon(Icons.flag, color: AppTheme.brandGreen),
                        title: Text(
                          job.destination!.address?.formatted ?? 'Unknown',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],

                  if (job.tracking.etaMinutes != null ||
                      job.tracking.etaDistance != null) ...[
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        if (job.tracking.etaMinutes != null)
                          _StatBox(
                              label: 'ETA',
                              value: '${job.tracking.etaMinutes} min'),
                        if (job.tracking.etaMinutes != null &&
                            job.tracking.etaDistance != null)
                          const SizedBox(width: 12),
                        if (job.tracking.etaDistance != null)
                          _StatBox(
                              label: 'Distance',
                              value:
                                  '${job.tracking.etaDistance!.toStringAsFixed(1)} mi'),
                      ],
                    ),
                  ],

                  const SizedBox(height: 24),
                  // Price breakdown
                  const Text('Earnings',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _EarningsRow('Base', job.pricing.basePrice),
                          if (job.pricing.heroTravelFee > 0)
                            _EarningsRow(
                              'Travel (${job.pricing.heroTravelMiles.toStringAsFixed(1)} mi)',
                              job.pricing.heroTravelFee,
                            ),
                          if (job.pricing.heroTravelFee == 0)
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
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Your Payout',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              Text(
                                job.pricing.heroPayout.totalPayout > 0
                                    ? job.pricing.heroPayout.formattedPayout
                                    : Formatters.currency(
                                        job.pricing.total - job.pricing.serviceFee),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.brandGreen),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (onAccept != null || onDecline != null)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, -2)),
                ],
              ),
              child: Row(
                children: [
                  if (onDecline != null)
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          onPressed: onDecline,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                          child: const Text('Decline'),
                        ),
                      ),
                    ),
                  if (onDecline != null && onAccept != null)
                    const SizedBox(width: 12),
                  if (onAccept != null)
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: onAccept,
                          child: const Text('Accept Job'),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
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
      case 'winch_out':
        return Icons.warning;
      default:
        return Icons.build;
    }
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;

  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            Text(value,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _EarningsRow extends StatelessWidget {
  final String label;
  final int amount;

  const _EarningsRow(this.label, this.amount);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(Formatters.currency(amount)),
        ],
      ),
    );
  }
}
