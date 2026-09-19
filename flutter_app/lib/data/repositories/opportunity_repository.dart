import '../models/app_item.dart';
import 'app_repository.dart';

abstract class OpportunityRepository {
  Future<List<AppItem>> getTopOpportunities({int limit = 5});
  Future<List<AppItem>> getFilteredOpportunities({
    String? category,
    String? platform,
    int? minScore,
    String? sortBy,
  });
}

class MockOpportunityRepository implements OpportunityRepository {
  final AppRepository appRepository;

  MockOpportunityRepository({required this.appRepository});

  @override
  Future<List<AppItem>> getTopOpportunities({int limit = 5}) async {
    final apps = await appRepository.getAllApps();
    final sorted = List<AppItem>.from(apps)
      ..sort((a, b) => b.opportunityScore.compareTo(a.opportunityScore));
    return sorted.take(limit).toList();
  }

  @override
  Future<List<AppItem>> getFilteredOpportunities({
    String? category,
    String? platform,
    int? minScore,
    String? sortBy,
  }) async {
    final apps = await appRepository.getAllApps();
    var filtered = apps.where((a) {
      if (category != null &&
          category != 'All Categories' &&
          category != 'All' &&
          !a.category.toLowerCase().contains(category.toLowerCase())) {
        return false;
      }
      if (platform != null &&
          platform != 'All Platforms' &&
          !a.platform.toLowerCase().contains(platform.toLowerCase())) {
        return false;
      }
      if (minScore != null && a.opportunityScore < minScore) {
        return false;
      }
      return true;
    }).toList();

    if (sortBy == 'Growth') {
      filtered.sort((a, b) => b.growthRate.compareTo(a.growthRate));
    } else if (sortBy == 'Rating') {
      filtered.sort((a, b) => b.rating.compareTo(a.rating));
    } else if (sortBy == 'Reviews') {
      filtered.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
    } else {
      // Default: Opportunity Score
      filtered.sort((a, b) => b.opportunityScore.compareTo(a.opportunityScore));
    }

    return filtered;
  }
}
