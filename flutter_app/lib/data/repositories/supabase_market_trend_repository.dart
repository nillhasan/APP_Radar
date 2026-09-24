import '../models/app_item.dart';
import '../models/market_trend.dart';
import '../mock/mock_data.dart';
import 'app_repository.dart';
import 'market_trend_repository.dart';

class SupabaseMarketTrendRepository implements MarketTrendRepository {
  final AppRepository appRepository;
  final MarketTrendRepository fallbackRepo;

  final Map<String, List<CategoryTrend>> _cachedTrends = {};
  DateTime? _lastFetchTime;
  static const Duration _cacheTtl = Duration(minutes: 5);

  SupabaseMarketTrendRepository({
    required this.appRepository,
    required this.fallbackRepo,
  });

  @override
  Future<List<CategoryTrend>> getCategoryTrends({String timeframe = '30 Days'}) async {
    if (_cachedTrends.containsKey(timeframe) && _lastFetchTime != null) {
      if (DateTime.now().difference(_lastFetchTime!) < _cacheTtl) {
        return _cachedTrends[timeframe]!;
      }
    }

    try {
      final rawApps = await appRepository.getAllApps();
      final seenIds = <String>{};
      final allApps = <AppItem>[];
      for (final a in rawApps) {
        if (seenIds.add(a.id)) allApps.add(a);
      }
      for (final a in MockData.apps) {
        if (seenIds.add(a.id)) allApps.add(a);
      }

      if (allApps.isEmpty) {
        final fallback = await fallbackRepo.getCategoryTrends(timeframe: timeframe);
        _cachedTrends[timeframe] = fallback;
        _lastFetchTime = DateTime.now();
        return fallback;
      }

      // Group apps by category
      final Map<String, List<AppItem>> categoryMap = {};
      for (final app in allApps) {
        final cat = app.category.trim().isNotEmpty ? app.category.trim() : 'Productivity';
        categoryMap.putIfAbsent(cat, () => []).add(app);
      }

      final List<CategoryTrend> trends = [];
      categoryMap.forEach((category, apps) {
        final totalApps = apps.length;
        final avgScore = apps.map((a) => a.opportunityScore).reduce((a, b) => a + b) / totalApps;

        // Find top breakout app in category by opportunity score
        apps.sort((a, b) => b.opportunityScore.compareTo(a.opportunityScore));
        final topApp = apps.first.name;

        final growthRate = _calculateCategoryGrowth(category, avgScore, timeframe);
        final sparkline = _generateCategorySparkline(growthRate, avgScore);

        trends.add(CategoryTrend(
          category: category,
          growthRate: growthRate,
          totalApps: totalApps,
          avgOpportunityScore: double.parse(avgScore.toStringAsFixed(1)),
          topApp: topApp,
          weeklySparkline: sparkline,
        ));
      });

      // Sort by highest growth rate
      trends.sort((a, b) => b.growthRate.compareTo(a.growthRate));
      final result = trends.isNotEmpty ? trends : await fallbackRepo.getCategoryTrends(timeframe: timeframe);
      _cachedTrends[timeframe] = result;
      _lastFetchTime = DateTime.now();
      return result;
    } catch (_) {
      final fallback = await fallbackRepo.getCategoryTrends(timeframe: timeframe);
      _cachedTrends[timeframe] = fallback;
      _lastFetchTime = DateTime.now();
      return fallback;
    }
  }

  double _calculateCategoryGrowth(String category, double avgScore, String timeframe) {
    double timeMultiplier;
    switch (timeframe) {
      case '7 Days':
        timeMultiplier = 0.28;
        break;
      case '90 Days':
        timeMultiplier = 2.4;
        break;
      case '1 Year':
        timeMultiplier = 4.8;
        break;
      case '30 Days':
      default:
        timeMultiplier = 1.0;
        break;
    }

    final catLower = category.toLowerCase();
    double baseRate;
    if (catLower.contains('ai') || catLower.contains('machine')) {
      baseRate = 120.0;
    } else if (catLower.contains('game')) {
      baseRate = 95.0;
    } else if (catLower.contains('utilit') || catLower.contains('tool')) {
      baseRate = 88.0;
    } else if (catLower.contains('productiv')) {
      baseRate = 84.0;
    } else if (catLower.contains('health') || catLower.contains('fitness')) {
      baseRate = 74.0;
    } else if (catLower.contains('photo') || catLower.contains('video')) {
      baseRate = 72.0;
    } else if (catLower.contains('business')) {
      baseRate = 68.0;
    } else if (catLower.contains('educat')) {
      baseRate = 65.0;
    } else if (catLower.contains('lifestyle')) {
      baseRate = 58.0;
    } else if (catLower.contains('entertain')) {
      baseRate = 54.0;
    } else if (catLower.contains('financ')) {
      baseRate = 50.0;
    } else if (catLower.contains('medic')) {
      baseRate = 46.0;
    } else {
      baseRate = (avgScore * 0.95).clamp(40.0, 90.0);
    }

    final scoreMod = (avgScore - 70.0) * 0.4;
    final total = (baseRate + scoreMod) * timeMultiplier;
    return double.parse(total.clamp(6.0, 750.0).toStringAsFixed(1));
  }

  List<double> _generateCategorySparkline(double growthRate, double avgScore) {
    final randSeed = (growthRate * 10).toInt();
    final points = <double>[];
    double current = (growthRate * 0.45).clamp(10.0, 500.0);
    for (int i = 0; i < 7; i++) {
      final step = ((randSeed + i * 17) % 15) - 3;
      current = (current + (growthRate * 0.08) + step).clamp(5.0, 800.0);
      points.add(double.parse(current.toStringAsFixed(1)));
    }
    return points;
  }

  @override
  Future<List<EmergingKeyword>> getEmergingKeywords() async {
    return await fallbackRepo.getEmergingKeywords();
  }
}
