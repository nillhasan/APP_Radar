import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../data/models/app_item.dart';
import '../data/models/build_blueprint.dart';
import '../features/dashboard/dashboard_view.dart';
import '../features/opportunities/opportunities_view.dart';
import '../features/explorer/app_explorer_view.dart';
import '../features/app_detail/app_detail_view.dart';
import '../features/competitors/competitors_view.dart';
import '../features/market_trends/market_trends_view.dart';
import '../features/watchlist/watchlist_view.dart';
import '../features/reports/reports_view.dart';
import '../features/reports/daily_report_preview_view.dart';
import '../features/build_with_ai/build_with_ai_view.dart';
import '../features/build_with_ai/build_blueprint_view.dart';
import '../features/settings/settings_view.dart';
import '../data/repositories/app_repository.dart';
import '../data/repositories/opportunity_repository.dart';
import '../data/repositories/market_trend_repository.dart';
import '../data/repositories/report_repository.dart';
import '../data/repositories/watchlist_repository.dart';
import '../services/ai/ai_service.dart';
import '../services/auth/auth_service.dart';
import '../services/subscription/subscription_service.dart';
import 'auth/auth_modal.dart';
import 'pricing/pricing_modal.dart';
import 'pwa/pwa_install_modal.dart';

class AppShell extends StatefulWidget {
  final AppRepository appRepo;
  final OpportunityRepository oppRepo;
  final MarketTrendRepository trendRepo;
  final ReportRepository reportRepo;
  final WatchlistRepository watchlistRepo;
  final AIService aiService;
  final AuthService authService;
  final SubscriptionService subscriptionService;

