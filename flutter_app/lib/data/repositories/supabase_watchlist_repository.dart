import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_item.dart';
import '../../services/auth/auth_service.dart';
import 'app_repository.dart';
import 'watchlist_repository.dart';

class SupabaseWatchlistRepository implements WatchlistRepository {
  final SupabaseClient? client;
  final AuthService authService;
  final AppRepository appRepository;
  final WatchlistRepository fallbackRepo;

  SupabaseWatchlistRepository({
    this.client,
    required this.authService,
    required this.appRepository,
    WatchlistRepository? fallbackRepo,
  }) : fallbackRepo = fallbackRepo ?? MockWatchlistRepository(appRepository: appRepository);

  @override
  Future<List<AppItem>> getWatchlistedApps() async {
    if (!authService.isAuthenticated || client == null) {
      return await fallbackRepo.getWatchlistedApps();
    }

    try {
      final userId = authService.currentUser!.id;
      final response = await client!
          .from('user_watchlists')
          .select('app_id, notes')
          .eq('user_id', userId);

      final List<dynamic> rows = response as List<dynamic>;
      if (rows.isEmpty) {
        return [];
      }

      final notesMap = <String, String>{};
      for (final r in rows) {
        final appIdStr = r['app_id'].toString();
        notesMap[appIdStr] = r['notes']?.toString() ?? '';
      }

      final allApps = await appRepository.getAllApps();
      return allApps.where((app) => notesMap.containsKey(app.id)).map((app) {
        return app.copyWith(
          isWatchlisted: true,
          notes: notesMap[app.id] ?? '',
        );
      }).toList();
    } catch (_) {
      return await fallbackRepo.getWatchlistedApps();
    }
  }

  @override
  Future<void> addToWatchlist(String appId) async {
    if (!authService.isAuthenticated || client == null) {
      await fallbackRepo.addToWatchlist(appId);
      return;
    }

    try {
      final userId = authService.currentUser!.id;
      final parsedAppId = int.tryParse(appId) ?? 1;

      await client!.from('user_watchlists').upsert({
        'user_id': userId,
        'app_id': parsedAppId,
        'notes': '',
      }, onConflict: 'user_id,app_id');
    } catch (_) {
      await fallbackRepo.addToWatchlist(appId);
    }
  }

  @override
  Future<void> removeFromWatchlist(String appId) async {
    if (!authService.isAuthenticated || client == null) {
      await fallbackRepo.removeFromWatchlist(appId);
      return;
    }

    try {
      final userId = authService.currentUser!.id;
      final parsedAppId = int.tryParse(appId) ?? 1;

      await client!
          .from('user_watchlists')
          .delete()
          .eq('user_id', userId)
          .eq('app_id', parsedAppId);
    } catch (_) {
      await fallbackRepo.removeFromWatchlist(appId);
    }
  }
}
