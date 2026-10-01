import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_radar/core/theme/app_theme.dart';
import 'package:app_radar/services/auth/auth_service.dart';
import 'package:app_radar/services/subscription/subscription_service.dart';
import 'package:app_radar/features/auth/auth_page_view.dart';
import 'package:app_radar/widgets/app_shell.dart';
import 'package:app_radar/data/repositories/app_repository.dart';
import 'package:app_radar/data/repositories/opportunity_repository.dart';
import 'package:app_radar/data/repositories/market_trend_repository.dart';
import 'package:app_radar/data/repositories/report_repository.dart';
import 'package:app_radar/data/repositories/watchlist_repository.dart';
import 'package:app_radar/services/ai/ai_service.dart';

void main() {
  group('MobileAction-Style Split-Screen Auth Page Tests', () {
    late AuthService authService;

    setUp(() {
      authService = AuthService();
    });

    testWidgets('AuthPageView renders all split-screen components on Desktop', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool authSuccessCalled = false;
      bool backToFrontPageCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: AuthPageView(
            authService: authService,
            onAuthSuccess: () => authSuccessCalled = true,
            onBackToFrontPage: () => backToFrontPageCalled = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Brand Header & Partner Badge
      expect(find.text('AppRadar'), findsOneWidget);
      expect(find.text('Telemetry Partner'), findsOneWidget);
      expect(find.text('Front Page'), findsOneWidget);

      // Left Form Elements
      expect(find.text("Let's get started"), findsOneWidget);
      expect(find.text('Fuel Your App Market Discovery with AppRadar'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('or sign up with'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Create a free account'), findsOneWidget);
      expect(find.text('Already have an account? '), findsOneWidget);
      expect(find.text('Log in'), findsOneWidget);

      // Right Testimonial & Social Proof Panel
      expect(find.text('“'), findsOneWidget);
      expect(find.textContaining('84% improvement in our session numbers'), findsOneWidget);
      expect(find.text('Zehra Türksoy'), findsOneWidget);
      expect(find.text('SEO & ASO Team Lead'), findsOneWidget);
      expect(find.text('SEM'), findsOneWidget);
      expect(find.text('Trusted by'), findsOneWidget);
      expect(find.text('∞ Meta'), findsOneWidget);
      expect(find.text('★ Starbucks'), findsOneWidget);

      // Test Mode Switch to Log In
      await tester.tap(find.text('Log in'));
      await tester.pumpAndSettle();

      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Log in to AppRadar'), findsOneWidget);
      expect(find.text("Don't have an account? "), findsOneWidget);

      // Test Back to Front Page button
      await tester.tap(find.text('Front Page'));
      await tester.pumpAndSettle();
      expect(backToFrontPageCalled, isTrue);

      // Test 1-Click Guest Bypass
      final guestBypassBtn = find.textContaining('Explore Console as Guest');
      expect(guestBypassBtn, findsOneWidget);
      await tester.tap(guestBypassBtn);
      await tester.pumpAndSettle();

      expect(authSuccessCalled, isTrue);
      expect(authService.isAuthenticated, isTrue);
    });

    testWidgets('AppShell Full Journey: Front Page -> Get Started -> Login Page -> Console -> Front Page', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final appRepo = MockAppRepository();
      final oppRepo = MockOpportunityRepository(appRepository: appRepo);
      final trendRepo = MockMarketTrendRepository();
      final reportRepo = MockReportRepository();
      final watchlistRepo = MockWatchlistRepository(appRepository: appRepo);
      final aiService = MockAIService();
      final subService = SubscriptionService(authService: authService);

      await tester.pumpWidget(
        MaterialApp(
          home: AppShell(
            appRepo: appRepo,
            oppRepo: oppRepo,
            trendRepo: trendRepo,
            reportRepo: reportRepo,
            watchlistRepo: watchlistRepo,
            aiService: aiService,
            authService: authService,
            subscriptionService: subService,
            initialShowLandingPage: true, // Starts on Front Page
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Initial State: Front Page with MobileAction-style templates & previews
      expect(find.text('Next-Gen Mobile App Intelligence & Market Telemetry'), findsOneWidget);
      expect(find.text('Get Started Free'), findsWidgets);

      // 2. Click "Get Started Free" in the navbar
      final getStartedNavbarBtn = find.text('Get Started Free').first;
      await tester.tap(getStartedNavbarBtn);
      await tester.pumpAndSettle();

      // 3. User is on the MobileAction-style Login / Signup Page!
      expect(find.text("Let's get started"), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Zehra Türksoy'), findsOneWidget);

      // 4. Click 1-Click Guest Demo to login and proceed to Console
      await tester.tap(find.textContaining('Explore Console as Guest'));
      await tester.pumpAndSettle();

      // 5. User is inside the Console! Base features ready for operation
      expect(find.text('DISCOVERY SUITE'), findsOneWidget);
      expect(find.text('Opportunities'), findsOneWidget);
      expect(find.text('App Explorer'), findsOneWidget);

      // 6. User clicks "Front Page" in the header to return to the landing page
      final frontPageBtn = find.text('Front Page').first;
      await tester.tap(frontPageBtn);
      await tester.pumpAndSettle();

      // Back on the Front Page!
      expect(find.text('Next-Gen Mobile App Intelligence & Market Telemetry'), findsOneWidget);
    });
  });
}
