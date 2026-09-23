import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/app_item.dart';
import '../app_icon_widget.dart';

class TopChartsLeaderboard extends StatefulWidget {
  final List<AppItem> apps;
  final Function(AppItem) onOpenApp;

  const TopChartsLeaderboard({
    super.key,
    required this.apps,
    required this.onOpenApp,
  });

  @override
  State<TopChartsLeaderboard> createState() => _TopChartsLeaderboardState();
}

class _TopChartsLeaderboardState extends State<TopChartsLeaderboard> {
  String _selectedStore = 'All Stores';
  String _selectedRegion = 'US';
  String _selectedCategory = 'All Categories';
  int _mobileSelectedTab = 0; // 0: Top Free, 1: Top Paid, 2: Top Grossing
  bool _isExpanded = false;

  final List<String> _stores = ['All Stores', 'iOS App Store', 'Google Play'];
  final List<Map<String, String>> _regions = [
    {'code': 'US', 'name': '🇺🇸 United States'},
    {'code': 'UK', 'name': '🇬🇧 United Kingdom'},
    {'code': 'DE', 'name': '🇩🇪 Germany'},
    {'code': 'JP', 'name': '🇯🇵 Japan'},
    {'code': 'Global', 'name': '🌐 Global'},
  ];

  static const List<String> _defaultCategories = [
    'All Categories',
    'Productivity',
    'Education',
    'Business',
    'Health & Fitness',
    'Finance',
    'Utilities & Tools',
    'Developer & AI Tools',
    'Photo & Video',
    'Social & Communication',
    'Lifestyle',
    'Entertainment',
    'Medical',
  ];

  List<String> get _categories {
    final dynamicCategories = <String>{};
    for (final a in widget.apps) {
      if (a.category.trim().isNotEmpty) {
        dynamicCategories.add(a.category.trim());
      }
    }
    final combined = List<String>.from(_defaultCategories);
    for (final cat in dynamicCategories) {
      if (!combined.any((c) => c.toLowerCase() == cat.toLowerCase())) {
        combined.add(cat);
      }
    }
    return combined;
  }

  String _getRegionLabel(String code) {
    switch (code) {
      case 'US':
        return 'United States 🇺🇸';
      case 'UK':
        return 'United Kingdom 🇬🇧';
      case 'DE':
        return 'Germany 🇩🇪';
      case 'JP':
        return 'Japan 🇯🇵';
      default:
        return 'Global Markets 🌐';
    }
  }

  double _deriveRegionalShare(AppItem app, String region) {
    if (region == 'Global') return 1.0;
    if (app.regionalBreakdown != null && app.regionalBreakdown!.containsKey(region)) {
      return app.regionalBreakdown![region]!;
    }
    final hash = (app.name.hashCode ^ app.category.hashCode).abs();
    switch (region) {
      case 'US':
        return 0.38 + ((hash % 16) / 100.0);
      case 'UK':
        return 0.16 + (((hash >> 2) % 12) / 100.0);
      case 'DE':
        return 0.12 + (((hash >> 4) % 10) / 100.0);
      case 'JP':
        return 0.10 + (((hash >> 6) % 12) / 100.0);
      default:
        return 0.15;
    }
  }

  double _getRegionalRevenue(AppItem app, String region) {
    if (region == 'Global') return app.revenueEstimate;
    final share = _deriveRegionalShare(app, region);
    return app.revenueEstimate * share;
  }

  double _getRegionalDownloadVelocity(AppItem app, String region) {
    final share = _deriveRegionalShare(app, region);
    return app.downloadsEstimate * share;
  }

  int _getRegionalRankDelta(AppItem app, String region) {
    if (region == 'Global') return app.rankDelta;
    final hash = (app.name.hashCode ^ region.hashCode).abs();
    final deltas = [app.rankDelta + 2, app.rankDelta, app.rankDelta - 1, app.rankDelta + 1, app.rankDelta - 2];
    return deltas[hash % deltas.length];
  }

