import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_radar/data/models/app_item.dart';
import 'package:app_radar/data/mock/mock_data.dart';
import 'package:app_radar/widgets/top_charts/top_charts_leaderboard.dart';
import 'package:app_radar/features/app_detail/widgets/competitor_avatar_stack.dart';
import 'package:app_radar/features/app_detail/widgets/regional_breakdown_bar.dart';
import 'package:app_radar/features/app_detail/app_detail_view.dart';

void main() {
  final testApps = MockData.apps;

  group('AppItem Model New Fields Tests', () {
    test('MockData apps include appUrl, price, rankDelta, regionalBreakdown and competitorIds', () {
      final app1 = testApps.firstWhere((a) => a.id == 'app_1');
      expect(app1.appUrl, isNotNull);
      expect(app1.price, equals(0.0));
      expect(app1.rankDelta, equals(2));
      expect(app1.regionalBreakdown, isNotNull);
      expect(app1.regionalBreakdown!['US'], equals(0.48));
      expect(app1.competitorIds, contains('app_3'));

      final paidApp = testApps.firstWhere((a) => a.price > 0);
      expect(paidApp.price, greaterThan(0.0));
      expect(paidApp.appUrl, isNotNull);
    });

    test('copyWith properly updates new fields', () {
      final app = testApps.first;
      final updated = app.copyWith(
        price: 7.99,
        rankDelta: -3,
        appUrl: 'https://example.com/app',
        competitorIds: ['rival_1', 'rival_2'],
      );

      expect(updated.price, equals(7.99));
      expect(updated.rankDelta, equals(-3));
      expect(updated.appUrl, equals('https://example.com/app'));
      expect(updated.competitorIds, equals(['rival_1', 'rival_2']));
    });
  });

  group('TopChartsLeaderboard Widget Tests', () {
    testWidgets('Renders 3 columns on desktop and triggers onOpenApp when app clicked', (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      AppItem? clickedApp;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TopChartsLeaderboard(
                apps: testApps,
                onOpenApp: (app) {
                  clickedApp = app;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Top Charts Leaderboard'), findsOneWidget);
      expect(find.text('Top Free'), findsOneWidget);
      expect(find.text('Top Paid'), findsOneWidget);
      expect(find.text('Top Grossing'), findsOneWidget);

      // Verify trend delta badges render
      expect(find.byIcon(Icons.arrow_drop_up), findsWidgets);

      // Tap on an app item
      final appNoteTaker = find.text('AI Note Taker');
      expect(appNoteTaker, findsWidgets);
      await tester.tap(appNoteTaker.first);
      await tester.pumpAndSettle();

      expect(clickedApp, isNotNull);
      expect(clickedApp!.name, equals('AI Note Taker'));
    });

    testWidgets('Dynamically updates regional revenue and headers when changing country', (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TopChartsLeaderboard(
                apps: testApps,
                onOpenApp: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Default is US
      expect(find.text('US STORE TELEMETRY'), findsOneWidget);

      // Tap Region Dropdown and select United Kingdom
      final ukOption = find.text('🇬🇧 United Kingdom');
      // In the dropdown button, current value is displayed
      final regionDropdown = find.text('🇺🇸 United States');
      expect(regionDropdown, findsOneWidget);
      await tester.tap(regionDropdown);
      await tester.pumpAndSettle();

      // Tap UK in popup menu
      expect(ukOption, findsWidgets);
      await tester.tap(ukOption.last);
      await tester.pumpAndSettle();

      // Verify UK telemetry is now active
      expect(find.text('UK STORE TELEMETRY'), findsOneWidget);
      expect(find.textContaining('United Kingdom 🇬🇧'), findsWidgets);
    });

    testWidgets('Renders responsive tab bar on mobile screens', (tester) async {
      tester.view.physicalSize = const Size(500, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TopChartsLeaderboard(
                apps: testApps,
                onOpenApp: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Top Charts Leaderboard'), findsOneWidget);
      // In mobile mode, tabs are visible
      expect(find.text('Top Free'), findsOneWidget);
      expect(find.text('Top Paid'), findsOneWidget);
      expect(find.text('Top Grossing'), findsOneWidget);

      // Switch to Top Paid tab
      await tester.tap(find.text('Top Paid'));
      await tester.pumpAndSettle();

      // Top Paid header shows
      expect(find.text('Top Paid Apps'), findsOneWidget);
    });
  });

  group('CompetitorAvatarStack Widget Tests', () {
    testWidgets('Renders competitor rivals and handles selection callback', (tester) async {
      final currentApp = testApps.firstWhere((a) => a.id == 'app_1');
      AppItem? selectedCompetitor;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompetitorAvatarStack(
              currentApp: currentApp,
              allApps: testApps,
              onSelectCompetitor: (rival) {
                selectedCompetitor = rival;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Direct Category Competitors'), findsOneWidget);
      expect(find.text('1-Click Switch'), findsOneWidget);

      // Verify rival apps appear (e.g. PDF AI Assistant or Flow State Focus)
      final rivalText = find.text('PDF AI Assistant');
      expect(rivalText, findsOneWidget);

      await tester.tap(rivalText);
      await tester.pumpAndSettle();

      expect(selectedCompetitor, isNotNull);
      expect(selectedCompetitor!.id, equals('app_3'));
    });
  });

  group('RegionalBreakdownBar Widget Tests', () {
    testWidgets('Renders multi-color bar and regional breakdown percentage chips', (tester) async {
      const breakdown = {
        'US': 0.48,
        'UK': 0.16,
        'DE': 0.12,
        'JP': 0.14,
        'Other': 0.10,
      };

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RegionalBreakdownBar(
              regionalBreakdown: breakdown,
              totalRevenue: 320000.0,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('30-Day Regional Revenue & Market Share'), findsOneWidget);
      expect(find.text('🇺🇸 US'), findsOneWidget);
      expect(find.text('48%'), findsOneWidget);
      expect(find.text('🇬🇧 UK'), findsOneWidget);
      expect(find.text('16%'), findsOneWidget);
      expect(find.text('🇩🇪 DE'), findsOneWidget);
      expect(find.text('🇯🇵 JP'), findsOneWidget);
    });
  });

  group('AppDetailView Store Link & Competitor Integration Tests', () {
    testWidgets('Displays Store Page button, Competitor Stack, and Regional Bar', (tester) async {
      tester.view.physicalSize = const Size(1200, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final app = testApps.firstWhere((a) => a.id == 'app_1');
      AppItem? navigatedRival;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppDetailView(
              app: app,
              allApps: testApps,
              onSelectCompetitor: (rival) {
                navigatedRival = rival;
              },
              onBack: () {},
              onBuildWithAI: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Store Page button is present
      expect(find.text('Store Page ↗'), findsOneWidget);

      // Competitor Avatar Stack is present
      expect(find.text('Direct Category Competitors'), findsOneWidget);

      // Regional Breakdown Bar is present
      expect(find.text('30-Day Regional Revenue & Market Share'), findsOneWidget);

      // Tapping competitor from detail view triggers onSelectCompetitor
      final rival = find.text('PDF AI Assistant');
      expect(rival, findsOneWidget);
      await tester.tap(rival);
      await tester.pumpAndSettle();

      expect(navigatedRival, isNotNull);
      expect(navigatedRival!.name, equals('PDF AI Assistant'));
    });
  });
}
