import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_radar/data/mock/mock_data.dart';
import 'package:app_radar/data/models/app_item.dart';
import 'package:app_radar/data/repositories/app_repository.dart';
import 'package:app_radar/data/repositories/opportunity_repository.dart';
import 'package:app_radar/features/explorer/app_explorer_view.dart';
import 'package:app_radar/features/opportunities/opportunities_view.dart';
import 'package:app_radar/services/ai/gemini_ai_service.dart';
import 'package:app_radar/services/export/file_export_service.dart';
import 'package:app_radar/services/subscription/subscription_service.dart';
import 'package:app_radar/widgets/pricing/pricing_modal.dart';

void main() {
  group('Part 2 Commercial Features: FileExportService Tests', () {
    const exportService = FileExportService();
    final sampleApps = MockData.apps.take(3).toList();

    test('generateAppsListCsv produces valid CSV headers and data rows', () {
      final csv = exportService.generateAppsListCsv(sampleApps);

      expect(csv, contains('Rank,App Name,Category,Platform,Rating,Reviews,Downloads/Mo,Est. Revenue/Mo,Growth Rate %,Opportunity Score,Developer,Monetization,URL'));
      for (final app in sampleApps) {
        expect(csv, contains(app.name));
        expect(csv, contains(app.category));
        expect(csv, contains(app.rating.toString()));
      }
    });

    test('generateNotionMarkdownTable produces markdown table with headers and summary', () {
      final md = exportService.generateNotionMarkdownTable(sampleApps, title: 'Test Export');

      expect(md, contains('# 🚀 Test Export'));
      expect(md, contains('| App | Category | Platform | Rating | Est. Downloads | Est. Revenue | Growth | Opportunity |'));
      expect(md, contains('| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |'));
      for (final app in sampleApps) {
        expect(md, contains(app.name));
        expect(md, contains('${app.opportunityScore}/100'));
      }
    });
  });

  group('Part 2 Commercial Features: AppExplorerView Widget Tests', () {
    testWidgets('Renders URL Teardown card, preset chips, and export buttons', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final appRepo = MockAppRepository();
      AppItem? selectedApp;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppExplorerView(
              appRepo: appRepo,
              onOpenApp: (app) => selectedApp = app,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Verify URL Teardown card and inputs
      expect(find.text('Instant Store URL Teardown & Live Gap Analysis'), findsOneWidget);
      expect(find.text('Teardown App'), findsOneWidget);
      expect(find.text('📱 Duolingo'), findsOneWidget);
      expect(find.text('🧘 Headspace'), findsOneWidget);
      expect(find.text('📝 Notion'), findsOneWidget);
      expect(find.text('💰 Splitwise'), findsOneWidget);

      // 2. Verify Export buttons
      expect(find.text('Export CSV'), findsOneWidget);
      expect(find.text('Copy Notion Table'), findsOneWidget);

      // 3. Tap preset chip to trigger instant teardown
      await tester.tap(find.text('📱 Duolingo'));
      await tester.pumpAndSettle();

      expect(selectedApp, isNotNull);
      expect(selectedApp!.name, contains('Duolingo'));
      expect(selectedApp!.category, 'Education');
      expect(selectedApp!.opportunityScore, isPositive);
    });

    testWidgets('Parses custom Google Play store link and opens teardown', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final appRepo = MockAppRepository();
      AppItem? selectedApp;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppExplorerView(
              appRepo: appRepo,
              onOpenApp: (app) => selectedApp = app,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter custom package URL
      final textField = find.byType(TextField).first;
      await tester.enterText(textField, 'https://play.google.com/store/apps/details?id=com.spotify.music');
      await tester.tap(find.text('Teardown App'));
      await tester.pumpAndSettle();

      expect(selectedApp, isNotNull);
      expect(selectedApp!.name, contains('Music'));
      expect(selectedApp!.platform, 'Google Play Store');
    });

    testWidgets('Free account is limited to 1 instant store URL teardown and opens PricingModal on second', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final appRepo = MockAppRepository();
      final sub = SubscriptionService();
      sub.downgradeToFree();
      addTearDown(() => sub.resetUrlTeardowns());

      AppItem? selectedApp;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppExplorerView(
              appRepo: appRepo,
              subscriptionService: sub,
              onOpenApp: (app) => selectedApp = app,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify quota badge initially shows 1 remaining
      expect(find.text('FREE PLAN: 1 TEARDOWN REMAINING'), findsOneWidget);

      // 1. Perform 1st teardown (Duolingo) -> Allowed!
      await tester.tap(find.text('📱 Duolingo'));
      await tester.pumpAndSettle();

      expect(selectedApp, isNotNull);
      expect(selectedApp!.name, contains('Duolingo'));
      expect(sub.remainingFreeUrlTeardowns, 0);

      // Verify quota badge now shows limit reached
      expect(find.text('FREE LIMIT (1/1 USED) — UPGRADE'), findsOneWidget);

      // 2. Try to perform 2nd teardown on a different app (Headspace) -> Blocked!
      selectedApp = null;
      await tester.tap(find.text('🧘 Headspace'));
      await tester.pumpAndSettle();

      // Selected app should not change
      expect(selectedApp, isNull);

      // PricingModal paywall must be opened
      expect(find.byType(PricingModal), findsOneWidget);
      expect(find.text('Instant Store URL Teardown (Free Limit: 1 App)'), findsOneWidget);
    });
  });

  group('Part 2 Commercial Features: OpportunitiesView Export Tests', () {
    testWidgets('Renders Export CSV and Copy Notion Table buttons on OpportunitiesView', (tester) async {
      final oppRepo = MockOpportunityRepository(appRepository: MockAppRepository());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OpportunitiesView(
              oppRepo: oppRepo,
              onOpenApp: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Export CSV'), findsOneWidget);
      expect(find.text('Copy Notion Table'), findsOneWidget);
      expect(find.textContaining('High-Potential Opportunities'), findsOneWidget);
    });
  });

  group('Part 2 Commercial Features: GeminiAIService Tests', () {
    test('Falls back gracefully to MockAIService when no key is set', () async {
      final service = GeminiAIService(apiKey: '');
      final app = MockData.apps.first;
      final blueprint = await service.generateBlueprint(app);

      expect(blueprint, isNotNull);
      expect(blueprint.appName, contains(app.name));
      expect(blueprint.coreMvpFeatures, isNotEmpty);
      expect(blueprint.roadmap, isNotEmpty);
    });
  });
}
