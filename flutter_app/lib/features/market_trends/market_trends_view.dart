import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/app_item.dart';
import '../../data/models/market_trend.dart';
import '../../data/repositories/app_repository.dart';
import '../../data/repositories/market_trend_repository.dart';
import '../../widgets/app_icon_widget.dart';
import '../../widgets/score_badge.dart';
import '../../widgets/section_header.dart';

class MarketTrendsView extends StatefulWidget {
  final MarketTrendRepository trendRepo;
  final AppRepository? appRepo;
  final ValueChanged<AppItem>? onOpenApp;
  final ValueChanged<AppItem>? onBuildWithAI;
  final ValueChanged<String>? onExploreCategory;

  const MarketTrendsView({
    super.key,
    required this.trendRepo,
    this.appRepo,
    this.onOpenApp,
    this.onBuildWithAI,
    this.onExploreCategory,
  });

  @override
  State<MarketTrendsView> createState() => _MarketTrendsViewState();
}

class _MarketTrendsViewState extends State<MarketTrendsView> {
  String _selectedTimeframe = '30 Days';
  String _selectedCategory = 'All Categories';
  String _sortBy = 'growth'; // 'growth', 'score', 'apps'
  final TextEditingController _searchController = TextEditingController();

  late Future<List<dynamic>> _trendsFuture;
  List<AppItem> _allApps = [];

