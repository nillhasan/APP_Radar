import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/app_item.dart';
import '../../data/repositories/opportunity_repository.dart';
import '../../widgets/score_badge.dart';
import '../../widgets/section_header.dart';

class DailyReportPreviewView extends StatelessWidget {
  final OpportunityRepository oppRepo;
  final ValueChanged<AppItem> onOpenApp;

  const DailyReportPreviewView({
    super.key,
    required this.oppRepo,
    required this.onOpenApp,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AppItem>>(
      future: oppRepo.getTopOpportunities(limit: 5),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final topApps = snapshot.data!;

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SectionHeader(
              title: '🚀 Daily App Opportunity Intelligence Report',
              subtitle: 'September 19, 2026 • Automated Executive Brief by AppRadar AI Engine',
            ),
            // Market Snapshot Card
            Container(
              padding: const EdgeInsets.all(22),
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
                      Icon(Icons.public, color: AppColors.primary, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Market Snapshot & Executive Summary',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Over the past 24 hours, our algorithms ingested telemetry from 128 mobile apps across US, UK, and Canadian app stores. Key signal: surging dissatisfaction with meeting bots and bloated subscriptions is opening an immediate window for privacy-first, offline-capable mobile utilities.',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: const [
                      _Badge('Top Category: AI & Productivity (+120%)', AppColors.primaryLight, AppColors.primary),
                      _Badge('High-Conviction Plays: 5 Apps', AppColors.successLight, AppColors.success),
                      _Badge('Avg Sub Price: \$12.50/mo', AppColors.surfaceSecondary, AppColors.textSecondary),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Top 5 Opportunity Deep-Dives',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 14),

            // 5 Opportunities Teardown
            for (int i = 0; i < topApps.length; i++) ...[
              _buildReportTeardownItem(i + 1, topApps[i]),
              const SizedBox(height: 16),
            ],
          ],
        );
      },
    );
  }

  Widget _buildReportTeardownItem(int rank, AppItem app) {
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '#$rank',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(app.iconEmoji, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Text(
                          app.name,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSecondary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(app.category, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${app.rating} ⭐ (${(app.reviewCount / 1000).toStringAsFixed(1)}k reviews) • +${app.growthRate.toInt()}% growth • ${app.monetization}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              ScoreBadge(score: app.opportunityScore),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(),
          const SizedBox(height: 12),
          _detailLine('Why Interesting', app.whyGrowing),
          _detailLine('Core Features', app.coreFeatures.join(' • ')),
          _detailLine('Observed User Gaps', app.userPainPoints.join(' • ')),
          _detailLine('Suggested MVP Playbook', app.suggestedMvp.join(' • ')),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonal(
              onPressed: () => onOpenApp(app),
              child: const Text('Open App Teardown'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailLine(String label, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            TextSpan(text: content),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color bg;
  final Color textColor;
  const _Badge(this.text, this.bg, this.textColor);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor)),
    );
  }
}
