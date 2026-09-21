import '../models/app_item.dart';
import '../models/market_trend.dart';
import 'app_repository.dart';
import 'market_trend_repository.dart';

class SupabaseMarketTrendRepository implements MarketTrendRepository {
  final AppRepository appRepository;
  final MarketTrendRepository fallbackRepo;

  SupabaseMarketTrendRepository({
    required this.appRepository,
    required this.fallbackRepo,
  });

  @override
  Future<List<CategoryTrend>> getCategoryTrends({String timeframe = '30 Days'}) async {
    try {
      final allApps = await appRepository.getAllApps();
      if (allApps.isEmpty) {
        return await fallbackRepo.getCategoryTrends(timeframe: timeframe);
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
      return trends.isNotEmpty ? trends : await fallbackRepo.getCategoryTrends(timeframe: timeframe);
    } catch (_) {
      return await fallbackRepo.getCategoryTrends(timeframe: timeframe);
    }
  }

  @override
  Future<List<EmergingKeyword>> getEmergingKeywords() async {
    return await fallbackRepo.getEmergingKeywords();
  }
}
