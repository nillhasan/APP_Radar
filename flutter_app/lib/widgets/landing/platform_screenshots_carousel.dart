import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/theme_service.dart';

/// Interactive Auto-Moving Screenshot Showcase Carousel for AppRadar Front Page.
///
/// Features:
/// - 6 Real-world AppRadar platform screenshot mockups (Telemetry, Opportunity Radar,
///   Instant Teardown, Review Mining, Competitor Matrix, AI Blueprint)
/// - Auto-advance timer (every 4 seconds) with pause-on-hover
/// - Category selector chips at top for 1-click tab switching
/// - Left/right navigation buttons and interactive bottom indicator dots
/// - "Explore in Console (Get Started)" CTA that enforces the authentication flow
class PlatformScreenshotsCarousel extends StatefulWidget {
  final VoidCallback onGetStarted;

  const PlatformScreenshotsCarousel({
    super.key,
    required this.onGetStarted,
  });

  @override
  State<PlatformScreenshotsCarousel> createState() => _PlatformScreenshotsCarouselState();
}

class _PlatformScreenshotsCarouselState extends State<PlatformScreenshotsCarousel> {
  late final PageController _pageController;
  Timer? _autoPlayTimer;
  int _currentPage = 0;
  bool _isHovered = false;

  final List<_PlatformSlideData> _slides = [
    _PlatformSlideData(
      category: 'Store Telemetry',
      badge: 'LIVE APPLE & GOOGLE PLAY TELEMETRY',
      url: 'appradar.ai/console/dashboard/live-store-matrix',
      title: 'Real-Time Store Telemetry & Rankings Matrix',
      subtitle: 'Monitor hourly ranking shifts, download pulses, and estimated MRR across 2.8M+ apps in real time.',
      accentColor: const Color(0xFF2563EB),
      icon: Icons.radar,
    ),
    _PlatformSlideData(
      category: 'Opportunity Radar',
      badge: 'AI OPPORTUNITY ENGINE (0-100)',
      url: 'appradar.ai/console/opportunities/ai-gap-radar',
      title: 'AI Opportunity Radar & Gap Discovery',
      subtitle: 'Algorithmically uncover untapped micro-SaaS verticals with high willingness-to-pay and low competition.',
      accentColor: const Color(0xFF10B981),
      icon: Icons.local_fire_department_rounded,
    ),
    _PlatformSlideData(
      category: 'Instant Teardown',
      badge: '1-CLICK STORE REVERSE-ENGINEERING',
      url: 'appradar.ai/console/explorer/url-teardown',
      title: 'Store URL Reverse-Engineering & Tech Stack Teardown',
      subtitle: 'Paste any App Store or Google Play link to decompile monetization tiers, SDK stack, and pricing traps in 3 seconds.',
      accentColor: const Color(0xFF8B5CF6),
      icon: Icons.travel_explore_rounded,
    ),
    _PlatformSlideData(
      category: 'Review Mining',
      badge: 'CUSTOMER CHURN & SENTIMENT MINING',
      url: 'appradar.ai/console/review-mining/sentiment-analysis',
      title: 'Negative Review Mining: Turn Complaints into Gold',
      subtitle: 'Scrape thousands of 1★ & 2★ rival reviews to extract golden feature gaps that users are begging developers to build.',
      accentColor: const Color(0xFFF59E0B),
      icon: Icons.rate_review_outlined,
    ),
    _PlatformSlideData(
      category: 'Competitor Matrix',
      badge: 'SIDE-BY-SIDE BENCHMARK WAR ROOM',
      url: 'appradar.ai/console/competitors/market-matrix',
      title: 'Competitor Intelligence Matrix & Strategy Benchmarks',
      subtitle: 'Analyze your benchmark app against top 5 store rivals across pricing tiers, feature coverage, and velocity.',
      accentColor: const Color(0xFF06B6D4),
      icon: Icons.compare_arrows_rounded,
    ),
    _PlatformSlideData(
      category: 'AI Blueprint',
      badge: 'GEMINI 3.8 FLASH SYNTHESIS',
      url: 'appradar.ai/console/build-with-ai/gemini-blueprint',
      title: 'Build With AI: Idea to App Store in 14 Days',
      subtitle: 'Auto-synthesize 14-section production blueprints: MVP features, PostgreSQL schemas, and 14-day execution roadmap.',
      accentColor: const Color(0xFFEC4899),
      icon: Icons.auto_awesome,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);
    _startAutoPlay();
  }

