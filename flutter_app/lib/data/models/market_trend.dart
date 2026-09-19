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

  const EmergingKeyword({
    required this.keyword,
    required this.category,
    required this.searchVolumeGrowth,
    required this.competitionLevel,
  });
}
