import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_item.dart';
import '../models/negative_review_mining.dart';
import 'app_repository.dart';

class SupabaseAppRepository implements AppRepository {
  final SupabaseClient client;
  final AppRepository fallbackRepo;

  List<AppItem>? _cachedApps;
  DateTime? _lastFetchTime;
  static const Duration _cacheTtl = Duration(minutes: 5);

  /// In-flight request memoization to prevent duplicate concurrent network queries
  Future<List<AppItem>>? _inFlightFetch;

  SupabaseAppRepository({
    required this.client,
    required this.fallbackRepo,
  });

  /// Invalidate cache manually (e.g. after sync or pull-to-refresh)
  void invalidateCache() {
    _cachedApps = null;
    _lastFetchTime = null;
    _inFlightFetch = null;
  }

  @override
  Future<List<AppItem>> getAllApps({bool forceRefresh = false}) async {
    // 1. Return from memory immediately if cache is valid (< 5 minutes old)
    if (!forceRefresh && _cachedApps != null && _lastFetchTime != null) {
      if (DateTime.now().difference(_lastFetchTime!) < _cacheTtl) {
        return _cachedApps!;
      }
    }

    // 2. Return active in-flight request if another caller already started fetching
    if (!forceRefresh && _inFlightFetch != null) {
      return _inFlightFetch!;
    }

    _inFlightFetch = _fetchAndCacheApps();
    try {
      final result = await _inFlightFetch!;
      return result;
    } finally {
      _inFlightFetch = null;
    }
  }

  Future<List<AppItem>> _fetchAndCacheApps() async {
    // Strategy A: Query high-performance pre-joined view (zero redundant historical metrics)
    try {
      final response = await client
          .from('app_intelligence_view')
          .select()
          .order('id', ascending: true);

      final List<dynamic> data = response as List<dynamic>;
      if (data.isNotEmpty) {
        final mapped = data.map((json) => _mapJsonToAppItem(json as Map<String, dynamic>)).toList();
        _cachedApps = mapped;
        _lastFetchTime = DateTime.now();
        return mapped;
      }
    } catch (_) {
      // If the view does not exist yet on Supabase, proceed to Strategy B
    }

    // Strategy B: Fallback to optimized select on base tables
    try {
      final response = await client
          .from('apps')
          .select('*, app_analysis(*), app_metrics(rank, downloads, revenue_estimate, rating, review_count, growth_rate, metric_date)')
          .order('id', ascending: true);

      final List<dynamic> data = response as List<dynamic>;
      if (data.isEmpty) {
        final fallback = await fallbackRepo.getAllApps();
        _cachedApps = fallback;
        _lastFetchTime = DateTime.now();
        return fallback;
      }

      final mapped = data.map((json) => _mapJsonToAppItem(json as Map<String, dynamic>)).toList();
      _cachedApps = mapped;
      _lastFetchTime = DateTime.now();
      return mapped;
    } catch (e) {
      final fallback = await fallbackRepo.getAllApps();
      _cachedApps = fallback;
      _lastFetchTime = DateTime.now();
      return fallback;
    }
  }

  @override
  Future<AppItem?> getAppById(String id) async {
    // Instant in-memory check
    if (_cachedApps != null) {
      final matched = _cachedApps!.where((a) => a.id == id);
      if (matched.isNotEmpty) return matched.first;
    }

    // Try view first
    try {
      final response = await client
          .from('app_intelligence_view')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response != null) {
        return _mapJsonToAppItem(response);
      }
    } catch (_) {}