  @override
  void dispose() {
    _stopAutoPlay();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!_isHovered && mounted && _pageController.hasClients) {
        final nextPage = (_currentPage + 1) % _slides.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  void _stopAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = null;
  }

  void _goToPage(int page) {
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        page,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.instance.isDark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 36,
          vertical: isMobile ? 32 : 56,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF080D1A) : const Color(0xFFF8FAFC),
          border: Border.symmetric(
            horizontal: BorderSide(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Section Header Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1B4B) : const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? const Color(0xFF4338CA) : const Color(0xFFC7D2FE),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.slideshow_rounded, size: 14, color: Color(0xFF4F46E5)),
                      const SizedBox(width: 6),
                      Text(
                        'INTERACTIVE APPRADAR PLATFORM SHOWCASE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4338CA),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Main Heading
                Text(
                  'Explore Inside the AppRadar Intelligence Console',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isMobile ? 24 : 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 10),

                // Subtitle description
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: Text(
                    'Step inside our high-velocity telemetry engine. Slide through the core tools our founders and growth teams use every day to discover breakout apps before the competition.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Category Chips Selector Tabs
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slides.length, (index) {
                      final item = _slides[index];
                      final isSelected = _currentPage == index;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          avatar: Icon(
                            item.icon,
                            size: 15,
                            color: isSelected ? Colors.white : item.accentColor,
                          ),
                          label: Text(
                            item.category,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155)),
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (_) => _goToPage(index),
                          selectedColor: const Color(0xFF2563EB),
                          backgroundColor: isDark ? const Color(0xFF111827) : Colors.white,
                          side: BorderSide(
                            color: isSelected
                                ? const Color(0xFF2563EB)
                                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 24),

                // The Moving Slide Viewport Container
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
                        blurRadius: 28,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Column(
                      children: [
                        // Browser Chrome Header Window Bar
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF090D16) : const Color(0xFFF1F5F9),
                            border: Border(
                              bottom: BorderSide(
                                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              // 3 Window Dots
                              const Row(
                                children: [
                                  CircleAvatar(radius: 5, backgroundColor: Color(0xFFEF4444)),
                                  SizedBox(width: 6),
                                  CircleAvatar(radius: 5, backgroundColor: Color(0xFFF59E0B)),
                                  SizedBox(width: 6),
                                  CircleAvatar(radius: 5, backgroundColor: Color(0xFF10B981)),
                                ],
                              ),
                              const SizedBox(width: 14),

                              // Simulated URL Pill
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF111827) : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.lock_rounded, size: 12, color: Color(0xFF10B981)),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          _slides[_currentPage].url,
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Live Status Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  children: [
                                    CircleAvatar(radius: 3, backgroundColor: Color(0xFF10B981)),
                                    SizedBox(width: 5),
                                    Text(
                                      'LIVE MATRIX',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF10B981)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Animated PageView with Slides
                        SizedBox(
                          height: isMobile ? 480 : 440,
                          child: Stack(
                            children: [
                              PageView.builder(
                                controller: _pageController,
                                itemCount: _slides.length,
                                onPageChanged: (idx) => setState(() => _currentPage = idx),
                                itemBuilder: (context, index) {
                                  return _buildSlideContent(index, isDark, isMobile);
                                },
                              ),

                              // Previous Button
                              Positioned(
                                left: 12,
                                top: 0,
                                bottom: 0,
                                child: Center(
                                  child: IconButton(
                                    onPressed: () {
                                      final prev = (_currentPage - 1 + _slides.length) % _slides.length;
                                      _goToPage(prev);
                                    },
                                    icon: const Icon(Icons.chevron_left_rounded, size: 28),
                                    style: IconButton.styleFrom(
                                      backgroundColor: isDark
                                          ? const Color(0xFF1E293B).withValues(alpha: 0.85)
                                          : Colors.white.withValues(alpha: 0.9),
                                      foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
                                      elevation: 3,
                                    ),
                                  ),
                                ),
                              ),

                              // Next Button
                              Positioned(
                                right: 12,
                                top: 0,
                                bottom: 0,
                                child: Center(
                                  child: IconButton(
                                    onPressed: () {
                                      final next = (_currentPage + 1) % _slides.length;
                                      _goToPage(next);
                                    },
                                    icon: const Icon(Icons.chevron_right_rounded, size: 28),
                                    style: IconButton.styleFrom(
                                      backgroundColor: isDark
                                          ? const Color(0xFF1E293B).withValues(alpha: 0.85)
                                          : Colors.white.withValues(alpha: 0.9),
                                      foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
                                      elevation: 3,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Bottom Indicator Dots and Quick Nav
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_slides.length, (index) {
                    final isSelected = _currentPage == index;
                    return GestureDetector(
                      onTap: () => _goToPage(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isSelected ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF2563EB)
                              : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // Slide Content Renderer
  // ----------------------------------------------------
  Widget _buildSlideContent(int index, bool isDark, bool isMobile) {
    final slide = _slides[index];

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 18 : 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: slide.accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(slide.icon, color: slide.accentColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            slide.badge,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: slide.accentColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            slide.title,
                            style: TextStyle(
                              fontSize: isMobile ? 15 : 18,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Get Started CTA Button inside screenshot card
              ElevatedButton.icon(
                onPressed: widget.onGetStarted,
                icon: const Icon(Icons.lock_open_rounded, size: 14),
                label: Text(
                  isMobile ? 'Get Started' : 'Unlock in Console',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Render simulated live screenshot component for this slide
          _buildScreenshotMockupBody(index, isDark, isMobile),
        ],
      ),
    );
  }

  Widget _buildScreenshotMockupBody(int index, bool isDark, bool isMobile) {
    switch (index) {
      case 0:
        return _buildTelemetryMockup(isDark, isMobile);
      case 1:
        return _buildOpportunityRadarMockup(isDark, isMobile);
      case 2:
        return _buildTeardownMockup(isDark, isMobile);
      case 3:
        return _buildReviewMiningMockup(isDark, isMobile);
      case 4:
        return _buildCompetitorMatrixMockup(isDark, isMobile);
      case 5:
      default:
        return _buildAiBlueprintMockup(isDark, isMobile);
    }
  }

  // 1. Live Store Telemetry Mockup
  Widget _buildTelemetryMockup(bool isDark, bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _metricChip('Active Apps', '2,840,192', '+1,420/d', const Color(0xFF2563EB), isDark),
              const SizedBox(width: 8),
              _metricChip('Store Feeds', 'US • UK • CA', 'Live Polling', const Color(0xFF10B981), isDark),
              if (!isMobile) ...[
                const SizedBox(width: 8),
                _metricChip('Grossing Pulse', '\$48.2M/mo', '+18.4% WoW', const Color(0xFF8B5CF6), isDark),
              ],
            ],
          ),
          const SizedBox(height: 14),
          _appRowSample('1', 'AI Note Taker Pro', 'Productivity', '\$48.2k/mo', '+18% 7d', '94/100', isDark),
          const SizedBox(height: 8),
          _appRowSample('2', 'Habit Hero Daily', 'Health & Fitness', '\$32.4k/mo', '+26% 7d', '88/100', isDark),
          const SizedBox(height: 8),
          _appRowSample('3', 'Voice Scan AI Transcribe', 'Business', '\$61.0k/mo', '+44% 7d', '91/100', isDark),
        ],
      ),
    );
  }

  // 2. AI Opportunity Radar Mockup
  Widget _buildOpportunityRadarMockup(bool isDark, bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF10B981)),
                    ),
                    child: const Text('OPPORTUNITY: 94/100', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF10B981), fontSize: 13)),
                  ),
                  const SizedBox(width: 12),
                  Text('Prime Blue Ocean Window', style: TextStyle(fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 13)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFF2563EB).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                child: const Text('Willingness-to-Pay: 96%', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF2563EB), fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0B0F19) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFFF59E0B), size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'High unsatisfied demand detected in offline-first voice recording with automatic markdown summary export. Incumbents have an average rating of 3.8★ due to sync glitches.',
                    style: TextStyle(fontSize: 12.5, height: 1.45, color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 3. Instant Teardown Mockup
  Widget _buildTeardownMockup(bool isDark, bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0B0F19) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.link, size: 16, color: Color(0xFF8B5CF6)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'https://apps.apple.com/us/app/ai-scanner-doc-lens/id152849102',
                    style: TextStyle(fontSize: 11.5, color: isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4338CA)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFF8B5CF6), borderRadius: BorderRadius.circular(4)),
                  child: const Text('DECOMPILED', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _tagPill('Paywall: Hard Onboarding (\$9.99/wk)', const Color(0xFFEF4444)),
              _tagPill('SDK: RevenueCat + Supabase', const Color(0xFF2563EB)),
              _tagPill('AI Engine: GPT-4o Mini API', const Color(0xFF10B981)),
              _tagPill('Top Complaint: Auto-Renewal Confusion', const Color(0xFFF59E0B)),
            ],
          ),
        ],
      ),
    );
  }

  // 4. Review Mining Mockup
  Widget _buildReviewMiningMockup(bool isDark, bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _metricChip('Dissatisfaction Rate', '71.4%', 'High Churn', const Color(0xFFEF4444), isDark),
              const SizedBox(width: 8),
              _metricChip('Analyzed 1★ Reviews', '3,418', 'Filtered AI', const Color(0xFFF59E0B), isDark),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0B0F19) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'GOLDEN GAP: "I love the idea but the app crashes when exporting notes to Notion. I would pay \$50 one-time for an app that just does direct markdown export."',
                    style: TextStyle(fontSize: 11.5, fontStyle: FontStyle.italic, color: Color(0xFFF59E0B)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 5. Competitor Matrix Mockup
  Widget _buildCompetitorMatrixMockup(bool isDark, bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('FOCUS: AI Note Taker vs 3 Top Rivals', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: isDark ? Colors.white : const Color(0xFF0F172A))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFF06B6D4).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                child: const Text('4 Rivals Benchmarked', style: TextStyle(color: Color(0xFF06B6D4), fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _competitorRow('AI Note Taker (Focus)', '\$4.99/mo', '✅ Full Offline', '4.8★ (+0.3)', const Color(0xFF10B981), isDark),
          const SizedBox(height: 6),
          _competitorRow('Notion Mobile', '\$10.00/mo', '❌ Requires Online', '4.1★ (-0.2)', const Color(0xFFEF4444), isDark),
          const SizedBox(height: 6),
          _competitorRow('Otter.ai Voice', '\$16.99/mo', '❌ Cloud Only', '4.2★ (-0.1)', const Color(0xFFEF4444), isDark),
        ],
      ),
    );
  }

  // 6. Build With AI Blueprint Mockup
  Widget _buildAiBlueprintMockup(bool isDark, bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('14-Section Production Blueprint (Ready to Build)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: isDark ? Colors.white : const Color(0xFF0F172A))),
              const Text('Synthesized in 1.4s', style: TextStyle(color: Color(0xFFEC4899), fontWeight: FontWeight.w700, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0B0F19) : const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'CREATE TABLE user_notes (\n  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),\n  user_id UUID REFERENCES auth.users,\n  markdown_body TEXT NOT NULL,\n  ai_summary TEXT,\n  created_at TIMESTAMPTZ DEFAULT now()\n);',
              style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: Color(0xFF38BDF8), height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  // Helpers
  Widget _metricChip(String label, String value, String sub, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0B0F19) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 10.5, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
            Text(sub, style: const TextStyle(fontSize: 9.5, color: Color(0xFF10B981), fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _appRowSample(String rank, String title, String cat, String mrr, String change, String score, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0B0F19) : Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text('#$rank', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF2563EB))),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                Text(cat, style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8))),
              ],
            ),
          ),
          Text(mrr, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF0F172A))),
          const SizedBox(width: 8),
          Text(change, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF10B981))),
        ],
      ),
    );
  }

  Widget _tagPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }

  Widget _competitorRow(String name, String pricing, String feature, String rating, Color tagColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0B0F19) : Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Expanded(child: Text(name, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: isDark ? Colors.white : const Color(0xFF0F172A)))),
          Text(pricing, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11)),
          const SizedBox(width: 12),
          Text(feature, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: tagColor)),
          const SizedBox(width: 12),
          Text(rating, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFFF59E0B))),
        ],
      ),
    );
  }
}

class _PlatformSlideData {
  final String category;
  final String badge;
  final String url;
  final String title;
  final String subtitle;
  final Color accentColor;
  final IconData icon;

  _PlatformSlideData({
    required this.category,
    required this.badge,
    required this.url,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.icon,
  });
}
