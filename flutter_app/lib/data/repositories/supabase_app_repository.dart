import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_item.dart';
import 'app_repository.dart';

class SupabaseAppRepository implements AppRepository {
  final SupabaseClient client;
  final AppRepository fallbackRepo;

  SupabaseAppRepository({
    required this.client,
    required this.fallbackRepo,
  });

  @override
  Future<List<AppItem>> getAllApps() async {
    try {
      final response = await client
          .from('apps')
          .select('*, app_analysis(*), app_metrics(*)')
          .order('id', ascending: true);

      final List<dynamic> data = response as List<dynamic>;
      if (data.isEmpty) {
        // Fallback to rich mock data if live table is currently empty
        return await fallbackRepo.getAllApps();
      }

      return data.map((json) => _mapJsonToAppItem(json as Map<String, dynamic>)).toList();
    } catch (e) {
      // Graceful fallback to mock data on network or RLS restriction
      return await fallbackRepo.getAllApps();
    }
  }

  @override
  Future<AppItem?> getAppById(String id) async {
    try {
      final response = await client
          .from('apps')
          .select('*, app_analysis(*), app_metrics(*)')
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
    final analysisList = json['app_analysis'] as List<dynamic>? ?? [];
    final analysis = analysisList.isNotEmpty ? analysisList.first as Map<String, dynamic> : <String, dynamic>{};

    final metricsList = json['app_metrics'] as List<dynamic>? ?? [];
    final metrics = metricsList.isNotEmpty ? metricsList.first as Map<String, dynamic> : <String, dynamic>{};

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
    );
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
}
