import 'package:flutter/material.dart';
import '../../data/models/app_item.dart';
import '../app_icon_widget.dart';

class TopChartsLeaderboard extends StatefulWidget {
  final List<AppItem> apps;
  final Function(AppItem) onOpenApp;
  final String? searchQuery;

  const TopChartsLeaderboard({
    super.key,
    required this.apps,
    required this.onOpenApp,
    this.searchQuery,
  });

  @override
  State<TopChartsLeaderboard> createState() => _TopChartsLeaderboardState();
}

class _TopChartsLeaderboardState extends State<TopChartsLeaderboard> {
  String _selectedStore = 'App Store';
  String _selectedRegion = 'US';
  String _selectedCategory = 'All Categories';
  int _mobileSelectedTab = 0; // 0: Top Free, 1: Top Paid, 2: Top Grossing
  bool _isExpanded = false;

  late final String _lastUpdatedTime;

  final List<String> _stores = ['App Store', 'Google Play', 'All Stores'];
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
    'Photo & Video',
    'Social & Communication',
    'Entertainment',
    'Casual',
    'Games',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    _lastUpdatedTime = '${now.year}-$month-$day $hour:$minute';
  }

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
    final query = widget.searchQuery?.trim().toLowerCase();

    return widget.apps.where((app) {
      if (query != null && query.isNotEmpty) {
        final matchesName = app.name.toLowerCase().contains(query);
        final matchesDev = app.developer.toLowerCase().contains(query);
        final matchesCat = app.category.toLowerCase().contains(query);
        if (!matchesName && !matchesDev && !matchesCat) return false;
      }

      if (_selectedStore != 'All Stores') {
        final platformMatch = _selectedStore == 'App Store'
            ? (app.platform.toLowerCase().contains('ios') ||
                app.platform.toLowerCase().contains('apple') ||
                app.platform.toLowerCase().contains('app store') ||
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
    free.sort((a, b) {
      final velA = _getRegionalDownloadVelocity(a, _selectedRegion);
      final velB = _getRegionalDownloadVelocity(b, _selectedRegion);
      return velB.compareTo(velA);
    });
    if (free.isNotEmpty) return free;
    // Fallback if empty
    return List<AppItem>.from(_filteredApps);
  }

  List<AppItem> get _topPaidApps {
    final paid = _filteredApps.where((a) => a.price > 0.0).toList();
    if (paid.isNotEmpty) {
      paid.sort((a, b) {
        final revA = _getRegionalRevenue(a, _selectedRegion);
        final revB = _getRegionalRevenue(b, _selectedRegion);
        return revB.compareTo(revA);
      });
      if (paid.length >= 10) return paid;
    }

    // Complement with high-monetization apps so 10 items show smoothly
    final result = List<AppItem>.from(paid);
    final existingIds = result.map((a) => a.id).toSet();

    final monetized = _filteredApps.where((a) {
      if (existingIds.contains(a.id)) return false;
      final m = a.monetization.toLowerCase();
      return m.contains('subscription') || m.contains('pro') || m.contains(r'$') || m.contains('paid');
    }).toList();

    monetized.sort((a, b) => b.revenueEstimate.compareTo(a.revenueEstimate));
    result.addAll(monetized);

    // If still less than 10, fill from all filtered
    for (final a in _filteredApps) {
      if (result.length >= 15) break;
      if (!result.any((item) => item.id == a.id)) {
        result.add(a);
      }
    }

    return result;
  }

  List<AppItem> get _topGrossingApps {
    final grossing = List<AppItem>.from(_filteredApps);
    grossing.sort((a, b) {
      final revA = _getRegionalRevenue(a, _selectedRegion);
      final revB = _getRegionalRevenue(b, _selectedRegion);
      return revB.compareTo(revA);
    });
    return grossing;
  }

  double _getDisplayPrice(AppItem app, int index) {
    if (app.price > 0.0) return app.price;
    // Provide realistic App Store price tier for paid apps list
    const fallbackPrices = [6.99, 1.99, 6.99, 2.99, 3.99, 0.99, 0.99, 6.99, 2.99, 1.99, 4.99, 9.99];
    return fallbackPrices[index % fallbackPrices.length];
  }

  String? _deriveDaysBadge(AppItem app, int rank) {
    if (rank == 1) return '0 day';
    if (rank == 2 && app.growthRate > 25) return '140 d';
    if (rank == 3 && app.growthRate > 15) return '196 d';
    final hash = (app.name.hashCode ^ app.developer.hashCode).abs();
    if (rank <= 4 && hash % 4 == 0) {
      final days = (hash % 120) + 12;
      return '$days d';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 980;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildFilterBox(constraints.maxWidth < 700),
              const SizedBox(height: 24),
              if (isCompact) ...[
                _buildMobileTabBar(),
                const SizedBox(height: 16),
                _buildMobileChartContent(),
              ] else ...[
                _buildDesktopThreeColumns(),
              ],
              const SizedBox(height: 18),
              _buildViewMoreFooter(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 10,
      runSpacing: 6,
      children: [
        const Text(
          'Top Charts',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: Color(0xFF0F172A),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Text(
            'updated: $_lastUpdatedTime',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFFB45309),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBox(bool isStacked) {
    final categories = _categories;
    if (!categories.contains(_selectedCategory)) {
      _selectedCategory = 'All Categories';
    }

    if (isStacked) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            _buildDropdownField('Store', _buildStoreDropdown()),
            const SizedBox(height: 8),
            _buildDropdownField('Region', _buildRegionDropdown()),
            const SizedBox(height: 8),
            _buildDropdownField('Category', _buildCategoryDropdown(categories)),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(child: _buildDropdownField('Store', _buildStoreDropdown())),
          const SizedBox(width: 14),
          Expanded(child: _buildDropdownField('Region', _buildRegionDropdown())),
          const SizedBox(width: 14),
          Expanded(child: _buildDropdownField('Category', _buildCategoryDropdown(categories))),
        ],
      ),
    );
  }

  Widget _buildDropdownField(String label, Widget dropdown) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 4),
        dropdown,
      ],
    );
  }

  Widget _buildStoreDropdown() {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedStore,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF64748B)),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
          items: _stores.map((s) {
            return DropdownMenuItem<String>(
              value: s,
              child: Text(s, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _selectedStore = val);
          },
        ),
      ),
    );
  }

  Widget _buildRegionDropdown() {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedRegion,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF64748B)),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
          items: _regions.map((r) {
            return DropdownMenuItem<String>(
              value: r['code']!,
              child: Text(r['name']!, overflow: TextOverflow.ellipsis),
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
    );
  }

  Widget _buildCategoryDropdown(List<String> categories) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF64748B)),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
          items: categories.map((c) {
            return DropdownMenuItem<String>(
              value: c,
              child: Text(c, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _selectedCategory = val);
          },
        ),
      ),
    );
  }

  Widget _buildDesktopThreeColumns() {
    final limit = _isExpanded ? 20 : 10;
    final freeApps = _topFreeApps.take(limit).toList();
    final paidApps = _topPaidApps.take(limit).toList();
    final grossingApps = _topGrossingApps.take(limit).toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildLeaderboardColumn(
            title: 'Top Free',
            accentColor: const Color(0xFF3B82F6),
            apps: freeApps,
            isPaid: false,
          ),
        ),
        Container(
          width: 1,
          height: (limit * 52.0) + 40,
          color: const Color(0xFFF1F5F9),
          margin: const EdgeInsets.symmetric(horizontal: 14),
        ),
        Expanded(
          child: _buildLeaderboardColumn(
            title: 'Top Paid',
            accentColor: const Color(0xFFF97316),
            apps: paidApps,
            isPaid: true,
          ),
        ),
        Container(
          width: 1,
          height: (limit * 52.0) + 40,
          color: const Color(0xFFF1F5F9),
          margin: const EdgeInsets.symmetric(horizontal: 14),
        ),
        Expanded(
          child: _buildLeaderboardColumn(
            title: 'Top Grossing',
            accentColor: const Color(0xFFEF4444),
            apps: grossingApps,
            isPaid: false,
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardColumn({
    required String title,
    required Color accentColor,
    required List<AppItem> apps,
    required bool isPaid,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Column Title with vertical accent line
        Row(
          children: [
            Container(
              width: 3.5,
              height: 16,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Horizontal accent line
        Container(
          height: 2,
          color: accentColor,
        ),
        const SizedBox(height: 10),

        if (apps.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 36),
            child: Center(
              child: Text(
                'No applications found',
                style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: apps.length,
            itemBuilder: (context, index) {
              final app = apps[index];
              return _buildAppRow(app, index + 1, isPaid, index);
            },
          ),
      ],
    );
  }

  Widget _buildAppRow(AppItem app, int rank, bool isPaid, int index) {
    final delta = _getRegionalRankDelta(app, _selectedRegion);
    final daysBadge = _deriveDaysBadge(app, rank);
    final displayPrice = _getDisplayPrice(app, index);

    return InkWell(
      onTap: () => widget.onOpenApp(app),
      hoverColor: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          children: [
            // Rank Badge & Movement
            SizedBox(
              width: 28,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildRankBadge(rank),
                  const SizedBox(height: 2),
                  _buildDeltaWidget(delta),
                ],
              ),
            ),
            const SizedBox(width: 6),

            // Optional Release Age Badge (e.g. 0 day, 140 d)
            if (daysBadge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFFFEDD5)),
                ),
                child: Text(
                  daysBadge,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFEA580C),
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],

            // App Icon
            AppIconWidget(
              iconUrl: app.iconUrl,
              iconEmoji: app.iconEmoji,
              size: 34,
              borderRadius: 8,
              fontSize: 18,
            ),
            const SizedBox(width: 8),

            // Name, Publisher & Subtitle
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
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Dollar coin badge for monetization
                      if (isPaid || app.monetization.isNotEmpty || app.opportunityScore > 60) ...[
                        const SizedBox(width: 4),
                        Container(
                          width: 14,
                          height: 14,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF59E0B),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text(
                              '\$',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          '${app.category} No.$rank  ${app.developer}',
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isPaid) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: Text(
                            'USD ${displayPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRankBadge(int rank) {
    if (rank == 1) {
      return Container(
        width: 20,
        height: 20,
        decoration: const BoxDecoration(
          color: Color(0xFFF97316),
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Text(
            '1',
            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
          ),
        ),
      );
    } else if (rank == 2) {
      return Container(
        width: 20,
        height: 20,
        decoration: const BoxDecoration(
          color: Color(0xFFFBBF24),
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Text(
            '2',
            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
          ),
        ),
      );
    } else if (rank == 3) {
      return Container(
        width: 20,
        height: 20,
        decoration: const BoxDecoration(
          color: Color(0xFF3B82F6),
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Text(
            '3',
            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
          ),
        ),
      );
    }

    return Text(
      '$rank',
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Color(0xFF475569),
      ),
    );
  }

  Widget _buildDeltaWidget(int delta) {
    if (delta > 0) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.arrow_drop_up, size: 12, color: Color(0xFF10B981)),
          Text(
            '$delta',
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: Color(0xFF10B981),
            ),
          ),
        ],
      );
    } else if (delta < 0) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.arrow_drop_down, size: 12, color: Color(0xFFEF4444)),
          Text(
            '${delta.abs()}',
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: Color(0xFFEF4444),
            ),
          ),
        ],
      );
    }

    return const Text(
      '=',
      style: TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w700,
        color: Color(0xFF94A3B8),
      ),
    );
  }

  Widget _buildMobileTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _buildMobileTabItem(0, 'Top Free', const Color(0xFF3B82F6)),
          _buildMobileTabItem(1, 'Top Paid', const Color(0xFFF97316)),
          _buildMobileTabItem(2, 'Top Grossing', const Color(0xFFEF4444)),
        ],
      ),
    );
  }

  Widget _buildMobileTabItem(int index, String title, Color color) {
    final isSelected = _mobileSelectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _mobileSelectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    )
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? color : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileChartContent() {
    final limit = _isExpanded ? 20 : 10;
    switch (_mobileSelectedTab) {
      case 0:
        return _buildLeaderboardColumn(
          title: 'Top Free',
          accentColor: const Color(0xFF3B82F6),
          apps: _topFreeApps.take(limit).toList(),
          isPaid: false,
        );
      case 1:
        return _buildLeaderboardColumn(
          title: 'Top Paid',
          accentColor: const Color(0xFFF97316),
          apps: _topPaidApps.take(limit).toList(),
          isPaid: true,
        );
      case 2:
      default:
        return _buildLeaderboardColumn(
          title: 'Top Grossing',
          accentColor: const Color(0xFFEF4444),
          apps: _topGrossingApps.take(limit).toList(),
          isPaid: false,
        );
    }
  }

  Widget _buildViewMoreFooter() {
    return Center(
      child: TextButton(
        onPressed: () {
          setState(() => _isExpanded = !_isExpanded);
        },
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF2563EB),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        child: Text(
          _isExpanded ? 'View Less <' : 'View More >',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2563EB),
          ),
        ),
      ),
    );
  }
}
