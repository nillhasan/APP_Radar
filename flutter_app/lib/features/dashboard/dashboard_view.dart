import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/app_item.dart';
import '../../data/models/market_trend.dart';
import '../../data/repositories/opportunity_repository.dart';
import '../../data/repositories/market_trend_repository.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/score_badge.dart';
import '../../widgets/section_header.dart';
import '../../widgets/app_icon_widget.dart';
import '../../widgets/top_charts/top_charts_leaderboard.dart';
import '../../data/repositories/app_repository.dart';

class DashboardView extends StatefulWidget {
  final OpportunityRepository oppRepo;
  final MarketTrendRepository trendRepo;
  final AppRepository? appRepo;
  final ValueChanged<AppItem> onOpenApp;
  final VoidCallback onNavigateToBuildAI;

  const DashboardView({
    super.key,
    required this.oppRepo,
    required this.trendRepo,
    this.appRepo,
    required this.onOpenApp,
    required this.onNavigateToBuildAI,
  });

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  late Future<List<dynamic>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _dataFuture = Future.wait([
      widget.oppRepo.getTopOpportunities(limit: 5),
      widget.trendRepo.getCategoryTrends(),
      widget.appRepo?.getAllApps() ?? widget.oppRepo.getFilteredOpportunities(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1080;

    return FutureBuilder<List<dynamic>>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final topApps = snapshot.data![0] as List<AppItem>;
        final trends = snapshot.data![1] as List<CategoryTrend>;
        final allApps = snapshot.data![2] as List<AppItem>;

        return RefreshIndicator(
          onRefresh: () async {
            setState(() => _loadData());
            await _dataFuture;
          },
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              SectionHeader(
                title: 'Discover Tomorrow’s App Opportunities Today',
                subtitle:
                    'AI-computed market velocity, store signals, and review sentiment across ${allApps.length} tracked applications.',
              ),
              _buildKpiGrid(allApps),
              const SizedBox(height: 24),
              TopChartsLeaderboard(
                apps: allApps,
                onOpenApp: widget.onOpenApp,
              ),
              const SizedBox(height: 24),
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: _buildTopOpportunitiesCard(topApps),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 3,
                      child: _buildMarketTrendsCard(trends),
                    ),
                  ],
                )
              else ...[
                _buildTopOpportunitiesCard(topApps),
                const SizedBox(height: 20),
                _buildMarketTrendsCard(trends),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildKpiGrid(List<AppItem> allApps) {
    final totalCount = allApps.length;
    final highPotentialCount = allApps.where((a) => a.opportunityScore >= 75).length;
    final velocityCount = allApps.where((a) => a.growthRate >= 15.0).length;
    final platformsCount = allApps.map((a) => a.platform).toSet().length;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            MetricCard(
              title: 'Apps Analyzed',
              value: '$totalCount',
              delta: '+24% this week',
              icon: Icons.analytics_outlined,
              isPositive: true,
            ),
            MetricCard(
              title: 'New Opportunities',
              value: '$velocityCount',
              delta: 'Growth > 15%',
              icon: Icons.bolt,
              isPositive: true,
            ),
            MetricCard(
              title: 'High Potential',
              value: '$highPotentialCount',
              delta: 'Score ≥ 75',
              icon: Icons.star_border,
              isPositive: true,
            ),
            MetricCard(
              title: 'Markets Tracked',
              value: '$platformsCount',
              delta: 'US • UK • CA',
              icon: Icons.public,
              isPositive: true,
            ),
          ],
        );
      },
    );
  }

  Widget _buildTopOpportunitiesCard(List<AppItem> apps) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Top Opportunities Today',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Ranked by transparent 5-signal opportunity composite',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Updated hourly',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          for (int i = 0; i < apps.length; i++) ...[
            _buildOpportunityRow(i + 1, apps[i]),
            if (i < apps.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }

  Widget _buildOpportunityRow(int rank, AppItem app) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 540),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: rank <= 3 ? AppColors.primaryLight : AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '#$rank',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: rank <= 3 ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              AppIconWidget(
                iconUrl: app.iconUrl,
                iconEmoji: app.iconEmoji,
                size: 38,
                borderRadius: 8,
                fontSize: 20,
              ),
              const SizedBox(width: 14),
              SizedBox(
                width: 200,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            app.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSecondary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            app.category,
                            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${app.rating} ⭐ (${(app.reviewCount / 1000).toStringAsFixed(1)}k reviews) • +${app.growthRate.toInt()}% growth',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ScoreBadge(score: app.opportunityScore),
              const SizedBox(width: 12),
              FilledButton.tonal(
                onPressed: () => widget.onOpenApp(app),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                child: const Text('View Teardown'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMarketTrendsCard(List<CategoryTrend> trends) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Market Category Trends',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    '30D Growth',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              for (final t in trends) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.category,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${t.totalApps} apps tracked',
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.successLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '+${t.growthRate.toInt()}%',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.auto_awesome, color: Colors.amber, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Turn Signals into Shipped Apps',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Generate a full MVP Blueprint, database schema, and Flutter architecture from any discovered opportunity.',
                style: TextStyle(fontSize: 12, color: Color(0xFFDBEAFE), height: 1.4),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: widget.onNavigateToBuildAI,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Open Build With AI', style: TextStyle(fontWeight: FontWeight.w700)),
                    SizedBox(width: 6),
                    Icon(Icons.arrow_forward, size: 14),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
