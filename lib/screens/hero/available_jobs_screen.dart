import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/job_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/hero_provider.dart';
import '../../providers/job_provider.dart';
import '../../widgets/job/job_card.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_display.dart';
import 'job_details_screen.dart';

class AvailableJobsScreen extends ConsumerWidget {
  const AvailableJobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingJobs = ref.watch(pendingJobsProvider);
    final user = ref.watch(currentUserProvider);
    final heroId = user?.heroProfileId;

    return Scaffold(
      appBar: AppBar(title: const Text('Available Jobs')),
      body: pendingJobs.when(
        data: (jobs) {
          if (jobs.isEmpty) {
            return const ErrorDisplay(
              message: 'No jobs available right now.\nStay online to get notified.',
              icon: Icons.work_outline,
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(pendingJobsProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: jobs.length,
              itemBuilder: (context, index) {
                final job = jobs[index];
                return JobCard(
                  job: job,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => JobDetailsScreen(
                          job: job,
                          onAccept: heroId != null
                              ? () async {
                                  final success = await ref
                                      .read(heroProvider(heroId).notifier)
                                      .acceptJob(job.id);
                                  if (success && context.mounted) {
                                    Navigator.pop(context);
                                  }
                                }
                              : null,
                          onDecline: () => Navigator.pop(context),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
        loading: () => const LoadingIndicator(message: 'Loading jobs...'),
        error: (err, _) => ErrorDisplay(
          message: 'Failed to load jobs: $err',
          onRetry: () => ref.invalidate(pendingJobsProvider),
        ),
      ),
    );
  }
}
