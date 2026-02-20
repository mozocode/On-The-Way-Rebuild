import 'package:flutter/material.dart';
import '../../models/job_model.dart';
import '../../models/service_type_model.dart';
import '../../utils/formatters.dart';

class JobCard extends StatelessWidget {
  final JobModel job;
  final VoidCallback? onTap;

  const JobCard({super.key, required this.job, this.onTap});

  @override
  Widget build(BuildContext context) {
    final service = ServiceTypes.getById(job.serviceType);
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _serviceIcon(job.serviceType),
                      color: theme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service?.name ?? job.serviceType,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          job.pickup.address?.formatted ?? 'Unknown location',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        Formatters.currency(job.pricing.total),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _StatusChip(status: job.status),
                    ],
                  ),
                ],
              ),
              if (job.tracking.etaMinutes != null) ...[
                const Divider(height: 24),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      'ETA: ${job.tracking.etaMinutes} min',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    if (job.tracking.etaDistance != null) ...[
                      const SizedBox(width: 16),
                      Icon(Icons.place, size: 16, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        '${job.tracking.etaDistance!.toStringAsFixed(1)} mi',
                        style:
                            TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _serviceIcon(String serviceId) {
    switch (serviceId) {
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

class _StatusChip extends StatelessWidget {
  final JobStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final config = _statusConfig(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: (config['color'] as Color).withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        config['label'] as String,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: config['color'] as Color,
        ),
      ),
    );
  }

  Map<String, dynamic> _statusConfig(JobStatus status) {
    switch (status) {
      case JobStatus.pending:
      case JobStatus.searching:
        return {'label': 'Searching', 'color': Colors.orange};
      case JobStatus.assigned:
        return {'label': 'Assigned', 'color': Colors.blue};
      case JobStatus.enRoute:
        return {'label': 'En Route', 'color': Colors.blue};
      case JobStatus.arrived:
        return {'label': 'Arrived', 'color': Colors.green};
      case JobStatus.inProgress:
        return {'label': 'In Progress', 'color': Colors.green};
      case JobStatus.completed:
        return {'label': 'Completed', 'color': Colors.grey};
      case JobStatus.cancelled:
        return {'label': 'Cancelled', 'color': Colors.red};
      case JobStatus.noHeroesAvailable:
        return {'label': 'No Heroes', 'color': Colors.red};
    }
  }
}
