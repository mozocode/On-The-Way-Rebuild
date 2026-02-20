import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/job_model.dart';
import '../../models/service_type_model.dart';
import '../../utils/formatters.dart';

class ServiceProgressScreen extends StatefulWidget {
  final JobModel job;
  final Future<void> Function(String status) onUpdateStatus;

  const ServiceProgressScreen({
    super.key,
    required this.job,
    required this.onUpdateStatus,
  });

  @override
  State<ServiceProgressScreen> createState() => _ServiceProgressScreenState();
}

class _ServiceProgressScreenState extends State<ServiceProgressScreen> {
  bool _isUpdating = false;

  Future<void> _updateStatus(String status) async {
    setState(() => _isUpdating = true);
    try {
      await widget.onUpdateStatus(status);
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = ServiceTypes.getById(widget.job.serviceType);
    final job = widget.job;

    return Scaffold(
      appBar: AppBar(title: const Text('Service In Progress')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status timeline
                  _StatusTimeline(job: job),
                  const SizedBox(height: 28),

                  // Service info
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service?.name ?? job.serviceType,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Customer: ${job.customer.name}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          job.pickup.address?.formatted ?? 'Unknown location',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Earnings preview
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Your Payout',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600)),
                          Text(
                            Formatters.currency(
                                job.pricing.total - job.pricing.serviceFee),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.brandGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Action button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: _buildActionButton(job),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(JobModel job) {
    switch (job.status) {
      case JobStatus.assigned:
      case JobStatus.enRoute:
        return ElevatedButton.icon(
          onPressed: _isUpdating ? null : () => _updateStatus('arrived'),
          icon: const Icon(Icons.flag),
          label: const Text('I Have Arrived'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
        );
      case JobStatus.arrived:
        return ElevatedButton.icon(
          onPressed: _isUpdating ? null : () => _updateStatus('in_progress'),
          icon: const Icon(Icons.play_arrow),
          label: const Text('Start Service'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
        );
      case JobStatus.inProgress:
        return ElevatedButton.icon(
          onPressed: _isUpdating ? null : () => _updateStatus('completed'),
          icon: const Icon(Icons.check),
          label: const Text('Complete Service'),
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.brandGreen),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _StatusTimeline extends StatelessWidget {
  final JobModel job;

  const _StatusTimeline({required this.job});

  @override
  Widget build(BuildContext context) {
    final steps = [
      _Step('Assigned', Icons.assignment, _isReached(JobStatus.assigned)),
      _Step('En Route', Icons.directions_car, _isReached(JobStatus.enRoute)),
      _Step('Arrived', Icons.flag, _isReached(JobStatus.arrived)),
      _Step('In Progress', Icons.build, _isReached(JobStatus.inProgress)),
      _Step('Completed', Icons.check_circle, _isReached(JobStatus.completed)),
    ];

    return Column(
      children: List.generate(steps.length, (i) {
        final step = steps[i];
        final isLast = i == steps.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: step.reached
                        ? AppTheme.brandGreen
                        : Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(step.icon, size: 18, color: Colors.white),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 28,
                    color: step.reached ? AppTheme.brandGreen : Colors.grey[300],
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                step.label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: step.reached ? FontWeight.w600 : FontWeight.normal,
                  color: step.reached ? Colors.black : Colors.grey[500],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  bool _isReached(JobStatus target) {
    const order = [
      JobStatus.assigned,
      JobStatus.enRoute,
      JobStatus.arrived,
      JobStatus.inProgress,
      JobStatus.completed,
    ];
    final current = order.indexOf(job.status);
    final check = order.indexOf(target);
    if (current == -1 || check == -1) return false;
    return current >= check;
  }
}

class _Step {
  final String label;
  final IconData icon;
  final bool reached;

  const _Step(this.label, this.icon, this.reached);
}
