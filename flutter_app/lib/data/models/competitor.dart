class CompetitorApp {
  final String name;
  final String category;
  final double rating;
  final int reviews;
  final String pricing;
  final String marketPosition;
  final Map<String, bool> featureMatrix;

  const CompetitorApp({
    required this.name,
    required this.category,
    required this.rating,
    required this.reviews,
    required this.pricing,
    required this.marketPosition,
    required this.featureMatrix,
  });
}
