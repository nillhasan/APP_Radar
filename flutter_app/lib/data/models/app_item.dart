import 'negative_review_mining.dart';

class AppSignals {
  final int growthSignal;
  final int revenueSignal;
  final int rankingSignal;
  final int reviewSignal;
  final int marketSignal;

  const AppSignals({
    required this.growthSignal,
    required this.revenueSignal,
    required this.rankingSignal,
    required this.reviewSignal,
    required this.marketSignal,
  });

  int get compositeScore => (growthSignal * 0.30 +
          revenueSignal * 0.25 +
          rankingSignal * 0.20 +
          reviewSignal * 0.15 +
          marketSignal * 0.10)
      .round();
}

class AppItem {
  final String id;
  final String name;
  final String developer;
  final String category;
  final String platform;
  final String iconEmoji;
  final String? iconUrl;
  final String description;
  final double rating;
  final int reviewCount;
  final int ranking;
  final int downloadsEstimate;
  final double revenueEstimate;
  final double growthRate;
  final int opportunityScore;
  final AppSignals signals;
  final String monetization;
  final String whatItDoes;
  final String targetUser;
  final String whyGrowing;
  final String coreValueProp;
  final List<String> coreFeatures;
  final List<String> aiFeatures;
  final List<String> userPainPoints;
  final List<String> competitorGaps;
  final List<String> suggestedMvp;
  final List<String> screenshots;
  final bool isWatchlisted;
  final String notes;
  final NegativeReviewMining? negativeReviews;
  final String? appUrl;
  final double price;
  final int rankDelta;
  final Map<String, double>? regionalBreakdown;
  final List<String> competitorIds;

  const AppItem({
    required this.id,
    required this.name,
    required this.developer,
    required this.category,
    required this.platform,
    required this.iconEmoji,
    this.iconUrl,
    required this.description,
    required this.rating,
    required this.reviewCount,
    required this.ranking,
    required this.downloadsEstimate,
    required this.revenueEstimate,
    required this.growthRate,
    required this.opportunityScore,
    required this.signals,
    required this.monetization,
    required this.whatItDoes,
    required this.targetUser,
    required this.whyGrowing,
    required this.coreValueProp,
    required this.coreFeatures,
    required this.aiFeatures,
    required this.userPainPoints,
    required this.competitorGaps,
    required this.suggestedMvp,
    this.screenshots = const [],
    this.isWatchlisted = false,
    this.notes = '',
    this.negativeReviews,
    this.appUrl,
    this.price = 0.0,
    this.rankDelta = 0,
    this.regionalBreakdown,
    this.competitorIds = const [],
  });

  AppItem copyWith({
    bool? isWatchlisted,
    String? notes,
    NegativeReviewMining? negativeReviews,
    String? iconUrl,
    List<String>? screenshots,
    String? appUrl,
    double? price,
    int? rankDelta,
    Map<String, double>? regionalBreakdown,
    List<String>? competitorIds,
  }) {
    return AppItem(
      id: id,
      name: name,
      developer: developer,
      category: category,
      platform: platform,
      iconEmoji: iconEmoji,
      iconUrl: iconUrl ?? this.iconUrl,
      description: description,
      rating: rating,
      reviewCount: reviewCount,
      ranking: ranking,
      downloadsEstimate: downloadsEstimate,
      revenueEstimate: revenueEstimate,
      growthRate: growthRate,
      opportunityScore: opportunityScore,
      signals: signals,
      monetization: monetization,
      whatItDoes: whatItDoes,
      targetUser: targetUser,
      whyGrowing: whyGrowing,
      coreValueProp: coreValueProp,
      coreFeatures: coreFeatures,
      aiFeatures: aiFeatures,
      userPainPoints: userPainPoints,
      competitorGaps: competitorGaps,
      suggestedMvp: suggestedMvp,
      screenshots: screenshots ?? this.screenshots,
      isWatchlisted: isWatchlisted ?? this.isWatchlisted,
      notes: notes ?? this.notes,
      negativeReviews: negativeReviews ?? this.negativeReviews,
      appUrl: appUrl ?? this.appUrl,
      price: price ?? this.price,
      rankDelta: rankDelta ?? this.rankDelta,
      regionalBreakdown: regionalBreakdown ?? this.regionalBreakdown,
      competitorIds: competitorIds ?? this.competitorIds,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppItem && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
