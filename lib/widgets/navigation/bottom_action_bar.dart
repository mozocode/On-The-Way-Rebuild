import 'package:flutter/material.dart';
import '../../models/job_model.dart';

class BottomActionBar extends StatelessWidget {
  final JobModel? job;
  final VoidCallback? onArrived;
  final VoidCallback? onStartService;
  final VoidCallback? onCompleteService;

  const BottomActionBar({
    super.key,
    this.job,
    this.onArrived,
    this.onStartService,
    this.onCompleteService,
  });

  @override
  Widget build(BuildContext context) {
    if (job == null) return const SizedBox.shrink();
    switch (job!.status) {
      case JobStatus.assigned:
      case JobStatus.enRoute:
        return _buildButton(context, 'I Have Arrived', Icons.flag, Colors.green, onArrived);
      case JobStatus.arrived:
        return _buildButton(context, 'Start Service', Icons.play_arrow, Colors.blue, onStartService);
      case JobStatus.inProgress:
        return _buildButton(context, 'Complete Service', Icons.check, Colors.green, onCompleteService);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildButton(BuildContext context, String label, IconData icon, Color color, VoidCallback? onPressed) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon),
            label: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ),
    );
  }
}
