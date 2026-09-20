class StoreReview {
  final String author;
  final int rating; // 1 or 2 stars
  final String date;
  final String category; // e.g., 'Pricing & Paywall Traps', 'Crashes & Data Loss', 'Missing Offline', 'Bad UI / UX'
  final String comment;
  final String builderOpportunity; // Actionable takeaway: how a competitor can solve this

  const StoreReview({
    required this.author,
    required this.rating,
    required this.date,
    required this.category,
    required this.comment,
    required this.builderOpportunity,
  });
}

class NegativeReviewMining {
  final int totalAnalyzed;
  final int dissatisfactionRate; // e.g. 28 -> 28% of all store reviews are 1-star or 2-star
  final Map<String, int> categoryDistribution; // e.g. {'Pricing & Paywalls': 42, 'Crashes & Bugs': 28, 'Missing Features': 18, 'Bad UI / UX': 12}
  final String goldenOpportunitySummary;
  final List<StoreReview> sampleReviews;

  const NegativeReviewMining({
    required this.totalAnalyzed,
    required this.dissatisfactionRate,
    required this.categoryDistribution,
    required this.goldenOpportunitySummary,
    required this.sampleReviews,
  });
}
