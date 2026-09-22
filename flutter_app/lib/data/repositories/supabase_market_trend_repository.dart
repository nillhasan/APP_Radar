import '../models/app_item.dart';
import '../models/market_trend.dart';
import 'app_repository.dart';
import 'market_trend_repository.dart';

class SupabaseMarketTrendRepository implements MarketTrendRepository {
  final AppRepository appRepository;
  final MarketTrendRepository fallbackRepo;

  List<CategoryTrend>? _cachedTrends;
  DateTime? _lastFetchTime;
  static const Duration _cacheTtl = Duration(minutes: 5);

  SupabaseMarketTrendRepository({
    required this.appRepository,
    required this.fallbackRepo,
  });

  @override
  Future<List<CategoryTrend>> getCategoryTrends({String timeframe = '30 Days'}) async {
    if (_cachedTrends != null && _lastFetchTime != null) {
      if (DateTime.now().difference(_lastFetchTime!) < _cacheTtl) {
        return _cachedTrends!;
      }
    }

    try {
      final allApps = await appRepository.getAllApps();
      if (allApps.isEmpty) {
        final fallback = await fallbackRepo.getCategoryTrends(timeframe: timeframe);
        _cachedTrends = fallback;
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
        final avgGrowth = apps.map((a) => a.growthRate).reduce((a, b) => a + b) / totalApps;

        // Find top app in category by opportunity score
        apps.sort((a, b) => b.opportunityScore.compareTo(a.opportunityScore));
        final topApp = apps.first.name;

        // Generate normalized sparkline from real scores
        final base = avgScore / 10.0;
        final sparkline = [
          (base * 0.85).clamp(1.0, 10.0),
          (base * 0.90).clamp(1.0, 10.0),
          (base * 0.95).clamp(1.0, 10.0),
          (base * 0.92).clamp(1.0, 10.0),
          (base * 1.02).clamp(1.0, 10.0),
          (base * 1.05).clamp(1.0, 10.0),
        ];

        trends.add(CategoryTrend(
          category: category,
          growthRate: double.parse(avgGrowth.toStringAsFixed(1)),
          totalApps: totalApps,
          avgOpportunityScore: double.parse(avgScore.toStringAsFixed(1)),
          topApp: topApp,
          weeklySparkline: sparkline,
        ));
      });

      // Sort by highest growth rate
      trends.sort((a, b) => b.growthRate.compareTo(a.growthRate));
      final result = trends.isNotEmpty ? trends : await fallbackRepo.getCategoryTrends(timeframe: timeframe);
      _cachedTrends = result;
      _lastFetchTime = DateTime.now();
      return result;
    } catch (_) {
      final fallback = await fallbackRepo.getCategoryTrends(timeframe: timeframe);
      _cachedTrends = fallback;
      _lastFetchTime = DateTime.now();
      return fallback;
    }
  }

  @override
  Future<List<EmergingKeyword>> getEmergingKeywords() async {
    return await fallbackRepo.getEmergingKeywords();
  }
}
