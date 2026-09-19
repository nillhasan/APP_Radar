import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class ScoreBadge extends StatelessWidget {
  final int score;
  final bool showLabel;
  final double fontSize;

  const ScoreBadge({
    super.key,
    required this.score,
    this.showLabel = true,
    this.fontSize = 13,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color border;
    Color text;

    if (score >= 80) {
      bg = AppColors.primaryLight;
      border = AppColors.primaryBorder;
      text = AppColors.primary;
    } else if (score >= 70) {
      bg = const Color(0xFFF0FDF4); // emerald 50
      border = AppColors.successBorder;
      text = AppColors.success;
    } else {
      bg = AppColors.warningLight;
      border = AppColors.warningBorder;
      text = AppColors.warning;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: fontSize > 14 ? 14 : 10,
        vertical: fontSize > 14 ? 6 : 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.radar,
            size: fontSize + 1,
            color: text,
          ),
          const SizedBox(width: 5),
          Text(
            showLabel ? '$score / 100' : '$score',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: text,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}
