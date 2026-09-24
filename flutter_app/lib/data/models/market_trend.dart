class CategoryTrend {
  final String category;
  final double growthRate;
  final int totalApps;
  final double avgOpportunityScore;
  final String topApp;
  final List<double> weeklySparkline;

  const CategoryTrend({
    required this.category,
    required this.growthRate,
    required this.totalApps,
    required this.avgOpportunityScore,
    required this.topApp,
    required this.weeklySparkline,
  });
}

class EmergingKeyword {
  final String keyword;
  final String category;
  final double searchVolumeGrowth;
  final String competitionLevel; // Low, Medium, High
  final int estimatedMonthlySearches;
  final String whyTrending;
  final String builderOpportunity;
  final List<double> sparkline;

  const EmergingKeyword({
    required this.keyword,
    required this.category,
    required this.searchVolumeGrowth,
    required this.competitionLevel,
    this.estimatedMonthlySearches = 48000,
    this.whyTrending = 'Surging search intent with low incumbent app satisfaction.',
    this.builderOpportunity = 'Build a lightweight Flutter MVP with offline-first support and simple pricing.',
    this.sparkline = const [24, 38, 55, 72, 95, 120, 160],
  });
}