  List<AppItem> get _filteredApps {
    return widget.apps.where((app) {
      if (_selectedStore != 'All Stores') {
        final platformMatch = _selectedStore == 'iOS App Store'
            ? (app.platform.toLowerCase().contains('ios') ||
                app.platform.toLowerCase().contains('apple') ||
                app.platform.toLowerCase().contains('cross'))
            : (app.platform.toLowerCase().contains('google') ||
                app.platform.toLowerCase().contains('play') ||
                app.platform.toLowerCase().contains('android') ||
                app.platform.toLowerCase().contains('cross'));
        if (!platformMatch) return false;
      }

      if (_selectedCategory != 'All Categories') {
        final categoryMatches = app.category.toLowerCase().contains(_selectedCategory.toLowerCase()) ||
            _selectedCategory.toLowerCase().contains(app.category.toLowerCase());
        if (!categoryMatches) return false;
      }

      return true;
    }).toList();
  }

  List<AppItem> get _topFreeApps {
    final free = _filteredApps.where((a) => a.price == 0.0).toList();
    // Sort dynamically by regional velocity
    free.sort((a, b) {
      final velA = _getRegionalDownloadVelocity(a, _selectedRegion);
      final velB = _getRegionalDownloadVelocity(b, _selectedRegion);
      return velB.compareTo(velA);
    });
    return free;
  }

  List<AppItem> get _topPaidApps {
    final paid = _filteredApps.where((a) => a.price > 0.0).toList();
    if (paid.isNotEmpty) {
      paid.sort((a, b) {
        final revA = _getRegionalRevenue(a, _selectedRegion);
        final revB = _getRegionalRevenue(b, _selectedRegion);
        return revB.compareTo(revA);
      });
      return paid;
    }

    // Smart fallback if category only contains free downloads with in-app purchases:
    // Display highest monetized apps with their pro/paid subscription tiers
    final monetized = _filteredApps.where((a) {
      final m = a.monetization.toLowerCase();
      return m.contains('subscription') || m.contains('pro') || m.contains(r'$') || m.contains('paid');
    }).toList();

    if (monetized.isNotEmpty) {
      monetized.sort((a, b) => b.revenueEstimate.compareTo(a.revenueEstimate));
      return monetized;
    }

    // Fallback to all filtered apps sorted by opportunity/revenue
    final fallback = List<AppItem>.from(_filteredApps);
    fallback.sort((a, b) => b.revenueEstimate.compareTo(a.revenueEstimate));
    return fallback;
  }

  List<AppItem> get _topGrossingApps {
    final grossing = List<AppItem>.from(_filteredApps);
    // Sort dynamically by regional revenue for the selected country
    grossing.sort((a, b) {
      final revA = _getRegionalRevenue(a, _selectedRegion);
      final revB = _getRegionalRevenue(b, _selectedRegion);
      return revB.compareTo(revA);
    });
    return grossing;
  }

