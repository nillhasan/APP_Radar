import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_radar/data/mock/mock_data.dart';
import 'package:app_radar/widgets/top_charts/top_charts_leaderboard.dart';
import 'package:app_radar/widgets/top_charts/category_picker_modal.dart';

void main() {
  final testApps = MockData.apps;

  group('CategoryPickerModal Widget Tests', () {
    testWidgets('Renders all sections, chips, and updates header on selection', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      String? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await CategoryPickerModal.show(context, initialCategory: 'All Categories');
                },
                child: const Text('Open Modal'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open the modal
      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      // Header shows Category | Selected: All Categories
      expect(find.textContaining('Category | '), findsOneWidget);
      expect(find.textContaining('All Categories'), findsWidgets);

      // Section titles
      expect(find.text('Applications'), findsOneWidget);
      expect(find.text('Games'), findsOneWidget);

      // Application chips present
      expect(find.text('Productivity'), findsOneWidget);
      expect(find.text('Finance'), findsOneWidget);
      expect(find.text('Social Networking'), findsOneWidget);

      // Game chips present
      expect(find.text('Action'), findsOneWidget);
      expect(find.text('Board'), findsOneWidget);
      expect(find.text('Puzzle'), findsOneWidget);
      expect(find.text('Strategy'), findsOneWidget);

      // Tap on 'Productivity' application chip
      await tester.tap(find.text('Productivity'));
      await tester.pumpAndSettle();

      // Header should reflect 'Productivity'
      expect(find.textContaining('Productivity'), findsWidgets);

      // Tap 'Ok' button
      await tester.tap(find.text('Ok'));
      await tester.pumpAndSettle();

      // Result should be 'Productivity'
      expect(result, equals('Productivity'));
    });

    testWidgets('Clicking Cancel dismisses dialog without selection change', (tester) async {
      String? result = 'Initial';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await CategoryPickerModal.show(context, initialCategory: 'All Categories');
                },
                child: const Text('Open Modal'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      // Select 'Finance'
      await tester.tap(find.text('Finance'));
      await tester.pumpAndSettle();

      // Tap 'Cancel'
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(result, isNull);
    });
  });

  group('TopCharts Leaderboard Regional & Games Data Tests', () {
    testWidgets('Includes Bangladesh and India in Region dropdown', (tester) async {
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

      // Open region dropdown
      final regionDropdown = find.text('🇺🇸 United States');
      expect(regionDropdown, findsOneWidget);
      await tester.tap(regionDropdown);
      await tester.pumpAndSettle();

      // Both Bangladesh and India are available
      expect(find.text('🇧🇩 Bangladesh'), findsWidgets);
      expect(find.text('🇮🇳 India'), findsWidgets);

      // Select Bangladesh
      await tester.tap(find.text('🇧🇩 Bangladesh').last);
      await tester.pumpAndSettle();

      expect(find.text('🇧🇩 Bangladesh'), findsWidgets);
    });

    testWidgets('Selecting Games shows populated Free, Paid, and Grossing game charts', (tester) async {
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

      // Tap Category trigger button to open CategoryPickerModal
      final categoryTrigger = find.text('All Categories');
      expect(categoryTrigger, findsWidgets);
      await tester.tap(categoryTrigger.first);
      await tester.pumpAndSettle();

      // Modal is open, scroll down inside modal to Games section
      await tester.drag(find.byType(SingleChildScrollView).last, const Offset(0, -350));
      await tester.pumpAndSettle();

      final gamesHeader = find.widgetWithText(InkWell, 'Games');
      expect(gamesHeader, findsOneWidget);
      await tester.tap(gamesHeader);
      await tester.pumpAndSettle();

      // Confirm with Ok
      await tester.tap(find.text('Ok'));
      await tester.pumpAndSettle();

      // Verify Games is selected in the category trigger
      expect(find.text('Games'), findsWidgets);

      // Verify multiple top games appear in charts (e.g. Subway Surfers, Roblox, Minecraft)
      expect(find.textContaining('Subway Surfers'), findsWidgets);
      expect(find.textContaining('Roblox'), findsWidgets);
      expect(find.textContaining('Minecraft'), findsWidgets);

      // Change region to Bangladesh to verify regional game champions
      await tester.tap(find.text('🇺🇸 United States'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('🇧🇩 Bangladesh').last);
      await tester.pumpAndSettle();

      expect(find.textContaining('Ludo King'), findsWidgets);
      expect(find.textContaining('Free Fire'), findsWidgets);
    });
  });
}
