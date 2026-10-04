import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.textInverse,
        primaryContainer: AppColors.primaryLight,
        onPrimaryContainer: AppColors.primary,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.error,
        onError: AppColors.textInverse,
      ),
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Segoe UI',
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textInverse,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.borderFocus, width: 1.5),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.signalBlue,
        onPrimary: AppColors.textInverse,
        primaryContainer: AppColors.darkPrimaryLight,
        onPrimaryContainer: AppColors.signalBlue,
        surface: AppColors.carbon,
        onSurface: AppColors.paper,
        error: AppColors.error,
        onError: AppColors.textInverse,
      ),
      scaffoldBackgroundColor: AppColors.obsidian,
      fontFamily: 'Inter',
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 56, fontWeight: FontWeight.w400, letterSpacing: -2.2, color: AppColors.paper, height: 1.1),
        displayMedium: TextStyle(fontSize: 40, fontWeight: FontWeight.w400, letterSpacing: -1.6, color: AppColors.paper, height: 1.15),
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w400, letterSpacing: -1.2, color: AppColors.paper, height: 1.2),
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w500, letterSpacing: -0.65, color: AppColors.paper, height: 1.25),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, letterSpacing: -0.4, color: AppColors.paper),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: -0.2, color: AppColors.paper),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: -0.1, color: AppColors.ash, height: 1.5),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: -0.05, color: AppColors.ash, height: 1.45),
        labelLarge: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.1, color: AppColors.paper),
        labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.2, color: AppColors.smoke),
      ),
      cardTheme: CardThemeData(
        color: AppColors.carbon,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), // REKKI --radius-cards: 16px
          side: const BorderSide(color: AppColors.rekkiBorderSubtle, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.paper,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: Border(bottom: BorderSide(color: AppColors.rekkiBorderSubtle, width: 1)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.signalBlue,
          foregroundColor: AppColors.paper,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(59)), // REKKI --radius-buttons: 59px
          textStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13.5, letterSpacing: -0.1),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.paper,
          side: const BorderSide(color: AppColors.rekkiBorderSubtle),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(59)), // REKKI --radius-buttons: 59px
          textStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13.5, letterSpacing: -0.1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.iron, // REKKI --color-iron: #1f1f1f
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        hintStyle: const TextStyle(color: AppColors.ash, fontSize: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8), // REKKI --radius-inputs: 8px
          borderSide: const BorderSide(color: AppColors.rekkiBorderInput),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.rekkiBorderInput),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.signalBlue, width: 1.5),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.rekkiBorderSubtle,
        thickness: 1,
        space: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.carbon,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.rekkiBorderSubtle),
        ),
      ),
    );
  }
}
