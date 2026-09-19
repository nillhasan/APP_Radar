import '../../data/models/app_item.dart';
import '../../data/models/build_blueprint.dart';
import '../../data/mock/mock_data.dart';

abstract class AIService {
  Future<BuildBlueprint> generateBlueprint(AppItem app);
  Future<String> analyzeMarketGap(String category);
}

class MockAIService implements AIService {
  @override
  Future<BuildBlueprint> generateBlueprint(AppItem app) async {
    // Simulate network latency for AI inference
    await Future.delayed(const Duration(milliseconds: 600));
    return MockData.createBlueprintForApp(app);
  }

  @override
  Future<String> analyzeMarketGap(String category) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return 'Analysis for $category indicates high unmet user demand for privacy-first, offline-capable mobile workflows with straightforward pricing.';
  }
}