  @override
  void initState() {
    super.initState();
    _loadTrends();
    _loadApps();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadTrends() {
    _trendsFuture = Future.wait([
      widget.trendRepo.getCategoryTrends(timeframe: _selectedTimeframe),
      widget.trendRepo.getEmergingKeywords(),
    ]);
  }

  Future<void> _loadApps() async {
    if (widget.appRepo == null) return;
    try {
      final apps = await widget.appRepo!.getAllApps();
      if (mounted) {
        setState(() {
          _allApps = apps;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      children: [
        // 1. PAGE HEADER
        SectionHeader(
          title: 'Macro Market Trends & Emerging Signals',
          subtitle:
              'Detect high-growth algorithmic surges, fast-moving consumer search keywords, and underserved indie niches.',
          trailing: _buildHeaderControls(),
        ),
        const SizedBox(height: 18),

        // 2. MAIN FUTURE BUILDER
        FutureBuilder<List<dynamic>>(
          future: _trendsFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(60),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final allTrends = snapshot.data![0] as List<CategoryTrend>;
            final allKeywords = snapshot.data![1] as List<EmergingKeyword>;

            // Top KPI highlight calculations
            final topGrowthCategory = allTrends.isNotEmpty ? allTrends.first : null;
            final topKeyword = allKeywords.isNotEmpty
                ? (List<EmergingKeyword>.from(allKeywords)
                  ..sort((a, b) => b.searchVolumeGrowth.compareTo(a.searchVolumeGrowth)))
                    .first
                : null;
            final highestScoreCategory = allTrends.isNotEmpty
                ? (List<CategoryTrend>.from(allTrends)
                  ..sort((a, b) => b.avgOpportunityScore.compareTo(a.avgOpportunityScore)))
                    .first
                : null;
            final lowCompCount = allKeywords.where((k) => k.competitionLevel == 'Low').length;

            // Apply Filters & Search Query
            final query = _searchController.text.trim().toLowerCase();

            var filteredTrends = allTrends.where((t) {
              final catMatch = _selectedCategory == 'All Categories' ||
                  _selectedCategory == 'All' ||
                  t.category.toLowerCase().contains(_selectedCategory.toLowerCase()) ||
                  _selectedCategory.toLowerCase().contains(t.category.toLowerCase());
              if (!catMatch) return false;
              if (query.isEmpty) return true;
              return t.category.toLowerCase().contains(query) ||
                  t.topApp.toLowerCase().contains(query);
            }).toList();

            // Sort trends
            if (_sortBy == 'score') {
              filteredTrends.sort((a, b) => b.avgOpportunityScore.compareTo(a.avgOpportunityScore));
            } else if (_sortBy == 'apps') {
              filteredTrends.sort((a, b) => b.totalApps.compareTo(a.totalApps));
            } else {
              filteredTrends.sort((a, b) => b.growthRate.compareTo(a.growthRate));
            }

            var filteredKeywords = allKeywords.where((k) {
              final catMatch = _selectedCategory == 'All Categories' ||
                  _selectedCategory == 'All' ||
                  k.category.toLowerCase().contains(_selectedCategory.toLowerCase()) ||
                  _selectedCategory.toLowerCase().contains(k.category.toLowerCase());
              if (!catMatch) return false;
              if (query.isEmpty) return true;
              return k.keyword.toLowerCase().contains(query) ||
                  k.category.toLowerCase().contains(query) ||
                  k.builderOpportunity.toLowerCase().contains(query);
            }).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 3. TOP SUMMARY KPI CARDS
                _buildKpiSummaryRow(
                  isDesktop: isDesktop,
                  topGrowthCat: topGrowthCategory,
                  topKeyword: topKeyword,
                  highestScoreCat: highestScoreCategory,
                  lowCompCount: lowCompCount,
                ),
                const SizedBox(height: 20),

                // 4. SEARCH & FILTER TOOLBAR
                _buildFilterToolbar(),
                const SizedBox(height: 22),

                // 5. MAIN CONTENT COLUMNS
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 6,
                        child: _buildCategoryVelocitySection(filteredTrends),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 4,
                        child: _buildEmergingKeywordsSection(filteredKeywords),
                      ),
                    ],
                  )
                else ...[
                  _buildCategoryVelocitySection(filteredTrends),
                  const SizedBox(height: 24),
                  _buildEmergingKeywordsSection(filteredKeywords),
                ],

                const SizedBox(height: 28),

                // 6. ACTIONABLE INDIE BUILDER PLAYBOOK BANNER
                _buildStrategicIndiePlaybookBanner(),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildHeaderControls() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Category Filter Dropdown
        Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCategory,
              icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.textSecondary),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              items: AppConstants.categories.map((c) {
                return DropdownMenuItem(value: c, child: Text(c));
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedCategory = val;
                  });
                }
              },
            ),
          ),
        ),

        // Timeframe Selector
        Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedTimeframe,
              icon: const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.primary),
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
      ],
    );
  }

  Widget _buildKpiSummaryRow({
    required bool isDesktop,
    required CategoryTrend? topGrowthCat,
    required EmergingKeyword? topKeyword,
    required CategoryTrend? highestScoreCat,
    required int lowCompCount,
  }) {
    final cards = [
      _buildKpiCard(
        title: 'FASTEST GROWING SECTOR',
        mainText: topGrowthCat?.category ?? 'AI & Tools',
        subText: topGrowthCat != null ? '+${topGrowthCat.growthRate.toInt()}% trajectory' : 'Surging demand',
        icon: Icons.rocket_launch_rounded,
        color: AppColors.primary,
        bgColor: AppColors.primaryLight,
        badgeText: 'Top Growth',
        onTap: () {
          if (topGrowthCat != null) {
            setState(() => _selectedCategory = topGrowthCat.category);
          }
        },
      ),
      _buildKpiCard(
        title: 'TOP BREAKOUT KEYWORD',
        mainText: topKeyword?.keyword ?? 'Voice Summarizer',
        subText: topKeyword != null ? '+${topKeyword.searchVolumeGrowth.toInt()}% search growth' : 'High intent',
        icon: Icons.trending_up_rounded,
        color: AppColors.aiPurple,
        bgColor: AppColors.aiPurpleLight,
        badgeText: topKeyword?.competitionLevel ?? 'Low Comp',
        onTap: () {
          if (topKeyword != null) {
            _showKeywordIntelligenceModal(topKeyword);
          }
        },
      ),
      _buildKpiCard(
        title: 'HIGHEST OPPORTUNITY SECTOR',
        mainText: highestScoreCat?.category ?? 'Utilities & Tools',
        subText: highestScoreCat != null
            ? '${highestScoreCat.avgOpportunityScore} Avg Score'
            : 'Weakest Moat',
        icon: Icons.stars_rounded,
        color: AppColors.success,
        bgColor: AppColors.successLight,
        badgeText: 'Highest ROI',
        onTap: () {
          if (highestScoreCat != null) {
            setState(() => _selectedCategory = highestScoreCat.category);
          }
        },
      ),
      _buildKpiCard(
        title: 'LOW-COMPETITION GAPS',
        mainText: '$lowCompCount Monitored Niches',
        subText: 'High search volume with weak incumbent apps',
        icon: Icons.lightbulb_rounded,
        color: AppColors.warning,
        bgColor: AppColors.warningLight,
        badgeText: 'Actionable',
        onTap: () {
          setState(() {
            _selectedCategory = 'All Categories';
          });
        },
      ),
    ];

    if (isDesktop) {
      return Row(
        children: cards
            .map((c) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: c,
                  ),
                ))
            .toList(),
      );
    }

    return Column(
      children: cards
          .map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: c,
              ))
          .toList(),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String mainText,
    required String subText,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required String badgeText,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              mainText,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subText,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterToolbar() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          // Live Search Bar
          SizedBox(
            width: 320,
            height: 40,
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Filter categories, keywords, or apps...',
                hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.primary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surfaceSecondary,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ),

          // Sorting Pill Options
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Sort by:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
              const SizedBox(width: 8),
              _buildSortChip('Highest Growth', 'growth', Icons.trending_up_rounded),
              const SizedBox(width: 6),
              _buildSortChip('Opportunity Score', 'score', Icons.stars_rounded),
              const SizedBox(width: 6),
              _buildSortChip('Tracked Apps', 'apps', Icons.apps_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSortChip(String label, String value, IconData icon) {
    final isSelected = _sortBy == value;
    return InkWell(
      onTap: () => setState(() => _sortBy = value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : AppColors.surfaceSecondary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // CATEGORY GROWTH MOMENTUM SECTION
  // ---------------------------------------------------------
  Widget _buildCategoryVelocitySection(List<CategoryTrend> trends) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.candlestick_chart_rounded, size: 20, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text(
                    'Category Growth Momentum',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                ],
              ),
              Text(
                'Showing ${trends.length} categories • Click to deep dive',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          if (trends.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: Text(
                  'No categories match your search or filter criteria.',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: trends.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final t = trends[index];
                return _buildCategoryItemRow(t);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryItemRow(CategoryTrend t) {
    return InkWell(
      onTap: () => _showCategoryIntelligenceModal(t),
      hoverColor: AppColors.surfaceHover,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Category Icon
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _getCategoryColor(t.category).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      _getCategoryEmoji(t.category),
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Category Title & Tracked Count
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              t.category,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
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
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(
                              '${t.totalApps} apps',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.bolt, size: 13, color: AppColors.primary),
                          const SizedBox(width: 3),
                          const Text(
                            'Breakout: ',
                            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                          Flexible(
                            child: Text(
                              t.topApp,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Sparkline Mini Chart
                SizedBox(
                  width: 90,
                  height: 32,
                  child: CustomPaint(
                    painter: SparklinePainter(
                      data: t.weeklySparkline.isNotEmpty
                          ? t.weeklySparkline
                          : const [20, 30, 45, 60, 75, 85, 95],
                      lineColor: AppColors.primary,
                      fillColor: AppColors.primary,
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Growth Rate & Opportunity Score
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.successLight,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.successBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.north_east_rounded, size: 11, color: AppColors.success),
                          const SizedBox(width: 2),
                          Text(
                            '+${t.growthRate.toInt()}%',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Score: ${t.avgOpportunityScore.toStringAsFixed(1)}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textMuted),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // BREAKOUT SEARCH KEYWORDS SECTION
  // ---------------------------------------------------------
  Widget _buildEmergingKeywordsSection(List<EmergingKeyword> keywords) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.query_stats_rounded, size: 20, color: AppColors.aiPurple),
                  SizedBox(width: 8),
                  Text(
                    'Breakout Search Keywords',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.aiPurpleLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'High Intent',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.aiPurple),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Surging mobile store search volume paired with weak or absent indie app competition.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          if (keywords.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: Text(
                  'No search signals match your filters.',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: keywords.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final kw = keywords[index];
                return _buildKeywordTile(kw);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildKeywordTile(EmergingKeyword kw) {
    return InkWell(
      onTap: () => _showKeywordIntelligenceModal(kw),
      hoverColor: AppColors.surfaceHover,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kw.keyword,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSecondary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          kw.category,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '~${(kw.estimatedMonthlySearches / 1000).toInt()}k/mo',
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Competition Badge
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
                  fontWeight: FontWeight.w700,
                  color: kw.competitionLevel == 'Low' ? AppColors.success : AppColors.warning,
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Growth Badge
            Text(
              '+${kw.searchVolumeGrowth.toInt()}%',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary),
            ),

            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // STRATEGIC INDIE BUILDER PLAYBOOK BANNER
  // ---------------------------------------------------------
  Widget _buildStrategicIndiePlaybookBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.05),
            AppColors.aiPurple.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Icon(Icons.lightbulb_outline_rounded, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Strategic Market Takeaway for Indie Builders & Solo Hackers',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 6),
                const Text(
                  'The intersection of high search velocity (+100%) and Low Competition indicates customer demand where legacy apps either charge predatory subscription fees (\$10+/week) or require forced cloud logins. Shipping an offline-first, honest one-time price MVP captures immediate store ranking and organic downloads.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        if (widget.onBuildWithAI != null && _allApps.isNotEmpty) {
                          widget.onBuildWithAI!(_allApps.first);
                        }
                      },
                      icon: const Icon(Icons.auto_awesome, size: 16, color: Colors.white),
                      label: const Text(
                        'Launch Build With AI Blueprint',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        if (widget.onExploreCategory != null) {
                          widget.onExploreCategory!('Games');
                        }
                      },
                      icon: const Icon(Icons.explore_outlined, size: 16, color: AppColors.primary),
                      label: const Text(
                        'Explore Live App Radar Gaps',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primaryBorder),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // INTERACTIVE MODAL 1: CATEGORY INTELLIGENCE DRILL-DOWN
  // ---------------------------------------------------------
  void _showCategoryIntelligenceModal(CategoryTrend trend) {
    // Find all apps matching this category
    final catLower = trend.category.trim().toLowerCase();
    final matchingApps = _allApps.where((a) {
      final aLower = a.category.trim().toLowerCase();
      return aLower == catLower || aLower.contains(catLower) || catLower.contains(aLower);
    }).toList();
    matchingApps.sort((a, b) => b.opportunityScore.compareTo(a.opportunityScore));

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 720,
            constraints: const BoxConstraints(maxHeight: 650),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Modal Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: _getCategoryColor(trend.category).withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              _getCategoryEmoji(trend.category),
                              style: const TextStyle(fontSize: 22),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${trend.category} Sector Deep Dive',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                            ),
                            Text(
                              '${trend.totalApps} tracked applications • +${trend.growthRate.toInt()}% Market Growth Momentum',
                              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),

                // Vital Stat Badges
                Row(
                  children: [
                    _buildModalStatBox('Opportunity Index', '${trend.avgOpportunityScore}/100', Icons.stars_rounded, AppColors.primary),
                    const SizedBox(width: 12),
                    _buildModalStatBox('Growth Momentum', '+${trend.growthRate.toInt()}%', Icons.trending_up_rounded, AppColors.success),
                    const SizedBox(width: 12),
                    _buildModalStatBox('Top Breakout App', trend.topApp, Icons.bolt_rounded, AppColors.aiPurple),
                  ],
                ),
                const SizedBox(height: 20),

                // Top Breakout Apps in this category
                const Text(
                  'Top Performing & High-Opportunity Apps in this Sector',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),

                Expanded(
                  child: matchingApps.isEmpty
                      ? Center(
                          child: Text(
                            'No individual apps tracked for ${trend.category} yet.',
                            style: const TextStyle(color: AppColors.textMuted),
                          ),
                        )
                      : ListView.separated(
                          itemCount: matchingApps.length.clamp(0, 6),
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, idx) {
                            final app = matchingApps[idx];
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceSecondary,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  AppIconWidget(
                                    iconUrl: app.iconUrl,
                                    iconEmoji: app.iconEmoji,
                                    size: 36,
                                    borderRadius: 8,
                                    fontSize: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          app.name,
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${app.developer} • ★ ${app.rating.toStringAsFixed(1)} (${(app.reviewCount / 1000).toStringAsFixed(1)}k reviews)',
                                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ScoreBadge(score: app.opportunityScore, fontSize: 11),
                                  const SizedBox(width: 8),
                                  OutlinedButton(
                                    onPressed: () {
                                      Navigator.of(ctx).pop();
                                      if (widget.onOpenApp != null) {
                                        widget.onOpenApp!(app);
                                      }
                                    },
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      minimumSize: const Size(60, 32),
                                    ),
                                    child: const Text('Teardown', style: TextStyle(fontSize: 11)),
                                  ),
                                  const SizedBox(width: 6),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.of(ctx).pop();
                                      if (widget.onBuildWithAI != null) {
                                        widget.onBuildWithAI!(app);
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      minimumSize: const Size(60, 32),
                                    ),
                                    child: const Text('Build AI', style: TextStyle(fontSize: 11, color: Colors.white)),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),

                // Footer CTA
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        setState(() => _selectedCategory = trend.category);
                      },
                      icon: const Icon(Icons.filter_list_rounded, size: 16),
                      label: Text('Filter View to ${trend.category}'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        if (widget.onBuildWithAI != null && matchingApps.isNotEmpty) {
                          widget.onBuildWithAI!(matchingApps.first);
                        }
                      },
                      icon: const Icon(Icons.auto_awesome, size: 16, color: Colors.white),
                      label: Text(
                        'Target ${trend.category} in AI Studio',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModalStatBox(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
                  ),
                  Text(
                    value,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // INTERACTIVE MODAL 2: KEYWORD OPPORTUNITY DRILL-DOWN
  // ---------------------------------------------------------
  void _showKeywordIntelligenceModal(EmergingKeyword kw) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 620,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.aiPurpleLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.saved_search_rounded, color: AppColors.aiPurple, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              kw.keyword,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                            ),
                            Text(
                              'Category: ${kw.category} • ~${(kw.estimatedMonthlySearches / 1000).toInt()},000 Searches/Month',
                              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 14),

                // Signal Metrics Row
                Row(
                  children: [
                    _buildModalStatBox(
                      'Search Velocity',
                      '+${kw.searchVolumeGrowth.toInt()}% YoY',
                      Icons.trending_up,
                      AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    _buildModalStatBox(
                      'Incumbent Competition',
                      '${kw.competitionLevel} Saturation',
                      Icons.shield_outlined,
                      kw.competitionLevel == 'Low' ? AppColors.success : AppColors.warning,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Why This is Trending
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.psychology_outlined, size: 16, color: AppColors.primary),
                          SizedBox(width: 6),
                          Text(
                            'Consumer Demand Drivers (Why it is trending)',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        kw.whyTrending,
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Recommended MVP Opportunity
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.aiPurpleLight.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.aiPurple.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.architecture_rounded, size: 16, color: AppColors.aiPurple),
                          SizedBox(width: 6),
                          Text(
                            'Recommended MVP Specification & Strategy',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.aiPurple),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        kw.builderOpportunity,
                        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Dismiss'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        // Find closest app in category or first app to generate blueprint
                        AppItem? candidateApp;
                        final match = _allApps.where((a) => a.category.toLowerCase() == kw.category.toLowerCase()).toList();
                        if (match.isNotEmpty) {
                          candidateApp = match.first;
                        } else if (_allApps.isNotEmpty) {
                          candidateApp = _allApps.first;
                        }
                        if (candidateApp != null && widget.onBuildWithAI != null) {
                          widget.onBuildWithAI!(candidateApp);
                        }
                      },
                      icon: const Icon(Icons.auto_awesome, size: 16, color: Colors.white),
                      label: const Text(
                        'Generate AI Blueprint for this Signal',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------
  // CATEGORY HELPERS
  // ---------------------------------------------------------
  String _getCategoryEmoji(String category) {
    final c = category.toLowerCase();
    if (c.contains('game')) return '🎮';
    if (c.contains('productiv')) return '⚡';
    if (c.contains('utilit') || c.contains('tool')) return '🛠️';
    if (c.contains('health') || c.contains('fitness')) return '🏃';
    if (c.contains('ai') || c.contains('machine')) return '🤖';
    if (c.contains('financ')) return '💳';
    if (c.contains('educat')) return '📚';
    if (c.contains('photo') || c.contains('video')) return '📸';
    if (c.contains('lifestyle')) return '🌿';
    if (c.contains('entertain')) return '🍿';
    if (c.contains('business')) return '💼';
    if (c.contains('medic')) return '🩺';
    if (c.contains('graphic') || c.contains('design')) return '🎨';
    if (c.contains('communicat')) return '💬';
    if (c.contains('travel')) return '✈️';
    return '📱';
  }

  Color _getCategoryColor(String category) {
    final c = category.toLowerCase();
    if (c.contains('game')) return const Color(0xFFE11D48);
    if (c.contains('ai')) return AppColors.aiPurple;
    if (c.contains('health')) return const Color(0xFF10B981);
    if (c.contains('financ')) return const Color(0xFF059669);
    if (c.contains('productiv')) return AppColors.primary;
    if (c.contains('photo')) return const Color(0xFFD97706);
    if (c.contains('utilit')) return const Color(0xFF475569);
    return AppColors.primary;
  }
}

// ---------------------------------------------------------
// SMOOTH BEZIER SPARKLINE PAINTER
// ---------------------------------------------------------
class SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color lineColor;
  final Color fillColor;

  SparklinePainter({
    required this.data,
    required this.lineColor,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final minVal = data.reduce((a, b) => a < b ? a : b);
    final maxVal = data.reduce((a, b) => a > b ? a : b);
    final range = (maxVal - minVal) == 0 ? 1.0 : (maxVal - minVal);

    final path = Path();
    final fillPath = Path();

    final stepX = size.width / (data.length - 1);
    final points = <Offset>[];

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final normalized = (data[i] - minVal) / range;
      final y = size.height - (normalized * (size.height - 8)) - 4;
      points.add(Offset(x, y));
    }

    path.moveTo(points[0].dx, points[0].dy);
    fillPath.moveTo(points[0].dx, size.height);
    fillPath.lineTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final controlX = (p0.dx + p1.dx) / 2;
      path.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
      fillPath.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
    }

    fillPath.lineTo(points.last.dx, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [fillColor.withValues(alpha: 0.28), fillColor.withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    // End point highlight dot
    final dotPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(points.last, 3.5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant SparklinePainter oldDelegate) => true;
}
