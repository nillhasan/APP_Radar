import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/app_item.dart';
import '../../widgets/score_badge.dart';
import '../../widgets/signal_bar.dart';
import '../../core/utils/formatters.dart';

class AppDetailView extends StatelessWidget {
  final AppItem app;
  final VoidCallback onBack;
  final ValueChanged<AppItem> onBuildWithAI;

  const AppDetailView({
    super.key,
    required this.app,
    required this.onBack,
    required this.onBuildWithAI,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Navigation Breadcrumb & Back
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Back to Opportunities'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              'Opportunities / ${app.category} / ${app.name}',
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Hero Card
        _buildHeroCard(context),
        const SizedBox(height: 20),

        // Screenshots Gallery
        _buildScreenshotGallery(),
        const SizedBox(height: 20),

        // AI Summary & 5-Signal Breakdown Grid
        if (isDesktop)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 5, child: _buildAiTeardownCard()),
              const SizedBox(width: 20),
              Expanded(flex: 3, child: _buildSignalsRadarCard()),
            ],
          )
        else ...[
          _buildAiTeardownCard(),
          const SizedBox(height: 20),
          _buildSignalsRadarCard(),
        ],
        const SizedBox(height: 20),

        // Features vs Pain Points Split Grid
        if (isDesktop)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildListCard('Core & AI Features', app.coreFeatures + app.aiFeatures, Icons.check_circle, AppColors.success)),
              const SizedBox(width: 20),
              Expanded(child: _buildListCard('User Pain Points & Gaps', app.userPainPoints, Icons.warning_amber_rounded, AppColors.warning)),
            ],
          )
        else ...[
          _buildListCard('Core & AI Features', app.coreFeatures + app.aiFeatures, Icons.check_circle, AppColors.success),
          const SizedBox(height: 20),
          _buildListCard('User Pain Points & Gaps', app.userPainPoints, Icons.warning_amber_rounded, AppColors.warning),
        ],
        const SizedBox(height: 20),

        // Build Opportunity & MVP Action Card
        _buildBuildOpportunityCard(context),
      ],
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Container(
      padding: const EdgeInsets.all(24),
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
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(app.iconEmoji, style: const TextStyle(fontSize: 34)),
              ),
              const SizedBox(width: 18),
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
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            app.category,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSecondary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            app.platform,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Published by ${app.developer} • Rank #${app.ranking} Top Grossing',
                      style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              if (isDesktop) ...[
                ScoreBadge(score: app.opportunityScore, fontSize: 16),
                const SizedBox(width: 16),
                FilledButton.icon(
                  onPressed: () => onBuildWithAI(app),
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: const Text('Build This App'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                ),
              ],
            ],
          ),
          if (!isDesktop) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ScoreBadge(score: app.opportunityScore, fontSize: 14),
                FilledButton.icon(
                  onPressed: () => onBuildWithAI(app),
                  icon: const Icon(Icons.auto_awesome, size: 16),
                  label: const Text('Build This App'),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),
          // Metrics Row
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              _metricBlock('Rating & Reviews', '${app.rating} ⭐ (${AppFormatters.formatNumber(app.reviewCount)})'),
              _metricBlock('Est. Downloads', '${AppFormatters.formatNumber(app.downloadsEstimate)}/mo'),
              _metricBlock('Est. Revenue', '${AppFormatters.formatCurrency(app.revenueEstimate)}/mo'),
              _metricBlock('Growth Velocity', '+${app.growthRate.toInt()}% (90D)'),
              _metricBlock('Monetization', app.monetization),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricBlock(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildScreenshotGallery() {
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
            children: const [
              Text(
                'Mobile Workflow Screenshots',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              Text(
                'Deconstructed UI Flows',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: app.screenshots.length,
              itemBuilder: (context, idx) {
                final shotTitle = app.screenshots[idx];
                return Container(
                  width: 220,
                  margin: const EdgeInsets.only(right: 14),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.smartphone, size: 36, color: AppColors.primary),
                      const SizedBox(height: 12),
                      Text(
                        'Screen #${idx + 1}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        shotTitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiTeardownCard() {
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
            children: const [
              Icon(Icons.auto_awesome, size: 18, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'AI Teardown & Strategic Analysis',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          _teardownItem('What this app does', app.whatItDoes),
          _teardownItem('Target User Segment', app.targetUser),
          _teardownItem('Why it is growing', app.whyGrowing),
          _teardownItem('Core Value Proposition', app.coreValueProp),
          _teardownItem('Monetization Model', app.monetization),
        ],
      ),
    );
  }

  Widget _teardownItem(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
          const SizedBox(height: 4),
          Text(content, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildSignalsRadarCard() {
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
              const Text(
                '5-Signal Radar Breakdown',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              ScoreBadge(score: app.opportunityScore, fontSize: 12),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          SignalBar(label: 'Growth Signal', value: app.signals.growthSignal),
          const SizedBox(height: 8),
          SignalBar(label: 'Revenue Signal', value: app.signals.revenueSignal),
          const SizedBox(height: 8),
          SignalBar(label: 'Ranking Signal', value: app.signals.rankingSignal),
          const SizedBox(height: 8),
          SignalBar(label: 'Review Signal', value: app.signals.reviewSignal),
          const SizedBox(height: 8),
          SignalBar(label: 'Market Opportunity Signal', value: app.signals.marketSignal),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: const [
                Icon(Icons.info_outline, size: 16, color: AppColors.primary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Composite score weighted by market demand, revenue velocity, and store visibility momentum.',
                    style: TextStyle(fontSize: 11, color: AppColors.primary, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListCard(String title, List<String> items, IconData icon, Color iconColor) {
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
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 16, color: iconColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBuildOpportunityCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.rocket_launch, color: Colors.amber, size: 22),
              SizedBox(width: 10),
              Text(
                'AI Build Opportunity & Suggested MVP',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Capitalize on competitor gaps by shipping a focused, privacy-first mobile client solving verified user frustrations.',
            style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8), height: 1.4),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              for (final mvp in app.suggestedMvp)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check, size: 14, color: AppColors.success),
                      const SizedBox(width: 6),
                      Text(mvp, style: const TextStyle(fontSize: 12, color: Colors.white)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => onBuildWithAI(app),
            icon: const Icon(Icons.auto_awesome, size: 18),
            label: const Text('Generate 14-Section Build Blueprint'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}
