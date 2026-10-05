import 'package:flutter/material.dart';

class AppColors {
  // REKKI Design System Core Tokens (from DESIGN.md)
  static const Color signalBlue = Color(0xFF0063E1); // #0063e1 - Primary CTA & active indicator
  static const Color obsidian = Color(0xFF000000);   // #000000 - Page canvas, deep base
  static const Color carbon = Color(0xFF040910);     // #040910 - First card elevation, panel base
  static const Color graphite = Color(0xFF0D0D0D);   // #0d0d0d - Mid-surface, standard card surface
  static const Color iron = Color(0xFF1F1F1F);       // #1f1f1f - Input field backgrounds, form controls
  static const Color steel = Color(0xFF2B2C2E);      // #2b2c2e - Modal surfaces, hover states
  static const Color ash = Color(0xFF858585);        // #858585 - Body text, muted labels
  static const Color smoke = Color(0xFF979797);      // #979797 - Icon strokes, tertiary borders
  static const Color fog = Color(0xFF8C8C8C);        // #8c8c8c - Subdued navigation links
  static const Color paper = Color(0xFFFFFFFF);      // #ffffff - Headings, high-contrast actions

  // REKKI Inset Borders & Shadows (12% and 20% white)
  static const Color rekkiBorderSubtle = Color(0x1FFFFFFF); // rgba(255, 255, 255, 0.12) - cards & panels
  static const Color rekkiBorderInput = Color(0x33FFFFFF);  // rgba(255, 255, 255, 0.20) - input borders

  // Brand Accents
  static const Color primary = signalBlue;
  static const Color primaryHover = Color(0xFF0052BA);
  static const Color primaryLight = Color(0xFFEFF6FF); // Blue 50
  static const Color primaryBorder = Color(0xFFBFDBFE); // Blue 200
  static const Color accent = Color(0xFFE11D48); // Rose / Vibrant Game accent

  // AI Brand Gradient / Accent
  static const Color aiPurple = Color(0xFF7C3AED);
  static const Color aiPurpleLight = Color(0xFFF5F3FF);
  static const Color aiCyan = Color(0xFF0891B2);

  // Background & Surface Neutrals (Light Mode)
  static const Color background = Color(0xFFF8FAFC); // Slate 50
  static const Color surface = Color(0xFFFFFFFF); // Pure White
  static const Color surfaceSecondary = Color(0xFFF1F5F9); // Slate 100
  static const Color surfaceHover = Color(0xFFF8FAFC);

  // Borders & Dividers
  static const Color border = Color(0xFFE2E8F0); // Slate 200
  static const Color borderLight = Color(0xFFF1F5F9);
  static const Color borderFocus = signalBlue;

  // Typography
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF475569); // Slate 600
  static const Color textMuted = Color(0xFF94A3B8); // Slate 400
  static const Color textInverse = Color(0xFFFFFFFF);

  // Dark Mode Neutral Tokens (REKKI Mission Control System)
  static const Color darkBackground = obsidian;            // #000000 Pitch black canvas
  static const Color darkSurface = carbon;                 // #040910 Card surface base
  static const Color darkSurfaceSecondary = graphite;      // #0d0d0d Elevated card & section surface
  static const Color darkSurfaceHover = steel;             // #2b2c2e Hover elevation
  static const Color darkBorder = rekkiBorderSubtle;       // rgba(255, 255, 255, 0.12)
  static const Color darkBorderLight = Color(0x2EFFFFFF);  // rgba(255, 255, 255, 0.18)
  static const Color darkTextPrimary = paper;              // #ffffff Primary text & headings
  static const Color darkTextSecondary = ash;              // #858585 Body text & secondary labels
  static const Color darkTextMuted = smoke;                // #979797 Low-priority text & strokes
  static const Color darkPrimaryLight = Color(0xFF061838); // Subtle signal blue elevation tint

  // Active theme state (updated by ThemeService)
  static bool isDark = false;

  // Dynamic getters for responsive components
  static Color get currentBackground => isDark ? darkBackground : background;
  static Color get currentSurface => isDark ? darkSurface : surface;
  static Color get currentSurfaceSecondary => isDark ? darkSurfaceSecondary : surfaceSecondary;
  static Color get currentBorder => isDark ? darkBorder : border;
  static Color get currentTextPrimary => isDark ? darkTextPrimary : textPrimary;
  static Color get currentTextSecondary => isDark ? darkTextSecondary : textSecondary;
  static Color get currentTextMuted => isDark ? darkTextMuted : textMuted;
  static Color get currentPrimaryLight => isDark ? darkPrimaryLight : primaryLight;

  // Semantic Status (Aligned with REKKI quiet instruments)
  static const Color success = Color(0xFF10B981); // Emerald 500
  static const Color successLight = Color(0xFFECFDF5);
  static const Color successBorder = Color(0xFFA7F3D0);

  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color warningLight = Color(0xFFFFFBEB);
  static const Color warningBorder = Color(0xFFFDE68A);

  static const Color error = Color(0xFFEF4444); // Red 500
  static const Color errorLight = Color(0xFFFEF2F2);
  static const Color errorBorder = Color(0xFFFECACA);

  // Danger alias (semantic)
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerLight = Color(0xFFFEF2F2);
  static const Color dangerBorder = Color(0xFFFECACA);

  static const Color info = signalBlue;
  static const Color infoLight = Color(0xFFEFF6FF);
}
