import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/mock/mock_data.dart';
import '../../widgets/section_header.dart';

class CompetitorsView extends StatelessWidget {
  const CompetitorsView({super.key});

  @override
  Widget build(BuildContext context) {
    final competitors = MockData.competitorsForNoteTaker;
    final allFeatures = [
      'AI Summary',
      'Action Item Extraction',
      'Speaker Diarization',
      'Bot-Free Audio Recording',
      'Offline Transcription',
      'Notion & Slack Export',
      'Custom Vocabulary',
    ];

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SectionHeader(
          title: 'Competitor Intelligence Matrix',
          subtitle:
              'Benchmark market leaders and emerging alternatives to detect unaddressed feature gaps and pricing moats.',
        ),
        // Overview cards
        Row(
          children: [
            Expanded(
              child: _statPill('Benchmark Focus', 'AI Note Taker', Icons.radar, AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _statPill('Direct Rivals', '3 Tracked', Icons.groups, AppColors.success),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _statPill('Key Market Gap', 'Bot-Free + Offline Audio', Icons.bolt, AppColors.warning),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Competitor Cards Row
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: competitors.map((c) {
            final isFocus = c.name.contains('Focus App');
            return Container(
              width: 280,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isFocus ? AppColors.primaryLight.withValues(alpha: 0.4) : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isFocus ? AppColors.primary : AppColors.border,
                  width: isFocus ? 1.5 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          c.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isFocus ? AppColors.primary : AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isFocus)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('FOCUS', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    c.marketPosition,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${c.rating} ⭐ (${(c.reviews / 1000).toStringAsFixed(1)}k)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      Text(c.pricing, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        // Full Feature Matrix Table
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
              const Text(
                'Feature Coverage Comparison Matrix',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  horizontalMargin: 16,
                  columnSpacing: 28,
                  headingRowColor: WidgetStateProperty.all(AppColors.surfaceSecondary),
                  columns: [
                    const DataColumn(label: Text('Feature / Capability', style: TextStyle(fontWeight: FontWeight.w700))),
                    ...competitors.map((c) => DataColumn(
                          label: Text(
                            c.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: c.name.contains('Focus') ? AppColors.primary : AppColors.textPrimary,
                            ),
                          ),
                        )),
                  ],
                  rows: allFeatures.map((feat) {
                    return DataRow(
                      cells: [
                        DataCell(Text(feat, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                        ...competitors.map((c) {
                          final hasFeature = c.featureMatrix[feat] ?? false;
                          return DataCell(
                            hasFeature
                                ? const Icon(Icons.check_circle, color: AppColors.success, size: 18)
                                : const Icon(Icons.remove, color: AppColors.textMuted, size: 18),
                          );
                        }),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statPill(String title, String val, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              Text(val, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }
}
