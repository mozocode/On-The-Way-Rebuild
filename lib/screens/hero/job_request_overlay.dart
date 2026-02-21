import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/dispatch_config.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/hero_provider.dart';
import '../../providers/job_provider.dart';
import '../../models/job_model.dart';
import '../../models/service_type_model.dart';
import 'hero_active_job_screen.dart';

class JobRequestOverlay extends ConsumerStatefulWidget {
  final String jobId;
  final String? serviceType;
  final String? pickupAddress;
  final double? estimatedPrice;
  final double? distanceMiles;
  final int? estimatedMinutes;
  final DateTime? expiresAt;

  const JobRequestOverlay({
    super.key,
    required this.jobId,
    this.serviceType,
    this.pickupAddress,
    this.estimatedPrice,
    this.distanceMiles,
    this.estimatedMinutes,
    this.expiresAt,
  });

  @override
  ConsumerState<JobRequestOverlay> createState() => _JobRequestOverlayState();
}

class _JobRequestOverlayState extends ConsumerState<JobRequestOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _timerController;
  bool _isResponding = false;

  @override
  void initState() {
    super.initState();
    final remaining = widget.expiresAt != null
        ? widget.expiresAt!.difference(DateTime.now())
        : Duration(seconds: DispatchConfig.heroResponseTimeoutSeconds);

    final effectiveDuration =
        remaining.isNegative ? const Duration(seconds: 5) : remaining;

    _timerController = AnimationController(
      vsync: this,
      duration: effectiveDuration,
    )..forward();

    _timerController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        Navigator.of(context).pop();
      }
    });

    HapticFeedback.heavyImpact();
  }

  @override
  void dispose() {
    _timerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final jobAsync = ref.watch(jobStreamProvider(widget.jobId));

    return Material(
      color: Colors.black54,
      child: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            jobAsync.when(
              data: (job) => _buildCard(context, job),
              loading: () => _buildCard(context, null),
              error: (_, __) => _buildCard(context, null),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, JobModel? job) {
    final serviceType = job?.serviceType ?? widget.serviceType ?? '';
    final service = ServiceTypes.getById(serviceType);
    final serviceName = service?.name ?? serviceType.replaceAll('_', ' ');
    final price = job != null
        ? (job.pricing.total / 100).toStringAsFixed(2)
        : widget.estimatedPrice?.toStringAsFixed(2) ?? '0.00';
    final address =
        job?.pickup.address?.formatted ?? widget.pickupAddress ?? 'Loading...';
    final distMiles = widget.distanceMiles;
    final etaMin = widget.estimatedMinutes;
    final subType = job?.serviceSubType;
    final hasDestination = job?.destination != null;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
            child: AnimatedBuilder(
              animation: _timerController,
              builder: (context, child) {
                return LinearProgressIndicator(
                  value: 1 - _timerController.value,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation(
                    _timerController.value > 0.3
                        ? AppTheme.brandGreen
                        : Colors.orange,
                  ),
                  minHeight: 6,
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.brandGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_serviceIcon(serviceType),
                              color: AppTheme.brandGreen, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            serviceName.toUpperCase(),
                            style: TextStyle(
                              color: AppTheme.brandGreen,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (subType != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          subType.replaceAll('_', ' '),
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '\$$price',
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -1,
                  ),
                ),
                if (job != null && job.pricing.hasSurge)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      job.pricing.surgePricing.formattedMultiplier,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (distMiles != null)
                      _InfoChip(
                        icon: Icons.location_on,
                        label: '${distMiles.toStringAsFixed(1)} mi',
                        subtitle: 'away',
                      ),
                    if (etaMin != null)
                      _InfoChip(
                        icon: Icons.access_time,
                        label: '$etaMin min',
                        subtitle: 'to pickup',
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.place, color: AppTheme.brandGreen),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Pickup',
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            Text(
                              address,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasDestination) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.flag, color: Colors.redAccent),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Destination',
                                style:
                                    TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              Text(
                                job!.destination!.address?.formatted ??
                                    'Unknown',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isResponding ? null : _declineJob,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                        child: const Text(
                          'Decline',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isResponding ? null : _acceptJob,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.brandGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isResponding
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Accept',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _acceptJob() async {
    setState(() => _isResponding = true);
    _timerController.stop();

    final user = ref.read(currentUserProvider);
    final heroId = user?.heroProfileId;
    if (heroId == null) {
      setState(() => _isResponding = false);
      return;
    }

    try {
      final success = await ref
          .read(heroProvider(heroId).notifier)
          .acceptJob(widget.jobId);

      if (mounted) {
        Navigator.of(context).pop();
        if (success) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => HeroActiveJobScreen(jobId: widget.jobId),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isResponding = false);
        _timerController.forward();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to accept: $e')),
        );
      }
    }
  }

  Future<void> _declineJob() async {
    setState(() => _isResponding = true);

    final user = ref.read(currentUserProvider);
    final heroId = user?.heroProfileId;
    if (heroId != null) {
      await ref
          .read(heroProvider(heroId).notifier)
          .declineJob(widget.jobId);
    }

    if (mounted) Navigator.of(context).pop();
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

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey[600], size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }
}
