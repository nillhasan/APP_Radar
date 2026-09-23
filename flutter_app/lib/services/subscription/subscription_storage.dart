import 'subscription_storage_stub.dart'
    if (dart.library.html) 'subscription_storage_web.dart';

class SubscriptionStorage {
  static String? getStoredTier() => getStoredTierImpl();
  static void setStoredTier(String? tier) => setStoredTierImpl(tier);

  static Set<String> getStoredUrlTeardowns() => getStoredUrlTeardownsImpl();
  static void setStoredUrlTeardowns(Set<String> ids) => setStoredUrlTeardownsImpl(ids);
}
