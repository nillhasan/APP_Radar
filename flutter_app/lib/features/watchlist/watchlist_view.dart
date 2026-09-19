import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/app_item.dart';
import '../../data/repositories/watchlist_repository.dart';
import '../../widgets/score_badge.dart';
import '../../widgets/section_header.dart';

class WatchlistView extends StatefulWidget {
  final WatchlistRepository watchlistRepo;
  final ValueChanged<AppItem> onOpenApp;
  final ValueChanged<AppItem> onBuildWithAI;

  const WatchlistView({
    super.key,
    required this.watchlistRepo,
    required this.onOpenApp,
    required this.onBuildWithAI,
  });

  @override
  State<WatchlistView> createState() => _WatchlistViewState();
}

class _WatchlistViewState extends State<WatchlistView> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SectionHeader(
          title: 'Saved Watchlist & Opportunity Monitor',
          subtitle: 'Monitor high-conviction apps, track score shifts, and record strategic execution notes.',
        ),
        FutureBuilder<List<AppItem>>(
          future: widget.watchlistRepo.getWatchlistedApps(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ));
            }

            final apps = snapshot.data!;

            if (apps.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(40),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: const [
                    Icon(Icons.bookmark_border, size: 48, color: AppColors.textMuted),
                    SizedBox(height: 12),
                    Text(
                      'No apps in watchlist yet',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Explore opportunities or app explorer and tap bookmark to add apps here.',
                      style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: apps.map((app) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
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
                          Container(
                            width: 44,
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceSecondary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(app.iconEmoji, style: const TextStyle(fontSize: 22)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      app.name,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceSecondary,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(app.category, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Rank #${app.ranking} • ${app.rating} ⭐ • +${app.growthRate.toInt()}% growth',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                          ScoreBadge(score: app.opportunityScore),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSecondary.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.edit_note, size: 18, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                app.notes.isNotEmpty ? app.notes : 'No private notes added yet.',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontStyle: app.notes.isNotEmpty ? FontStyle.normal : FontStyle.italic,
                                  color: app.notes.isNotEmpty ? AppColors.textPrimary : AppColors.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () async {
                              await widget.watchlistRepo.removeFromWatchlist(app.id);
                              setState(() {});
                            },
                            icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                            label: const Text('Remove', style: TextStyle(color: AppColors.error, fontSize: 12)),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () => widget.onOpenApp(app),
                            icon: const Icon(Icons.analytics_outlined, size: 16),
                            label: const Text('Deep Teardown', style: TextStyle(fontSize: 12)),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            onPressed: () => widget.onBuildWithAI(app),
                            icon: const Icon(Icons.auto_awesome, size: 16),
                            label: const Text('Build With AI', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
