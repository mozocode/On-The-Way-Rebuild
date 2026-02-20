import 'package:flutter/material.dart';
import '../../../config/theme.dart';

class OnboardingProgressIndicator extends StatelessWidget {
  final int currentStep;
  final List<int> completedSteps;
  final int totalSteps;

  const OnboardingProgressIndicator({
    super.key,
    required this.currentStep,
    required this.completedSteps,
    this.totalSteps = 5,
  });

  static const _stepLabels = [
    'Personal',
    'Vehicle',
    'Services',
    'Documents',
    'Review',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: [
          // Step dots + connecting lines
          Row(
            children: List.generate(totalSteps * 2 - 1, (index) {
              if (index.isOdd) {
                // Connector line
                final stepBefore = (index ~/ 2) + 1;
                final isCompleted = completedSteps.contains(stepBefore);
                return Expanded(
                  child: Container(
                    height: 2,
                    color: isCompleted
                        ? AppTheme.brandGreen
                        : Colors.grey[300],
                  ),
                );
              }

              // Step dot
              final step = (index ~/ 2) + 1;
              final isCompleted = completedSteps.contains(step);
              final isCurrent = step == currentStep;

              return Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted
                      ? AppTheme.brandGreen
                      : isCurrent
                          ? Colors.white
                          : Colors.grey[200],
                  border: Border.all(
                    color: isCompleted || isCurrent
                        ? AppTheme.brandGreen
                        : Colors.grey[300]!,
                    width: isCurrent ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : Text(
                          '$step',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isCurrent
                                ? AppTheme.brandGreen
                                : Colors.grey[500],
                          ),
                        ),
                ),
              );
            }),
          ),

          const SizedBox(height: 8),

          // Step labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(totalSteps, (index) {
              final step = index + 1;
              final isCurrent = step == currentStep;
              final isCompleted = completedSteps.contains(step);
              return SizedBox(
                width: 60,
                child: Text(
                  _stepLabels[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                    color: isCompleted || isCurrent
                        ? AppTheme.brandGreen
                        : Colors.grey[500],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
