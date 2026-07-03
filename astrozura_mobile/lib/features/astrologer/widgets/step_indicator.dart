import 'package:flutter/material.dart';

class StepIndicator extends StatelessWidget {
  final int currentStep; // 1, 2, 3
  final int totalSteps;

  const StepIndicator({
    super.key,
    required this.currentStep,
    this.totalSteps = 3,
  });

  /// 🔥 STEP TITLES
  String getStepTitle(int step) {
    switch (step) {
      case 1:
        return "Personalize your session";
      case 2:
        return "Select Time Slot";
      case 3:
        return "Payment Method";
      default:
        return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    double progress = currentStep / totalSteps;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// 🔹 STEP TEXT ROW
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [

              /// LEFT: STEP COUNT
              Text(
                "STEP $currentStep OF $totalSteps",
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),

              /// RIGHT: DYNAMIC TITLE
              Text(
                getStepTitle(currentStep), // 🔥 DYNAMIC
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF0d437b),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          /// 🔹 PROGRESS BAR
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.white,
              color: const Color(0xFF2F5AA8),
            ),
          ),
        ],
      ),
    );
  }
}