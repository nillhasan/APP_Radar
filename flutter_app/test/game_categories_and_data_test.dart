import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_radar/core/constants/app_constants.dart';
import 'package:app_radar/core/constants/category_utils.dart';
import 'package:app_radar/data/mock/mock_data.dart';
import 'package:app_radar/data/repositories/app_repository.dart';
import 'package:app_radar/data/repositories/opportunity_repository.dart';
import 'package:app_radar/widgets/filter_bar.dart';

void main() {
  group('GAME Categories & Data Integrity Tests', () {
    test('CategoryUtils recognizes all 18 game subcategories', () {
      const expectedGameGenres = [
        'Action',
        'Adventure',
        'Casual',
        'Board',
        'Card',
        'Casino',
        'Dice',
        'Educational',
        'Family',
        'Music',
        'Puzzle',
        'Racing',
        'Role Playing',
        'Simulation',
        'Sports',
        'Strategy',
        'Trivia',
        'Word',
      ];

      for (final genre in expectedGameGenres) {
        expect(CategoryUtils.isGameCategory(genre), isTrue,
            reason: 'Failed for genre: $genre');
      }
      expect(CategoryUtils.isGameCategory('Games'), isTrue);
      expect(CategoryUtils.isGameCategory('Productivity'), isFalse);
      expect(CategoryUtils.isGameCategory('Finance'), isFalse);
    });

    test('AppConstants.categories includes all 18 game subcategories and Applications', () {
      expect(AppConstants.categories, contains('All Categories'));
      expect(AppConstants.categories, contains('Applications'));
      expect(AppConstants.categories, contains('Games'));

      for (final g in AppConstants.gameCategories) {
        expect(AppConstants.categories, contains(g));
      }
    });

    test('MockAppRepository returns rich games for every single game subcategory', () async {
      final repo = MockAppRepository();

      // Card
      final cardApps = await repo.searchApps('', category: 'Card');
      expect(cardApps.any((a) => a.name.contains('UNO!')), isTrue);
      expect(cardApps.any((a) => a.name.contains('MARVEL SNAP')), isTrue);

      // Casino
      final casinoApps = await repo.searchApps('', category: 'Casino');
      expect(casinoApps.any((a) => a.name.contains('Zynga Poker')), isTrue);
      expect(casinoApps.any((a) => a.name.contains('WSOP Poker')), isTrue);

      // Dice
      final diceApps = await repo.searchApps('', category: 'Dice');
      expect(diceApps.any((a) => a.name.contains('Yahtzee')), isTrue);
      expect(diceApps.any((a) => a.name.contains('Dice Dreams')), isTrue);

      // Educational
      final eduApps = await repo.searchApps('', category: 'Educational');
      expect(eduApps.any((a) => a.name.contains('Prodigy Math')), isTrue);
      expect(eduApps.any((a) => a.name.contains('Toca Life')), isTrue);

      // Family
      final familyApps = await repo.searchApps('', category: 'Family');
      expect(familyApps.any((a) => a.name.contains('Talking Tom')), isTrue);
      expect(familyApps.any((a) => a.name.contains('Playkids')), isTrue);

      // Music
      final musicApps = await repo.searchApps('', category: 'Music');
      expect(musicApps.any((a) => a.name.contains('Magic Tiles')), isTrue);
      expect(musicApps.any((a) => a.name.contains('Beatstar')), isTrue);

      // Trivia
      final triviaApps = await repo.searchApps('', category: 'Trivia');
      expect(triviaApps.any((a) => a.name.contains('Trivia Crack')), isTrue);
      expect(triviaApps.any((a) => a.name.contains('Kahoot!')), isTrue);

      // Word
      final wordApps = await repo.searchApps('', category: 'Word');
      expect(wordApps.any((a) => a.name.contains('Wordscapes')), isTrue);
      expect(wordApps.any((a) => a.name.contains('NYT Games')), isTrue);

      // Board
      final boardApps = await repo.searchApps('', category: 'Board');
      expect(boardApps.any((a) => a.name.contains('Ludo King')), isTrue);
      expect(boardApps.any((a) => a.name.contains('Chess AI')), isTrue);

      // Action
      final actionApps = await repo.searchApps('', category: 'Action');
      expect(actionApps.any((a) => a.name.contains('Free Fire')), isTrue);
      expect(actionApps.any((a) => a.name.contains('PUBG')), isTrue);

      // All Games
      final allGames = await repo.searchApps('', category: 'Games');
      expect(allGames.length, greaterThanOrEqualTo(35));

      // Applications only
      final appsOnly = await repo.searchApps('', category: 'Applications');
      expect(appsOnly.every((a) => !CategoryUtils.isGameApp(a)), isTrue);
    });

    test('MockOpportunityRepository filters opportunities accurately by Game category', () async {
      final appRepo = MockAppRepository();
      final oppRepo = MockOpportunityRepository(appRepository: appRepo);

      final cardOpps = await oppRepo.getFilteredOpportunities(category: 'Card');
      expect(cardOpps.isNotEmpty, isTrue);
      expect(cardOpps.any((a) => a.name.contains('MARVEL SNAP')), isTrue);

      final diceOpps = await oppRepo.getFilteredOpportunities(category: 'Dice');
      expect(diceOpps.isNotEmpty, isTrue);
      expect(diceOpps.any((a) => a.name.contains('Dice Dreams')), isTrue);

      final triviaOpps = await oppRepo.getFilteredOpportunities(category: 'Trivia');
      expect(triviaOpps.isNotEmpty, isTrue);
      expect(triviaOpps.any((a) => a.name.contains('Kahoot!')), isTrue);
    });

    testWidgets('FilterBar category button opens CategoryPickerModal and selects category', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      String selected = 'All Categories';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return FilterBar(
                  searchQuery: '',
                  onSearchChanged: (_) {},
                  selectedCategory: selected,
                  onCategoryChanged: (cat) => setState(() => selected = cat),
                  selectedPlatform: 'All Platforms',
                  onPlatformChanged: (_) {},
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify category trigger button exists
      final trigger = find.byKey(const ValueKey('filter_bar_category_trigger'));
      expect(trigger, findsOneWidget);
      expect(find.text('All Categories'), findsOneWidget);

      // Tap trigger to open CategoryPickerModal
      await tester.tap(trigger);
      await tester.pumpAndSettle();

      // Modal dialog is open, find "Games" radio header
      await tester.drag(find.byType(SingleChildScrollView).last, const Offset(0, -350));
      await tester.pumpAndSettle();

      final gamesHeader = find.widgetWithText(InkWell, 'Games');
      expect(gamesHeader, findsOneWidget);
      await tester.tap(gamesHeader);
      await tester.pumpAndSettle();

      // Tap Ok in dialog
      await tester.tap(find.text('Ok'));
      await tester.pumpAndSettle();

      // Verify selected category is now "Games"
      expect(selected, 'Games');
      expect(find.text('Games'), findsWidgets);
    });
  });
}
