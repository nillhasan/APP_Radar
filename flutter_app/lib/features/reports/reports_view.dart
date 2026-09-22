import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/report_item.dart';
import '../../data/repositories/report_repository.dart';
import '../../widgets/section_header.dart';

class ReportsView extends StatefulWidget {
  final ReportRepository reportRepo;
  final VoidCallback onViewDailyReport;

  const ReportsView({
    super.key,
    required this.reportRepo,
    required this.onViewDailyReport,
  });

  @override
  State<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<ReportsView> {
  String _selectedFilter = 'All';
  late Future<List<ReportItem>> _reportsFuture;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  void _loadReports() {
    _reportsFuture = widget.reportRepo.getReports(type: _selectedFilter);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          SectionHeader(
            title: 'Automated Intelligence Reports',
            subtitle: 'Scheduled market synthesis digests delivered daily, weekly, and monthly.',
            trailing: Wrap(
              spacing: 8,
              children: ['All', 'Daily', 'Weekly', 'Monthly'].map((type) {
                final isSel = _selectedFilter == type;
                return ChoiceChip(
                  label: Text(type),
                  selected: isSel,
                  onSelected: (_) {
                    setState(() {
                      _selectedFilter = type;
                      _loadReports();
                    });
                  },
                );
              }).toList(),
            ),
          ),
          FutureBuilder<List<ReportItem>>(
            future: _reportsFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ));
            }

            final reports = snapshot.data!;

            return Column(
              children: reports.map((r) {
                final isDaily = r.type == 'Daily';
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
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
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  r.type.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '${r.date.month}/${r.date.day}/${r.date.year}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.successLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle, size: 12, color: AppColors.success),
                                const SizedBox(width: 4),
                                Text(
                                  r.status,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.success),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        r.title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        r.marketSummary,
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Wrap(
                            spacing: 18,
                            children: [
                              _infoStat('Apps Analyzed', '${r.appsAnalyzed}'),
                              _infoStat('Opportunities Found', '${r.opportunitiesFound}'),
                              _infoStat('Top Opportunity', '${r.topOpportunityName} (${r.topOpportunityScore}/100)'),
                            ],
                          ),
                          FilledButton.icon(
                            onPressed: isDaily ? widget.onViewDailyReport : () {},
                            icon: const Icon(Icons.visibility_outlined, size: 16),
                            label: const Text('Read Digest'),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _infoStat(String label, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(val, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      ],
    );
  }
}
