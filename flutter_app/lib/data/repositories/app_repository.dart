import '../models/app_item.dart';
import '../mock/mock_data.dart';

abstract class AppRepository {
  Future<List<AppItem>> getAllApps();
  Future<AppItem?> getAppById(String id);
  Future<List<AppItem>> searchApps(String query, {String? category, String? platform});
  Future<void> toggleWatchlist(String appId);
  Future<void> updateNotes(String appId, String notes);
}

class MockAppRepository implements AppRepository {
  final List<AppItem> _apps = List.from(MockData.apps);

  @override
  Future<List<AppItem>> getAllApps() async {
    return List.unmodifiable(_apps);
  }

  @override
  Future<AppItem?> getAppById(String id) async {
    try {
      return _apps.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<AppItem>> searchApps(String query, {String? category, String? platform}) async {
    return _apps.where((app) {
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
    final idx = _apps.indexWhere((a) => a.id == appId);
    if (idx != -1) {
      _apps[idx] = _apps[idx].copyWith(isWatchlisted: !_apps[idx].isWatchlisted);
    }
  }

  @override
  Future<void> updateNotes(String appId, String notes) async {
    final idx = _apps.indexWhere((a) => a.id == appId);
    if (idx != -1) {
      _apps[idx] = _apps[idx].copyWith(notes: notes);
    }
  }
}
