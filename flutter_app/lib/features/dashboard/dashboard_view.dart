import 'package:flutter/material.dart';
import '../../data/models/app_item.dart';
import '../../data/repositories/opportunity_repository.dart';
import '../../data/repositories/market_trend_repository.dart';
import '../../data/repositories/app_repository.dart';
import '../../widgets/app_icon_widget.dart';
import '../../widgets/top_charts/top_charts_leaderboard.dart';

class DashboardView extends StatefulWidget {
  final OpportunityRepository oppRepo;
  final MarketTrendRepository trendRepo;
  final AppRepository? appRepo;
  final ValueChanged<AppItem> onOpenApp;
  final VoidCallback onNavigateToBuildAI;

  const DashboardView({
    super.key,
    required this.oppRepo,
    required this.trendRepo,
    this.appRepo,
    required this.onOpenApp,
    required this.onNavigateToBuildAI,
  });

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  late Future<List<dynamic>> _dataFuture;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchFocusNode.addListener(() {
      setState(() {
        _showSuggestions = _searchFocusNode.hasFocus && _searchQuery.trim().isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _loadData() {
    _dataFuture = Future.wait([
      widget.oppRepo.getTopOpportunities(limit: 5),
      widget.trendRepo.getCategoryTrends(),
      widget.appRepo?.getAllApps() ?? widget.oppRepo.getFilteredOpportunities(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return FutureBuilder<List<dynamic>>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final allApps = snapshot.data![2] as List<AppItem>;

        final matchingSuggestions = _searchQuery.trim().isEmpty
            ? <AppItem>[]
            : allApps
                .where((a) =>
                    a.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    a.developer.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    a.category.toLowerCase().contains(_searchQuery.toLowerCase()))
                .take(5)
                .toList();

        return Stack(
          children: [
            // Ambient Atmosphere Background Gradient
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.0, 0.18, 0.42, 0.75, 1.0],
                    colors: [
                      Color(0xFF93C5FD), // Vibrant sky top (matching reference Image 1)
                      Color(0xFFBAE6FD), // Sky blue tint
                      Color(0xFFE0F2FE), // Soft ice blue
                      Color(0xFFF8FAFC), // Clean off-white
                      Colors.white,
                    ],
                  ),
                ),
              ),
            ),

            // Top-left ambient glowing decorative orb
            Positioned(
              top: -60,
              left: -40,
              child: IgnorePointer(
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.65),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Top-right ambient glowing decorative orb
            Positioned(
              top: -40,
              right: -30,
              child: IgnorePointer(
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFBAE6FD).withValues(alpha: 0.5),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Main Content ScrollView
            RefreshIndicator(
              onRefresh: () async {
                setState(() => _loadData());
                await _dataFuture;
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : 24,
                  vertical: isMobile ? 24 : 36,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1140),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Pill Category/Intelligence Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF93C5FD).withValues(alpha: 0.6)),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2563EB).withValues(alpha: 0.06),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.radar_rounded, size: 14, color: Color(0xFF2563EB)),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  isMobile ? 'GLOBAL STORE INTELLIGENCE' : 'GLOBAL STORE TELEMETRY & APP INTELLIGENCE',
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    fontStyle: FontStyle.italic,
                                    color: Color(0xFF1D4ED8),
                                    letterSpacing: 0.5,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Big Bold Hero Headline (matching Image 1)
                        Text(
                          'Next-Gen Mobile App Intelligence & Market Telemetry',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isMobile ? 24 : 34,
                            fontWeight: FontWeight.w800,
                            fontStyle: FontStyle.italic,
                            letterSpacing: -0.6,
                            color: const Color(0xFF1D4ED8), // Royal Blue
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Hero Subtitle Description (matching Image 1)
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 680),
                          child: Text(
                            'Uncover real-time store trends, monitor competitor breakthroughs, and accelerate your app\'s global growth with high-precision telemetry.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isMobile ? 13 : 14.5,
                              height: 1.55,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF475569),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Floating Pill Search Bar
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 580),
                            child: Column(
                              children: [
                                Container(
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 16,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      // Refresh icon on left
                                      IconButton(
                                        icon: const Icon(Icons.refresh_rounded, color: Color(0xFF94A3B8), size: 20),
                                        tooltip: 'Refresh live data',
                                        splashRadius: 20,
                                        onPressed: () {
                                          setState(() => _loadData());
                                        },
                                      ),
                                      // Text Field
                                      Expanded(
                                        child: TextField(
                                          controller: _searchController,
                                          focusNode: _searchFocusNode,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF0F172A),
                                          ),
                                          decoration: const InputDecoration(
                                            hintText: 'Search for app or publisher...',
                                            hintStyle: TextStyle(
                                              color: Color(0xFF94A3B8),
                                              fontSize: 13.5,
                                              fontStyle: FontStyle.italic,
                                              fontWeight: FontWeight.w400,
                                            ),
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                                            isDense: true,
                                          ),
                                          onChanged: (val) {
                                            setState(() {
                                              _searchQuery = val;
                                              _showSuggestions = val.trim().isNotEmpty;
                                            });
                                          },
                                          onSubmitted: (val) {
                                            setState(() => _showSuggestions = false);
                                            if (matchingSuggestions.isNotEmpty) {
                                              widget.onOpenApp(matchingSuggestions.first);
                                            }
                                          },
                                        ),
                                      ),
                                      // Clear query button
                                      if (_searchQuery.isNotEmpty)
                                        IconButton(
                                          icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF94A3B8)),
                                          splashRadius: 16,
                                          onPressed: () {
                                            setState(() {
                                              _searchController.clear();
                                              _searchQuery = '';
                                              _showSuggestions = false;
                                            });
                                          },
                                        ),
                                      // Blue circular search button on right
                                      Padding(
                                        padding: const EdgeInsets.only(right: 7),
                                        child: InkWell(
                                          onTap: () {
                                            setState(() => _showSuggestions = false);
                                            if (matchingSuggestions.isNotEmpty) {
                                              widget.onOpenApp(matchingSuggestions.first);
                                            }
                                          },
                                          borderRadius: BorderRadius.circular(20),
                                          child: Container(
                                            width: 36,
                                            height: 36,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFF2563EB),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.search_rounded,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Instant Search Suggestions Dropdown
                                if (_showSuggestions && matchingSuggestions.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.08),
                                          blurRadius: 18,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: matchingSuggestions.map((app) {
                                        return InkWell(
                                          onTap: () {
                                            setState(() {
                                              _showSuggestions = false;
                                              _searchController.text = app.name;
                                              _searchQuery = app.name;
                                            });
                                            widget.onOpenApp(app);
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                            child: Row(
                                              children: [
                                                AppIconWidget(
                                                  iconUrl: app.iconUrl,
                                                  iconEmoji: app.iconEmoji,
                                                  size: 28,
                                                  borderRadius: 6,
                                                  fontSize: 14,
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        app.name,
                                                        style: const TextStyle(
                                                          fontSize: 12.5,
                                                          fontWeight: FontWeight.w700,
                                                          color: Color(0xFF0F172A),
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                      Text(
                                                        '${app.category} • ${app.developer}',
                                                        style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF94A3B8)),
                                              ],
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Main Elevated Pop-up Card
                        TopChartsLeaderboard(
                          apps: allApps,
                          onOpenApp: widget.onOpenApp,
                          searchQuery: _searchQuery,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
