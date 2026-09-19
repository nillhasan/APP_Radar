import '../models/market_trend.dart';
import '../mock/mock_data.dart';

abstract class MarketTrendRepository {
  Future<List<CategoryTrend>> getCategoryTrends({String timeframe = '30 Days'});
  Future<List<EmergingKeyword>> getEmergingKeywords();
}

class MockMarketTrendRepository implements MarketTrendRepository {
  @override
  Future<List<CategoryTrend>> getCategoryTrends({String timeframe = '30 Days'}) async {
    return MockData.categoryTrends;
  }

  @override
  Future<List<EmergingKeyword>> getEmergingKeywords() async {
    return MockData.emergingKeywords;
  }
}