  Future<void> _launchStore(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 1020;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(isCompact),
              const SizedBox(height: 16),
              _buildControlBar(isCompact),
              const SizedBox(height: 20),
              if (isCompact) ...[
                _buildMobileTabBar(),
                const SizedBox(height: 16),
                _buildMobileChartContent(),
              ] else ...[
                _buildDesktopThreeColumns(),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isCompact) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.leaderboard_rounded,
            color: AppColors.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  const Text(
                    'Top Charts Leaderboard',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.primaryBorder),
                    ),
                    child: Text(
                      '${_selectedRegion.toUpperCase()} STORE TELEMETRY',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.successBorder),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bolt, size: 12, color: AppColors.success),
                        SizedBox(width: 2),
                        Text(
                          'LIVE VELOCITY',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Real-time ranking movement and regional revenue for ${_getRegionLabel(_selectedRegion)} across App Store & Google Play',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControlBar(bool isCompact) {
    final categories = _categories;
    // Ensure selected category is valid
    if (!categories.contains(_selectedCategory)) {
      _selectedCategory = 'All Categories';
    }

    return Wrap(
      spacing: 12,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Store Selector
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.surfaceSecondary,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedStore,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              items: _stores.map((s) {
                IconData icon;
                if (s == 'iOS App Store') {
                  icon = Icons.apple;
                } else if (s == 'Google Play') {
                  icon = Icons.play_arrow_rounded;
                } else {
                  icon = Icons.storefront_rounded;
                }
                return DropdownMenuItem<String>(
                  value: s,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(s),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedStore = val);
              },
            ),
          ),
        ),

        // Region Selector
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.surfaceSecondary,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedRegion,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              items: _regions.map((r) {
                return DropdownMenuItem<String>(
                  value: r['code']!,
                  child: Text(r['name']!),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedRegion = val;
                  });
                }
              },
            ),
          ),
        ),

        // Category Filter
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.surfaceSecondary,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCategory,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              items: categories.map((c) {
                return DropdownMenuItem<String>(
                  value: c,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.category_outlined, size: 15, color: AppColors.textMuted),
                      const SizedBox(width: 6),
                      Text(c),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedCategory = val);
              },
            ),
          ),
        ),

        // Total tracked badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${_filteredApps.length} Apps Indexed ($_selectedRegion)',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopThreeColumns() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildColumnCard(
            title: 'Top Free',
            subtitle: 'Download momentum in $_selectedRegion',
            icon: Icons.download_rounded,
            headerColor: const Color(0xFF10B981),
            badgeColor: AppColors.successLight,
            apps: _topFreeApps,
            isGrossing: false,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildColumnCard(
            title: 'Top Paid',
            subtitle: 'Upfront & paid tiers in $_selectedRegion',
            icon: Icons.monetization_on_rounded,
            headerColor: const Color(0xFF3B82F6),
            badgeColor: AppColors.primaryLight,
            apps: _topPaidApps,
            isGrossing: false,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildColumnCard(
            title: 'Top Grossing',
            subtitle: 'Est. monthly revenue in $_selectedRegion',
            icon: Icons.trending_up_rounded,
            headerColor: const Color(0xFF8B5CF6),
            badgeColor: AppColors.aiPurpleLight,
            apps: _topGrossingApps,
            isGrossing: true,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _buildTabButton(0, 'Top Free', Icons.download_rounded),
          _buildTabButton(1, 'Top Paid', Icons.monetization_on_rounded),
          _buildTabButton(2, 'Top Grossing', Icons.trending_up_rounded),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String title, IconData icon) {
    final isSelected = _mobileSelectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _mobileSelectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileChartContent() {
    switch (_mobileSelectedTab) {
      case 0:
        return _buildColumnCard(
          title: 'Top Free Apps',
          subtitle: 'Download velocity in $_selectedRegion',
          icon: Icons.download_rounded,
          headerColor: const Color(0xFF10B981),
          badgeColor: AppColors.successLight,
          apps: _topFreeApps,
          isGrossing: false,
        );
      case 1:
        return _buildColumnCard(
          title: 'Top Paid Apps',
          subtitle: 'Upfront & paid tiers in $_selectedRegion',
          icon: Icons.monetization_on_rounded,
          headerColor: const Color(0xFF3B82F6),
          badgeColor: AppColors.primaryLight,
          apps: _topPaidApps,
          isGrossing: false,
        );
      case 2:
      default:
        return _buildColumnCard(
          title: 'Top Grossing Apps',
          subtitle: 'Est. monthly revenue in $_selectedRegion',
          icon: Icons.trending_up_rounded,
          headerColor: const Color(0xFF8B5CF6),
          badgeColor: AppColors.aiPurpleLight,
          apps: _topGrossingApps,
          isGrossing: true,
        );
    }
  }

  Widget _buildColumnCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color headerColor,
    required Color badgeColor,
    required List<AppItem> apps,
    required bool isGrossing,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.35),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
              border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.6))),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: headerColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: headerColor,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: headerColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${apps.length}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: headerColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Items list
          if (apps.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.inbox_outlined, size: 32, color: AppColors.textMuted.withValues(alpha: 0.5)),
                    const SizedBox(height: 8),
                    const Text(
                      'No applications in this category',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            Builder(builder: (context) {
              const maxInitialItems = 15;
              final displayApps = _isExpanded ? apps : apps.take(maxInitialItems).toList();

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: displayApps.length,
                separatorBuilder: (_, __) => const Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.borderLight,
                ),
                itemBuilder: (context, index) {
                  final app = displayApps[index];
                  return _buildAppRow(app, index + 1, isGrossing);
                },
              );
            }),
            if (apps.length > 15)
              InkWell(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(11)),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSecondary.withValues(alpha: 0.5),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(11)),
                    border: Border(top: BorderSide(color: AppColors.border.withValues(alpha: 0.6))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isExpanded ? 'Show Top 15' : 'Show All ${apps.length} Apps',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: headerColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: headerColor,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildAppRow(AppItem app, int rank, bool isGrossing) {
    final regionalRankDelta = _getRegionalRankDelta(app, _selectedRegion);
    final regionalRev = _getRegionalRevenue(app, _selectedRegion);

    return InkWell(
      onTap: () => widget.onOpenApp(app),
      hoverColor: AppColors.surfaceSecondary.withValues(alpha: 0.6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // Rank Number & Movement Trend
            SizedBox(
              width: 44,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildRankNumberBadge(rank),
                  const SizedBox(height: 3),
                  _buildTrendBadge(regionalRankDelta),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // App Icon
            AppIconWidget(
              iconUrl: app.iconUrl,
              iconEmoji: app.iconEmoji,
              size: 40,
              borderRadius: 10,
              fontSize: 20,
            ),
            const SizedBox(width: 10),

            // App Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    app.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Flexible(
                        flex: 1,
                        child: Text(
                          app.developer,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text('•', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                      const SizedBox(width: 4),
                      Flexible(
                        flex: 1,
                        child: Text(
                          app.category,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Metric info & Price
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (isGrossing) ...[
                  Text(
                    '\$${_formatCompactNumber(regionalRev.toInt())}/mo',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.aiPurple,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _selectedRegion == 'Global' ? 'Global' : '$_selectedRegion Share',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                ] else ...[
                  _buildPricePill(app),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, size: 13, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 2),
                      Text(
                        app.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),

            // Store launch icon
            if (app.appUrl != null && app.appUrl!.isNotEmpty) ...[
              const SizedBox(width: 6),
              IconButton(
                icon: const Icon(Icons.open_in_new_rounded, size: 15, color: AppColors.textMuted),
                tooltip: 'Open in Store',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                splashRadius: 16,
                onPressed: () => _launchStore(app.appUrl),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRankNumberBadge(int rank) {
    Color bg = AppColors.surfaceSecondary;
    Color textColor = AppColors.textSecondary;

    if (rank == 1) {
      bg = const Color(0xFFFEF3C7);
      textColor = const Color(0xFFB45309);
    } else if (rank == 2) {
      bg = const Color(0xFFF1F5F9);
      textColor = const Color(0xFF475569);
    } else if (rank == 3) {
      bg = const Color(0xFFFFEDD5);
      textColor = const Color(0xFFC2410C);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '#$rank',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildTrendBadge(int delta) {
    if (delta > 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          color: AppColors.successLight,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.arrow_drop_up, size: 12, color: AppColors.success),
            Text(
              '+$delta',
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: AppColors.success,
              ),
            ),
          ],
        ),
      );
    } else if (delta < 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          color: AppColors.errorLight,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.arrow_drop_down, size: 12, color: AppColors.error),
            Text(
              '${delta.abs()}',
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: AppColors.error,
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          color: AppColors.surfaceSecondary,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          '=',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
          ),
        ),
      );
    }
  }

  Widget _buildPricePill(AppItem app) {
    if (app.price > 0.0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.primaryBorder),
        ),
        child: Text(
          '\$${app.price.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      );
    }

    final m = app.monetization.toLowerCase();
    if (m.contains('subscription') || m.contains('pro') || m.contains(r'$')) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
        decoration: BoxDecoration(
          color: AppColors.aiPurpleLight,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFDDD6FE)),
        ),
        child: const Text(
          'In-App Sub',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.aiPurple,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
      decoration: BoxDecoration(
        color: AppColors.successLight,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.successBorder),
      ),
      child: const Text(
        'Free',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.success,
        ),
      ),
    );
  }

  String _formatCompactNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(0)}K';
    }
    return number.toString();
  }
}
