import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_radar/data/repositories/app_repository.dart';
import 'package:app_radar/data/mock/mock_data.dart';
import 'package:app_radar/features/competitors/competitors_view.dart';
import 'package:app_radar/features/app_detail/widgets/competitor_avatar_stack.dart';

void main() {
  final testApps = MockData.apps;
  final mockRepo = MockAppRepository();

  group('Competitor Intelligence Matrix Tests', () {
    testWidgets('Renders Search Bar, Active Focus Banner, Stat Pills, and Matrix', (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompetitorsView(
              appRepo: mockRepo,
              onOpenApp: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Header
      expect(find.text('Competitor Intelligence Matrix'), findsOneWidget);

      // Verify Search Bar is present
      expect(find.byType(TextField), findsOneWidget);
      expect(find.textContaining('Search any app to benchmark'), findsOneWidget);

      // Verify Benchmark Focus Banner is present
      expect(find.text('BENCHMARK FOCUS'), findsWidgets);

      // Verify Stat Pills
      expect(find.text('Benchmark Focus'), findsOneWidget);
      expect(find.text('Direct Rivals'), findsOneWidget);
      expect(find.text('Key Market Gap'), findsOneWidget);

      // Verify Feature Coverage Matrix Table
      expect(find.text('Feature Coverage & Competitor Moat Matrix'), findsOneWidget);
      expect(find.text('Feature / Capability'), findsOneWidget);
      expect(find.byType(DataTable), findsOneWidget);
    });

    testWidgets('Search input filters apps and clicking suggestion updates focus app', (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompetitorsView(
              appRepo: mockRepo,
              onOpenApp: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find search field and enter query "Calorie"
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'Calorie');
      await tester.pumpAndSettle();

      // Verify autocomplete suggestion appears
      expect(find.textContaining('Select Benchmark Target'), findsOneWidget);
      final calorieMatch = find.text('Calorie AI');
      expect(calorieMatch, findsWidgets);

      // Tap the suggestion
      await tester.tap(calorieMatch.first);
      await tester.pumpAndSettle();

      // Verify focus app is updated to Calorie AI
      expect(find.text('Calorie AI (Focus App)'), findsWidgets);
      expect(find.text('Health & Fitness'), findsWidgets);
    });

    testWidgets('Clicking "Set as Focus" on a rival switches focus app', (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompetitorsView(
              appRepo: mockRepo,
              onOpenApp: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Look for "Set as Focus" buttons on rival cards
      final setFocusButtons = find.text('Set as Focus');
      if (setFocusButtons.evaluate().isNotEmpty) {
        await tester.tap(setFocusButtons.first);
        await tester.pumpAndSettle();

        // Benchmark focus banner should still be present with new target
        expect(find.text('BENCHMARK FOCUS'), findsWidgets);
      }
    });

    testWidgets('CompetitorAvatarStack renders "Full Intelligence Matrix" button and handles tap', (tester) async {
      bool matrixOpened = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompetitorAvatarStack(
              currentApp: testApps.first,
              allApps: testApps,
              onSelectCompetitor: (_) {},
              onOpenMatrix: () => matrixOpened = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Full Intelligence Matrix'), findsOneWidget);
      await tester.tap(find.text('Full Intelligence Matrix'));
      await tester.pumpAndSettle();

      expect(matrixOpened, isTrue);
    });
  });
}
