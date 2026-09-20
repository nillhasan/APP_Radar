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
import 'auth/auth_modal.dart';

class AppShell extends StatefulWidget {
  final AppRepository appRepo;
  final OpportunityRepository oppRepo;
  final MarketTrendRepository trendRepo;
  final ReportRepository reportRepo;
  final WatchlistRepository watchlistRepo;
  final AIService aiService;
  final AuthService authService;

  const AppShell({
    super.key,
    required this.appRepo,
    required this.oppRepo,
    required this.trendRepo,
    required this.reportRepo,
    required this.watchlistRepo,
    required this.aiService,
    required this.authService,
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

  void _navigateToTab(int index) {
    setState(() {
      _selectedIndex = index;
      _selectedAppForDetail = null;
      _activeBlueprint = null;
    });
  }

  @override
  void initState() {
    super.initState();
    widget.authService.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    widget.authService.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
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
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
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
            child: Row(
              children: const [
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
        const SizedBox(width: 8),
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
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'FREE BUILDER PLAN',
                  style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.w700),
                ),
              ),
              const Divider(),
            ],
          ),
        ),
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surfaceSecondary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.primary,
              child: Text(
                auth.userInitials,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ),
            if (isDesktop) ...[
              const SizedBox(width: 8),
              Text(
                auth.userDisplayName,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_drop_down, size: 18, color: AppColors.textSecondary),
            ],
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
        const Divider(),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primaryBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.bolt, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Pro Workspace',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                      ),
                      Text(
                        '128 apps tracked',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
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
        onBack: () => setState(() => _activeBlueprint = null),
      );
    }

    switch (_selectedIndex) {
      case 0:
        return DashboardView(
          oppRepo: widget.oppRepo,
          trendRepo: widget.trendRepo,
          onOpenApp: _openAppDetail,
          onNavigateToBuildAI: () => _navigateToTab(8),
        );
      case 1:
        return OpportunitiesView(
          oppRepo: widget.oppRepo,
          onOpenApp: _openAppDetail,
        );
      case 2:
        return AppExplorerView(
          appRepo: widget.appRepo,
          onOpenApp: _openAppDetail,
        );
      case 3:
        return const CompetitorsView();
      case 4:
        return MarketTrendsView(trendRepo: widget.trendRepo);
      case 5:
        return WatchlistView(
          watchlistRepo: widget.watchlistRepo,
          onOpenApp: _openAppDetail,
          onBuildWithAI: (app) => _navigateToTab(8),
        );
      case 6:
        return ReportsView(
          reportRepo: widget.reportRepo,
          onViewDailyReport: () => _navigateToTab(7),
        );
      case 7:
        return DailyReportPreviewView(
          oppRepo: widget.oppRepo,
          onOpenApp: _openAppDetail,
        );
      case 8:
        return BuildWithAIView(
          appRepo: widget.appRepo,
          aiService: widget.aiService,
          onBlueprintGenerated: _openBlueprint,
        );
      case 9:
      default:
        return const SettingsView();
    }
  }
}
