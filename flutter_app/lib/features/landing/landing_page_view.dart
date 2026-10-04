import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_service.dart';
import '../../data/models/app_item.dart';
import '../../data/repositories/app_repository.dart';
import '../../data/repositories/opportunity_repository.dart';
import '../../services/auth/auth_service.dart';
import '../../services/subscription/subscription_service.dart';
import '../../widgets/top_charts/top_charts_leaderboard.dart';
import '../../widgets/landing/platform_screenshots_carousel.dart';
import '../../widgets/pricing/agency_inquiry_modal.dart';

/// MobileAction-inspired high-converting SaaS Front Page for AppRadar.
///
/// Showcases AppRadar's dual-store telemetry, AI opportunity radar, competitor
/// intelligence, and Gemini AI blueprints while providing seamless 1-click
/// access to the Console and AuthModal.
class LandingPageView extends StatefulWidget {
  final AppRepository appRepo;
  final OpportunityRepository oppRepo;
  final AuthService authService;
  final SubscriptionService subscriptionService;
  final VoidCallback onLaunchConsole;
  final ValueChanged<AppItem>? onOpenAppDetail;
  final ValueChanged<int>? onNavigateToConsoleTab;
  final VoidCallback onOpenAuthModal;
  final VoidCallback onOpenPricingModal;
  final VoidCallback? onGetStarted;

  const LandingPageView({
    super.key,
    required this.appRepo,
    required this.oppRepo,
    required this.authService,
    required this.subscriptionService,
    required this.onLaunchConsole,
    this.onOpenAppDetail,
    this.onNavigateToConsoleTab,
    required this.onOpenAuthModal,
    required this.onOpenPricingModal,
    this.onGetStarted,
  });

  @override
  State<LandingPageView> createState() => _LandingPageViewState();
}

