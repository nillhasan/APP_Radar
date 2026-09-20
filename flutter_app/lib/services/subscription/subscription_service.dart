import 'package:flutter/foundation.dart';

enum UserTier {
  free,
  pro,
}

class SubscriptionService extends ChangeNotifier {
  UserTier _tier = UserTier.free;
  final Set<String> _viewedAppIdsToday = {};
  static const int dailyTeardownsLimit = 3;

  UserTier get currentTier => _tier;
  bool get isPro => _tier == UserTier.pro;
  bool get isFree => _tier == UserTier.free;

  int get viewedCountToday => _viewedAppIdsToday.length;

  int get remainingFreeTeardowns {
    if (isPro) return 999;
    final remaining = dailyTeardownsLimit - _viewedAppIdsToday.length;
    return remaining > 0 ? remaining : 0;
  }

  bool canViewTeardown(String appId) {
    if (isPro) return true;
    if (_viewedAppIdsToday.contains(appId)) return true;
    return _viewedAppIdsToday.length < dailyTeardownsLimit;
  }

  void recordTeardownView(String appId) {
    if (!_viewedAppIdsToday.contains(appId)) {
      _viewedAppIdsToday.add(appId);
      notifyListeners();
    }
  }

  bool canGenerateBlueprint() {
    return isPro;
  }

  void upgradeToPro() {
    _tier = UserTier.pro;
    notifyListeners();
  }

  void downgradeToFree() {
    _tier = UserTier.free;
    notifyListeners();
  }

  void toggleTier() {
    _tier = isPro ? UserTier.free : UserTier.pro;
    notifyListeners();
  }

  void resetDailyLimits() {
    _viewedAppIdsToday.clear();
    notifyListeners();
  }
}
