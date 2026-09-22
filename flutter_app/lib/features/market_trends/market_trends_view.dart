import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/market_trend.dart';
import '../../data/repositories/market_trend_repository.dart';
import '../../widgets/section_header.dart';

class MarketTrendsView extends StatefulWidget {
  final MarketTrendRepository trendRepo;

  const MarketTrendsView({super.key, required this.trendRepo});

  @override
  State<MarketTrendsView> createState() => _MarketTrendsViewState();
}

class _MarketTrendsViewState extends State<MarketTrendsView> {
  String _selectedTimeframe = '30 Days';
  late Future<List<dynamic>> _trendsFuture;

  @override
  void initState() {
    super.initState();
    _loadTrends();
  }

  void _loadTrends() {
    _trendsFuture = Future.wait([
      widget.trendRepo.getCategoryTrends(timeframe: _selectedTimeframe),
      widget.trendRepo.getEmergingKeywords(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 960;

    return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          SectionHeader(
            title: 'Macro Market Trends & Emerging Signals',
            subtitle: 'Track algorithmic category expansions, fast-moving keywords, and market opportunity indices.',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedTimeframe,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  items: const [
                    DropdownMenuItem(value: '7 Days', child: Text('7 Days Window')),
                    DropdownMenuItem(value: '30 Days', child: Text('30 Days Window')),
                    DropdownMenuItem(value: '90 Days', child: Text('90 Days Window')),
                    DropdownMenuItem(value: '1 Year', child: Text('1 Year Window')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedTimeframe = val;
                        _loadTrends();
                      });
                    }
                  },
                ),
              ),
            ),
          ),
          FutureBuilder<List<dynamic>>(
            future: _trendsFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ));
            }

            final trends = snapshot.data![0] as List<CategoryTrend>;
            final keywords = snapshot.data![1] as List<EmergingKeyword>;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: _buildCategoryVelocityCard(trends)),
                      const SizedBox(width: 20),
                      Expanded(flex: 4, child: _buildEmergingKeywordsCard(keywords)),
                    ],
                  )
                else ...[
                  _buildCategoryVelocityCard(trends),
                  const SizedBox(height: 20),
                  _buildEmergingKeywordsCard(keywords),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildCategoryVelocityCard(List<CategoryTrend> trends) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Category Growth Momentum',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              Text('Relative Index', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          for (final t in trends) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(t.category, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.successLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '+${t.growthRate.toInt()}%',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.success),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${t.totalApps} tracked apps • Top breakout: ${t.topApp}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                      Text(
                        'Avg Score: ${t.avgOpportunityScore.toStringAsFixed(1)}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Visual bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: t.growthRate / 150.0,
                      minHeight: 6,
                      backgroundColor: AppColors.surfaceSecondary,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
          ],
        ],
      ),
    );
  }

  Widget _buildEmergingKeywordsCard(List<EmergingKeyword> keywords) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.query_stats, size: 20, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Breakout Search Keywords',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'High store search volume growth paired with low-to-medium app competition.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          const Divider(),
          for (final kw in keywords) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          kw.keyword,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          kw.category,
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: kw.competitionLevel == 'Low' ? AppColors.successLight : AppColors.warningLight,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: kw.competitionLevel == 'Low' ? AppColors.successBorder : AppColors.warningBorder,
                      ),
                    ),
                    child: Text(
                      '${kw.competitionLevel} Comp',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: kw.competitionLevel == 'Low' ? AppColors.success : AppColors.warning,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '+${kw.searchVolumeGrowth.toInt()}%',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}
