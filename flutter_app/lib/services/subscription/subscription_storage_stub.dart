String? _inMemoryTier;
final Set<String> _inMemoryUrlTeardowns = {};

String? getStoredTierImpl() => _inMemoryTier;

void setStoredTierImpl(String? tier) {
  _inMemoryTier = tier;
}

Set<String> getStoredUrlTeardownsImpl() => Set.from(_inMemoryUrlTeardowns);

void setStoredUrlTeardownsImpl(Set<String> ids) {
  _inMemoryUrlTeardowns.clear();
  _inMemoryUrlTeardowns.addAll(ids);
}
