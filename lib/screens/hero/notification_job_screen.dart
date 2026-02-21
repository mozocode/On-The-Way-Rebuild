import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/hero_provider.dart';
import '../../providers/job_provider.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_display.dart';
import 'job_details_screen.dart';

class NotificationJobScreen extends ConsumerWidget {
  final String jobId;

  const NotificationJobScreen({super.key, required this.jobId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobAsync = ref.watch(jobStreamProvider(jobId));
    final user = ref.watch(currentUserProvider);
    final heroId = user?.heroProfileId;

    return jobAsync.when(
      data: (job) {
        if (job == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Job Details')),
            body: const ErrorDisplay(
              message: 'This job is no longer available.',
              icon: Icons.work_off_outlined,
            ),
          );
        }

        return JobDetailsScreen(
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
          onDecline: () {
            if (heroId != null) {
              ref.read(heroProvider(heroId).notifier).declineJob(job.id);
            }
            Navigator.pop(context);
          },
        );
      },
      loading: () => const Scaffold(
        body: LoadingIndicator(message: 'Loading job details...'),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(title: const Text('Job Details')),
        body: ErrorDisplay(
          message: 'Failed to load job: $err',
          onRetry: () => ref.invalidate(jobStreamProvider(jobId)),
        ),
      ),
    );
  }
}