class _LandingPageViewState extends State<LandingPageView> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey _topChartsKey = GlobalKey();
  final GlobalKey _featuresKey = GlobalKey();
  final GlobalKey _pricingKey = GlobalKey();

  int _selectedProductTab = 0; // 0: Telemetry, 1: Opportunities, 2: Teardown, 3: Competitors, 4: AI Blueprints
  bool _isAnnualPricing = false;
  List<AppItem> _cachedApps = [];

  final List<String> _dynamicHeroWords = [
    'Real-Time Telemetry',
    'AI Opportunity Radar',
    'Deep Review Mining',
    'Predictive Growth Signals',
  ];
  int _activeHeroWordIndex = 0;
  Timer? _heroWordTimer;

  @override
  void initState() {
    super.initState();
    ThemeService.instance.addListener(_onThemeChanged);
    _loadSampleApps();
    _heroWordTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        setState(() {
          _activeHeroWordIndex = (_activeHeroWordIndex + 1) % _dynamicHeroWords.length;
        });
      }
    });
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  void _loadSampleApps() {
    widget.appRepo.getAllApps().then((apps) {
      if (mounted) setState(() => _cachedApps = apps);
    });
  }

  @override
  void dispose() {
    ThemeService.instance.removeListener(_onThemeChanged);
    _heroWordTimer?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _scrollToKey(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _handleHeroSearch() {
    if (!widget.authService.isAuthenticated) {
      (widget.onGetStarted ?? widget.onOpenAuthModal)();
      return;
    }
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      // Direct jump to console App Explorer with query
      widget.onNavigateToConsoleTab?.call(2); // Tab 2: App Explorer
      widget.onLaunchConsole();
    } else {
      widget.onLaunchConsole();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isTablet = screenWidth >= 768 && screenWidth < 1100;
    final isDark = ThemeService.instance.isDark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
      endDrawer: isMobile ? _buildMobileDrawer(isDark) : null,
      body: Stack(
        children: [
          // Scrollable Page Content
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 72), // Offset for sticky navbar
                _buildHeroSection(isMobile, isTablet),
                _buildSocialProofMarquee(isMobile),
                // Auto-moving platform screenshot showcase carousel (6 AppRadar feature screens)
                PlatformScreenshotsCarousel(
                  onGetStarted: widget.authService.isAuthenticated
                      ? widget.onLaunchConsole
                      : (widget.onGetStarted ?? widget.onOpenAuthModal),
                ),
                _buildProductSuiteTabsSection(isMobile, isTablet),
                _buildKeyMetricsSection(isMobile),
                _buildQuantifiedCaseStudies(isMobile, isTablet),
                _buildEnterpriseIntegrations(isMobile),
                _buildPricingSection(isMobile, isTablet),
                _buildPreFooterCtaBanner(isMobile),
                _buildFooter(isMobile),
              ],
            ),
          ),

          // Sticky Top Navigation Header (MobileAction style)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildStickyNavbar(isMobile, isDark),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 1. STICKY TOP NAVBAR
  // ==========================================
  Widget _buildStickyNavbar(bool isMobile, bool isDark) {
    return Container(
      height: 72,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32),
      decoration: BoxDecoration(
        color: isDark ? AppColors.obsidian.withValues(alpha: 0.98) : Colors.white.withValues(alpha: 0.95),
        border: Border(bottom: BorderSide(color: isDark ? AppColors.rekkiBorderSubtle : const Color(0xFFE2E8F0), width: 1)),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Row(
        children: [
          // Logo & Branding
          InkWell(
            onTap: () => _scrollController.animateTo(0, duration: const Duration(milliseconds: 400), curve: Curves.easeOut),
            borderRadius: BorderRadius.circular(8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.iron : const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isDark ? AppColors.rekkiBorderSubtle : Colors.transparent),
                  ),
                  child: const Icon(Icons.radar, color: AppColors.signalBlue, size: 20),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'AppRadar',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 19,
                        letterSpacing: -0.6,
                        color: isDark ? AppColors.paper : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Find. Analyze. Build.',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.smoke : const Color(0xFF2563EB).withValues(alpha: 0.9),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),
          Flexible(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Desktop Nav Links
                  if (!isMobile) ...[
                    _buildNavLink('Platform', () => _scrollToKey(_featuresKey), isDark),
                    const SizedBox(width: 14),
                    _buildNavLink('Leaderboard', () => _scrollToKey(_topChartsKey), isDark),
                    const SizedBox(width: 14),
                    _buildNavLink('Solutions', () => _scrollToKey(_featuresKey), isDark),
                    const SizedBox(width: 14),
                    _buildNavLink('Pricing', () => _scrollToKey(_pricingKey), isDark),
                    const SizedBox(width: 18),
                  ],

                  // Theme Mode Toggle Button
                  IconButton(
                    tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                    icon: Icon(
                      isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                      color: isDark ? const Color(0xFFFBBF24) : const Color(0xFF475569),
                      size: 20,
                    ),
                    onPressed: () => ThemeService.instance.toggleTheme(),
                  ),
                  const SizedBox(width: 6),

                  // Right CTAs
                  if (!widget.authService.isAuthenticated) ...[
                    OutlinedButton(
                      onPressed: widget.onOpenAuthModal,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark ? AppColors.paper : const Color(0xFF1E293B),
                        side: BorderSide(color: isDark ? AppColors.rekkiBorderSubtle : const Color(0xFFCBD5E1), width: 1.2),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        shape: const StadiumBorder(), // REKKI --radius-buttons: 59px
                      ),
                      child: const Text('Sign In', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                  ],

                  if (isMobile) ...[
                    const SizedBox(width: 8),
                    Builder(
                      builder: (ctx) => IconButton(
                        icon: Icon(Icons.menu, color: isDark ? Colors.white : const Color(0xFF1E293B)),
                        onPressed: () => Scaffold.of(ctx).openEndDrawer(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavLink(String title, VoidCallback onTap, [bool isDark = false]) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.ash : const Color(0xFF475569), // REKKI --color-ash: #858585
            letterSpacing: -0.1,
          ),
        ),
      ),
    );
  }

  Widget _buildMobileDrawer(bool isDark) {
    return Drawer(
      child: Container(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.radar, color: Color(0xFF2563EB), size: 24),
                const SizedBox(width: 8),
                Text('AppRadar', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                const Spacer(),
                IconButton(icon: Icon(Icons.close, color: isDark ? Colors.white : Colors.black), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const Divider(height: 32),
            ListTile(
              leading: Icon(
                isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                color: isDark ? const Color(0xFFFBBF24) : const Color(0xFF2563EB),
              ),
              title: Text(
                isDark ? 'Light Mode' : 'Dark Mode',
                style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF0F172A)),
              ),
              trailing: Switch(
                value: isDark,
                onChanged: (_) => ThemeService.instance.toggleTheme(),
                activeThumbColor: const Color(0xFF2563EB),
              ),
              onTap: () => ThemeService.instance.toggleTheme(),
            ),
            ListTile(
              leading: const Icon(Icons.view_carousel_outlined, color: Color(0xFF2563EB)),
              title: Text('Platform Features', style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF0F172A))),
              onTap: () {
                Navigator.pop(context);
                _scrollToKey(_featuresKey);
              },
            ),
            ListTile(
              leading: const Icon(Icons.leaderboard_outlined, color: Color(0xFF2563EB)),
              title: Text('Store Rankings', style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF0F172A))),
              onTap: () {
                Navigator.pop(context);
                _scrollToKey(_topChartsKey);
              },
            ),
            ListTile(
              leading: const Icon(Icons.bolt, color: Color(0xFF2563EB)),
              title: Text('Pricing & Plans', style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF0F172A))),
              onTap: () {
                Navigator.pop(context);
                _scrollToKey(_pricingKey);
              },
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  if (widget.authService.isAuthenticated) {
                    widget.onLaunchConsole();
                  } else if (widget.onGetStarted != null) {
                    widget.onGetStarted!();
                  } else {
                    widget.onOpenAuthModal();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D4ED8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Get Started Free',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (!widget.authService.isAuthenticated)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onOpenAuthModal();
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Sign In', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 2. HERO SECTION (Split Hero / MobileAction)
  // ==========================================
  Widget _buildHeroSection(bool isMobile, bool isTablet) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1100;
    final isDark = ThemeService.instance.isDark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.obsidian : Colors.white,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 18 : (isTablet ? 32 : 56),
        vertical: isMobile ? 32 : 56,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 5,
                      child: _buildHeroLeftContent(isMobile, isTablet),
                    ),
                    const SizedBox(width: 44),
                    Expanded(
                      flex: 6,
                      child: _buildHeroMockupDashboard(isMobile),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroLeftContent(isMobile, isTablet),
                    const SizedBox(height: 36),
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 680),
                        child: _buildHeroMockupDashboard(isMobile),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildHeroLeftContent(bool isMobile, bool isTablet) {
    final isDark = ThemeService.instance.isDark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Eyebrow Tag (REKKI Status Pill)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? AppColors.iron : const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(59), // REKKI --radius-full: 59px
            border: Border.all(color: isDark ? AppColors.rekkiBorderSubtle : const Color(0xFFBFDBFE)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.radar_rounded, size: 14, color: AppColors.signalBlue),
              const SizedBox(width: 6),
              Text(
                'GLOBAL STORE TELEMETRY & APP INTELLIGENCE',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.paper : const Color(0xFF1D4ED8),
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // Architectural Whisper-Weight Headline (REKKI Diatype style: weight 400 with negative tracking)
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: isMobile ? 36 : (isTablet ? 44 : 54),
              fontWeight: FontWeight.w400, // REKKI: Whisper-weight display headline
              color: isDark ? AppColors.paper : const Color(0xFF0F172A),
              height: 1.10,
              letterSpacing: -2.0, // REKKI tight tracking
            ),
            children: [
              const TextSpan(text: 'Build\napp store\nintelligence on\n'),
              TextSpan(
                text: _dynamicHeroWords[_activeHeroWordIndex],
                style: const TextStyle(
                  color: AppColors.signalBlue,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const TextSpan(
                text: ' |',
                style: TextStyle(
                  color: AppColors.signalBlue,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Subtitle Heading
        Text(
          'Next-Gen Mobile App Intelligence & Market Telemetry',
          style: TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.paper : const Color(0xFF1E293B),
            letterSpacing: -0.2,
          ),
        ),

        const SizedBox(height: 12),

        // Description Paragraph
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Text(
            'Climb the charts on the App Store and Google Play Store. Uncover untapped micro-SaaS opportunities, track rival monetization, and auto-generate MVP blueprints in minutes.',
            style: TextStyle(
              fontSize: 14.5,
              height: 1.55,
              color: isDark ? AppColors.ash : const Color(0xFF475569), // REKKI Ash #858585
              fontWeight: FontWeight.w400,
            ),
          ),
        ),

        const SizedBox(height: 28),

        // Dual Action Buttons (REKKI 59px pill buttons)
        Wrap(
          spacing: 14,
          runSpacing: 12,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                if (widget.authService.isAuthenticated) {
                  widget.onLaunchConsole();
                } else if (widget.onGetStarted != null) {
                  widget.onGetStarted!();
                } else {
                  widget.onOpenAuthModal();
                }
              },
              icon: const Icon(
                Icons.arrow_forward_rounded,
                size: 17,
              ),
              label: const Text(
                'Get Started Free',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.signalBlue, // REKKI Signal Blue #0063e1
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                elevation: 0,
                shadowColor: Colors.transparent, // REKKI: zero drop shadows
                shape: const StadiumBorder(), // REKKI --radius-buttons: 59px
              ),
            ),

            OutlinedButton.icon(
              onPressed: () => _scrollToKey(_topChartsKey),
              icon: const Icon(Icons.leaderboard_outlined, size: 17),
              label: const Text(
                'Explore Live Charts',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark ? AppColors.paper : const Color(0xFF0F172A),
                backgroundColor: isDark ? AppColors.iron : Colors.white,
                side: BorderSide(color: isDark ? AppColors.rekkiBorderSubtle : const Color(0xFFCBD5E1), width: 1.2),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: const StadiumBorder(), // REKKI --radius-buttons: 59px
              ),
            ),
          ],
        ),

        const SizedBox(height: 22),

        // Dual-Store Live Telemetry Line
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.apple, size: 18, color: isDark ? Colors.white : const Color(0xFF0F172A)),
            const SizedBox(width: 4),
            const Icon(Icons.android, size: 18, color: Color(0xFF10B981)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Dual-Store Live Telemetry • Apple App Store & Google Play',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // RIGHT COLUMN: PRODUCT MOCKUP DASHBOARD
  // ==========================================
  Widget _buildHeroMockupDashboard(bool isMobile) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. TOP MAIN CARD: Search & Store Telemetry Intelligence (Like MobileAction)
        _buildTopTelemetryMockupCard(isMobile),
        const SizedBox(height: 14),
        // 2. BOTTOM SPLIT MOCKUP CARDS: Opportunity Radar + Store Teardown
        if (isMobile) ...[
          _buildOpportunityRadarMiniCard(),
          const SizedBox(height: 12),
          _buildTeardownMiniCard(),
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildOpportunityRadarMiniCard()),
              const SizedBox(width: 14),
              Expanded(child: _buildTeardownMiniCard()),
            ],
          ),
      ],
    );
  }

  Widget _buildTopTelemetryMockupCard(bool isMobile) {
    final isDark = ThemeService.instance.isDark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.carbon : Colors.white,
        borderRadius: BorderRadius.circular(16), // REKKI --radius-cards: 16px
        border: Border.all(color: isDark ? AppColors.rekkiBorderSubtle : const Color(0xFFE2E8F0), width: 1),
        boxShadow: isDark
            ? [] // REKKI: zero drop shadows, elevation via inset border and surface steps
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Icon + Search Ads / Store Telemetry
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.iron : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.bar_chart_rounded, size: 16, color: AppColors.signalBlue),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Store Telemetry & Opportunity Radar',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.paper : const Color(0xFF475569),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.iron : const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(59), // REKKI status pill
                  border: Border.all(color: isDark ? AppColors.rekkiBorderSubtle : const Color(0xFFA7F3D0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.fiber_manual_record, size: 8, color: Color(0xFF10B981)),
                    const SizedBox(width: 4),
                    Text(
                      'LIVE FEED',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Search Input Bar with "Top 100" selector (MobileAction style)
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                const Icon(Icons.search, size: 16, color: Color(0xFF94A3B8)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onSubmitted: (_) => _handleHeroSearch(),
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                    decoration: const InputDecoration(
                      hintText: 'Search for app or publisher...',
                      hintStyle: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                Container(
                  height: 24,
                  width: 1,
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: [
                      Text(
                        'Top 100',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF475569)),
                      ),
                      const Icon(Icons.keyboard_arrow_down, size: 14, color: Color(0xFF64748B)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16, color: Color(0xFF2563EB)),
                  onPressed: _handleHeroSearch,
                  tooltip: 'Search in Console',
                  splashRadius: 16,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Filter row (MobileAction style: Country, Date, CSV)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildMockupFilterChip('🇺🇸 United States', Icons.keyboard_arrow_down, isDark),
                const SizedBox(width: 8),
                _buildMockupFilterChip('📅 Real-Time Telemetry', Icons.keyboard_arrow_down, isDark),
                const SizedBox(width: 8),
                _buildMockupFilterChip('📥 CSV Export', null, isDark),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Telemetry Data Table Rows (MobileAction table style)
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            child: Column(
              children: [
                _buildMockupTableRow(
                  keyword: 'habit tracker & routine',
                  category: 'Productivity',
                  oppScore: '98/100',
                  scoreColor: const Color(0xFF10B981),
                  growth: '+22.4%',
                  appIcons: const [
                    Color(0xFF3B82F6),
                    Color(0xFF10B981),
                    Color(0xFFF59E0B),
                  ],
                  isDark: isDark,
                ),
                Divider(height: 12, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                _buildMockupTableRow(
                  keyword: 'sleep sound & white noise',
                  category: 'Health & Fit',
                  oppScore: '89/100',
                  scoreColor: const Color(0xFF059669),
                  growth: '+18.1%',
                  appIcons: const [
                    Color(0xFF8B5CF6),
                    Color(0xFFEC4899),
                    Color(0xFF06B6D4),
                  ],
                  isDark: isDark,
                ),
                Divider(height: 12, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                _buildMockupTableRow(
                  keyword: 'ai invoice & receipt scanner',
                  category: 'Business',
                  oppScore: '96/100',
                  scoreColor: const Color(0xFF16A34A),
                  growth: '+34.8%',
                  appIcons: const [
                    Color(0xFFF97316),
                    Color(0xFF6366F1),
                    Color(0xFF14B8A6),
                  ],
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMockupFilterChip(String label, IconData? trailingIcon, [bool isDark = false]) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155)),
          ),
          if (trailingIcon != null) ...[
            const SizedBox(width: 2),
            Icon(trailingIcon, size: 13, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ],
        ],
      ),
    );
  }

  Widget _buildMockupTableRow({
    required String keyword,
    required String category,
    required String oppScore,
    required Color scoreColor,
    required String growth,
    required List<Color> appIcons,
    bool isDark = false,
  }) {
    return Row(
      children: [
        const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF10B981)),
        const SizedBox(width: 6),
        Expanded(
          flex: 4,
          child: Text(
            keyword,
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF1E293B)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: scoreColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            oppScore,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: scoreColor),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 48,
          height: 18,
          child: Stack(
            children: [
              for (int i = 0; i < appIcons.length; i++)
                Positioned(
                  left: i * 12.0,
                  child: Container(
                    width: 17,
                    height: 17,
                    decoration: BoxDecoration(
                      color: appIcons[i],
                      shape: BoxShape.circle,
                      border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.white, width: 1.5),
                    ),
                    child: const Icon(Icons.apps, size: 9, color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          growth,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF059669)),
        ),
      ],
    );
  }

  Widget _buildOpportunityRadarMiniCard() {
    final isDark = ThemeService.instance.isDark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.carbon : Colors.white,
        borderRadius: BorderRadius.circular(16), // REKKI --radius-cards: 16px
        border: Border.all(color: isDark ? AppColors.rekkiBorderSubtle : const Color(0xFFE2E8F0)),
        boxShadow: isDark
            ? [] // REKKI: zero drop shadows
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_fire_department_rounded, size: 15, color: Color(0xFFF97316)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'AI Opportunity Scores',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: isDark ? AppColors.paper : const Color(0xFF475569)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.iron : const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(59), // REKKI pill status
                  border: Border.all(color: isDark ? AppColors.rekkiBorderSubtle : Colors.transparent),
                ),
                child: Text('94 / 100', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: isDark ? const Color(0xFFFED7AA) : const Color(0xFFEA580C))),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.iron : const Color(0xFFF97316),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.bolt, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('HabitFlow Micro-SaaS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isDark ? AppColors.paper : const Color(0xFF0F172A)), overflow: TextOverflow.ellipsis),
                    Text('Productivity • US Store', style: TextStyle(fontSize: 10.5, color: isDark ? AppColors.ash : const Color(0xFF64748B)), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildPhonePreviewStrip(isDark ? AppColors.iron : const Color(0xFFEFF6FF), const Color(0xFF3B82F6)),
              const SizedBox(width: 6),
              _buildPhonePreviewStrip(isDark ? AppColors.iron : const Color(0xFFF0FDF4), const Color(0xFF10B981)),
              const SizedBox(width: 6),
              _buildPhonePreviewStrip(isDark ? AppColors.iron : const Color(0xFFFAF5FF), const Color(0xFF8B5CF6)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhonePreviewStrip(Color bg, Color accent) {
    return Expanded(
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: accent.withValues(alpha: 0.25)),
        ),
        padding: const EdgeInsets.all(4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 14, height: 3, decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 4),
            Container(width: 22, height: 2, decoration: BoxDecoration(color: accent.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(2))),
            const Spacer(),
            Center(child: Icon(Icons.insert_chart_outlined_rounded, size: 14, color: accent)),
          ],
        ),
      ),
    );
  }

  Widget _buildTeardownMiniCard() {
    final isDark = ThemeService.instance.isDark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.carbon : Colors.white,
        borderRadius: BorderRadius.circular(16), // REKKI --radius-cards: 16px
        border: Border.all(color: isDark ? AppColors.rekkiBorderSubtle : const Color(0xFFE2E8F0)),
        boxShadow: isDark
            ? [] // REKKI: zero drop shadows
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.travel_explore_rounded, size: 15, color: isDark ? AppColors.signalBlue : const Color(0xFF8B5CF6)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Teardown Telemetry',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: isDark ? AppColors.paper : const Color(0xFF475569),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.iron : const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'REVERSED',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                    color: isDark ? AppColors.ash : const Color(0xFF7C3AED),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTeardownMetric('Downloads', '185K', '+12%', isDark),
                    const SizedBox(height: 5),
                    _buildTeardownMetric('Revenue', '\$42.5K', '+18%', isDark),
                    const SizedBox(height: 5),
                    _buildTeardownMetric('Tech', 'Flutter + SQL', null, isDark),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.graphite : null,
                  gradient: isDark
                      ? null
                      : const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                        ),
                  border: isDark ? Border.all(color: AppColors.signalBlue.withValues(alpha: 0.4)) : null,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.query_stats, color: isDark ? AppColors.signalBlue : Colors.white, size: 20),
                    const SizedBox(height: 2),
                    Text(
                      'ARR',
                      style: TextStyle(
                        fontSize: 7.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.ash : Colors.white70,
                      ),
                    ),
                    Text(
                      '\$510K',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        color: isDark ? AppColors.paper : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeardownMetric(String label, String value, String? badge, [bool isDark = false]) {
    return Row(
      children: [
        Flexible(
          child: Text(
            '$label: ',
            style: TextStyle(fontSize: 10, color: isDark ? AppColors.ash : const Color(0xFF64748B)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: isDark ? AppColors.paper : const Color(0xFF0F172A)),
        ),
        if (badge != null) ...[
          const SizedBox(width: 3),
          Text(
            badge,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF10B981)),
          ),
        ],
      ],
    );
  }

  // ==========================================
  // 3. SOCIAL PROOF & MARQUEE
  // ==========================================
  Widget _buildSocialProofMarquee(bool isMobile) {
    final isDark = ThemeService.instance.isDark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.obsidian : const Color(0xFFF8FAFC),
        border: Border.symmetric(horizontal: BorderSide(color: isDark ? AppColors.rekkiBorderSubtle : const Color(0xFFE2E8F0))),
      ),
      child: Column(
        children: [
          Text(
            'TRUSTED BY 5,000+ MOBILE DEVELOPERS & GROWTH TEAMS WORLDWIDE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.ash : const Color(0xFF94A3B8),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const SizedBox(width: 24),
                _buildCategoryBadge('🎮 Gaming Studios', const Color(0xFF8B5CF6), isDark),
                _buildCategoryBadge('⚡ Productivity Utilities', AppColors.signalBlue, isDark),
                _buildCategoryBadge('🧘 Health & Fitness', const Color(0xFF10B981), isDark),
                _buildCategoryBadge('💳 FinTech Apps', const Color(0xFFF59E0B), isDark),
                _buildCategoryBadge('🛍️ Mobile E-Commerce', const Color(0xFFEC4899), isDark),
                _buildCategoryBadge('🤖 AI Micro-SaaS', const Color(0xFF06B6D4), isDark),
                const SizedBox(width: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBadge(String label, Color color, [bool isDark = false]) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.carbon : Colors.white,
        borderRadius: BorderRadius.circular(59), // REKKI 59px pill
        border: Border.all(color: isDark ? AppColors.rekkiBorderSubtle : color.withValues(alpha: 0.3)),
        boxShadow: isDark
            ? [] // REKKI: zero drop shadows
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: isDark ? AppColors.paper : color),
      ),
    );
  }

  // ==========================================
  // 4. INTERACTIVE PRODUCT SUITE TABS (MobileAction)
  // ==========================================
  Widget _buildProductSuiteTabsSection(bool isMobile, bool isTablet) {
    final isDark = ThemeService.instance.isDark;

    return Container(
      key: _featuresKey,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 18 : 36,
        vertical: isMobile ? 36 : 60,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1140),
          child: Column(
            children: [
              // Section Header
              Text(
                'EVERYTHING YOU NEED TO WIN THE APP STORES',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.signalBlue : const Color(0xFF2563EB),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Complete Intelligence & Telemetry Suite',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isMobile ? 26 : 34,
                  fontWeight: FontWeight.w500, // REKKI whisper-weight
                  color: isDark ? AppColors.paper : const Color(0xFF0F172A),
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Text(
                  'Switch between tabs below to explore how AppRadar transforms raw store signals into actionable opportunities and production blueprints.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.5,
                    color: isDark ? AppColors.ash : const Color(0xFF64748B),
                    height: 1.5,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Interactive Tab Switcher Buttons (Like MobileAction)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _buildFeatureTabItem(0, 'Store Telemetry', Icons.leaderboard_outlined, AppColors.signalBlue, isDark),
                  _buildFeatureTabItem(1, 'Opportunity Radar', Icons.local_fire_department_outlined, const Color(0xFFF97316), isDark),
                  _buildFeatureTabItem(2, 'Instant Teardown', Icons.travel_explore_outlined, const Color(0xFF10B981), isDark),
                  _buildFeatureTabItem(3, 'Competitor Matrix', Icons.compare_arrows_outlined, const Color(0xFF8B5CF6), isDark),
                  _buildFeatureTabItem(4, 'Build With AI', Icons.auto_awesome, const Color(0xFFEC4899), isDark),
                ],
              ),

              const SizedBox(height: 28),

              // Active Tab Content Display
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: KeyedSubtree(
                  key: ValueKey(_selectedProductTab),
                  child: _buildActiveTabContent(isMobile, isTablet),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureTabItem(int index, String title, IconData icon, Color color, [bool isDark = false]) {
    final isSelected = _selectedProductTab == index;
    return InkWell(
      onTap: () => setState(() => _selectedProductTab = index),
      borderRadius: BorderRadius.circular(59), // REKKI 59px pill
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.signalBlue : color)
              : (isDark ? AppColors.carbon : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(59), // REKKI 59px pill
          border: Border.all(
            color: isSelected
                ? (isDark ? AppColors.signalBlue : color)
                : (isDark ? AppColors.rekkiBorderSubtle : const Color(0xFFE2E8F0)),
          ),
          boxShadow: isDark || !isSelected
              ? [] // REKKI: zero drop shadows
              : [
                  BoxShadow(
                    color: color.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : (isDark ? AppColors.ash : const Color(0xFF475569))),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : (isDark ? AppColors.paper : const Color(0xFF475569)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTabContent(bool isMobile, bool isTablet) {
    switch (_selectedProductTab) {
      case 0:
        return _buildStoreTelemetryTab(isMobile);
      case 1:
        return _buildOpportunityRadarTab(isMobile);
      case 2:
        return _buildInstantTeardownTab(isMobile);
      case 3:
        return _buildCompetitorMatrixTab(isMobile);
      case 4:
      default:
        return _buildBuildWithAiTab(isMobile);
    }
  }

  // Tab 0: Store Telemetry with embedded TopChartsLeaderboard
  Widget _buildStoreTelemetryTab(bool isMobile) {
    final isDark = ThemeService.instance.isDark;

    return Container(
      key: _topChartsKey,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.carbon : Colors.white,
        borderRadius: BorderRadius.circular(16), // REKKI 16px radius
        border: Border.all(color: isDark ? AppColors.rekkiBorderSubtle : const Color(0xFFE2E8F0)),
        boxShadow: isDark
            ? [] // REKKI zero drop shadows
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.iron : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.leaderboard_rounded, color: isDark ? AppColors.signalBlue : const Color(0xFF2563EB), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Live Dual-Store Leaderboard',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.paper : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Real-time ranking movements across Top Free, Top Paid, and Top Grossing categories.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark ? AppColors.ash : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  if (!widget.authService.isAuthenticated) {
                    (widget.onGetStarted ?? widget.onOpenAuthModal)();
                  } else {
                    widget.onNavigateToConsoleTab?.call(0);
                    widget.onLaunchConsole();
                  }
                },
                icon: Icon(widget.authService.isAuthenticated ? Icons.open_in_new : Icons.lock_open_rounded, size: 14),
                label: Text(
                  widget.authService.isAuthenticated ? 'Open in Console' : 'Get Started to Unlock',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.signalBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: const StadiumBorder(), // REKKI 59px pill button
                ),
              ),
            ],
          ),
          Divider(height: 28, color: isDark ? AppColors.rekkiBorderSubtle : const Color(0xFFE2E8F0)),
          // Live Embedded TopChartsLeaderboard!
          TopChartsLeaderboard(
            apps: _cachedApps,
            onOpenApp: (app) {
              if (!widget.authService.isAuthenticated) {
                (widget.onGetStarted ?? widget.onOpenAuthModal)();
              } else {
                widget.onOpenAppDetail?.call(app);
                widget.onLaunchConsole();
              }
            },
          ),
        ],
      ),
    );
  }

  // Tab 1: AI Opportunity Radar
  Widget _buildOpportunityRadarTab(bool isMobile) {
    return _buildFeatureDetailCard(
      title: 'AI Opportunity Radar & Gap Discovery',
      description: 'Algorithmic 0–100 scores analyzing market saturation, competitor weaknesses, and unbundling opportunities before big publishers notice.',
      badgeColor: const Color(0xFFF97316),
      icon: Icons.local_fire_department_rounded,
      features: const [
        'Saturation Meter: Analyzes organic competition in every store genre',
        'Monetization Gaps: Highlights high-ARPU app concepts with low ad resistance',
        'Unbundling Detector: Identifies bloated mega-apps ripe for streamlined micro-SaaS alternatives',
      ],
      previewWidget: _buildOpportunityScoreMockup(),
      ctaText: widget.authService.isAuthenticated ? 'Explore Opportunities in Console' : 'Get Started Free to Unlock',
      onCta: () {
        if (!widget.authService.isAuthenticated) {
          (widget.onGetStarted ?? widget.onOpenAuthModal)();
        } else {
          widget.onNavigateToConsoleTab?.call(1);
          widget.onLaunchConsole();
        }
      },
    );
  }

  // Tab 2: Instant URL Teardown
  Widget _buildInstantTeardownTab(bool isMobile) {
    return _buildFeatureDetailCard(
      title: 'Instant Store URL Reverse-Engineering',
      description: 'Paste any App Store or Google Play URL to instantly extract revenue estimates, download velocity, tech stack detection, and monetization teardowns.',
      badgeColor: const Color(0xFF10B981),
      icon: Icons.travel_explore_rounded,
      features: const [
        'Instant Store Link Parser: Supports apps.apple.com and play.google.com URLs',
        'Telemetry Estimation: Estimated monthly active users, downloads, and revenue',
        'Export Capabilities: One-click export to CSV & JSON for investment & growth decks',
      ],
      previewWidget: _buildTeardownMockup(),
      ctaText: widget.authService.isAuthenticated ? 'Launch App Explorer in Console' : 'Get Started Free to Reverse-Engineer',
      onCta: () {
        if (!widget.authService.isAuthenticated) {
          (widget.onGetStarted ?? widget.onOpenAuthModal)();
        } else {
          widget.onNavigateToConsoleTab?.call(2);
          widget.onLaunchConsole();
        }
      },
    );
  }

  // Tab 3: Competitor Intelligence Matrix
  Widget _buildCompetitorMatrixTab(bool isMobile) {
    return _buildFeatureDetailCard(
      title: 'Competitor Intelligence Matrix',
      description: 'Direct head-to-head benchmarking. Track rivals\' release cadences, keyword strategy, pricing updates, and user complaint patterns.',
      badgeColor: const Color(0xFF8B5CF6),
      icon: Icons.compare_arrows_rounded,
      features: const [
        'Head-to-head feature matrix and release history tracking',
        'Negative review mining to spot where competitors fail users',
        'Opportunity unbundling roadmap directly linked to market gaps',
      ],
      previewWidget: _buildCompetitorMatrixMockup(),
      ctaText: widget.authService.isAuthenticated ? 'Open Competitors in Console' : 'Get Started Free to Benchmark',
      onCta: () {
        if (!widget.authService.isAuthenticated) {
          (widget.onGetStarted ?? widget.onOpenAuthModal)();
        } else {
          widget.onNavigateToConsoleTab?.call(3);
          widget.onLaunchConsole();
        }
      },
    );
  }

  // Tab 4: Build With AI
  Widget _buildBuildWithAiTab(bool isMobile) {
    return _buildFeatureDetailCard(
      title: 'Build With AI: Idea to App Store in 14 Days',
      description: 'Turn market opportunities into execution-ready products with Gemini Pro 1.5 AI. Generates complete 14-section architectural blueprints, PostgreSQL schemas, and Flutter MVPs.',
      badgeColor: const Color(0xFFEC4899),
      icon: Icons.auto_awesome,
      features: const [
        'Complete 14-section execution blueprints tailored for solo builders & studios',
        'Production PostgreSQL / Supabase SQL schema design ready to deploy',
        '5-step agile MVP execution roadmap to validate and ship in record time',
      ],
      previewWidget: _buildAiBlueprintMockup(),
      ctaText: widget.authService.isAuthenticated ? 'Build With AI in Console' : 'Get Started Free to Build Blueprint',
      onCta: () {
        if (!widget.authService.isAuthenticated) {
          (widget.onGetStarted ?? widget.onOpenAuthModal)();
        } else {
          widget.onNavigateToConsoleTab?.call(8);
          widget.onLaunchConsole();
        }
      },
    );
  }

  Widget _buildFeatureDetailCard({
    required String title,
    required String description,
    required Color badgeColor,
    required IconData icon,
    required List<String> features,
    required Widget previewWidget,
    required String ctaText,
    required VoidCallback onCta,
  }) {
    final isDark = ThemeService.instance.isDark;

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark ? AppColors.carbon : Colors.white,
        borderRadius: BorderRadius.circular(16), // REKKI 16px radius
        border: Border.all(color: isDark ? AppColors.rekkiBorderSubtle : const Color(0xFFE2E8F0)),
        boxShadow: isDark
            ? [] // REKKI zero drop shadows
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.iron : badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: isDark ? AppColors.signalBlue : badgeColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.paper : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.ash : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          previewWidget,
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: features.map((f) {
              return Container(
                constraints: const BoxConstraints(maxWidth: 540),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.iron : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isDark ? AppColors.rekkiBorderSubtle : const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 14, color: isDark ? AppColors.signalBlue : badgeColor),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        f,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.paper : const Color(0xFF334155),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Center(
            child: ElevatedButton.icon(
              onPressed: onCta,
              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              label: Text(ctaText, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? AppColors.signalBlue : badgeColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: const StadiumBorder(), // REKKI 59px pill button
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Mockup cards for interactive tabs
  Widget _buildOpportunityScoreMockup() {
    final isDark = ThemeService.instance.isDark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.graphite : const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.rekkiBorderSubtle : const Color(0xFFFED7AA)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.iron : const Color(0xFFEA580C),
              borderRadius: BorderRadius.circular(12),
              border: isDark ? Border.all(color: AppColors.signalBlue.withValues(alpha: 0.4)) : null,
            ),
            child: Column(
              children: [
                Text('94/100', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: isDark ? AppColors.signalBlue : Colors.white)),
                Text('OPPORTUNITY', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: isDark ? AppColors.ash : Colors.white70)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'High-Velocity Micro-SaaS Niche Detected',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: isDark ? AppColors.paper : const Color(0xFF9A3412)),
                ),
                const SizedBox(height: 4),
                Text(
                  'Low competitor density • 68% dissatisfied user sentiment on market leaders • High organic search volume',
                  style: TextStyle(fontSize: 12, color: isDark ? AppColors.ash : const Color(0xFFC2410C)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeardownMockup() {
    final isDark = ThemeService.instance.isDark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.graphite : const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.rekkiBorderSubtle : const Color(0xFFA7F3D0)),
      ),
      child: Row(
        children: [
          Icon(Icons.link_rounded, color: isDark ? AppColors.signalBlue : const Color(0xFF059669), size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'https://apps.apple.com/app/id123456789',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: isDark ? AppColors.paper : const Color(0xFF065F46)),
                ),
                const SizedBox(height: 4),
                Text(
                  'Estimated 185K Monthly Active Users • \$42.5K/mo In-App Purchases • Flutter + RevenueCat Stack Detected',
                  style: TextStyle(fontSize: 11.5, color: isDark ? AppColors.ash : const Color(0xFF047857)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompetitorMatrixMockup() {
    final isDark = ThemeService.instance.isDark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.graphite : const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.rekkiBorderSubtle : const Color(0xFFDDD6FE)),
      ),
      child: Row(
        children: [
          Icon(Icons.hub_rounded, color: isDark ? AppColors.signalBlue : const Color(0xFF7C3AED), size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Head-to-Head Positioning Benchmark',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: isDark ? AppColors.paper : const Color(0xFF5B21B6)),
                ),
                const SizedBox(height: 4),
                Text(
                  'Competitors lag in dark mode & widget support • 42% user complaints cite subscription billing traps',
                  style: TextStyle(fontSize: 11.5, color: isDark ? AppColors.ash : const Color(0xFF6D28D9)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiBlueprintMockup() {
    final isDark = ThemeService.instance.isDark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.graphite : const Color(0xFFFDF2F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.rekkiBorderSubtle : const Color(0xFFFBCFE8)),
      ),
      child: Row(
        children: [
          Icon(Icons.terminal_rounded, color: isDark ? AppColors.signalBlue : const Color(0xFFDB2777), size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CREATE TABLE user_telemetry ( id UUID PRIMARY KEY, app_id TEXT... );',
                  style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w700, fontSize: 12, color: isDark ? AppColors.paper : const Color(0xFF9D174D)),
                ),
                const SizedBox(height: 4),
                Text(
                  'Production schema generated • 14-section architectural design ready to copy into your codebase',
                  style: TextStyle(fontSize: 11.5, color: isDark ? AppColors.ash : const Color(0xFFBE185D)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 5. KEY PLATFORM METRICS
  // ==========================================
  Widget _buildKeyMetricsSection(bool isMobile) {
    final isDark = ThemeService.instance.isDark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.obsidian : const Color(0xFF0F172A),
        border: Border.symmetric(horizontal: BorderSide(color: isDark ? AppColors.rekkiBorderSubtle : const Color(0xFF1E293B))),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1140),
          child: Column(
            children: [
              Text(
                'PROVEN AT SCALE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.signalBlue : const Color(0xFF60A5FA),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Data That Drives Market Winners',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w500, // REKKI whisper-weight
                  letterSpacing: -1.0,
                  color: isDark ? AppColors.paper : Colors.white,
                ),
              ),
              const SizedBox(height: 36),
              Wrap(
                spacing: 24,
                runSpacing: 24,
                alignment: WrapAlignment.center,
                children: [
                  _buildMetricStatCard('50M+', 'Store Signals Analyzed Daily', isMobile, isDark),
                  _buildMetricStatCard('94.2%', 'AI Blueprint Precision Rate', isMobile, isDark),
                  _buildMetricStatCard('14 Days', 'Avg. Time to Validate & Ship MVP', isMobile, isDark),
                  _buildMetricStatCard('175+', 'Global App Store Regions Tracked', isMobile, isDark),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricStatCard(String value, String label, bool isMobile, [bool isDark = false]) {
    return Container(
      width: isMobile ? 150 : 230,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.carbon : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16), // REKKI 16px radius
        border: Border.all(color: isDark ? AppColors.rekkiBorderSubtle : Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
              color: isDark ? AppColors.signalBlue : const Color(0xFF60A5FA),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.ash : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 6. QUANTIFIED CASE STUDIES (MobileAction)
  // ==========================================
  Widget _buildQuantifiedCaseStudies(bool isMobile, bool isTablet) {
    final isDark = ThemeService.instance.isDark;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 18 : 36, vertical: 48),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1140),
          child: Column(
            children: [
              Text(
                'CUSTOMER SUCCESS STORIES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.signalBlue : const Color(0xFF2563EB),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Real Growth. Real Results.',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w500, // REKKI whisper-weight
                  letterSpacing: -1.0,
                  color: isDark ? AppColors.paper : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 32),
              Wrap(
                spacing: 20,
                runSpacing: 20,
                alignment: WrapAlignment.center,
                children: [
                  _buildCaseStudyCard(
                    stat: '+210%',
                    metric: 'Organic Downloads Uplift',
                    quote: 'Uncovered 3 neglected micro-SaaS categories in Productivity using AppRadar Opportunities.',
                    author: 'Marcus Vance, Indie App Founder',
                    isMobile: isMobile,
                  ),
                  _buildCaseStudyCard(
                    stat: '65%',
                    metric: 'Faster Market Validation',
                    quote: 'Replaced 4 disconnected spreadsheet tools with Instant URL Teardown and Competitor Matrix.',
                    author: 'Elena Rostova, Lead UA Strategist',
                    isMobile: isMobile,
                  ),
                  _buildCaseStudyCard(
                    stat: '14 Days',
                    metric: 'From Idea to Play Store Launch',
                    quote: 'Generated complete Supabase schema & Flutter architecture with Build With AI in under 2 minutes.',
                    author: 'Tariq Al-Mansoor, Solo Developer',
                    isMobile: isMobile,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCaseStudyCard({
    required String stat,
    required String metric,
    required String quote,
    required String author,
    required bool isMobile,
  }) {
    final isDark = ThemeService.instance.isDark;

    return Container(
      width: isMobile ? double.infinity : 340,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.carbon : Colors.white,
        borderRadius: BorderRadius.circular(16), // REKKI 16px radius
        border: Border.all(color: isDark ? AppColors.rekkiBorderSubtle : const Color(0xFFE2E8F0)),
        boxShadow: isDark
            ? [] // REKKI zero drop shadows
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stat,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
              color: isDark ? AppColors.signalBlue : const Color(0xFF2563EB),
            ),
          ),
          Text(
            metric,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.ash : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '"$quote"',
            style: TextStyle(
              fontSize: 13.5,
              fontStyle: FontStyle.italic,
              color: isDark ? AppColors.paper : const Color(0xFF334155),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            author,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.ash : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 7. ENTERPRISE INTEGRATIONS
  // ==========================================
  Widget _buildEnterpriseIntegrations(bool isMobile) {
    final isDark = ThemeService.instance.isDark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.obsidian : const Color(0xFFF8FAFC),
        border: Border.symmetric(horizontal: BorderSide(color: isDark ? AppColors.rekkiBorderSubtle : const Color(0xFFE2E8F0))),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1140),
          child: Column(
            children: [
              Text(
                'ENTERPRISE ECOSYSTEM & SECURITY',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.ash : const Color(0xFF64748B),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 24,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  _buildIntegrationItem('Apple App Store Connect', Icons.apple, isDark),
                  _buildIntegrationItem('Google Play Console', Icons.shop_outlined, isDark),
                  _buildIntegrationItem('Supabase Enterprise Auth', Icons.lock_outline, isDark),
                  _buildIntegrationItem('Google Gemini 1.5 Pro AI', Icons.auto_awesome, isDark),
                  _buildIntegrationItem('Stripe Infrastructure', Icons.credit_card, isDark),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntegrationItem(String label, IconData icon, [bool isDark = false]) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: isDark ? AppColors.signalBlue : const Color(0xFF2563EB)),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.paper : const Color(0xFF334155),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 8. PRICING PLANS
  // ==========================================
  Widget _buildPricingSection(bool isMobile, bool isTablet) {
    final isDark = ThemeService.instance.isDark;

    return Container(
      key: _pricingKey,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 18 : 36, vertical: 56),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1060),
          child: Column(
            children: [
              // Eyebrow Tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.iron : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(59), // REKKI 59px pill
                  border: Border.all(color: isDark ? AppColors.rekkiBorderSubtle : const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt, size: 13, color: isDark ? AppColors.signalBlue : const Color(0xFF2563EB)),
                    const SizedBox(width: 5),
                    Text(
                      'SIMPLE, TRANSPARENT TIERS',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: isDark ? AppColors.signalBlue : const Color(0xFF1D4ED8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Title (Exact match to AppRadar PricingModal)
              Text(
                'Unlock Full Market Intelligence & AI Blueprints',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isMobile ? 24 : 32,
                  fontWeight: FontWeight.w500, // REKKI whisper-weight
                  letterSpacing: -1.0,
                  color: isDark ? AppColors.paper : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),

              // Subtitle
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Text(
                  'Get instant access to deep architectural teardowns, 14-section specifications, and daily market intelligence.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppColors.ash : const Color(0xFF64748B),
                    height: 1.45,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Monthly vs Annual Billing Toggle (Image 2 Match)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.graphite : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(59), // REKKI 59px pill
                    border: Border.all(color: isDark ? AppColors.rekkiBorderSubtle : const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildPricingToggleOption(
                        label: 'Monthly Billing',
                        isSelected: !_isAnnualPricing,
                        onSelect: () => setState(() => _isAnnualPricing = false),
                        isDark: isDark,
                      ),
                      _buildPricingToggleOption(
                        label: 'Annual Billing',
                        isSelected: _isAnnualPricing,
                        badge: 'SAVE 20%',
                        onSelect: () => setState(() => _isAnnualPricing = true),
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 36),

              // 3 Pricing Tier Cards (Grid / Column)
              if (isMobile)
                Column(
                  children: [
                    _buildLandingProCard(isDark),
                    const SizedBox(height: 18),
                    _buildLandingFreeCard(isDark),
                    const SizedBox(height: 18),
                    _buildLandingAgencyCard(isDark),
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildLandingFreeCard(isDark)),
                    const SizedBox(width: 18),
                    Expanded(child: _buildLandingProCard(isDark)),
                    const SizedBox(width: 18),
                    Expanded(child: _buildLandingAgencyCard(isDark)),
                  ],
                ),
              const SizedBox(height: 28),

              // Bottom Security & Guarantee Assurance (Image 2 Match)
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                runSpacing: 4,
                children: [
                  Icon(Icons.verified_user_outlined, size: 14, color: isDark ? AppColors.ash : const Color(0xFF64748B)),
                  Text(
                    'Guaranteed 256-bit secure checkout. Cancel anytime with 1 click. No questions asked.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.ash : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPricingToggleOption({
    required String label,
    required bool isSelected,
    String? badge,
    required VoidCallback onSelect,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onSelect,
      borderRadius: BorderRadius.circular(59), // REKKI 59px pill
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.iron : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(59), // REKKI 59px pill
          border: isSelected && isDark ? Border.all(color: AppColors.rekkiBorderSubtle) : null,
          boxShadow: isSelected && !isDark
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? (isDark ? AppColors.paper : const Color(0xFF0F172A))
                    : (isDark ? AppColors.ash : const Color(0xFF64748B)),
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.carbon : const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: isDark ? AppColors.signalBlue.withValues(alpha: 0.5) : const Color(0xFFA7F3D0)),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.signalBlue : const Color(0xFF047857),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // 1. Starter Free Card (Exact Image 2 Match)
  Widget _buildLandingFreeCard(bool isDark) {
    final isCurrent = widget.subscriptionService.isFree && widget.authService.isAuthenticated;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? AppColors.carbon : Colors.white,
        borderRadius: BorderRadius.circular(16), // REKKI 16px radius
        border: Border.all(color: isDark ? AppColors.rekkiBorderSubtle : const Color(0xFFE2E8F0)),
        boxShadow: isDark
            ? [] // REKKI zero drop shadows
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Starter Free',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.paper : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'For casual exploring',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.ash : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '\$0',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: isDark ? AppColors.paper : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '/ forever',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.ash : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (isCurrent)
            Container(
              height: 44,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? AppColors.iron : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(59), // REKKI 59px pill
                border: Border.all(color: isDark ? AppColors.rekkiBorderSubtle : const Color(0xFFE2E8F0)),
              ),
              child: Center(
                child: Text(
                  'Current Plan',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.ash : const Color(0xFF64748B),
                    fontSize: 13,
                  ),
                ),
              ),
            )
          else if (!widget.authService.isAuthenticated)
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton(
                onPressed: widget.onGetStarted ?? widget.onOpenAuthModal,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: isDark ? AppColors.rekkiBorderInput : const Color(0xFFCBD5E1)),
                  shape: const StadiumBorder(), // REKKI 59px pill button
                ),
                child: Text(
                  'Get Started Free',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: isDark ? AppColors.paper : const Color(0xFF0F172A),
                  ),
                ),
              ),
            )
          else
            OutlinedButton(
              onPressed: null,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
                shape: const StadiumBorder(), // REKKI 59px pill button
              ),
              child: const Text('Free Tier Included'),
            ),
          const SizedBox(height: 24),
          Divider(color: isDark ? AppColors.rekkiBorderSubtle : const Color(0xFFE2E8F0)),
          const SizedBox(height: 16),
          _buildPricingFeatureRow('3 AI App Teardowns / day', isIncluded: true, isDark: isDark),
          _buildPricingFeatureRow('Opportunity Radar Signals', isIncluded: true, isDark: isDark),
          _buildPricingFeatureRow('Up to 3 Watchlist Items', isIncluded: true, isDark: isDark),
          _buildPricingFeatureRow('14-Section Build Blueprints', isIncluded: false, isDark: isDark),
          _buildPricingFeatureRow('Daily Automated Email Digest', isIncluded: false, isDark: isDark),
          _buildPricingFeatureRow('Export Specs to JSON / MD', isIncluded: false, isDark: isDark),
        ],
      ),
    );
  }

  // 2. Pro Builder Card (Exact Image 2 Match)
  Widget _buildLandingProCard(bool isDark) {
    final isCurrent = widget.subscriptionService.isPro;
    final price = _isAnnualPricing ? '\$23' : '\$29';
    final billingNote = _isAnnualPricing ? 'billed \$279/year' : 'billed monthly';

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? AppColors.graphite : Colors.white,
        borderRadius: BorderRadius.circular(16), // REKKI 16px radius
        border: Border.all(color: AppColors.signalBlue, width: isDark ? 1.5 : 2),
        boxShadow: isDark
            ? [] // REKKI zero drop shadows
            : [
                BoxShadow(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                'Pro Builder',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.signalBlue : const Color(0xFF2563EB),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.signalBlue,
                  borderRadius: BorderRadius.circular(59), // REKKI 59px pill
                ),
                child: Text(
                  isCurrent ? 'ACTIVE PLAN' : 'MOST POPULAR',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'For indie hackers & builders',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.ash : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                price,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: isDark ? AppColors.paper : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '/ month',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.ash : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          Text(
            billingNote,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppColors.ash : const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 18),

          // Pro Action: Active Plan or Upgrade Modal
          if (isCurrent)
            Column(
              children: [
                Container(
                  height: 44,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.iron : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(59), // REKKI 59px pill
                    border: Border.all(color: AppColors.signalBlue.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, size: 18, color: AppColors.signalBlue),
                      const SizedBox(width: 8),
                      Text(
                        'Current Active Plan',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.signalBlue,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => widget.subscriptionService.launchCustomerPortal(),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    child: Text(
                      'Manage billing & payment methods →',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.signalBlue : const Color(0xFF60A5FA),
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            FilledButton.icon(
              onPressed: widget.onOpenPricingModal,
              icon: const Icon(Icons.bolt, size: 16),
              label: const Text('Upgrade to Pro Builder'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
                backgroundColor: AppColors.signalBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: const StadiumBorder(), // REKKI 59px pill button
              ),
            ),

          const SizedBox(height: 16),
          Divider(color: isDark ? AppColors.rekkiBorderSubtle : const Color(0xFFE2E8F0)),
          const SizedBox(height: 16),
          _buildPricingFeatureRow('Unlimited AI App Teardowns', isIncluded: true, isHighlight: true, isDark: isDark),
          _buildPricingFeatureRow('Complete 14-Section Build Blueprints', isIncluded: true, isHighlight: true, isDark: isDark),
          _buildPricingFeatureRow('Unlimited Cloud-Synced Watchlists', isIncluded: true, isDark: isDark),
          _buildPricingFeatureRow('Daily 8 AM Executive Intelligence Email', isIncluded: true, isDark: isDark),
          _buildPricingFeatureRow('Export Architecture Specs to MD/JSON', isIncluded: true, isDark: isDark),
          _buildPricingFeatureRow('Priority Scraper & Gemini AI Queue', isIncluded: true, isDark: isDark),
        ],
      ),
    );
  }

  // 3. Agency & Team Card (Exact Image 2 Match)
  Widget _buildLandingAgencyCard(bool isDark) {
    final price = _isAnnualPricing ? '\$63' : '\$79';
    final billingNote = _isAnnualPricing ? 'billed \$759/year' : 'billed monthly';

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? AppColors.carbon : Colors.white,
        borderRadius: BorderRadius.circular(16), // REKKI 16px radius
        border: Border.all(color: isDark ? AppColors.rekkiBorderSubtle : const Color(0xFFE2E8F0)),
        boxShadow: isDark
            ? [] // REKKI zero drop shadows
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Agency & Team',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.paper : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'For studios & development teams',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.ash : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                price,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: isDark ? AppColors.paper : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '/ month',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.ash : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          Text(
            billingNote,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppColors.ash : const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton(
            onPressed: () {
              AgencyInquiryModal.show(
                context,
                authService: widget.authService,
              );
            },
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 44),
              side: BorderSide(color: isDark ? AppColors.rekkiBorderInput : const Color(0xFFCBD5E1)),
              shape: const StadiumBorder(), // REKKI 59px pill button
            ),
            child: Text(
              'Contact for Custom Seats',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: isDark ? AppColors.paper : const Color(0xFF0F172A),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Divider(color: isDark ? AppColors.rekkiBorderSubtle : const Color(0xFFE2E8F0)),
          const SizedBox(height: 16),
          _buildPricingFeatureRow('Everything in Pro Builder', isIncluded: true, isDark: isDark),
          _buildPricingFeatureRow('5 Team Member Seats', isIncluded: true, isDark: isDark),
          _buildPricingFeatureRow('Custom Webhook Dispatchers', isIncluded: true, isDark: isDark),
          _buildPricingFeatureRow('Custom Store Category Scrapers', isIncluded: true, isDark: isDark),
          _buildPricingFeatureRow('Dedicated Slack & Discord Channel', isIncluded: true, isDark: isDark),
        ],
      ),
    );
  }

  // Feature row with checkmark or strikethrough minus
  Widget _buildPricingFeatureRow(
    String text, {
    required bool isIncluded,
    bool isHighlight = false,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isIncluded ? Icons.check_circle : Icons.remove_circle_outline,
            size: 16,
            color: isIncluded
                ? (isHighlight ? AppColors.signalBlue : const Color(0xFF10B981))
                : (isDark ? AppColors.iron : const Color(0xFF94A3B8)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w500,
                color: isIncluded
                    ? (isDark ? AppColors.paper : const Color(0xFF1E293B))
                    : (isDark ? AppColors.ash : const Color(0xFF94A3B8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 9. PRE-FOOTER CTA BANNER
  // ==========================================
  Widget _buildPreFooterCtaBanner(bool isMobile) {
    final isDark = ThemeService.instance.isDark;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 18 : 36, vertical: 36),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1140),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 48, vertical: isMobile ? 36 : 48),
            decoration: BoxDecoration(
              color: isDark ? AppColors.carbon : null,
              gradient: isDark
                  ? null
                  : const LinearGradient(
                      colors: [Color(0xFF1D4ED8), Color(0xFF1E40AF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              borderRadius: BorderRadius.circular(16), // REKKI 16px radius
              border: isDark ? Border.all(color: AppColors.rekkiBorderSubtle) : null,
              boxShadow: isDark
                  ? [] // REKKI zero drop shadows
                  : [
                      BoxShadow(
                        color: const Color(0xFF1D4ED8).withValues(alpha: 0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
            ),
            child: Column(
              children: [
                Text(
                  'Ready to Build Apps That Climb the Charts?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w500, // REKKI whisper-weight
                    color: isDark ? AppColors.paper : Colors.white,
                    letterSpacing: -1.0,
                  ),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Text(
                    'Join thousands of developers and growth teams using AppRadar to find market gaps, analyze competitors, and build market-winning apps.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.5,
                      color: isDark ? AppColors.ash : const Color(0xFFDBEAFE),
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Wrap(
                  spacing: 14,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        if (widget.authService.isAuthenticated) {
                          widget.onLaunchConsole();
                        } else if (widget.onGetStarted != null) {
                          widget.onGetStarted!();
                        } else {
                          widget.onOpenAuthModal();
                        }
                      },
                      icon: const Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                      ),
                      label: const Text(
                        'Get Started Free',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? AppColors.signalBlue : Colors.white,
                        foregroundColor: isDark ? Colors.white : const Color(0xFF1D4ED8),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: const StadiumBorder(), // REKKI 59px pill button
                      ),
                    ),
                    if (!widget.authService.isAuthenticated)
                      OutlinedButton.icon(
                        onPressed: widget.onOpenAuthModal,
                        icon: Icon(Icons.login_rounded, size: 18, color: isDark ? AppColors.paper : Colors.white),
                        label: Text(
                          'Sign In to Account',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14.5,
                            color: isDark ? AppColors.paper : Colors.white,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: isDark ? AppColors.rekkiBorderInput : Colors.white, width: 1.5),
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                          shape: const StadiumBorder(), // REKKI 59px pill button
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 10. FOOTER
  // ==========================================
  Widget _buildFooter(bool isMobile) {
    final isDark = ThemeService.instance.isDark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.obsidian : const Color(0xFF0F172A),
        border: Border(top: BorderSide(color: isDark ? AppColors.rekkiBorderSubtle : const Color(0xFF334155))),
      ),
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 48, vertical: 48),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1140),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.signalBlue,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.radar, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'AppRadar',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: isDark ? AppColors.paper : Colors.white,
                        ),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () {
                      if (widget.authService.isAuthenticated) {
                        widget.onLaunchConsole();
                      } else if (widget.onGetStarted != null) {
                        widget.onGetStarted!();
                      } else {
                        widget.onOpenAuthModal();
                      }
                    },
                    icon: Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: isDark ? AppColors.signalBlue : const Color(0xFF60A5FA),
                    ),
                    label: Text(
                      'Get Started Free',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.signalBlue : const Color(0xFF60A5FA),
                      ),
                    ),
                  ),
                ],
              ),
              Divider(color: isDark ? AppColors.rekkiBorderSubtle : const Color(0xFF334155), height: 36),
              if (isMobile)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '© 2026 AppRadar Inc. All rights reserved.',
                      style: TextStyle(fontSize: 12, color: isDark ? AppColors.fog : const Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 16,
                      children: [
                        InkWell(
                          onTap: () {},
                          child: Text('Privacy Policy', style: TextStyle(fontSize: 12, color: isDark ? AppColors.ash : const Color(0xFF94A3B8))),
                        ),
                        InkWell(
                          onTap: () {},
                          child: Text('Terms of Service', style: TextStyle(fontSize: 12, color: isDark ? AppColors.ash : const Color(0xFF94A3B8))),
                        ),
                        InkWell(
                          onTap: () {},
                          child: Text('Security', style: TextStyle(fontSize: 12, color: isDark ? AppColors.ash : const Color(0xFF94A3B8))),
                        ),
                      ],
                    ),
                  ],
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '© 2026 AppRadar Inc. All rights reserved.',
                      style: TextStyle(fontSize: 12, color: isDark ? AppColors.fog : const Color(0xFF64748B)),
                    ),
                    Wrap(
                      spacing: 16,
                      children: [
                        InkWell(
                          onTap: () {},
                          child: Text('Privacy Policy', style: TextStyle(fontSize: 12, color: isDark ? AppColors.ash : const Color(0xFF94A3B8))),
                        ),
                        InkWell(
                          onTap: () {},
                          child: Text('Terms of Service', style: TextStyle(fontSize: 12, color: isDark ? AppColors.ash : const Color(0xFF94A3B8))),
                        ),
                        InkWell(
                          onTap: () {},
                          child: Text('Security', style: TextStyle(fontSize: 12, color: isDark ? AppColors.ash : const Color(0xFF94A3B8))),
                        ),
                      ],
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
