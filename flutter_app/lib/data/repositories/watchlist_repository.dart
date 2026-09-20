import '../models/app_item.dart';
import 'app_repository.dart';

abstract class WatchlistRepository {
  Future<List<AppItem>> getWatchlistedApps();
  Future<void> addToWatchlist(String appId);
  Future<void> removeFromWatchlist(String appId);
  Future<bool> isWatchlisted(String appId);
  Future<void> toggleWatchlist(String appId);
}

class MockWatchlistRepository implements WatchlistRepository {
  final AppRepository appRepository;

  MockWatchlistRepository({required this.appRepository});

  @override
  Future<List<AppItem>> getWatchlistedApps() async {
    final apps = await appRepository.getAllApps();
    return apps.where((a) => a.isWatchlisted).toList();
  }

  @override
  Future<void> addToWatchlist(String appId) async {
    final app = await appRepository.getAppById(appId);
    if (app != null && !app.isWatchlisted) {
      await appRepository.toggleWatchlist(appId);
    }
  }

  @override
  Future<void> removeFromWatchlist(String appId) async {
    final app = await appRepository.getAppById(appId);
    if (app != null && app.isWatchlisted) {
      await appRepository.toggleWatchlist(appId);
    }
  }

  @override
  Future<bool> isWatchlisted(String appId) async {
    final app = await appRepository.getAppById(appId);
    return app?.isWatchlisted ?? false;
  }

  @override
  Future<void> toggleWatchlist(String appId) async {
    final saved = await isWatchlisted(appId);
    if (saved) {
      await removeFromWatchlist(appId);
    } else {
      await addToWatchlist(appId);
    }
  }
}
