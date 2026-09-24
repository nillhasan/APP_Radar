import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/app_item.dart';
import '../../data/repositories/opportunity_repository.dart';
import '../../data/repositories/watchlist_repository.dart';
import '../../services/export/file_export_service.dart';
import '../../widgets/filter_bar.dart';
import '../../widgets/score_badge.dart';
import '../../widgets/section_header.dart';
import '../../widgets/signal_bar.dart';
import '../../widgets/app_icon_widget.dart';

class OpportunitiesView extends StatefulWidget {
  final OpportunityRepository oppRepo;
  final ValueChanged<AppItem> onOpenApp;
  final WatchlistRepository? watchlistRepo;

  const OpportunitiesView({
    super.key,
    required this.oppRepo,
    required this.onOpenApp,
    this.watchlistRepo,
  });

  @override
  State<OpportunitiesView> createState() => _OpportunitiesViewState();
}

class _OpportunitiesViewState extends State<OpportunitiesView> {
  String _search = '';
  String _category = 'All Categories';
  String _platform = 'All Platforms';
  String _sortBy = 'Opportunity Score';
  Set<String> _watchlistedAppIds = {};
  late Future<List<AppItem>> _oppsFuture;
  int _visibleCount = 20;

  @override
  void initState() {
    super.initState();
    _loadOpportunities();
    _loadWatchlist();
  }

  void _loadOpportunities() {
    _visibleCount = 20;
    _oppsFuture = widget.oppRepo.getFilteredOpportunities(
      category: _category,
      platform: _platform,
      sortBy: _sortBy,
    );
  }

  Future<void> _loadWatchlist() async {
    if (widget.watchlistRepo != null) {
      final saved = await widget.watchlistRepo!.getWatchlistedApps();
      if (mounted) {
        setState(() {
          _watchlistedAppIds = saved.map((a) => a.id).toSet();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SectionHeader(
            title: 'Opportunity Discovery Matrix',
            subtitle:
                'Filter and evaluate vetted mobile application opportunities ranked by multi-signal algorithms.',
          ),
          FilterBar(
            searchQuery: _search,
            onSearchChanged: (val) => setState(() => _search = val),
            selectedCategory: _category,
            onCategoryChanged: (val) {
              setState(() {
                _category = val;
                _loadOpportunities();
              });
            },
            selectedPlatform: _platform,
            onPlatformChanged: (val) {
              setState(() {
                _platform = val;
                _loadOpportunities();
              });
            },
            selectedSort: _sortBy,
            onSortChanged: (val) {
              setState(() {
                _sortBy = val;
                _loadOpportunities();
              });
            },
          ),
          FutureBuilder<List<AppItem>>(
            future: _oppsFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ));
            }

            var apps = snapshot.data!;
            if (_search.isNotEmpty) {
              apps = apps.where((a) =>
                  a.name.toLowerCase().contains(_search.toLowerCase()) ||
                  a.description.toLowerCase().contains(_search.toLowerCase())).toList();
            }

            if (apps.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(40),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.search_off, size: 48, color: AppColors.textMuted),
                    SizedBox(height: 12),
                    Text(
                      'No matching opportunities found',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Try adjusting your search keywords or filter criteria.',
                      style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                    ),
                  ],
                ),
              );
            }

            final visibleApps = apps.take(_visibleCount).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildExportToolbar(apps),
                const SizedBox(height: 14),
                for (final app in visibleApps) ...[
                  _buildOpportunityCard(app),
                  const SizedBox(height: 16),
                ],
                if (apps.length > _visibleCount)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: OutlinedButton.icon(
                        onPressed: () => setState(() => _visibleCount += 20),
                        icon: const Icon(Icons.expand_more_rounded),
                        label: Text('Load More Opportunities (${apps.length - _visibleCount} remaining)'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildExportToolbar(List<AppItem> apps) {
    const exportService = FileExportService();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_outlined, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                '${apps.length} High-Potential Opportunities',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  exportService.downloadAppsListCsv(apps, fileName: 'AppRadar_Opportunities_Export.csv');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('📥 Exported ${apps.length} opportunities to CSV!'),
                      backgroundColor: AppColors.primary,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.download, size: 15),
                label: const Text('Export CSV', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  final md = exportService.generateNotionMarkdownTable(apps, title: 'AppRadar Vetted Opportunities');
                  await Clipboard.setData(ClipboardData(text: md));
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('📋 Copied Notion Table for ${apps.length} opportunities! Paste into Notion.'),
                        backgroundColor: AppColors.success,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.table_chart_outlined, size: 15),
                label: const Text('Copy Notion Table', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOpportunityCard(AppItem app) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppIconWidget(
                iconUrl: app.iconUrl,
                iconEmoji: app.iconEmoji,
                size: 46,
                borderRadius: 10,
                fontSize: 24,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            app.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            app.category,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSecondary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            app.platform,
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'by ${app.developer} • Rank #${app.ranking} in Category',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              ScoreBadge(score: app.opportunityScore, fontSize: 14),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            app.description,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 16),
          // Signals breakdown bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondary.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: isDesktop
                ? Row(
                    children: [
                      Expanded(child: SignalBar(label: 'Growth Signal', value: app.signals.growthSignal)),
                      const SizedBox(width: 16),
                      Expanded(child: SignalBar(label: 'Revenue Signal', value: app.signals.revenueSignal)),
                      const SizedBox(width: 16),
                      Expanded(child: SignalBar(label: 'Ranking Signal', value: app.signals.rankingSignal)),
                      const SizedBox(width: 16),
                      Expanded(child: SignalBar(label: 'Review Signal', value: app.signals.reviewSignal)),
                    ],
                  )
                : Column(
                    children: [
                      SignalBar(label: 'Growth Signal', value: app.signals.growthSignal),
                      SignalBar(label: 'Revenue Signal', value: app.signals.revenueSignal),
                      SignalBar(label: 'Review Signal', value: app.signals.reviewSignal),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 6,
                children: [
                  _metricPill(Icons.star, '${app.rating} (${(app.reviewCount / 1000).toStringAsFixed(1)}k)'),
                  _metricPill(Icons.trending_up, '+${app.growthRate.toInt()}% 30D'),
                  _metricPill(Icons.attach_money, 'Est. \$${(app.revenueEstimate / 1000).toStringAsFixed(0)}k/mo'),
                ],
              ),
              Row(
                children: [
                  if (widget.watchlistRepo != null) ...[
                    IconButton(
                      tooltip: _watchlistedAppIds.contains(app.id)
                          ? 'Remove from Watchlist'
                          : 'Save to Watchlist',
                      icon: Icon(
                        _watchlistedAppIds.contains(app.id)
                            ? Icons.bookmark
                            : Icons.bookmark_border,
                        color: _watchlistedAppIds.contains(app.id)
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        size: 22,
                      ),
                      onPressed: () async {
                        final isSaved = _watchlistedAppIds.contains(app.id);
                        await widget.watchlistRepo!.toggleWatchlist(app.id);
                        if (mounted) {
                          setState(() {
                            if (isSaved) {
                              _watchlistedAppIds.remove(app.id);
                            } else {
                              _watchlistedAppIds.add(app.id);
                            }
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isSaved
                                  ? 'Removed ${app.name} from Watchlist'
                                  : 'Saved ${app.name} to Watchlist!'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(width: 6),
                  ],
                  FilledButton.icon(
                    onPressed: () => widget.onOpenApp(app),
                    icon: const Icon(Icons.analytics_outlined, size: 16),
                    label: const Text('View Full Analysis'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricPill(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
      ],
    );
  }
}