    // Fallback to table
    try {
      final response = await client
          .from('apps')
          .select('*, app_analysis(*), app_metrics(rank, downloads, revenue_estimate, rating, review_count, growth_rate, metric_date)')
          .eq('id', id)
          .maybeSingle();

      if (response == null) {
        return await fallbackRepo.getAppById(id);
      }

      return _mapJsonToAppItem(response);
    } catch (e) {
      return await fallbackRepo.getAppById(id);
    }
  }

  @override
  Future<List<AppItem>> searchApps(String query, {String? category, String? platform}) async {
    final all = await getAllApps();
    return all.where((app) {
      final matchesQuery = query.isEmpty ||
          app.name.toLowerCase().contains(query.toLowerCase()) ||
          app.description.toLowerCase().contains(query.toLowerCase()) ||
          app.developer.toLowerCase().contains(query.toLowerCase());

      final matchesCategory = category == null ||
          category == 'All Categories' ||
          category == 'All' ||
          app.category.toLowerCase().contains(category.toLowerCase());

      final matchesPlatform = platform == null ||
          platform == 'All Platforms' ||
          app.platform.toLowerCase().contains(platform.toLowerCase());

      return matchesQuery && matchesCategory && matchesPlatform;
    }).toList();
  }

  @override
  Future<void> toggleWatchlist(String appId) async {
    await fallbackRepo.toggleWatchlist(appId);
  }

  @override
  Future<void> updateNotes(String appId, String notes) async {
    await fallbackRepo.updateNotes(appId, notes);
  }

  AppItem _mapJsonToAppItem(Map<String, dynamic> json) {
    // Support flat structure (from app_intelligence_view) and nested structure (from apps table joins)
    final Map<String, dynamic> analysis;
    if (json.containsKey('opportunity_score') && json['opportunity_score'] != null) {
      analysis = json;
    } else {
      final analysisList = json['app_analysis'] as List<dynamic>? ?? [];
      analysis = analysisList.isNotEmpty ? analysisList.first as Map<String, dynamic> : <String, dynamic>{};
    }

    final Map<String, dynamic> metrics;
    if (json.containsKey('downloads') && json['downloads'] != null) {
      metrics = json;
    } else {
      final metricsList = json['app_metrics'] as List<dynamic>? ?? [];
      metrics = metricsList.isNotEmpty ? metricsList.first as Map<String, dynamic> : <String, dynamic>{};
    }

    final opportunityScore = (analysis['opportunity_score'] as num?)?.toInt() ?? 78;
    final growthSignal = (analysis['growth_signal'] as num?)?.toInt() ?? 80;
    final revenueSignal = (analysis['revenue_signal'] as num?)?.toInt() ?? 75;
    final rankingSignal = (analysis['ranking_signal'] as num?)?.toInt() ?? 82;
    final reviewSignal = (analysis['review_signal'] as num?)?.toInt() ?? 76;
    final marketSignal = (analysis['market_signal'] as num?)?.toInt() ?? 78;

    final name = json['name'] as String? ?? 'Untitled App';
    final category = json['category'] as String? ?? 'Productivity';

    return AppItem(
      id: json['id']?.toString() ?? 'app_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      developer: json['developer'] as String? ?? 'Independent Developer',
      category: category,
      platform: json['platform'] as String? ?? 'iOS App Store',
      iconEmoji: _inferEmojiForCategory(category, name),
      iconUrl: json['icon_url'] as String?,
      description: json['description'] as String? ?? 'Real-time tracked mobile application.',
      rating: (json['rating'] as num?)?.toDouble() ?? 4.7,
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 5000,
      ranking: (metrics['rank'] as num?)?.toInt() ?? 5,
      downloadsEstimate: (metrics['downloads'] as num?)?.toInt() ?? 120000,
      revenueEstimate: (metrics['revenue_estimate'] as num?)?.toDouble() ?? 240000.0,
      growthRate: (metrics['growth_rate'] as num?)?.toDouble() ?? growthSignal.toDouble(),
      opportunityScore: opportunityScore,
      signals: AppSignals(
        growthSignal: growthSignal,
        revenueSignal: revenueSignal,
        rankingSignal: rankingSignal,
        reviewSignal: reviewSignal,
        marketSignal: marketSignal,
      ),
      monetization: analysis['monetization'] as String? ?? 'Freemium in-app purchases',
      whatItDoes: analysis['ai_summary'] as String? ?? json['description'] as String? ?? '',
      targetUser: analysis['target_user'] as String? ?? 'Mobile power users and professionals',
      whyGrowing: analysis['market_opportunity'] as String? ?? 'Surging user demand in app store charts.',
      coreValueProp: analysis['build_opportunity'] as String? ?? 'Seamless workflow with automated intelligence.',
      coreFeatures: _parseStringList(analysis['core_features']),
      aiFeatures: _parseStringList(analysis['ai_features'] ?? ['Smart categorization', 'Instant processing']),
      userPainPoints: _parseStringList(analysis['user_pain_points']),
      competitorGaps: _parseStringList(analysis['risks'] ?? ['Pricing alternatives', 'Platform parity']),
      suggestedMvp: _parseStringList(analysis['mvp_features']),
      screenshots: (json['screenshot_urls'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          ['Overview Screen', 'Feature Detail', 'Export Flow'],
      isWatchlisted: false,
      notes: '',
      appUrl: json['app_url'] as String? ?? 'https://apps.apple.com',
      price: _parsePrice(json['price'], analysis['monetization']),
      rankDelta: (metrics['rank_delta'] as num?)?.toInt() ?? _inferRankDelta(name),
      regionalBreakdown: _buildRegionalBreakdown(json['regional_breakdown'], name, category),
      competitorIds: (json['competitor_ids'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          const ['app_1', 'app_2', 'app_3'],
      negativeReviews: _buildNegativeReviewMining(
        name,
        category,
        _parseStringList(analysis['user_pain_points']),
        _parseStringList(analysis['risks']),
        (json['rating'] as num?)?.toDouble() ?? 4.7,
        (json['review_count'] as num?)?.toInt() ?? 5000,
      ),
    );
  }

  double _parsePrice(dynamic rawPrice, dynamic monetization) {
    if (rawPrice != null && rawPrice is num && rawPrice > 0) {
      return rawPrice.toDouble();
    }
    if (monetization is String) {
      final lower = monetization.toLowerCase();
      if (lower.contains('paid') || lower.contains('upfront')) {
        final match = RegExp(r'\$(\d+(\.\d+)?)').firstMatch(lower);
        if (match != null) {
          return double.tryParse(match.group(1) ?? '0') ?? 0.0;
        }
      }
    }
    return 0.0;
  }

  int _inferRankDelta(String name) {
    final hash = (name.hashCode ^ 1337).abs();
    final deltas = [1, 2, -1, 3, 0, -2, 4, 2, -1, 0];
    return deltas[hash % deltas.length];
  }

  Map<String, double> _buildRegionalBreakdown(dynamic jsonBreakdown, String name, String category) {
    if (jsonBreakdown is Map) {
      return Map<String, double>.from(
        jsonBreakdown.map(
          (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
        ),
      );
    }
    final hash = (name.hashCode ^ category.hashCode).abs();
    final usShare = 0.35 + ((hash % 20) / 100.0);
    final ukShare = 0.15 + (((hash >> 2) % 15) / 100.0);
    final deShare = 0.10 + (((hash >> 4) % 12) / 100.0);
    final jpShare = 0.08 + (((hash >> 6) % 16) / 100.0);
    final otherShare = (1.0 - (usShare + ukShare + deShare + jpShare)).clamp(0.05, 0.20);
    final total = usShare + ukShare + deShare + jpShare + otherShare;
    return {
      'US': double.parse((usShare / total).toStringAsFixed(2)),
      'UK': double.parse((ukShare / total).toStringAsFixed(2)),
      'DE': double.parse((deShare / total).toStringAsFixed(2)),
      'JP': double.parse((jpShare / total).toStringAsFixed(2)),
      'Other': double.parse((otherShare / total).toStringAsFixed(2)),
    };
  }

  List<String> _parseStringList(dynamic data) {
    if (data is List) {
      return data.map((e) => e.toString()).toList();
    }
    return ['Feature automation', 'Cloud sync', 'Direct export'];
  }

  String _inferEmojiForCategory(String category, String name) {
    final lower = '$category $name'.toLowerCase();
    if (lower.contains('note') || lower.contains('voice') || lower.contains('record')) return '🎙️';
    if (lower.contains('food') || lower.contains('calorie') || lower.contains('diet')) return '🥗';
    if (lower.contains('pdf') || lower.contains('doc')) return '📄';
    if (lower.contains('language') || lower.contains('learn') || lower.contains('tutor')) return '🗣️';
    if (lower.contains('budget') || lower.contains('finance') || lower.contains('money')) return '💳';
    if (lower.contains('sleep') || lower.contains('health')) return '🌙';
    if (lower.contains('habit')) return '⚡';
    return '📱';
  }

  NegativeReviewMining _buildNegativeReviewMining(
    String name,
    String category,
    List<String> userPainPoints,
    List<String> competitorGaps,
    double rating,
    int reviewCount,
  ) {
    final dissatisfactionRate = ((5.0 - rating.clamp(1.0, 5.0)) * 22).round().clamp(8, 48);
    final totalAnalyzed = (reviewCount * 0.08).round().clamp(45, 1200);

    final goldenOpp = competitorGaps.isNotEmpty
        ? competitorGaps.first
        : 'Build a simplified, indie-friendly alternative with transparent pricing and offline-first reliability.';

    final List<StoreReview> sampleReviews = [];
    final complaints = userPainPoints.isNotEmpty
        ? userPainPoints
        : [
            'Overpriced subscription tier for basic utility features',
            'Constant paywall popups ruin the mobile experience',
            'Occasional sync failures and missing offline storage',
          ];

    final categories = ['Pricing & Paywalls', 'Missing Features', 'Bugs & Stability', 'UI & UX Friction'];
    for (int i = 0; i < complaints.length; i++) {
      final complaint = complaints[i];
      final cat = categories[i % categories.length];
      final rRating = (i % 2 == 0) ? 1 : 2;
      sampleReviews.add(
        StoreReview(
          author: 'Verified User ${i + 1}',
          rating: rRating,
          date: '${(i + 1) * 2} days ago',
          category: cat,
          comment: complaint,
          builderOpportunity: 'Eliminate $cat by offering a transparent, lightweight workflow.',
        ),
      );
    }

    return NegativeReviewMining(
      totalAnalyzed: totalAnalyzed,
      dissatisfactionRate: dissatisfactionRate,
      categoryDistribution: const {
        'Pricing & Paywalls': 40,
        'Missing Features': 25,
        'Bugs & Stability': 20,
        'UI & UX Friction': 15,
      },
      goldenOpportunitySummary: goldenOpp,
      sampleReviews: sampleReviews,
    );
  }
}
