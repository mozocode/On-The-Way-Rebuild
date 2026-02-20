import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../models/hero_application_model.dart';
import '../../providers/hero_application_provider.dart';
import 'steps/personal_info_step.dart';
import 'steps/vehicle_info_step.dart';
import 'steps/services_step.dart';
import 'steps/documents_step.dart';
import 'steps/agreements_step.dart';
import 'widgets/onboarding_progress_indicator.dart';

class HeroOnboardingScreen extends ConsumerStatefulWidget {
  const HeroOnboardingScreen({super.key});

  @override
  ConsumerState<HeroOnboardingScreen> createState() =>
      _HeroOnboardingScreenState();
}

class _HeroOnboardingScreenState extends ConsumerState<HeroOnboardingScreen> {
  final _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(heroApplicationProvider);

    ref.listen<int>(applicationStepProvider, (previous, next) {
      if (previous != next && _pageController.hasClients) {
        _pageController.animateToPage(
          next - 1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });

    if (appState.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (appState.application == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Become a Hero')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text('Unable to load application'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.read(heroApplicationProvider.notifier).refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Non-draft applications show the status screen
    if (!appState.application!.isDraft) {
      return _ApplicationStatusScreen(application: appState.application!);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Become a Hero'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _showExitDialog(context),
        ),
      ),
      body: Column(
        children: [
          OnboardingProgressIndicator(
            currentStep: appState.currentStep,
            completedSteps: appState.application!.completedSteps,
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                ref
                    .read(heroApplicationProvider.notifier)
                    .setCurrentStep(index + 1);
              },
              children: const [
                PersonalInfoStep(),
                VehicleInfoStep(),
                ServicesStep(),
                DocumentsStep(),
                AgreementsStep(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showExitDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save & Exit?'),
        content: const Text(
            'Your progress is saved. You can continue later.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Save & Exit'),
          ),
        ],
      ),
    );
    if (result == true && mounted) {
      Navigator.of(context).pop();
    }
  }
}

// ── Status screen shown for submitted / pending / approved / rejected ──

class _ApplicationStatusScreen extends StatelessWidget {
  final HeroApplicationModel application;

  const _ApplicationStatusScreen({required this.application});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Application Status')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              _statusIcon(),
              const SizedBox(height: 24),
              Text(
                application.statusLabel,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                _statusMessage(),
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.grey[600], fontSize: 15, height: 1.5),
              ),
              if (application.rejectionReason != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Reason:',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(application.rejectionReason!,
                          style: TextStyle(color: Colors.red.shade700)),
                    ],
                  ),
                ),
              ],
              const Spacer(),

              // Progress summary card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _progressRow('Personal Info', application.completedSteps.contains(1)),
                    _progressRow('Vehicle Info', application.completedSteps.contains(2)),
                    _progressRow('Services & Equipment', application.completedSteps.contains(3)),
                    _progressRow('Documents', application.completedSteps.contains(4)),
                    _progressRow('Agreements', application.completedSteps.contains(5)),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              if (application.isApproved)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Go to Dashboard'),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Back to Home'),
                  ),
                ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusIcon() {
    IconData icon;
    Color color;

    switch (application.status) {
      case ApplicationStatus.submitted:
      case ApplicationStatus.underReview:
      case ApplicationStatus.backgroundCheck:
        icon = Icons.hourglass_top_rounded;
        color = Colors.orange;
      case ApplicationStatus.approved:
        icon = Icons.check_circle_rounded;
        color = AppTheme.brandGreen;
      case ApplicationStatus.rejected:
        icon = Icons.cancel_rounded;
        color = Colors.red;
      case ApplicationStatus.needsInfo:
      case ApplicationStatus.pendingDocuments:
        icon = Icons.info_rounded;
        color = Colors.blue;
      default:
        icon = Icons.help_outline;
        color = Colors.grey;
    }

    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 56, color: color),
    );
  }

  String _statusMessage() {
    switch (application.status) {
      case ApplicationStatus.submitted:
        return 'Your application has been submitted! We\'ll review it within 1-2 business days.';
      case ApplicationStatus.underReview:
        return 'Our team is reviewing your application. You\'ll hear from us soon.';
      case ApplicationStatus.backgroundCheck:
        return 'We\'re running a background check. This typically takes 3-5 business days.';
      case ApplicationStatus.approved:
        return 'Congratulations! You\'ve been approved as an OTW Hero. Start accepting jobs now!';
      case ApplicationStatus.rejected:
        return 'Unfortunately, we couldn\'t approve your application at this time.';
      case ApplicationStatus.needsInfo:
        return 'We need some additional information to process your application.';
      case ApplicationStatus.pendingDocuments:
        return 'Please upload the required documents to continue.';
      default:
        return '';
    }
  }

  Widget _progressRow(String label, bool completed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            completed ? Icons.check_circle : Icons.circle_outlined,
            size: 20,
            color: completed ? AppTheme.brandGreen : Colors.grey[400],
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: completed ? Colors.black87 : Colors.grey[500],
              fontWeight: completed ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
