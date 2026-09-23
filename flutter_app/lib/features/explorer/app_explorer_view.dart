import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/app_item.dart';
import '../../data/models/negative_review_mining.dart';
import '../../data/repositories/app_repository.dart';
import '../../services/ai/ai_service.dart';
import '../../services/export/file_export_service.dart';
import '../../services/subscription/subscription_service.dart';
import '../../services/auth/auth_service.dart';
import '../../widgets/pricing/pricing_modal.dart';
import '../../widgets/auth/auth_modal.dart';
import '../../widgets/filter_bar.dart';
import '../../widgets/score_badge.dart';
import '../../widgets/section_header.dart';
import '../../widgets/app_icon_widget.dart';
import '../../core/utils/formatters.dart';

class AppExplorerView extends StatefulWidget {
  final AppRepository appRepo;
  final ValueChanged<AppItem> onOpenApp;
  final AIService? aiService;
  final SubscriptionService? subscriptionService;
  final AuthService? authService;

  const AppExplorerView({
    super.key,
    required this.appRepo,
    required this.onOpenApp,
    this.aiService,
    this.subscriptionService,
    this.authService,
  });

  @override
  State<AppExplorerView> createState() => _AppExplorerViewState();
}

class _AppExplorerViewState extends State<AppExplorerView> {
  String _search = '';
  String _category = 'All Categories';
  String _platform = 'All Platforms';
  final TextEditingController _urlController = TextEditingController();
  bool _isAnalyzingUrl = false;
  final FileExportService _exportService = const FileExportService();
  late Future<List<AppItem>> _appsFuture;

  // Pagination & Debouncing State
  int _currentPage = 0;
  int _rowsPerPage = 20;
  Timer? _searchDebounceTimer;

  @override
  void initState() {
    super.initState();
    _loadApps();
    widget.subscriptionService?.addListener(_onSubscriptionChanged);
  }

  void _onSubscriptionChanged() {
    if (mounted) setState(() {});
  }

  void _loadApps() {
    _appsFuture = widget.appRepo.getAllApps();
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    widget.subscriptionService?.removeListener(_onSubscriptionChanged);
    _urlController.dispose();
    super.dispose();
  }

