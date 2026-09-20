import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/app_item.dart';
import '../../data/repositories/app_repository.dart';
import '../../widgets/filter_bar.dart';
import '../../widgets/score_badge.dart';
import '../../widgets/section_header.dart';
import '../../widgets/app_icon_widget.dart';
import '../../core/utils/formatters.dart';

class AppExplorerView extends StatefulWidget {
  final AppRepository appRepo;
  final ValueChanged<AppItem> onOpenApp;

  const AppExplorerView({
    super.key,
    required this.appRepo,
    required this.onOpenApp,
  });

  @override
  State<AppExplorerView> createState() => _AppExplorerViewState();
}

class _AppExplorerViewState extends State<AppExplorerView> {
  String _search = '';
  String _category = 'All Categories';
  String _platform = 'All Platforms';

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SectionHeader(
          title: 'App Intelligence Explorer',
          subtitle: 'Search and inspect raw metrics, store performance, and revenue estimates.',
        ),
        FilterBar(
          searchQuery: _search,
          onSearchChanged: (val) => setState(() => _search = val),
          selectedCategory: _category,
          onCategoryChanged: (val) => setState(() => _category = val),
          selectedPlatform: _platform,
          onPlatformChanged: (val) => setState(() => _platform = val),
        ),
        FutureBuilder<List<AppItem>>(
          future: widget.appRepo.searchApps(
            _search,
            category: _category,
            platform: _platform,
          ),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ));
            }

            final apps = snapshot.data!;
            if (apps.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Text('No apps found matching criteria.'),
                ),
              );
            }

            return Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  horizontalMargin: 20,
                  columnSpacing: 24,
                  headingRowColor: WidgetStateProperty.all(AppColors.surfaceSecondary),
                  columns: const [
                    DataColumn(label: Text('App', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
                    DataColumn(label: Text('Category', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
                    DataColumn(label: Text('Platform', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
                    DataColumn(label: Text('Rank', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
                    DataColumn(label: Text('Rating & Reviews', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
                    DataColumn(label: Text('Est. Downloads', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
                    DataColumn(label: Text('Est. Revenue', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
                    DataColumn(label: Text('Growth', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
                    DataColumn(label: Text('Opportunity Score', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
                    DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
                  ],
                  rows: apps.map((app) {
                    return DataRow(
                      cells: [
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AppIconWidget(
                                iconUrl: app.iconUrl,
                                iconEmoji: app.iconEmoji,
                                size: 28,
                                borderRadius: 6,
                                fontSize: 16,
                              ),
                              const SizedBox(width: 10),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(app.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                  Text(app.developer, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        DataCell(Text(app.category, style: const TextStyle(fontSize: 12))),
                        DataCell(Text(app.platform, style: const TextStyle(fontSize: 12))),
                        DataCell(Text('#${app.ranking}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 14),
                              const SizedBox(width: 4),
                              Text('${app.rating} (${AppFormatters.formatNumber(app.reviewCount)})', style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                        DataCell(Text('${AppFormatters.formatNumber(app.downloadsEstimate)}/mo', style: const TextStyle(fontSize: 12))),
                        DataCell(Text(AppFormatters.formatCurrency(app.revenueEstimate), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.successLight,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '+${app.growthRate.toInt()}%',
                              style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w700, fontSize: 11),
                            ),
                          ),
                        ),
                        DataCell(ScoreBadge(score: app.opportunityScore, fontSize: 11)),
                        DataCell(
                          OutlinedButton(
                            onPressed: () => widget.onOpenApp(app),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            ),
                            child: const Text('Analyze', style: TextStyle(fontSize: 11)),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