  const AppShell({
    super.key,
    required this.appRepo,
    required this.oppRepo,
    required this.trendRepo,
    required this.reportRepo,
    required this.watchlistRepo,
    required this.aiService,
    required this.authService,
    required this.subscriptionService,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  AppItem? _selectedAppForDetail;
  BuildBlueprint? _activeBlueprint;


  final List<String> _navTitles = const [
    'Dashboard',
    'Opportunities',
    'App Explorer',
    'Competitors',
    'Market Trends',
    'Watchlist',
    'Reports',
    'Daily Report Preview',
    'Build With AI',
    'Settings',
  ];

  final List<IconData> _navIcons = const [
    Icons.dashboard_outlined,
    Icons.local_fire_department_outlined,
    Icons.travel_explore_outlined,
    Icons.compare_arrows_outlined,
    Icons.trending_up_outlined,
    Icons.bookmark_outline,
    Icons.description_outlined,
    Icons.newspaper_outlined,
    Icons.auto_awesome,
    Icons.settings_outlined,
  ];

  void _openAppDetail(AppItem app) {
    setState(() {
      _selectedAppForDetail = app;
      _activeBlueprint = null;
    });
  }

  void _openBlueprint(BuildBlueprint blueprint) {
    setState(() {
      _activeBlueprint = blueprint;
      _selectedAppForDetail = null;
    });
  }

  AppItem? _selectedAppForCompetitor;

  void _openCompetitorMatrix(AppItem app) {
    setState(() {
      _selectedAppForCompetitor = app;
      _selectedAppForDetail = null;
      _activeBlueprint = null;
      _selectedIndex = 3;
    });
  }

  final Set<int> _visitedTabs = {0};

  void _navigateToTab(int index) {
    setState(() {
      _selectedIndex = index;
      _visitedTabs.add(index);
      _selectedAppForDetail = null;
      _activeBlueprint = null;
      if (index != 3) {
        _selectedAppForCompetitor = null;
      }
    });
  }

  List<AppItem> _cachedApps = [];

  @override
  void initState() {
    super.initState();
    widget.authService.addListener(_onServiceStateChanged);
    widget.subscriptionService.addListener(_onServiceStateChanged);
    _loadAllApps();
    _checkPaymentReturnUrl();
  }

  void _loadAllApps() {
    widget.appRepo.getAllApps().then((apps) {
      if (mounted) setState(() => _cachedApps = apps);
    });
  }

  void _checkPaymentReturnUrl() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final params = Uri.base.queryParameters;
        final hasPaymentParam = params['payment'] == 'success' || params.containsKey('session_id');

        if (hasPaymentParam) {
          final sessionId = params['session_id'];
          await widget.subscriptionService.handlePaymentSuccess(sessionId: sessionId);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                backgroundColor: AppColors.primary,
                duration: Duration(seconds: 5),
                content: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '🎉 Payment Verified! Welcome to Pro. All features are unlocked.',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('Note: Error checking payment return parameters: $e');
      }
    });
  }

  @override
  void dispose() {
    widget.authService.removeListener(_onServiceStateChanged);
    widget.subscriptionService.removeListener(_onServiceStateChanged);
    super.dispose();
  }

  void _onServiceStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 960;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(isDesktop),
      drawer: isDesktop ? null : Drawer(child: Material(color: AppColors.surface, child: _buildNavContent(isDrawer: true))),
      body: Row(
        children: [
          if (isDesktop)
            Container(
              width: 240,
              decoration: const BoxDecoration(
                border: Border(right: BorderSide(color: AppColors.border, width: 1)),
              ),
              child: Material(
                color: AppColors.surface,
                child: _buildNavContent(),
              ),
            ),
          Expanded(
            child: Container(
              color: AppColors.background,
              child: _buildCurrentPage(),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDesktop) {
    return AppBar(
      titleSpacing: isDesktop ? 24 : 16,
      leading: isDesktop ? null : Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.radar, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          const Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'AppRadar',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    letterSpacing: -0.5,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Market Intelligence',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        if (isDesktop) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: const Row(
              children: [
                Icon(Icons.public, size: 14, color: AppColors.primary),
                SizedBox(width: 6),
                Text(
                  'USA • Sep 19, 2026',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
        ],
        IconButton(
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_outlined, color: AppColors.textSecondary),
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('3 new high-potential opportunities detected today!')),
            );
          },
        ),
        if (isDesktop)
          IconButton(
            tooltip: 'Install AppRadar PWA',
            icon: const Icon(Icons.install_desktop_rounded, color: AppColors.textSecondary, size: 20),
            onPressed: () => PwaInstallModal.show(context),
          ),
        const SizedBox(width: 8),
        // Plan Badge & Upgrade Action
        if (widget.subscriptionService.isFree) ...[
          OutlinedButton.icon(
            onPressed: () => PricingModal.show(
              context,
              subscriptionService: widget.subscriptionService,
              authService: widget.authService,
              onRequiresAuth: () => AuthModal.show(
                context,
                authService: widget.authService,
              ),
            ),
            icon: const Icon(Icons.bolt, size: 15, color: AppColors.aiPurple),
            label: const Text('Upgrade Pro', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.aiPurple)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.aiPurple.withValues(alpha: 0.4)),
              backgroundColor: AppColors.aiPurpleLight,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
          const SizedBox(width: 8),
        ],
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: _buildAuthHeaderButton(isDesktop),
        ),
      ],
    );
  }

  Widget _buildAuthHeaderButton(bool isDesktop) {
    final auth = widget.authService;

    if (!auth.isAuthenticated) {
      return ElevatedButton.icon(
        onPressed: () => AuthModal.show(
          context,
          authService: auth,
          onSuccess: () => setState(() {}),
        ),
        icon: const Icon(Icons.login, size: 16),
        label: const Text('Sign In', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
      );
    }

    return PopupMenuButton<String>(
      tooltip: 'Account Profile',
      offset: const Offset(0, 42),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (val) async {
        if (val == 'watchlist') {
          _navigateToTab(5); // Watchlist
        } else if (val == 'settings') {
          _navigateToTab(9); // Settings
        } else if (val == 'pricing') {
          PricingModal.show(
            context,
            subscriptionService: widget.subscriptionService,
            authService: widget.authService,
            onRequiresAuth: () => AuthModal.show(
              context,
              authService: widget.authService,
            ),
          );
        } else if (val == 'sync_subscription') {
          await widget.subscriptionService.fetchSubscriptionFromCloud();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: AppColors.primary,
                content: Text(
                  widget.subscriptionService.isPro
                      ? '🎉 Active Pro subscription confirmed!'
                      : 'Subscription status synced with cloud.',
                ),
              ),
            );
          }
        } else if (val == 'signout') {
          await auth.signOut();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Successfully signed out')),
            );
          }
        }
      },
      itemBuilder: (ctx) => [
        PopupMenuItem<String>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                auth.userDisplayName,
                style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontSize: 13),
              ),
              Text(
                auth.userEmail,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: widget.subscriptionService.isPro ? AppColors.aiPurpleLight : AppColors.successLight,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  widget.subscriptionService.isPro ? 'PRO PLAN' : 'FREE PLAN',
                  style: TextStyle(
                    color: widget.subscriptionService.isPro ? AppColors.aiPurple : AppColors.success,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Divider(),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'pricing',
          child: Row(
            children: [
              const Icon(Icons.bolt, size: 18, color: AppColors.aiPurple),
              const SizedBox(width: 8),
              Text(
                widget.subscriptionService.isFree ? 'Upgrade to Pro' : 'Pricing Plans',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.aiPurple),
              ),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'sync_subscription',
          child: Row(
            children: [
              Icon(Icons.sync, size: 18, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Restore / Sync Plan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'watchlist',
          child: Row(
            children: [
              Icon(Icons.bookmark_outline, size: 18, color: AppColors.textSecondary),
              SizedBox(width: 8),
              Text('My Cloud Watchlist', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'settings',
          child: Row(
            children: [
              Icon(Icons.settings_outlined, size: 18, color: AppColors.textSecondary),
              SizedBox(width: 8),
              Text('Account Settings', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'signout',
          child: Row(
            children: [
              Icon(Icons.logout, size: 18, color: AppColors.danger),
              SizedBox(width: 8),
              Text('Sign Out', style: TextStyle(fontSize: 13, color: AppColors.danger, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: widget.subscriptionService.isPro
                ? AppColors.aiPurple.withValues(alpha: 0.35)
                : AppColors.border,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 15,
              backgroundColor: widget.subscriptionService.isPro
                  ? const Color(0xFF8B5CF6)
                  : AppColors.primary,
              child: Text(
                auth.userInitials,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  auth.userDisplayName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.subscriptionService.isPro ? 'Pro' : 'Free',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: widget.subscriptionService.isPro ? FontWeight.w600 : FontWeight.w400,
                    color: widget.subscriptionService.isPro ? AppColors.aiPurple : AppColors.textMuted,
                    height: 1.1,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, size: 16, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildNavContent({bool isDrawer = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'DISCOVERY SUITE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Find. Analyze. Build.',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            itemCount: _navTitles.length,
            itemBuilder: (context, index) {
              final isSelected = _selectedAppForDetail == null &&
                  _activeBlueprint == null &&
                  _selectedIndex == index;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: ListTile(
                  dense: true,
                  selected: isSelected,
                  selectedTileColor: AppColors.primaryLight,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  leading: Icon(
                    _navIcons[index],
                    size: 20,
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  ),
                  title: Text(
                    _navTitles[index],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  onTap: () {
                    _navigateToTab(index);
                    if (isDrawer) Navigator.pop(context);
                  },
                ),
              );
            },
          ),
        ),
        if (isDrawer) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            child: ListTile(
              dense: true,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              leading: const Icon(Icons.install_mobile_rounded, size: 20, color: AppColors.primary),
              title: const Text('Install App (PWA)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                PwaInstallModal.show(context);
              },
            ),
          ),
        ],
        const Divider(),
        Padding(
          padding: const EdgeInsets.all(16),
          child: InkWell(
            onTap: widget.subscriptionService.isFree
                ? () => PricingModal.show(
                      context,
                      subscriptionService: widget.subscriptionService,
                      authService: widget.authService,
                      onRequiresAuth: () => AuthModal.show(
                        context,
                        authService: widget.authService,
                      ),
                    )
                : null,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.subscriptionService.isPro ? AppColors.primaryLight : AppColors.aiPurpleLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: widget.subscriptionService.isPro
                      ? AppColors.primaryBorder
                      : AppColors.aiPurple.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.subscriptionService.isPro ? Icons.workspace_premium : Icons.bolt,
                    color: widget.subscriptionService.isPro ? AppColors.primary : AppColors.aiPurple,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.subscriptionService.isPro ? 'Pro Builder Active' : 'Upgrade to Pro',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: widget.subscriptionService.isPro ? AppColors.primary : AppColors.aiPurple,
                          ),
                        ),
                        Text(
                          widget.subscriptionService.isPro
                              ? 'All features unlocked'
                              : '${widget.subscriptionService.remainingFreeTeardowns}/3 free teardowns left',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  if (widget.subscriptionService.isFree)
                    const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.aiPurple),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentPage() {
    if (_selectedAppForDetail != null) {
      return AppDetailView(
        app: _selectedAppForDetail!,
        watchlistRepo: widget.watchlistRepo,
        subscriptionService: widget.subscriptionService,
        allApps: _cachedApps,
        onSelectCompetitor: _openAppDetail,
        onViewCompetitorMatrix: _openCompetitorMatrix,
        onBack: () => setState(() => _selectedAppForDetail = null),
        onBuildWithAI: (app) {
          setState(() {
            _selectedAppForDetail = null;
            _selectedIndex = 8; // Switch to Build With AI
          });
        },
      );
    }

    if (_activeBlueprint != null) {
      return BuildBlueprintView(
        blueprint: _activeBlueprint!,
        subscriptionService: widget.subscriptionService,
        onBack: () => setState(() => _activeBlueprint = null),
      );
    }

    _visitedTabs.add(_selectedIndex);

    return IndexedStack(
      index: _selectedIndex,
      children: [
        _visitedTabs.contains(0)
            ? DashboardView(
                oppRepo: widget.oppRepo,
                trendRepo: widget.trendRepo,
                appRepo: widget.appRepo,
                onOpenApp: _openAppDetail,
                onNavigateToBuildAI: () => _navigateToTab(8),
              )
            : const SizedBox.shrink(),
        _visitedTabs.contains(1)
            ? OpportunitiesView(
                oppRepo: widget.oppRepo,
                watchlistRepo: widget.watchlistRepo,
                onOpenApp: _openAppDetail,
              )
            : const SizedBox.shrink(),
        _visitedTabs.contains(2)
            ? AppExplorerView(
                appRepo: widget.appRepo,
                aiService: widget.aiService,
                subscriptionService: widget.subscriptionService,
                authService: widget.authService,
                onOpenApp: _openAppDetail,
              )
            : const SizedBox.shrink(),
        _visitedTabs.contains(3)
            ? CompetitorsView(
                appRepo: widget.appRepo,
                onOpenApp: _openAppDetail,
                onBuildWithAI: (app) => _navigateToTab(8),
                initialApp: _selectedAppForCompetitor,
              )
            : const SizedBox.shrink(),
        _visitedTabs.contains(4)
            ? MarketTrendsView(
                trendRepo: widget.trendRepo,
                appRepo: widget.appRepo,
                onOpenApp: _openAppDetail,
                onBuildWithAI: (app) => _navigateToTab(8),
                onExploreCategory: (category) => _navigateToTab(2),
              )
            : const SizedBox.shrink(),
        _visitedTabs.contains(5)
            ? WatchlistView(
                watchlistRepo: widget.watchlistRepo,
                onOpenApp: _openAppDetail,
                onBuildWithAI: (app) => _navigateToTab(8),
                onExploreOpportunities: () => _navigateToTab(1),
              )
            : const SizedBox.shrink(),
        _visitedTabs.contains(6)
            ? ReportsView(
                reportRepo: widget.reportRepo,
                onViewDailyReport: () => _navigateToTab(7),
              )
            : const SizedBox.shrink(),
        _visitedTabs.contains(7)
            ? DailyReportPreviewView(
                oppRepo: widget.oppRepo,
                onOpenApp: _openAppDetail,
              )
            : const SizedBox.shrink(),
        _visitedTabs.contains(8)
            ? BuildWithAIView(
                appRepo: widget.appRepo,
                aiService: widget.aiService,
                subscriptionService: widget.subscriptionService,
                onBlueprintGenerated: _openBlueprint,
              )
            : const SizedBox.shrink(),
        _visitedTabs.contains(9)
            ? const SettingsView()
            : const SizedBox.shrink(),
      ],
    );
  }
}
