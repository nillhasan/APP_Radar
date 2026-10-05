import '../../data/models/app_item.dart';
import 'app_constants.dart';

/// Centralized category utilities to ensure uniform, accurate category matching
/// across all screens, repositories, and filters in AppRadar.
class CategoryUtils {
  static const List<String> gameCategories = AppConstants.gameCategories;
  static const List<String> applicationCategories = AppConstants.applicationCategories;

  /// Returns true if the category string represents a game category or 'Games'.
  static bool isGameCategory(String category) {
    final lower = category.trim().toLowerCase();
    if (lower == 'games' || lower == 'game') return true;
    return gameCategories.any((g) => g.toLowerCase() == lower);
  }

  /// Returns true if the category string represents an application category or 'Applications'.
  static bool isApplicationCategory(String category) {
    final lower = category.trim().toLowerCase();
    if (lower == 'applications' || lower == 'application' || lower == 'apps' || lower == 'app') return true;
    return applicationCategories.any((a) => a.toLowerCase() == lower);
  }

  /// Determines whether an app is classified as a Game.
  static bool isGameApp(AppItem app) {
    if (app.id.startsWith('app_game_')) return true;
    final catLower = app.category.trim().toLowerCase();
    if (catLower == 'games' || catLower == 'game') return true;
    if (app.subcategory != null && isGameCategory(app.subcategory!)) return true;
    if (isGameCategory(catLower)) return true;
    if (app.notes.toLowerCase().contains('game')) return true;
    return false;
  }

  /// Universal matcher for app item vs selected category
  static bool matchesCategory(AppItem app, String? selectedCategory) {
    if (selectedCategory == null ||
        selectedCategory.isEmpty ||
        selectedCategory == 'All Categories' ||
        selectedCategory == 'All') {
      return true;
    }

    final selectedLower = selectedCategory.trim().toLowerCase();
    final isGame = isGameApp(app);

    // If 'Games' is selected
    if (selectedLower == 'games' || selectedLower == 'game') {
      return isGame;
    }

    // If 'Applications' is selected
    if (selectedLower == 'applications' || selectedLower == 'application') {
      return !isGame;
    }

    // If selected is a game category (e.g. Action, Board, Card, Casino, Dice, etc.)
    if (isGameCategory(selectedCategory)) {
      if (!isGame) return false;
      if (app.subcategory != null && app.subcategory!.trim().toLowerCase() == selectedLower) {
        return true;
      }
      final catLower = app.category.toLowerCase();
      if (catLower == selectedLower || catLower.contains(selectedLower) || selectedLower.contains(catLower)) {
        return true;
      }
      final notesLower = app.notes.toLowerCase();
      if (notesLower.contains(selectedLower)) return true;
      final descLower = app.description.toLowerCase();
      if (descLower.contains(selectedLower)) return true;
      final whatLower = app.whatItDoes.toLowerCase();
      if (whatLower.contains(selectedLower)) return true;
      final coreMatch = app.coreFeatures.any((f) => f.toLowerCase().contains(selectedLower));
      if (coreMatch) return true;
      return false;
    }

    // If selected is an application category (e.g. Productivity, Finance, Education, etc.)
    if (isGame && !isGameCategory(selectedCategory)) {
      // Don't show games in app-only categories unless explicitly matching
      final catLower = app.category.toLowerCase();
      if (!catLower.contains(selectedLower)) {
        return false;
      }
    }

    final appCatLower = app.category.trim().toLowerCase();
    if (appCatLower == selectedLower ||
        appCatLower.contains(selectedLower) ||
        selectedLower.contains(appCatLower)) {
      return true;
    }

    if (app.subcategory != null && app.subcategory!.trim().toLowerCase() == selectedLower) {
      return true;
    }

    return app.coreFeatures.any((f) => f.toLowerCase().contains(selectedLower)) ||
        app.description.toLowerCase().contains(selectedLower) ||
        app.whatItDoes.toLowerCase().contains(selectedLower);
  }

  /// Matcher for market trend strings
  static bool matchesTrendCategory(String trendCategory, String selectedCategory) {
    if (selectedCategory == 'All Categories' || selectedCategory == 'All') return true;
    final tLower = trendCategory.trim().toLowerCase();
    final sLower = selectedCategory.trim().toLowerCase();
    if (sLower == 'games' || sLower == 'game') {
      return isGameCategory(trendCategory);
    }
    if (sLower == 'applications' || sLower == 'application') {
      return !isGameCategory(trendCategory);
    }
    return tLower == sLower || tLower.contains(sLower) || sLower.contains(tLower);
  }
}
