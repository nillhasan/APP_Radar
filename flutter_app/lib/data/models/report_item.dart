class ReportItem {
  final String id;
  final String title;
  final String type; // 'Daily', 'Weekly', 'Monthly'
  final DateTime date;
  final int appsAnalyzed;
  final int opportunitiesFound;
  final String topOpportunityName;
  final int topOpportunityScore;
  final String marketSummary;
  final String status; // 'Published', 'Draft'

  const ReportItem({
    required this.id,
    required this.title,
    required this.type,
    required this.date,
    required this.appsAnalyzed,
    required this.opportunitiesFound,
    required this.topOpportunityName,
    required this.topOpportunityScore,
    required this.marketSummary,
    this.status = 'Published',
  });
}
