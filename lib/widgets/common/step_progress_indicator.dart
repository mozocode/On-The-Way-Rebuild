import 'package:flutter/material.dart';
import '../../config/theme.dart';

class StepProgressIndicator extends StatelessWidget {
  final int currentStep; // 1, 2, or 3
  final int totalSteps;

  const StepProgressIndicator({
    super.key,
    required this.currentStep,
    this.totalSteps = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSteps * 2 - 1, (index) {
        if (index.isOdd) {
          // Connector line
          final stepBefore = (index ~/ 2) + 1;
          final isCompleted = stepBefore < currentStep;
          return Container(
            width: 40,
            height: 2,
            color: isCompleted ? AppTheme.brandGreen : Colors.grey[300],
          );
        } else {
          // Step circle
          final step = (index ~/ 2) + 1;
          final isCompleted = step < currentStep;
          final isActive = step == currentStep;

          return Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted || isActive ? AppTheme.brandGreen : Colors.white,
              border: Border.all(
                color: isCompleted || isActive ? AppTheme.brandGreen : Colors.grey[300]!,
                width: 2,
              ),
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : Text(
                      '$step',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isActive ? Colors.white : Colors.grey[400],
                      ),
                    ),
            ),
          );
        }
      }),
    );
  }
}
