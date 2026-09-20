import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/app_item.dart';
import '../../data/repositories/watchlist_repository.dart';
import '../../services/export/file_export_service.dart';
import '../../services/subscription/subscription_service.dart';
import '../../widgets/pricing/pricing_modal.dart';
import '../../widgets/score_badge.dart';
import '../../widgets/signal_bar.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/app_icon_widget.dart';
import 'widgets/negative_review_mining_card.dart';
import 'widgets/competitor_avatar_stack.dart';
import 'widgets/regional_breakdown_bar.dart';

class AppDetailView extends StatefulWidget {
  final AppItem app;
  final VoidCallback onBack;
  final ValueChanged<AppItem> onBuildWithAI;
  final WatchlistRepository? watchlistRepo;
  final SubscriptionService? subscriptionService;
  final List<AppItem>? allApps;
  final ValueChanged<AppItem>? onSelectCompetitor;

  const AppDetailView({
    super.key,
    required this.app,
    required this.onBack,
    required this.onBuildWithAI,
    this.watchlistRepo,
    this.subscriptionService,
    this.allApps,
    this.onSelectCompetitor,
  });

  @override
  State<AppDetailView> createState() => _AppDetailViewState();
}

class _AppDetailViewState extends State<AppDetailView> {
  AppItem get app => widget.app;
  bool _isWatchlisted = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkWatchlist();
    if (widget.subscriptionService != null && widget.subscriptionService!.canViewTeardown(app.id)) {
      widget.subscriptionService!.recordTeardownView(app.id);
    }
  }

  Future<void> _checkWatchlist() async {
    if (widget.watchlistRepo != null) {
      final saved = await widget.watchlistRepo!.isWatchlisted(app.id);
      if (mounted) setState(() => _isWatchlisted = saved);
    }
  }

  Future<void> _toggleWatchlist() async {
    if (widget.watchlistRepo == null || _isLoading) return;
    setState(() => _isLoading = true);
    await widget.watchlistRepo!.toggleWatchlist(app.id);
    if (mounted) {
      setState(() {
        _isWatchlisted = !_isWatchlisted;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isWatchlisted
              ? 'Saved ${app.name} to your Watchlist!'
              : 'Removed ${app.name} from your Watchlist'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _launchStoreUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Navigation Breadcrumb & Back
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: widget.onBack,
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Back to Opportunities'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
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

        // Direct Competitor Avatar Stack (1-click quick switch)
        if (widget.allApps != null && widget.allApps!.isNotEmpty) ...[
          CompetitorAvatarStack(
            currentApp: app,
            allApps: widget.allApps!,
            onSelectCompetitor: (competitor) {
              if (widget.onSelectCompetitor != null) {
                widget.onSelectCompetitor!(competitor);
              }
            },
          ),
          const SizedBox(height: 20),
        ],

        // 30-Day Regional Revenue & Market Share Distribution
        if (app.regionalBreakdown != null && app.regionalBreakdown!.isNotEmpty) ...[
          RegionalBreakdownBar(
            regionalBreakdown: app.regionalBreakdown!,
            totalRevenue: app.revenueEstimate,
          ),
          const SizedBox(height: 20),
        ],

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

        // 1★ & 2★ Negative Review & Pain Point Mining
        if (app.negativeReviews != null) ...[
          NegativeReviewMiningCard(mining: app.negativeReviews!, appName: app.name),
          const SizedBox(height: 20),
        ],

        // Build Opportunity & MVP Action Card
        _buildBuildOpportunityCard(context),
      ],
    );
  }

  Widget _buildHeroCard(BuildContext context) {
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
              AppIconWidget(
                iconUrl: app.iconUrl,
                iconEmoji: app.iconEmoji,
                size: 64,
                borderRadius: 14,
                fontSize: 34,
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          app.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
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
              const SizedBox(width: 16),
              ScoreBadge(score: app.opportunityScore, fontSize: 16),
            ],
          ),
          const SizedBox(height: 18),
          // Action Buttons Bar
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _buildExportButton(),
              if (app.appUrl != null && app.appUrl!.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () => _launchStoreUrl(app.appUrl!),
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                  label: const Text('Store Page ↗'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primaryBorder),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              if (widget.watchlistRepo != null)
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _toggleWatchlist,
                  icon: Icon(
                    _isWatchlisted ? Icons.bookmark : Icons.bookmark_border,
                    size: 18,
                    color: _isWatchlisted ? AppColors.primary : AppColors.textSecondary,
                  ),
                  label: Text(_isWatchlisted ? 'In Watchlist' : 'Add to Watchlist'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _isWatchlisted ? AppColors.primary : AppColors.textPrimary,
                    side: BorderSide(color: _isWatchlisted ? AppColors.primary : AppColors.border),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              FilledButton.icon(
                onPressed: () => widget.onBuildWithAI(app),
                icon: const Icon(Icons.auto_awesome, size: 18),
                label: const Text('Build This App'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
              ),
            ],
          ),
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

  void _openScreenshotLightbox(BuildContext context, int initialIndex) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (ctx) {
        int currentIndex = initialIndex;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final currentShot = app.screenshots[currentIndex];
            final isUrl = currentShot.startsWith('http://') || currentShot.startsWith('https://');

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Image or Mockup Box
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 720, maxWidth: 460),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Modal top bar
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              color: AppColors.surfaceSecondary,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Screen ${currentIndex + 1} of ${app.screenshots.length}',
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 20, color: AppColors.textSecondary),
                                    onPressed: () => Navigator.of(ctx).pop(),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            ),
                            Flexible(
                              child: isUrl
                                  ? Image.network(
                                      currentShot,
                                      fit: BoxFit.contain,
                                      loadingBuilder: (ctx, child, progress) {
                                        if (progress == null) return child;
                                        return const Center(
                                          child: Padding(
                                            padding: EdgeInsets.all(40),
                                            child: CircularProgressIndicator(),
                                          ),
                                        );
                                      },
                                      errorBuilder: (ctx, err, stack) => Padding(
                                        padding: const EdgeInsets.all(40),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: const [
                                            Icon(Icons.broken_image, size: 48, color: AppColors.textMuted),
                                            SizedBox(height: 12),
                                            Text('Failed to load screenshot image', style: TextStyle(color: AppColors.textMuted)),
                                          ],
                                        ),
                                      ),
                                    )
                                  : Padding(
                                      padding: const EdgeInsets.all(32),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.smartphone, size: 64, color: AppColors.primary),
                                          const SizedBox(height: 16),
                                          Text(
                                            currentShot,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                          ),
                                        ],
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Prev button
                  if (currentIndex > 0)
                    Positioned(
                      left: 10,
                      child: IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.9),
                          foregroundColor: Colors.black87,
                        ),
                        icon: const Icon(Icons.chevron_left, size: 30),
                        onPressed: () => setDialogState(() => currentIndex--),
                      ),
                    ),
                  // Next button
                  if (currentIndex < app.screenshots.length - 1)
                    Positioned(
                      right: 10,
                      child: IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.9),
                          foregroundColor: Colors.black87,
                        ),
                        icon: const Icon(Icons.chevron_right, size: 30),
                        onPressed: () => setDialogState(() => currentIndex++),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildScreenshotGallery() {
    if (app.screenshots.isEmpty) return const SizedBox.shrink();

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
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.phone_iphone, size: 18, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text(
                    'Mobile Workflow Screenshots',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                ],
              ),
              Text(
                '${app.screenshots.length} Deconstructed UI Flows • Click to Zoom',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 310,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: app.screenshots.length,
              itemBuilder: (context, idx) {
                final shot = app.screenshots[idx];
                final isUrl = shot.startsWith('http://') || shot.startsWith('https://');

                return MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => _openScreenshotLightbox(context, idx),
                    child: Container(
                      width: 170,
                      margin: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSecondary,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (isUrl)
                            Image.network(
                              shot,
                              fit: BoxFit.cover,
                              alignment: Alignment.topCenter,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Screen #${idx + 1}',
                                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stack) => _buildMockupFallback(idx, shot),
                            )
                          else
                            _buildMockupFallback(idx, shot),

                          // Top-right zoom badge
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(Icons.fullscreen, size: 14, color: Colors.white),
                            ),
                          ),

                          // Bottom screen label badge
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.75),
                                  ],
                                ),
                              ),
                              child: Text(
                                isUrl ? 'Screen #${idx + 1}' : shot,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMockupFallback(int idx, String title) {
    return Container(
      padding: const EdgeInsets.all(14),
      color: AppColors.surfaceSecondary,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.smartphone, size: 32, color: AppColors.primary),
          ),
          const SizedBox(height: 12),
          Text(
            'Screen #${idx + 1}',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
          ),
          const SizedBox(height: 6),
          Text(
            title.startsWith('http') ? 'Store Preview' : title,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildAiTeardownCard() {
    final isLocked = widget.subscriptionService != null && !widget.subscriptionService!.canViewTeardown(app.id);

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
          if (isLocked) ...[
            _teardownItem('What this app does', app.whatItDoes),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppColors.aiPurpleLight,
                    AppColors.primaryLight,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  const Icon(Icons.lock_outline, size: 32, color: AppColors.aiPurple),
                  const SizedBox(height: 10),
                  const Text(
                    'Daily Free Teardown Limit Reached (3/3)',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'You have explored all 3 complimentary AI opportunity teardowns today. Upgrade to Pro Builder for unlimited teardowns, full architecture blueprints, and store telemetry.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: () => PricingModal.show(
                      context,
                      subscriptionService: widget.subscriptionService!,
                      featureTrigger: 'Unlock unlimited daily AI opportunity teardowns and full architecture specs with Pro Builder.',
                    ),
                    icon: const Icon(Icons.bolt, size: 16),
                    label: const Text('Upgrade to Pro Builder — \$29/mo'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.aiPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            _teardownItem('What this app does', app.whatItDoes),
            _teardownItem('Target User Segment', app.targetUser),
            _teardownItem('Why it is growing', app.whyGrowing),
            _teardownItem('Core Value Proposition', app.coreValueProp),
            _teardownItem('Monetization Model', app.monetization),
          ],
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
              const Expanded(
                child: Text(
                  '5-Signal Radar Breakdown',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
              ),
              const SizedBox(width: 8),
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
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
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
            onPressed: () {
              if (widget.subscriptionService != null && !widget.subscriptionService!.canGenerateBlueprint()) {
                PricingModal.show(
                  context,
                  subscriptionService: widget.subscriptionService!,
                  featureTrigger: '14-Section AI Architecture Blueprints are an exclusive Pro Builder feature. Upgrade now to generate full product specifications, database schemas, and engineering roadmaps.',
                );
                return;
              }
              widget.onBuildWithAI(app);
            },
            icon: Icon(
              (widget.subscriptionService?.isFree ?? false) ? Icons.lock_outline : Icons.auto_awesome,
              size: 18,
            ),
            label: Text(
              (widget.subscriptionService?.isFree ?? false)
                  ? 'Generate Blueprint (Unlock with Pro)'
                  : 'Generate 14-Section Build Blueprint',
            ),
            style: FilledButton.styleFrom(
              backgroundColor: (widget.subscriptionService?.isFree ?? false) ? AppColors.aiPurple : AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportButton() {
    return PopupMenuButton<String>(
      tooltip: 'Export Teardown Report',
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onSelected: (val) {
        const exporter = FileExportService();
        if (val == 'csv') {
          exporter.downloadTeardownCsv(app);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.primary,
              content: Text('📥 Downloaded ${app.name} Teardown as CSV!'),
            ),
          );
        } else if (val == 'markdown') {
          exporter.downloadTeardownMarkdown(app);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.primary,
              content: Text('📥 Downloaded ${app.name} Summary as Markdown!'),
            ),
          );
        }
      },
      itemBuilder: (ctx) => [
        const PopupMenuItem(
          value: 'csv',
          child: Row(
            children: [
              Icon(Icons.table_chart_outlined, size: 16, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Export Data (CSV)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'markdown',
          child: Row(
            children: [
              Icon(Icons.description_outlined, size: 16, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Export Summary (MD)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceSecondary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.download, size: 16, color: AppColors.textPrimary),
            SizedBox(width: 6),
            Text('Export', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}
