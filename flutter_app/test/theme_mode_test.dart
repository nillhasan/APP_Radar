import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_radar/core/theme/app_colors.dart';
import 'package:app_radar/core/theme/app_theme.dart';
import 'package:app_radar/core/theme/theme_service.dart';
import 'package:app_radar/features/landing/landing_page_view.dart';
import 'package:app_radar/features/settings/settings_view.dart';
import 'package:app_radar/data/repositories/app_repository.dart';
import 'package:app_radar/data/repositories/opportunity_repository.dart';
import 'package:app_radar/services/auth/auth_service.dart';
import 'package:app_radar/services/subscription/subscription_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Theme System & Dark Mode Tests', () {
    setUp(() {
      ThemeService.instance.setThemeMode(ThemeMode.light);
    });

    tearDown(() {
      ThemeService.instance.setThemeMode(ThemeMode.light);
    });

    test('ThemeService toggles correctly and updates AppColors.isDark', () {
      expect(ThemeService.instance.isDark, isFalse);
      expect(ThemeService.instance.themeMode, ThemeMode.light);
      expect(AppColors.isDark, isFalse);

      ThemeService.instance.toggleTheme();

      expect(ThemeService.instance.isDark, isTrue);
      expect(ThemeService.instance.themeMode, ThemeMode.dark);
      expect(AppColors.isDark, isTrue);

      ThemeService.instance.toggleTheme();

      expect(ThemeService.instance.isDark, isFalse);
      expect(ThemeService.instance.themeMode, ThemeMode.light);
      expect(AppColors.isDark, isFalse);
    });

    test('AppTheme provides valid light and dark ThemeData', () {
      final light = AppTheme.lightTheme;
      final dark = AppTheme.darkTheme;

      expect(light.brightness, Brightness.light);
      expect(dark.brightness, Brightness.dark);

      expect(light.scaffoldBackgroundColor, AppColors.background);
      expect(dark.scaffoldBackgroundColor, AppColors.darkBackground);

      expect(light.cardTheme.color, AppColors.surface);
      expect(dark.cardTheme.color, AppColors.darkSurface);

      expect(light.appBarTheme.backgroundColor, AppColors.surface);
      expect(dark.appBarTheme.backgroundColor, AppColors.darkSurface);
    });

    testWidgets('LandingPageView renders theme toggle button and switches theme on click', (tester) async {
      final appRepo = MockAppRepository();
      final oppRepo = MockOpportunityRepository(appRepository: appRepo);
      final authService = AuthService();
      final subService = SubscriptionService(authService: authService);

      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: LandingPageView(
            appRepo: appRepo,
            oppRepo: oppRepo,
            authService: authService,
            subscriptionService: subService,
            onLaunchConsole: () {},
            onOpenAuthModal: () {},
            onOpenPricingModal: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find theme toggle button by tooltip
      final themeToggleFinder = find.byTooltip('Switch to Dark Mode');
      expect(themeToggleFinder, findsOneWidget);
      expect(ThemeService.instance.isDark, isFalse);

      // Tap theme toggle button
      await tester.tap(themeToggleFinder);
      await tester.pumpAndSettle();

      expect(ThemeService.instance.isDark, isTrue);
      expect(find.byTooltip('Switch to Light Mode'), findsOneWidget);

      // Tap again to switch back to Light Mode
      await tester.tap(find.byTooltip('Switch to Light Mode'));
      await tester.pumpAndSettle();

      expect(ThemeService.instance.isDark, isFalse);
    });

    testWidgets('SettingsView renders Appearance & Theme card and changes theme mode', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: const Scaffold(body: SettingsView()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Appearance & Theme'), findsOneWidget);
      expect(find.text('Interface Theme Mode'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);

      // Tap 'Dark' in segmented button
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      expect(ThemeService.instance.isDark, isTrue);

      // Tap 'Light' in segmented button
      await tester.tap(find.text('Light'));
      await tester.pumpAndSettle();

      expect(ThemeService.instance.isDark, isFalse);
    });
  });
}
