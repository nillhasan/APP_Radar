class BuildBlueprint {
  final String appName;
  final String productOverview;
  final String problem;
  final String targetUsers;
  final String valueProposition;
  final List<String> coreMvpFeatures;
  final List<String> userFlow;
  final List<String> screens;
  final String databaseDesign;
  final List<String> apiRequirements;
  final String aiArchitecture;
  final String flutterArchitecture;
  final String monetization;
  final List<String> competitiveDifferentiation;
  final List<RoadmapPhase> roadmap;

  const BuildBlueprint({
    required this.appName,
    required this.productOverview,
    required this.problem,
    required this.targetUsers,
    required this.valueProposition,
    required this.coreMvpFeatures,
    required this.userFlow,
    required this.screens,
    required this.databaseDesign,
    required this.apiRequirements,
    required this.aiArchitecture,
    required this.flutterArchitecture,
    required this.monetization,
    required this.competitiveDifferentiation,
    required this.roadmap,
  });
}

class RoadmapPhase {
  final String phase; // Research, MVP, Beta, Launch, Growth
  final String duration;
  final List<String> milestones;

  const RoadmapPhase({
    required this.phase,
    required this.duration,
    required this.milestones,
  });
}
