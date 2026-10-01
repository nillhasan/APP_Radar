import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_radar/data/repositories/app_repository.dart';
import 'package:app_radar/data/repositories/opportunity_repository.dart';
import 'package:app_radar/data/repositories/market_trend_repository.dart';
import 'package:app_radar/data/repositories/report_repository.dart';
import 'package:app_radar/data/repositories/watchlist_repository.dart';
import 'package:app_radar/services/ai/ai_service.dart';
import 'package:app_radar/services/auth/auth_service.dart';
import 'package:app_radar/services/subscription/subscription_service.dart';
import 'package:app_radar/features/landing/landing_page_view.dart';
import 'package:app_radar/widgets/landing/platform_screenshots_carousel.dart';
import 'package:app_radar/widgets/app_shell.dart';

void main() {
  group('LandingPageView Widget Tests (MobileAction Style)', () {
    late MockAppRepository appRepo;
    late MockOpportunityRepository oppRepo;
    late AuthService authService;
    late SubscriptionService subService;

    setUp(() {
      appRepo = MockAppRepository();
      oppRepo = MockOpportunityRepository(appRepository: appRepo);
      authService = AuthService();
      subService = SubscriptionService(authService: authService);
    });

    testWidgets('Renders all MobileAction-style sections on Desktop and carousel', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      bool getStartedCalled = false;

      await tester.pumpWidget(MaterialApp(
        home: LandingPageView(
          appRepo: appRepo,
          oppRepo: oppRepo,
          authService: authService,
          subscriptionService: subService,
          onLaunchConsole: () {},
          onGetStarted: () => getStartedCalled = true,
          onOpenAuthModal: () {},
          onOpenPricingModal: () {},
        ),
      ));
      await tester.pumpAndSettle();

      // Navbar
      expect(find.text('AppRadar'), findsWidgets);
      expect(find.text('Find. Analyze. Build.'), findsOneWidget);
      expect(find.text('Platform'), findsOneWidget);
      expect(find.text('Pricing'), findsWidgets);

      // Hero
      expect(find.text('GLOBAL STORE TELEMETRY & APP INTELLIGENCE'), findsOneWidget);
      expect(find.text('Next-Gen Mobile App Intelligence & Market Telemetry'), findsOneWidget);
      expect(find.text('Search for app or publisher...'), findsOneWidget);

      // Interactive Moving Screenshots Carousel (Showcase)
      expect(find.text('INTERACTIVE APPRADAR PLATFORM SHOWCASE'), findsOneWidget);
      expect(find.text('Explore Inside the AppRadar Intelligence Console'), findsOneWidget);

      // Unauthenticated visitor must NOT see direct "Launch Console" bypass
      expect(find.text('Launch Console'), findsNothing);

      // Clicking Get Started Free triggers auth flow callback
      final getStartedBtn = find.text('Get Started Free').first;
      await tester.tap(getStartedBtn);
      await tester.pumpAndSettle();

      expect(getStartedCalled, true);
    });

    testWidgets('Switching product tabs displays corresponding feature preview', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MaterialApp(
        home: LandingPageView(
          appRepo: appRepo,
          oppRepo: oppRepo,
          authService: authService,
          subscriptionService: subService,
          onLaunchConsole: () {},
          onOpenAuthModal: () {},
          onOpenPricingModal: () {},
        ),
      ));
      await tester.pumpAndSettle();

      // Scroll down to product suite tabs below sticky navbar
      final oppTab = find.text('Opportunity Radar').last;
      await tester.scrollUntilVisible(oppTab, 300, scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      // Nudge down so it's not obscured by the 72px sticky navbar
      await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, 120));
      await tester.pumpAndSettle();
      await tester.tap(oppTab);
      await tester.pumpAndSettle();

      expect(find.text('AI Opportunity Radar & Gap Discovery'), findsOneWidget);
      expect(find.text('94/100'), findsOneWidget);

      // Click Instant Teardown tab in product suite
      final teardownTab = find.text('Instant Teardown').last;
      await tester.tap(teardownTab);
      await tester.pumpAndSettle();

      expect(find.text('Instant Store URL Reverse-Engineering'), findsOneWidget);

      // Click Build With AI tab in product suite
      final aiTab = find.text('Build With AI').last;
      await tester.tap(aiTab);
      await tester.pumpAndSettle();

      expect(find.text('Build With AI: Idea to App Store in 14 Days'), findsOneWidget);
    });

    testWidgets('AppShell gates console: Get Started -> Login -> Console -> Front Page', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final trendRepo = MockMarketTrendRepository();
      final reportRepo = MockReportRepository();
      final watchlistRepo = MockWatchlistRepository(appRepository: appRepo);
      final aiService = MockAIService();

      await tester.pumpWidget(MaterialApp(
        home: AppShell(
          appRepo: appRepo,
          oppRepo: oppRepo,
          trendRepo: trendRepo,
          reportRepo: reportRepo,
          watchlistRepo: watchlistRepo,
          aiService: aiService,
          authService: authService,
          subscriptionService: subService,
          initialShowLandingPage: true, // starts on Landing Page
        ),
      ));
      await tester.pumpAndSettle();

      // Starts on Front Page
      expect(find.text('Next-Gen Mobile App Intelligence & Market Telemetry'), findsOneWidget);

      // Unauthenticated visitor clicks Get Started Free
      final getStartedNavbarBtn = find.text('Get Started Free').first;
      await tester.tap(getStartedNavbarBtn);
      await tester.pumpAndSettle();

      // Routed to MobileAction Auth Page (no direct backdoor)
      expect(find.text("Let's get started"), findsOneWidget);

      // Log in as guest demo
      await tester.tap(find.textContaining('Explore Console as Guest'));
      await tester.pumpAndSettle();

      // Now successfully inside the Console! (sidebar has DISCOVERY SUITE)
      expect(find.text('DISCOVERY SUITE'), findsOneWidget);
      expect(find.text('Opportunities'), findsOneWidget);
      expect(find.text('App Explorer'), findsOneWidget);

      // Click Front Page button in AppBar to switch back
      final frontPageBtn = find.text('Front Page').first;
      await tester.tap(frontPageBtn);
      await tester.pumpAndSettle();

      // Back on Front Page! And button remains Get Started Free
      expect(find.text('Next-Gen Mobile App Intelligence & Market Telemetry'), findsOneWidget);
      expect(find.text('Get Started Free'), findsWidgets);

      // Clicking Get Started Free takes authenticated user directly to console
      await tester.tap(find.widgetWithText(ElevatedButton, 'Get Started Free').first);
      await tester.pumpAndSettle();
      expect(find.text('DISCOVERY SUITE'), findsOneWidget);
    });

    testWidgets('PlatformScreenshotsCarousel advances slides and triggers onGetStarted', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      bool carouselGetStartedCalled = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PlatformScreenshotsCarousel(
              onGetStarted: () => carouselGetStartedCalled = true,
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Initial Slide 0: Store Telemetry
      expect(find.text('LIVE APPLE & GOOGLE PLAY TELEMETRY'), findsOneWidget);
      expect(find.text('Real-Time Store Telemetry & Rankings Matrix'), findsOneWidget);
      expect(find.text('appradar.ai/console/dashboard/live-store-matrix'), findsOneWidget);

      // Tap category chip for "Opportunity Radar"
      final oppChip = find.text('Opportunity Radar');
      await tester.tap(oppChip);
      await tester.pumpAndSettle();

      // Slide 1: Opportunity Radar
      expect(find.text('AI OPPORTUNITY ENGINE (0-100)'), findsOneWidget);
      expect(find.text('AI Opportunity Radar & Gap Discovery'), findsOneWidget);

      // Tap category chip for "Competitor Matrix"
      final compChip = find.text('Competitor Matrix');
      await tester.tap(compChip);
      await tester.pumpAndSettle();

      expect(find.text('SIDE-BY-SIDE BENCHMARK WAR ROOM'), findsOneWidget);
      expect(find.text('Competitor Intelligence Matrix & Strategy Benchmarks'), findsOneWidget);

      // Tap "Unlock in Console" CTA inside screenshot card
      final unlockBtn = find.text('Unlock in Console');
      expect(unlockBtn, findsOneWidget);
      await tester.tap(unlockBtn);
      await tester.pumpAndSettle();

      expect(carouselGetStartedCalled, isTrue);
    });

    testWidgets('Hero section retains Get Started Free and navigates to Console when authenticated', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      bool launchConsoleCalled = false;
      authService.signInDemoUser(email: 'founder@appradar.ai');

      await tester.pumpWidget(MaterialApp(
        home: LandingPageView(
          appRepo: appRepo,
          oppRepo: oppRepo,
          authService: authService,
          subscriptionService: subService,
          onLaunchConsole: () => launchConsoleCalled = true,
          onOpenAuthModal: () {},
          onOpenPricingModal: () {},
        ),
      ));
      await tester.pumpAndSettle();

      // When authenticated, Hero CTA still says "Get Started Free"
      final getStartedBtn = find.widgetWithText(ElevatedButton, 'Get Started Free');
      expect(getStartedBtn, findsWidgets);

      await tester.tap(getStartedBtn.first);
      await tester.pumpAndSettle();

      expect(launchConsoleCalled, isTrue);
    });

    testWidgets('AppShell: Hero Get Started button leads to Login, then Console, and returns directly to Console when authenticated', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final trendRepo = MockMarketTrendRepository();
      final reportRepo = MockReportRepository();
      final watchlistRepo = MockWatchlistRepository(appRepository: appRepo);
      final aiService = MockAIService();

      await tester.pumpWidget(MaterialApp(
        home: AppShell(
          appRepo: appRepo,
          oppRepo: oppRepo,
          trendRepo: trendRepo,
          reportRepo: reportRepo,
          watchlistRepo: watchlistRepo,
          aiService: aiService,
          authService: authService,
          subscriptionService: subService,
          initialShowLandingPage: true,
        ),
      ));
      await tester.pumpAndSettle();

      // 1. Unauthenticated: Hero CTA is "Get Started Free"
      final heroGetStartedBtn = find.widgetWithText(ElevatedButton, 'Get Started Free').first;
      expect(heroGetStartedBtn, findsOneWidget);

      // 2. Click hero "Get Started Free"
      await tester.tap(heroGetStartedBtn);
      await tester.pumpAndSettle();

      // 3. User is on Auth Page
      expect(find.text("Let's get started"), findsOneWidget);

      // 4. Log in
      await tester.tap(find.textContaining('Explore Console as Guest'));
      await tester.pumpAndSettle();

      // 5. User is inside Console!
      expect(find.text('DISCOVERY SUITE'), findsOneWidget);

      // 6. Navigate back to Front Page
      final frontPageBtn = find.text('Front Page').first;
      await tester.tap(frontPageBtn);
      await tester.pumpAndSettle();

      // 7. On Front Page, Hero CTA still says "Get Started Free" and directly enters Console
      final heroGetStartedBtn2 = find.widgetWithText(ElevatedButton, 'Get Started Free').first;
      expect(heroGetStartedBtn2, findsOneWidget);

      await tester.tap(heroGetStartedBtn2);
      await tester.pumpAndSettle();

      // 8. Directly back in Console without showing Auth Page!
      expect(find.text('DISCOVERY SUITE'), findsOneWidget);
    });
  });
}

