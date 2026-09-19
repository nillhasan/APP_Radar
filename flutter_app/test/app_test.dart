import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_radar/data/repositories/app_repository.dart';
import 'package:app_radar/data/repositories/opportunity_repository.dart';
import 'package:app_radar/services/ai/ai_service.dart';
import 'package:app_radar/main.dart';

void main() {
  group('AppRadar Repository & AI Tests', () {
    test('MockAppRepository returns seeded apps and supports search', () async {
      final repo = MockAppRepository();
      final allApps = await repo.getAllApps();
      expect(allApps.isNotEmpty, true);
      expect(allApps.length, greaterThanOrEqualTo(5));

      final noteApp = await repo.searchApps('Note Taker');
      expect(noteApp.length, 1);
      expect(noteApp.first.name, 'AI Note Taker');
      expect(noteApp.first.opportunityScore, greaterThan(75));
    });

    test('OpportunityRepository returns sorted top opportunities', () async {
      final appRepo = MockAppRepository();
      final oppRepo = MockOpportunityRepository(appRepository: appRepo);

      final top = await oppRepo.getTopOpportunities(limit: 3);
      expect(top.length, 3);
      expect(top[0].opportunityScore >= top[1].opportunityScore, true);
      expect(top[1].opportunityScore >= top[2].opportunityScore, true);
    });

    test('AIService generates complete 14-section BuildBlueprint', () async {
      final appRepo = MockAppRepository();
      final apps = await appRepo.getAllApps();
      final aiService = MockAIService();

      final blueprint = await aiService.generateBlueprint(apps.first);
      expect(blueprint.appName.isNotEmpty, true);
      expect(blueprint.coreMvpFeatures.isNotEmpty, true);
      expect(blueprint.screens.isNotEmpty, true);
      expect(blueprint.databaseDesign.contains('CREATE TABLE'), true);
      expect(blueprint.roadmap.length, 5);
    });
  });

  group('AppRadar UI Smoke Test', () {
    testWidgets('AppRadarApp renders dashboard and branding on Desktop', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const AppRadarApp());
      await tester.pumpAndSettle();

      expect(find.text('AppRadar'), findsWidgets);
      expect(find.text('Find. Analyze. Build.'), findsOneWidget);
      expect(find.text('Apps Analyzed'), findsOneWidget);
      expect(find.text('New Opportunities'), findsOneWidget);
      expect(find.text('High Potential'), findsOneWidget);
      expect(find.text('Markets Tracked'), findsOneWidget);
    });

    testWidgets('AppRadarApp renders on Mobile without errors', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const AppRadarApp());
      await tester.pumpAndSettle();

      expect(find.text('AppRadar'), findsWidgets);
      expect(find.byIcon(Icons.menu), findsOneWidget);
    });
  });
}
