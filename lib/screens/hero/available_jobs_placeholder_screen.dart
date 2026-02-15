import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Placeholder until Available Jobs list and accept flow are implemented.
class AvailableJobsPlaceholderScreen extends StatelessWidget {
  const AvailableJobsPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Available jobs')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.work_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Available jobs',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Jobs will appear here when dispatch is running.',
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go('/hero/home'),
                child: const Text('Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