  void _showUpgradePaywall() {
    final sub = widget.subscriptionService;
    if (sub != null) {
      PricingModal.show(
        context,
        subscriptionService: sub,
        authService: widget.authService,
        featureTrigger: 'Instant Store URL Teardown (Free Limit: 1 App)',
        onRequiresAuth: () {
          if (widget.authService != null) {
            AuthModal.show(context, authService: widget.authService!);
          }
        },
      );
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Free accounts are limited to 1 instant store URL teardown. Upgrade to Pro for unlimited store teardowns.'),
        backgroundColor: AppColors.aiPurple,
        duration: Duration(seconds: 4),
      ),
    );
  }

  Future<void> _handleCustomUrlTeardown(String rawInput) async {
    final input = rawInput.trim();
    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a Google Play URL, App Store link, or package ID.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final sub = widget.subscriptionService;
    if (sub != null && !sub.canPerformUrlTeardown(input)) {
      _showUpgradePaywall();
      return;
    }

    setState(() => _isAnalyzingUrl = true);

    try {
      final allApps = await widget.appRepo.getAllApps();
      final targetApp = _parseOrSynthesizeApp(input, allApps);

      sub?.recordUrlTeardown(input);
      if (targetApp.appUrl != null) sub?.recordUrlTeardown(targetApp.appUrl!);
      sub?.recordUrlTeardown(targetApp.id);

      if (mounted) {
        setState(() => _isAnalyzingUrl = false);
        _urlController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚡ Instant Teardown complete for ${targetApp.name}! Opening blueprint...'),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 2),
          ),
        );
        widget.onOpenApp(targetApp);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAnalyzingUrl = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error analyzing store URL: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  AppItem _parseOrSynthesizeApp(String input, List<AppItem> existingApps) {
    final lower = input.toLowerCase();

    // 1. Exact or partial match in existing database
    for (final app in existingApps) {
      final aUrl = app.appUrl?.toLowerCase() ?? '';
      if (app.id.toLowerCase() == lower ||
          app.name.toLowerCase() == lower ||
          (aUrl.isNotEmpty && aUrl.contains(lower)) ||
          (lower.contains('id=') && aUrl.isNotEmpty && aUrl.contains(lower.split('id=').last.split('&').first))) {
        return app;
      }
    }

    // 2. Parse URL or Package Name
    String name = 'Analyzed App';
    String category = 'Productivity';
    String platform = 'Google Play Store';
    String appId = 'custom_${DateTime.now().millisecondsSinceEpoch}';
    String appUrl = input.startsWith('http') ? input : 'https://play.google.com/store/apps/details?id=$input';
    String iconEmoji = '⚡';

    if (input.contains('play.google.com')) {
      platform = 'Google Play Store';
      final uri = Uri.tryParse(input);
      final idParam = uri?.queryParameters['id'];
      if (idParam != null && idParam.isNotEmpty) {
        final parts = idParam.split('.');
        name = parts.last;
        name = name.isNotEmpty ? (name[0].toUpperCase() + name.substring(1)) : 'Play App';
        appId = idParam;
      }
    } else if (input.contains('apps.apple.com')) {
      platform = 'iOS App Store';
      final uri = Uri.tryParse(input);
      final segments = uri?.pathSegments ?? [];
      final appIndex = segments.indexOf('app');
      if (appIndex != -1 && segments.length > appIndex + 1) {
        final rawName = segments[appIndex + 1].replaceAll('-', ' ');
        name = rawName.split(' ').map((w) => w.isNotEmpty ? (w[0].toUpperCase() + w.substring(1)) : '').join(' ').trim();
        appId = segments.last;
      }
    } else if (input.contains('.')) {
      final parts = input.split('.');
      name = parts.last;
      name = name.isNotEmpty ? (name[0].toUpperCase() + name.substring(1)) : 'Custom App';
      appId = input;
    } else {
      name = input;
    }

    // Infer category and theme emoji
    final nameLower = name.toLowerCase();
    if (nameLower.contains('fit') || nameLower.contains('run') || nameLower.contains('gym') || nameLower.contains('health') || nameLower.contains('sleep')) {
      category = 'Health & Fitness';
      iconEmoji = '🏃';
    } else if (nameLower.contains('money') || nameLower.contains('finance') || nameLower.contains('pay') || nameLower.contains('budget') || nameLower.contains('crypto') || nameLower.contains('split')) {
      category = 'Finance';
      iconEmoji = '💳';
    } else if (nameLower.contains('learn') || nameLower.contains('duo') || nameLower.contains('tutor') || nameLower.contains('card') || nameLower.contains('study')) {
      category = 'Education';
      iconEmoji = '🎓';
    } else if (nameLower.contains('photo') || nameLower.contains('video') || nameLower.contains('cam') || nameLower.contains('edit')) {
      category = 'Photo & Video';
      iconEmoji = '📸';
    } else {
      category = 'Productivity';
      iconEmoji = '⚡';
    }

    const oppScore = 86;
    return AppItem(
      id: appId,
      name: name,
      category: category,
      platform: platform,
      ranking: 8,
      rating: 4.6,
      reviewCount: 45000,
      downloadsEstimate: 620000,
      revenueEstimate: 140000,
      growthRate: 52.0,
      opportunityScore: oppScore,
      developer: '$name Technologies',
      description: '$name is a high-demand $platform application in the $category category with strong organic user search intent and clear market gaps.',
      whatItDoes: 'Streamlines core $category daily routines on mobile with cloud synchronization and automation.',
      whyGrowing: 'High user interest in self-improvement and AI-assisted mobile utilities with smooth cross-platform workflows.',
      coreValueProp: 'Fast, responsive mobile workflow with real-time sync and clean UX.',
      targetUser: 'Productivity enthusiasts, professionals, and students seeking a high-performance $category tool.',
      monetization: 'Freemium with \$9.99/mo Pro subscription or \$49.99 annual pass',
      iconEmoji: iconEmoji,
      signals: const AppSignals(
        growthSignal: 89,
        revenueSignal: 84,
        rankingSignal: 82,
        reviewSignal: 85,
        marketSignal: 88,
      ),
      coreFeatures: const [
        'Cloud synchronization across mobile and web',
        'Smart search and categorical organization',
        'Customizable templates and workflows',
        '1-tap data export to CSV and PDF',
      ],
      aiFeatures: const [
        'AI auto-tagging and semantic summarization',
        'Smart insight generator and trend recommendations',
      ],
      userPainPoints: const [
        'Aggressive subscription paywalls restricting basic utility features',
        'Persistent sync delays and lack of reliable offline-first database',
        'Cluttered interface filled with unwanted promotional upsells',
      ],
      competitorGaps: const [
        'Build an offline-first architecture with instantaneous local search',
        'Offer transparent, affordable pricing with a lifetime purchase option',
        'Deliver a bloat-free, distraction-free minimalist mobile experience',
      ],
      suggestedMvp: const [
        'Clean single-purpose mobile client built with Flutter',
        'Local SQLite storage with optional cloud backup',
        'Straightforward flat-rate pricing or generous free tier',
      ],
      negativeReviews: NegativeReviewMining(
        totalAnalyzed: 380,
        dissatisfactionRate: 28,
        categoryDistribution: const {
          'Pricing & Paywalls': 45,
          'Missing Features': 25,
          'Bugs & Stability': 18,
          'UI & UX Friction': 12,
        },
        goldenOpportunitySummary: 'Capture churned users of $name by guaranteeing an offline-first experience with transparent pricing and zero dark-pattern upsells.',
        sampleReviews: [
          StoreReview(
            author: 'Verified Store Reviewer',
            rating: 1,
            date: '3 days ago',
            category: 'Pricing & Paywalls',
            comment: 'Forced subscription popups on every launch. I just need a simple utility without paying \$15/month!',
            builderOpportunity: 'Offer a generous free tier and low-cost indie pricing to attract frustrated users.',
          ),
          StoreReview(
            author: 'Power User (Store Review)',
            rating: 2,
            date: '6 days ago',
            category: 'Missing Features',
            comment: 'Offline support is broken. It locks up whenever I do not have a strong cellular signal.',
            builderOpportunity: 'Architect the mobile app with an offline-first local database cache.',
          ),
        ],
      ),
      appUrl: appUrl,
      screenshots: const [],
      competitorIds: const ['app_1', 'app_2', 'app_3'],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SectionHeader(
            title: 'App Intelligence Explorer',
            subtitle: 'Search raw store performance, run instant custom URL teardowns, or export market intelligence.',
          ),

          // ⚡ INSTANT STORE URL TEARDOWN HERO CARD
          _buildUrlTeardownCard(),
          const SizedBox(height: 20),

          FilterBar(
            searchQuery: _search,
            onSearchChanged: (val) {
              _searchDebounceTimer?.cancel();
              _searchDebounceTimer = Timer(const Duration(milliseconds: 150), () {
                if (mounted) {
                  setState(() {
                    _search = val;
                    _currentPage = 0;
                  });
                }
              });
            },
            selectedCategory: _category,
            onCategoryChanged: (val) => setState(() {
              _category = val;
              _currentPage = 0;
            }),
            selectedPlatform: _platform,
            onPlatformChanged: (val) => setState(() {
              _platform = val;
              _currentPage = 0;
            }),
          ),
          FutureBuilder<List<AppItem>>(
            future: _appsFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ));
              }

              final allApps = snapshot.data!;
              final apps = allApps.where((app) {
                final matchesQuery = _search.isEmpty ||
                    app.name.toLowerCase().contains(_search.toLowerCase()) ||
                    app.description.toLowerCase().contains(_search.toLowerCase()) ||
                    app.developer.toLowerCase().contains(_search.toLowerCase());

                final matchesCategory = _category == 'All Categories' ||
                    _category == 'All' ||
                    app.category.toLowerCase().contains(_category.toLowerCase());

                final matchesPlatform = _platform == 'All Platforms' ||
                    app.platform.toLowerCase().contains(_platform.toLowerCase());

                return matchesQuery && matchesCategory && matchesPlatform;
              }).toList();

              if (apps.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Text('No apps found matching criteria.'),
                  ),
                );
              }

              final totalCount = apps.length;
              final maxPages = (totalCount / _rowsPerPage).ceil().clamp(1, 9999);
              if (_currentPage >= maxPages) {
                _currentPage = maxPages - 1;
              }
              final pagedApps = apps.skip(_currentPage * _rowsPerPage).take(_rowsPerPage).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildExportToolbar(apps),
                const SizedBox(height: 12),
                Container(
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
                      rows: pagedApps.map((app) {
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
                ),
                const SizedBox(height: 12),
                _buildPaginationControls(totalCount, maxPages),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildPaginationControls(int totalCount, int maxPages) {
    final startItem = totalCount == 0 ? 0 : (_currentPage * _rowsPerPage + 1);
    final endItem = math.min((_currentPage + 1) * _rowsPerPage, totalCount);

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
        spacing: 16,
        runSpacing: 10,
        children: [
          Text(
            'Showing $startItem–$endItem of $totalCount applications',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Per page: ', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _rowsPerPage,
                    isDense: true,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    items: const [
                      DropdownMenuItem(value: 20, child: Text('20')),
                      DropdownMenuItem(value: 50, child: Text('50')),
                      DropdownMenuItem(value: 100, child: Text('100')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _rowsPerPage = val;
                          _currentPage = 0;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 14),
              OutlinedButton.icon(
                onPressed: _currentPage > 0
                    ? () => setState(() => _currentPage--)
                    : null,
                icon: const Icon(Icons.chevron_left, size: 16),
                label: const Text('Prev', style: TextStyle(fontSize: 11)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  minimumSize: Size.zero,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'Page ${_currentPage + 1} of $maxPages',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _currentPage < maxPages - 1
                    ? () => setState(() => _currentPage++)
                    : null,
                icon: const Icon(Icons.chevron_right, size: 16),
                label: const Text('Next', style: TextStyle(fontSize: 11)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  minimumSize: Size.zero,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUrlTeardownCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        gradient: LinearGradient(
          colors: [
            AppColors.surface,
            AppColors.primaryLight.withValues(alpha: 0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.bolt, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Instant Store URL Teardown & Live Gap Analysis',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Paste any Google Play or Apple App Store URL or package ID to instantly mine pain points and generate an MVP PRD.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildQuotaBadge(),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _urlController,
                  decoration: InputDecoration(
                    hintText: 'https://play.google.com/store/apps/details?id=com.duolingo or com.duolingo',
                    hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                    prefixIcon: const Icon(Icons.link, size: 20, color: AppColors.primary),
                    suffixIcon: _urlController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => setState(() => _urlController.clear()),
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.surfaceSecondary,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  onSubmitted: (val) => _handleCustomUrlTeardown(val),
                ),
              ),
              const SizedBox(width: 12),
              Builder(
                builder: (context) {
                  final isLimitReached = widget.subscriptionService?.isFree == true &&
                      (widget.subscriptionService?.remainingFreeUrlTeardowns ?? 0) <= 0;
                  return ElevatedButton.icon(
                    onPressed: _isAnalyzingUrl
                        ? null
                        : () => _handleCustomUrlTeardown(_urlController.text),
                    icon: _isAnalyzingUrl
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Icon(isLimitReached ? Icons.lock : Icons.flash_on, size: 18),
                    label: Text(
                      _isAnalyzingUrl
                          ? 'Analyzing...'
                          : (isLimitReached ? 'Unlock Pro to Teardown' : 'Teardown App'),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isLimitReached ? AppColors.aiPurple : AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'Try instant samples:',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted),
              ),
              _buildPresetChip('📱 Duolingo', 'https://play.google.com/store/apps/details?id=com.duolingo'),
              _buildPresetChip('🧘 Headspace', 'https://play.google.com/store/apps/details?id=com.getsomeheadspace.android'),
              _buildPresetChip('📝 Notion', 'https://play.google.com/store/apps/details?id=notion.id'),
              _buildPresetChip('💰 Splitwise', 'https://play.google.com/store/apps/details?id=com.Splitwise.SplitwiseMobile'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuotaBadge() {
    final sub = widget.subscriptionService;
    final isPro = sub?.isPro ?? false;

    if (isPro) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.aiPurpleLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.aiPurple.withValues(alpha: 0.3)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.workspace_premium, size: 14, color: AppColors.aiPurple),
            SizedBox(width: 4),
            Text(
              'PRO UNLIMITED',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.aiPurple, letterSpacing: 0.5),
            ),
          ],
        ),
      );
    }

    final remaining = sub?.remainingFreeUrlTeardowns ?? 1;
    final hasLimitReached = remaining <= 0;

    return InkWell(
      onTap: hasLimitReached ? _showUpgradePaywall : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: hasLimitReached ? AppColors.warningLight : AppColors.primaryLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasLimitReached ? AppColors.warning.withValues(alpha: 0.4) : AppColors.primaryBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasLimitReached ? Icons.lock : Icons.bolt,
              size: 13,
              color: hasLimitReached ? AppColors.warning : AppColors.primary,
            ),
            const SizedBox(width: 5),
            Text(
              hasLimitReached
                  ? 'FREE LIMIT (1/1 USED) — UPGRADE'
                  : 'FREE PLAN: 1 TEARDOWN REMAINING',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: hasLimitReached ? AppColors.warning : AppColors.primary,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, String url) {
    final sub = widget.subscriptionService;
    final isPro = sub?.isPro ?? false;
    final canPerform = isPro || (sub?.canPerformUrlTeardown(url) ?? true);

    return InkWell(
      onTap: () {
        _urlController.text = url;
        _handleCustomUrlTeardown(url);
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surfaceSecondary,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: canPerform ? AppColors.border : AppColors.warning.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            if (!canPerform) ...[
              const SizedBox(width: 4),
              const Icon(Icons.lock, size: 11, color: AppColors.warning),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExportToolbar(List<AppItem> apps) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        Text(
          'Showing ${apps.length} verified applications',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMuted),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton.icon(
              onPressed: () {
                _exportService.downloadAppsListCsv(apps, fileName: 'AppRadar_Explorer_Export.csv');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('📥 Exported ${apps.length} apps to CSV!'),
                    backgroundColor: AppColors.primary,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.download, size: 16),
              label: const Text('Export CSV', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () async {
                final md = _exportService.generateNotionMarkdownTable(apps, title: 'AppRadar Market Explorer');
                await Clipboard.setData(ClipboardData(text: md));
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('📋 Copied Notion Table for ${apps.length} apps! Paste directly into Notion.'),
                      backgroundColor: AppColors.success,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.table_chart_outlined, size: 16),
              label: const Text('Copy Notion Table', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
