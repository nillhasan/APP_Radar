import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/report_item.dart';
import 'report_repository.dart';

class SupabaseReportRepository implements ReportRepository {
  final SupabaseClient client;
  final ReportRepository fallbackRepo;

  List<ReportItem>? _cachedReports;
  DateTime? _lastFetchTime;
  static const Duration _cacheTtl = Duration(minutes: 5);

  /// In-flight request memoization to prevent duplicate concurrent network queries
  Future<List<ReportItem>>? _inFlightFetch;

  SupabaseReportRepository({
    required this.client,
    required this.fallbackRepo,
  });

  /// Invalidate cache manually
  void invalidateCache() {
    _cachedReports = null;
    _lastFetchTime = null;
    _inFlightFetch = null;
  }

  @override
  Future<List<ReportItem>> getReports({String? type, bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedReports != null && _lastFetchTime != null) {
      if (DateTime.now().difference(_lastFetchTime!) < _cacheTtl) {
        if (type == null || type == 'All') {
          return _cachedReports!;
        }
        return _cachedReports!.where((r) => r.type.toLowerCase() == type.toLowerCase()).toList();
      }
    }

    if (!forceRefresh && _inFlightFetch != null) {
      final all = await _inFlightFetch!;
      if (type == null || type == 'All') {
        return all;
      }
      return all.where((r) => r.type.toLowerCase() == type.toLowerCase()).toList();
    }

    _inFlightFetch = _fetchAndCacheReports();
    try {
      final items = await _inFlightFetch!;
      if (type == null || type == 'All') {
        return items;
      }
      return items.where((r) => r.type.toLowerCase() == type.toLowerCase()).toList();
    } finally {
      _inFlightFetch = null;
    }
  }

  Future<List<ReportItem>> _fetchAndCacheReports() async {
    try {
      final response = await client
          .from('reports')
          .select()
          .order('report_date', ascending: false)
          .limit(20);

      final List<dynamic> data = response as List<dynamic>;
      if (data.isEmpty) {
        final fallback = await fallbackRepo.getReports();
        _cachedReports = fallback;
        _lastFetchTime = DateTime.now();
        return fallback;
      }

      final items = data.map((json) => _mapJsonToReportItem(json as Map<String, dynamic>)).toList();
      _cachedReports = items;
      _lastFetchTime = DateTime.now();
      return items;
    } catch (e) {
      final fallback = await fallbackRepo.getReports();
      _cachedReports = fallback;
      _lastFetchTime = DateTime.now();
      return fallback;
    }
  }

  @override
  Future<ReportItem?> getReportById(String id) async {
    if (_cachedReports != null) {
      final matched = _cachedReports!.where((r) => r.id == id);
      if (matched.isNotEmpty) return matched.first;
    }

    try {
      final response = await client
          .from('reports')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) {
        return await fallbackRepo.getReportById(id);
      }
      return _mapJsonToReportItem(response);
    } catch (e) {
      return await fallbackRepo.getReportById(id);
    }
  }

  @override
  Future<ReportItem> getLatestDailyReport() async {
    if (_cachedReports != null && _cachedReports!.isNotEmpty) {
      return _cachedReports!.first;
    }

    try {
      final response = await client
          .from('reports')
          .select()
          .order('report_date', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) {
        return await fallbackRepo.getLatestDailyReport();
      }
      return _mapJsonToReportItem(response);
    } catch (e) {
      return await fallbackRepo.getLatestDailyReport();
    }
  }

  ReportItem _mapJsonToReportItem(Map<String, dynamic> json) {
    final reportDate = json['report_date'] as String? ?? '';
    final date = DateTime.tryParse(reportDate) ?? DateTime.now();

    var topOpportunitiesRaw = json['top_opportunities'];
    List<dynamic> topOpportunities = [];
    if (topOpportunitiesRaw is List) {
      topOpportunities = topOpportunitiesRaw;
    } else if (topOpportunitiesRaw is String) {
      try {
        topOpportunities = jsonDecode(topOpportunitiesRaw) as List<dynamic>;
      } catch (_) {}
    }

    String topName = 'Market Opportunities';
    int topScore = 82;
    if (topOpportunities.isNotEmpty) {
      final first = topOpportunities.first;
      if (first is Map<String, dynamic>) {
        topName = first['name'] as String? ?? 'Market Opportunities';
        topScore = (first['score'] as num?)?.toInt() ?? 82;
      }
    }

    final appsAnalyzed = (json['apps_analyzed'] as num?)?.toInt() ?? 24;
    final opportunitiesFound = topOpportunities.isNotEmpty ? topOpportunities.length : 5;

    return ReportItem(
      id: json['id']?.toString() ?? '1',
      title: 'AppRadar Daily Store Intelligence Briefing',
      type: 'Daily',
      date: date,
      appsAnalyzed: appsAnalyzed,
      opportunitiesFound: opportunitiesFound,
      topOpportunityName: topName,
      topOpportunityScore: topScore,
      marketSummary: 'Comprehensive dual-store analysis across Apple App Store and Google Play Store with AI opportunity detection.',
      status: json['status'] as String? ?? 'Published',
    );
  }
}
