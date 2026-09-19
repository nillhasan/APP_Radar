import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class SignalBar extends StatelessWidget {
  final String label;
  final int value;
  final Color? barColor;

  const SignalBar({
    super.key,
    required this.label,
    required this.value,
    this.barColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = barColor ??
        (value >= 80
            ? AppColors.primary
            : value >= 70
                ? AppColors.success
                : AppColors.warning);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '$value/100',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (value.clamp(0, 100)) / 100.0,
              minHeight: 6,
              backgroundColor: AppColors.surfaceSecondary,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}
