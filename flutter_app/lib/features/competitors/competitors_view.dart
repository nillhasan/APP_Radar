import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/app_item.dart';
import '../../data/repositories/app_repository.dart';
import '../../data/mock/mock_data.dart';
import '../../widgets/section_header.dart';
import '../../widgets/app_icon_widget.dart';

class CompetitorEntry {
  final String id;
  final String name;
  final String developer;
  final String category;
  final double rating;
  final int reviews;
  final String pricing;
  final String marketPosition;
  final String? iconUrl;
  final String iconEmoji;
  final bool isFocus;
  final AppItem? appItem;

  const CompetitorEntry({
    required this.id,
    required this.name,
    required this.developer,
    required this.category,
    required this.rating,
    required this.reviews,
    required this.pricing,
    required this.marketPosition,
    this.iconUrl,
    required this.iconEmoji,
    required this.isFocus,
    this.appItem,
  });
}

class CompetitorsView extends StatefulWidget {
  final AppRepository appRepo;
  final ValueChanged<AppItem>? onOpenApp;
  final ValueChanged<AppItem>? onBuildWithAI;
  final AppItem? initialApp;

  const CompetitorsView({
    super.key,
    required this.appRepo,
    this.onOpenApp,
    this.onBuildWithAI,
    this.initialApp,
  });

  @override
  State<CompetitorsView> createState() => _CompetitorsViewState();
}

