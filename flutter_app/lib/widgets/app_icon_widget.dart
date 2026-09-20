import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Renders an app icon with support for network URLs (from App Store / Google Play)
/// and seamless fallback to category emoji.
class AppIconWidget extends StatelessWidget {
  final String? iconUrl;
  final String iconEmoji;
  final double size;
  final double borderRadius;
  final double fontSize;

  const AppIconWidget({
    super.key,
    this.iconUrl,
    required this.iconEmoji,
    this.size = 48,
    this.borderRadius = 12,
    this.fontSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    final hasValidUrl = iconUrl != null &&
        iconUrl!.trim().isNotEmpty &&
        (iconUrl!.startsWith('http://') || iconUrl!.startsWith('https://'));

    if (hasValidUrl) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.network(
          iconUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              color: AppColors.surfaceSecondary,
              alignment: Alignment.center,
              child: SizedBox(
                width: size * 0.4,
                height: size * 0.4,
                child: const CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) => _buildEmojiFallback(),
        ),
      );
    }

    return _buildEmojiFallback();
  }

  Widget _buildEmojiFallback() {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        iconEmoji,
        style: TextStyle(fontSize: fontSize),
      ),
    );
  }
}
