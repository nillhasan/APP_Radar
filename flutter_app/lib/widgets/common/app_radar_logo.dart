import 'package:flutter/material.dart';

/// Reusable branded AppRadar Logo widget.
/// Renders the custom generated AppRadar radar/A logo with subtle rounded corners and optional glow.
class AppRadarLogo extends StatelessWidget {
  final double size;
  final double? borderRadius;
  final bool showGlow;

  const AppRadarLogo({
    super.key,
    this.size = 32,
    this.borderRadius,
    this.showGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? (size * 0.24);

    Widget logo = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.asset(
        'assets/images/app_logo.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(radius),
            ),
            child: Icon(
              Icons.radar,
              size: size * 0.6,
              color: Colors.white,
            ),
          );
        },
      ),
    );

    if (showGlow) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2563EB).withValues(alpha: 0.4),
              blurRadius: size * 0.35,
              offset: Offset(0, size * 0.08),
            ),
          ],
        ),
        child: logo,
      );
    }

    return logo;
  }
}
