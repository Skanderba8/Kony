// lib/views/widgets/report_form/form_step_indicator.dart
import 'package:flutter/material.dart';

/// A stepper indicator for multi-step forms with completion status tracking
class FormStepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final Function(int) onStepTapped;
  final List<String> stepTitles;
  final List<bool> stepsCompleted;

  const FormStepIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.onStepTapped,
    required this.stepTitles,
    required this.stepsCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(totalSteps, (index) {
            final isActive = index == currentStep;
            final isCompleted = stepsCompleted[index];
            final isPassed = index < currentStep;

            return InkWell(
              onTap: () => onStepTapped(index),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _getStepColor(
                              isActive,
                              isCompleted,
                              isPassed,
                              context,
                            ),
                          ),
                          child: Center(
                            child:
                                isCompleted
                                    ? const Icon(
                                      Icons.check,
                                      size: 16,
                                      color: Colors.white,
                                    )
                                    : Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        color:
                                            isActive
                                                ? Colors.white
                                                : Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                          ),
                        ),
                        if (index < totalSteps - 1)
                          Container(
                            width: 20,
                            height: 2,
                            color:
                                (isCompleted || isPassed)
                                    ? Colors.green
                                    : Colors.grey.shade300,
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      stepTitles[index],
                      style: TextStyle(
                        fontSize: 12,
                        color: _getTextColor(
                          isActive,
                          isCompleted,
                          isPassed,
                          context,
                        ),
                        fontWeight:
                            isActive ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  /// Helper to determine the appropriate color for a step indicator
  Color _getStepColor(
    bool isActive,
    bool isCompleted,
    bool isPassed,
    BuildContext context,
  ) {
    if (isCompleted) {
      return Colors.green;
    } else if (isActive) {
      return Theme.of(context).primaryColor;
    } else if (isPassed) {
      return Colors.orange.shade300; // Visited but not completed
    } else {
      return Colors.grey.shade300;
    }
  }

  /// Helper to determine the appropriate text color based on step status
  Color _getTextColor(
    bool isActive,
    bool isCompleted,
    bool isPassed,
    BuildContext context,
  ) {
    if (isActive) {
      return Theme.of(context).primaryColor;
    } else if (isCompleted) {
      return Colors.green;
    } else if (isPassed) {
      return Colors.orange.shade700; // Visited but not completed
    } else {
      return Colors.grey.shade600;
    }
  }
}