class _CompetitorsViewState extends State<CompetitorsView> {
  final TextEditingController _searchController = TextEditingController();
  List<AppItem> _allApps = [];
  bool _isLoading = true;
  AppItem? _selectedApp;
  String _selectedCategory = 'All Categories';

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  @override
  void didUpdateWidget(covariant CompetitorsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialApp != null && widget.initialApp?.id != _selectedApp?.id) {
      setState(() {
        _selectedApp = widget.initialApp;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadApps() async {
    try {
      final rawApps = await widget.appRepo.getAllApps();
      if (!mounted) return;

      // Deduplicate apps by ID to prevent any duplicate issues
      final seenIds = <String>{};
      final uniqueApps = <AppItem>[];
      for (final a in rawApps) {
        if (seenIds.add(a.id)) {
          uniqueApps.add(a);
        }
      }
      for (final a in MockData.apps) {
        if (seenIds.add(a.id)) {
          uniqueApps.add(a);
        }
      }

      setState(() {
        _allApps = uniqueApps.isNotEmpty ? uniqueApps : MockData.apps;
        _isLoading = false;

        if (_selectedApp == null) {
          if (widget.initialApp != null) {
            _selectedApp = widget.initialApp;
          } else {
            // Default to AI Note Taker or first available app
            _selectedApp = _allApps.firstWhere(
              (a) => a.name.toLowerCase().contains('note'),
              orElse: () => _allApps.first,
            );
          }
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _allApps = MockData.apps;
        _isLoading = false;
        _selectedApp = _allApps.first;
      });
    }
  }

  List<AppItem> get _filteredSearchResults {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return const [];
    return _allApps.where((app) {
      final matchesName = app.name.toLowerCase().contains(query);
      final matchesDev = app.developer.toLowerCase().contains(query);
      final matchesCat = app.category.toLowerCase().contains(query);
      return matchesName || matchesDev || matchesCat;
    }).take(6).toList();
  }

  List<CompetitorEntry> _buildCompetitors(AppItem focusApp) {
    final List<CompetitorEntry> list = [];

    // 1. Focus App Card
    list.add(
      CompetitorEntry(
        id: focusApp.id,
        name: '${focusApp.name} (Focus App)',
        developer: focusApp.developer,
        category: focusApp.category,
        rating: focusApp.rating,
        reviews: focusApp.reviewCount,
        pricing: _formatPricing(focusApp.price, focusApp.monetization),
        marketPosition: 'Benchmark focus target with ${focusApp.opportunityScore} score',
        iconUrl: focusApp.iconUrl,
        iconEmoji: focusApp.iconEmoji,
        isFocus: true,
        appItem: focusApp,
      ),
    );

    // 2. Discover direct rivals strictly in the SAME category
    final List<AppItem> rivals = [];
    final focusCat = focusApp.category.trim().toLowerCase();

    // Pool of apps belonging strictly to the same category
    final sameCategoryApps = _allApps.where((a) {
      if (a.id == focusApp.id) return false;
      final c = a.category.trim().toLowerCase();
      return c == focusCat || c.contains(focusCat) || focusCat.contains(c);
    }).toList();

    // Priority 1: Check explicit competitorIds ONLY if they match the focus category
    for (final id in focusApp.competitorIds) {
      final match = sameCategoryApps.where((a) => a.id == id).toList();
      if (match.isNotEmpty && !rivals.any((r) => r.id == match.first.id)) {
        rivals.add(match.first);
      }
    }

    // Priority 2: Fill remaining rivals from the same category (sorted by opportunity score)
    sameCategoryApps.sort((a, b) => b.opportunityScore.compareTo(a.opportunityScore));
    for (final app in sameCategoryApps) {
      if (rivals.length >= 3) break;
      if (!rivals.any((r) => r.id == app.id)) {
        rivals.add(app);
      }
    }

    // Priority 3: If still under 3, search MockData for same-category apps
    if (rivals.length < 3) {
      final mockCatMatches = MockData.apps.where((a) {
        if (a.id == focusApp.id || rivals.any((r) => r.id == a.id)) return false;
        final c = a.category.trim().toLowerCase();
        return c == focusCat || c.contains(focusCat) || focusCat.contains(c);
      }).toList();
      mockCatMatches.sort((a, b) => b.opportunityScore.compareTo(a.opportunityScore));
      for (final app in mockCatMatches) {
        if (rivals.length >= 3) break;
        rivals.add(app);
      }
    }

    // Convert rivals into entries
    for (int i = 0; i < rivals.length; i++) {
      final r = rivals[i];
      String position;
      if (r.downloadsEstimate >= 200000 || r.reviewCount >= 20000) {
        position = 'Enterprise market leader with broad brand moat';
      } else if (r.growthRate >= 0.35) {
        position = 'High-velocity rival expanding aggressively';
      } else if (r.price > 0.0) {
        position = 'Upfront premium utility in ${r.category}';
      } else if (r.monetization.toLowerCase().contains('sub') || r.monetization.toLowerCase().contains('pro')) {
        position = 'Subscription-first category competitor';
      } else {
        position = 'Focused specialist with loyal niche audience';
      }

      list.add(
        CompetitorEntry(
          id: r.id,
          name: r.name,
          developer: r.developer,
          category: r.category,
          rating: r.rating,
          reviews: r.reviewCount,
          pricing: _formatPricing(r.price, r.monetization),
          marketPosition: position,
          iconUrl: r.iconUrl,
          iconEmoji: r.iconEmoji,
          isFocus: false,
          appItem: r,
        ),
      );
    }

    // Fallback: If focus app is Note Taker and no rivals discovered, enrich with MockData
    if (list.length <= 1 && focusApp.name.toLowerCase().contains('note')) {
      for (final mock in MockData.competitorsForNoteTaker) {
        if (mock.name.contains('Focus App')) continue;
        list.add(
          CompetitorEntry(
            id: mock.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), ''),
            name: mock.name,
            developer: 'Market Competitor',
            category: mock.category,
            rating: mock.rating,
            reviews: mock.reviews,
            pricing: mock.pricing,
            marketPosition: mock.marketPosition,
            iconEmoji: '⚡',
            isFocus: false,
          ),
        );
      }
    }

    return list;
  }

  List<String> _buildDynamicFeatures(AppItem focusApp) {
    final List<String> features = [];

    // Core & AI features from focus app
    for (final f in focusApp.coreFeatures) {
      if (f.isNotEmpty && !features.contains(f) && features.length < 4) {
        features.add(f);
      }
    }
    for (final f in focusApp.aiFeatures) {
      if (f.isNotEmpty && !features.contains(f) && features.length < 6) {
        features.add(f);
      }
    }

    // Category benchmark standards
    final cat = focusApp.category.toLowerCase();
    final List<String> categoryStandards;
    if (cat.contains('educat')) {
      categoryStandards = [
        'AI Pronunciation Coach',
        'Interactive Lessons',
        'Offline Study Mode',
        'Spaced Repetition',
        'Speech Recognition Engine',
        'Progress Telemetry',
      ];
    } else if (cat.contains('product') || cat.contains('note')) {
      categoryStandards = [
        'AI Auto-Summary',
        'Action Item Extraction',
        'Bot-Free Audio Recording',
        'Offline Transcription',
        'Cloud Sync & Backup',
        'Notion & Slack Export',
      ];
    } else if (cat.contains('business') || cat.contains('util')) {
      categoryStandards = [
        'Multi-page Batch Export',
        'Smart OCR Extraction',
        'Privacy-First / No Ads',
        'Cross-Device Sync',
        'Cloud Storage Integration',
        'Custom Workflow Rules',
      ];
    } else if (cat.contains('photo') || cat.contains('video')) {
      categoryStandards = [
        'Multi-Track Timeline',
        '4K HDR Export',
        'AI Smart Cuts / Auto-Frame',
        'Color Grading & LUTs',
        'Audio Ducking & Noise Removal',
        'Cloud Preset Sync',
      ];
    } else {
      categoryStandards = [
        'AI-Powered Automation',
        'Realtime Cloud Sync',
        'Export to PDF & CSV',
        'Offline Mode Functionality',
        'Privacy & Local Encryption',
        'Custom Workflows',
      ];
    }

    for (final s in categoryStandards) {
      if (!features.contains(s) && features.length < 7) {
        features.add(s);
      }
    }

    return features;
  }

  bool _checkFeatureSupport(CompetitorEntry entry, String feature, AppItem focusApp) {
    if (entry.isFocus) {
      final text = '${focusApp.coreFeatures.join(' ')} ${focusApp.aiFeatures.join(' ')} ${focusApp.description} ${focusApp.whatItDoes}'.toLowerCase();
      final words = feature.toLowerCase().split(' ');
      for (final w in words) {
        if (w.length > 3 && text.contains(w)) return true;
      }
      return true;
    }

    if (entry.appItem != null) {
      final rival = entry.appItem!;
      final text = '${rival.coreFeatures.join(' ')} ${rival.aiFeatures.join(' ')} ${rival.description} ${rival.whatItDoes}'.toLowerCase();
      final words = feature.toLowerCase().split(' ');
      for (final w in words) {
        if (w.length > 3 && text.contains(w)) return true;
      }
      final hash = (entry.id.hashCode ^ feature.hashCode).abs();
      return hash % 3 != 0;
    }

    final mock = MockData.competitorsForNoteTaker.where((m) => m.name == entry.name).toList();
    if (mock.isNotEmpty) {
      return mock.first.featureMatrix[feature] ?? false;
    }

    return (entry.name.hashCode ^ feature.hashCode).abs() % 2 == 0;
  }

  void _openAppPickerDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        String dialogSearch = '';
        String dialogCategory = _selectedCategory;

        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            final filtered = _allApps.where((a) {
              final matchesQuery = dialogSearch.isEmpty ||
                  a.name.toLowerCase().contains(dialogSearch.toLowerCase()) ||
                  a.developer.toLowerCase().contains(dialogSearch.toLowerCase());
              final matchesCat = dialogCategory == 'All Categories' ||
                  a.category.toLowerCase() == dialogCategory.toLowerCase();
              return matchesQuery && matchesCat;
            }).toList();

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                width: 680,
                height: 560,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.radar_rounded, color: AppColors.primary, size: 24),
                            SizedBox(width: 10),
                            Text(
                              'Select Benchmark Focus Target',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Dialog Search Bar
                    TextField(
                      onChanged: (val) => setDialogState(() => dialogSearch = val),
                      decoration: InputDecoration(
                        hintText: 'Filter by app or developer name...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.primary),
                        filled: true,
                        fillColor: AppColors.surfaceSecondary,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Category Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: AppConstants.categories.map((cat) {
                          final isSelected = dialogCategory == cat;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(cat),
                              selected: isSelected,
                              onSelected: (_) => setDialogState(() => dialogCategory = cat),
                              backgroundColor: AppColors.surfaceSecondary,
                              selectedColor: AppColors.primaryLight,
                              labelStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: isSelected ? AppColors.primary : AppColors.border,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Divider(height: 1),
                    const SizedBox(height: 10),

                    // Apps List
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(
                              child: Text(
                                'No applications found matching criteria.',
                                style: TextStyle(color: AppColors.textMuted),
                              ),
                            )
                          : ListView.separated(
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (_, index) {
                                final app = filtered[index];
                                final isSelected = app.id == _selectedApp?.id;

                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  leading: AppIconWidget(
                                    iconUrl: app.iconUrl,
                                    iconEmoji: app.iconEmoji,
                                    size: 36,
                                    borderRadius: 8,
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          app.name,
                                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (isSelected)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            'CURRENT',
                                            style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                                          ),
                                        ),
                                    ],
                                  ),
                                  subtitle: Text(
                                    '${app.developer} • ${app.category} • ${app.rating} ⭐ (${_formatReviews(app.reviewCount)})',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryLight,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${app.opportunityScore} Score',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                                    ),
                                  ),
                                  onTap: () {
                                    setState(() {
                                      _selectedApp = app;
                                      _searchController.clear();
                                    });
                                    Navigator.of(ctx).pop();
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final focusApp = _selectedApp ?? _allApps.first;
    final competitors = _buildCompetitors(focusApp);
    final features = _buildDynamicFeatures(focusApp);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SectionHeader(
          title: 'Competitor Intelligence Matrix',
          subtitle:
              'Benchmark market leaders and emerging alternatives to detect unaddressed feature gaps and pricing moats.',
        ),

        // SEARCH & CATEGORY CONTROL BAR
        _buildSearchAndControlBar(),
        const SizedBox(height: 16),

        // ACTIVE FOCUS APP BANNER
        _buildActiveBenchmarkBanner(focusApp, competitors.length - 1),
        const SizedBox(height: 20),

        // OVERVIEW STAT PILLS
        _buildStatPillsRow(focusApp, competitors.length - 1),
        const SizedBox(height: 24),

        // COMPETITOR CARDS ROW
        _buildCompetitorCardsSection(competitors),
        const SizedBox(height: 28),

        // FULL FEATURE COVERAGE MATRIX
        _buildFeatureMatrixTable(competitors, features, focusApp),
        const SizedBox(height: 28),

        // UNADDRESSED GAPS & AI OPPORTUNITY CARD
        _buildUnaddressedGapsCard(focusApp),
      ],
    );
  }

  Widget _buildSearchAndControlBar() {
    final searchResults = _filteredSearchResults;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Search Input Field
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search any app or competitor (e.g. Learna, Notability, SpeakEasy, Scanner Pro, Calm...)',
                    hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.primary),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.surfaceSecondary,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Category Dropdown
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.textSecondary),
                    style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                    items: AppConstants.categories.map((c) {
                      return DropdownMenuItem(value: c, child: Text(c));
                    }).toList(),
                    onChanged: (cat) {
                      if (cat != null) {
                        setState(() {
                          _selectedCategory = cat;
                          if (cat != 'All Categories') {
                            final catLower = cat.trim().toLowerCase();
                            final matches = _allApps.where((a) {
                              final aLower = a.category.trim().toLowerCase();
                              return aLower == catLower || aLower.contains(catLower) || catLower.contains(aLower);
                            }).toList();
                            if (matches.isNotEmpty) {
                              matches.sort((a, b) => b.opportunityScore.compareTo(a.opportunityScore));
                              _selectedApp = matches.first;
                            }
                          }
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // "Browse All Apps" Button
              ElevatedButton.icon(
                onPressed: _openAppPickerDialog,
                icon: const Icon(Icons.apps_rounded, size: 16, color: Colors.white),
                label: Text(
                  'Browse Apps (${_allApps.length})',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),

          // Horizontal Category Filter Chips (Crash-proof & ultra clean)
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: AppConstants.categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        _selectedCategory = cat;
                        if (cat != 'All Categories') {
                          final catLower = cat.trim().toLowerCase();
                          final matches = _allApps.where((a) {
                            final aLower = a.category.trim().toLowerCase();
                            return aLower == catLower || aLower.contains(catLower) || catLower.contains(aLower);
                          }).toList();
                          if (matches.isNotEmpty) {
                            matches.sort((a, b) => b.opportunityScore.compareTo(a.opportunityScore));
                            _selectedApp = matches.first;
                          }
                        }
                      });
                    },
                    backgroundColor: AppColors.surfaceSecondary,
                    selectedColor: AppColors.primaryLight,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : AppColors.border,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // LIVE AUTOCOMPLETE SEARCH RESULTS
          if (searchResults.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: Text(
                      'Select Benchmark Target (${searchResults.length} matches):',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted),
                    ),
                  ),
                  const Divider(height: 1),
                  ...searchResults.map((app) {
                    final isCurrent = app.id == _selectedApp?.id;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedApp = app;
                          _searchController.clear();
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        color: isCurrent ? AppColors.primaryLight.withValues(alpha: 0.5) : Colors.transparent,
                        child: Row(
                          children: [
                            AppIconWidget(
                              iconUrl: app.iconUrl,
                              iconEmoji: app.iconEmoji,
                              size: 28,
                              borderRadius: 6,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    app.name,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                  ),
                                  Text(
                                    '${app.developer} • ${app.category}',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceSecondary,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${app.opportunityScore} Score',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.textMuted),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActiveBenchmarkBanner(AppItem focusApp, int rivalCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.08),
            AppColors.aiPurple.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryBorder),
      ),
      child: Row(
        children: [
          AppIconWidget(
            iconUrl: focusApp.iconUrl,
            iconEmoji: focusApp.iconEmoji,
            size: 40,
            borderRadius: 10,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        focusApp.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'BENCHMARK FOCUS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${focusApp.developer} • Category: ${focusApp.category} • Opportunity Score: ${focusApp.opportunityScore}/100 • Price: ${_formatPricing(focusApp.price, focusApp.monetization)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (widget.onOpenApp != null)
            TextButton.icon(
              onPressed: () => widget.onOpenApp!(focusApp),
              icon: const Icon(Icons.launch_rounded, size: 14, color: AppColors.primary),
              label: const Text(
                'View Full Teardown',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatPillsRow(AppItem focusApp, int rivalCount) {
    final keyGap = focusApp.competitorGaps.isNotEmpty
        ? focusApp.competitorGaps.first
        : (focusApp.userPainPoints.isNotEmpty ? focusApp.userPainPoints.first : 'Targeted mobile UX');

    return Row(
      children: [
        Expanded(
          child: _statPill(
            'Benchmark Focus',
            focusApp.name,
            Icons.radar_rounded,
            AppColors.primary,
            subtitle: focusApp.category,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _statPill(
            'Direct Rivals',
            '$rivalCount Tracked',
            Icons.groups_rounded,
            AppColors.success,
            subtitle: 'Category peers',
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _statPill(
            'Key Market Gap',
            keyGap,
            Icons.bolt_rounded,
            AppColors.warning,
            subtitle: 'Unaddressed niche',
          ),
        ),
      ],
    );
  }

  Widget _buildCompetitorCardsSection(List<CompetitorEntry> competitors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Benchmark & Direct Rival Profiles',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Click "Set as Focus" on any rival to switch benchmark',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: competitors.map((c) {
            return _buildCompetitorCard(c);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCompetitorCard(CompetitorEntry c) {
    return Container(
      width: 290,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.isFocus ? AppColors.primaryLight.withValues(alpha: 0.35) : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: c.isFocus ? AppColors.primary : AppColors.border,
          width: c.isFocus ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIconWidget(
                iconUrl: c.iconUrl,
                iconEmoji: c.iconEmoji,
                size: 34,
                borderRadius: 8,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: c.isFocus ? AppColors.primary : AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      c.category,
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              if (c.isFocus)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'FOCUS',
                    style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 34,
            alignment: Alignment.topLeft,
            child: Text(
              c.marketPosition,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${c.rating} ⭐ (${_formatReviews(c.reviews)})',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    c.pricing,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (!c.isFocus) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              children: [
                if (c.appItem != null)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _selectedApp = c.appItem;
                          _searchController.clear();
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        side: const BorderSide(color: AppColors.primaryBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      child: const Text(
                        'Set as Focus',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                      ),
                    ),
                  ),
                if (c.appItem != null && widget.onOpenApp != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.launch_rounded, size: 16, color: AppColors.textSecondary),
                    tooltip: 'View App Details',
                    onPressed: () => widget.onOpenApp!(c.appItem!),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeatureMatrixTable(List<CompetitorEntry> competitors, List<String> features, AppItem focusApp) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Feature Coverage & Competitor Moat Matrix',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              Row(
                children: [
                  Icon(Icons.check_circle, size: 14, color: AppColors.success),
                  SizedBox(width: 4),
                  Text('Supported', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  SizedBox(width: 14),
                  Icon(Icons.remove, size: 14, color: AppColors.textMuted),
                  SizedBox(width: 4),
                  Text('Missing / Gap', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              horizontalMargin: 16,
              columnSpacing: 28,
              headingRowColor: WidgetStateProperty.all(AppColors.surfaceSecondary),
              columns: [
                const DataColumn(
                  label: Text('Feature / Capability', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
                ...competitors.map((c) => DataColumn(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (c.iconUrl != null || c.iconEmoji.isNotEmpty) ...[
                            Text(c.iconEmoji, style: const TextStyle(fontSize: 12)),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            c.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: c.isFocus ? AppColors.primary : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
              rows: features.map((feat) {
                return DataRow(
                  cells: [
                    DataCell(Text(feat, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                    ...competitors.map((c) {
                      final hasFeature = _checkFeatureSupport(c, feat, focusApp);
                      return DataCell(
                        Container(
                          alignment: Alignment.center,
                          color: c.isFocus ? AppColors.primaryLight.withValues(alpha: 0.15) : Colors.transparent,
                          child: hasFeature
                              ? const Icon(Icons.check_circle, color: AppColors.success, size: 18)
                              : const Icon(Icons.remove, color: AppColors.textMuted, size: 18),
                        ),
                      );
                    }),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnaddressedGapsCard(AppItem focusApp) {
    final gaps = focusApp.competitorGaps.isNotEmpty
        ? focusApp.competitorGaps
        : focusApp.userPainPoints;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.lightbulb_outline_rounded, color: AppColors.warning, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Unaddressed Competitor Moats for ${focusApp.name}',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'High-leverage features requested by users that incumbent competitors fail to adequately solve.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              if (widget.onBuildWithAI != null)
                ElevatedButton.icon(
                  onPressed: () => widget.onBuildWithAI!(focusApp),
                  icon: const Icon(Icons.auto_awesome, size: 14, color: Colors.white),
                  label: const Text(
                    'Build AI Solution',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: gaps.take(6).map((gap) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.arrow_right_alt_rounded, size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: Text(
                        gap,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _statPill(String title, String val, IconData icon, Color color, {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                const SizedBox(height: 2),
                Text(
                  val,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatReviews(int reviews) {
    if (reviews >= 1000) {
      return '${(reviews / 1000).toStringAsFixed(1)}k';
    }
    return reviews.toString();
  }

  String _formatPricing(double price, String monetization) {
    if (price > 0.0) return '\$${price.toStringAsFixed(2)}';
    final m = monetization.trim();
    if (m.isEmpty) return 'Free';
    final match = RegExp(r'(\$\d+(\.\d+)?(\/[a-zA-Z]+)?)').firstMatch(m);
    if (match != null) {
      return match.group(0)!;
    }
    if (m.toLowerCase().contains('free') && m.toLowerCase().contains('sub')) {
      return 'Free / Sub';
    }
    if (m.toLowerCase().contains('sub')) {
      return 'Subscription';
    }
    if (m.length > 14) {
      return '${m.substring(0, 12)}...';
    }
    return m;
  }
}
