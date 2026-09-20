import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/app_item.dart';
import '../../../widgets/app_icon_widget.dart';

class CompetitorAvatarStack extends StatelessWidget {
  final AppItem currentApp;
  final List<AppItem> allApps;
  final Function(AppItem) onSelectCompetitor;
  final VoidCallback? onOpenMatrix;

  const CompetitorAvatarStack({
    super.key,
    required this.currentApp,
    required this.allApps,
    required this.onSelectCompetitor,
    this.onOpenMatrix,
  });

  List<AppItem> get _competitors {
    // 1. First try matching competitorIds
    final List<AppItem> matches = [];
    for (final id in currentApp.competitorIds) {
      final found = allApps.where((a) => a.id == id).toList();
      if (found.isNotEmpty) {
        matches.add(found.first);
      }
    }

    // 2. If fewer than 2 matches, add apps in the same category (excluding current app)
    if (matches.length < 2) {
      final sameCategory = allApps.where(
        (a) => a.id != currentApp.id &&
            !matches.any((m) => m.id == a.id) &&
            a.category.toLowerCase() == currentApp.category.toLowerCase(),
      );
      matches.addAll(sameCategory);
    }

    // 3. If still empty, add any other apps
    if (matches.isEmpty) {
      final others = allApps.where((a) => a.id != currentApp.id).take(3);
      matches.addAll(others);
    }

    return matches;
  }

  @override
  Widget build(BuildContext context) {
    final competitors = _competitors;
    if (competitors.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.aiPurpleLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.compare_arrows_rounded,
                  size: 18,
                  color: AppColors.aiPurple,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Direct Category Competitors',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${competitors.length} Rivals Tracked',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const Spacer(),
              if (onOpenMatrix != null)
                InkWell(
                  onTap: onOpenMatrix,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primaryBorder),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.compare_arrows_rounded, size: 14, color: AppColors.primary),
                        SizedBox(width: 5),
                        Text(
                          'Full Intelligence Matrix',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded, size: 12, color: AppColors.primary),
                      ],
                    ),
                  ),
                )
              else
                const Text(
                  '1-Click Switch',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Horizontal scroll of competitor cards
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: competitors.map((rival) {
                return _buildCompetitorCard(context, rival);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompetitorCard(BuildContext context, AppItem rival) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onSelectCompetitor(rival),
          borderRadius: BorderRadius.circular(10),
          hoverColor: AppColors.primaryLight.withValues(alpha: 0.5),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondary.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppIconWidget(
                  iconUrl: rival.iconUrl,
                  iconEmoji: rival.iconEmoji,
                  size: 34,
                  borderRadius: 8,
                  fontSize: 16,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          rival.name,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.aiPurpleLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${rival.opportunityScore} Opp',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.aiPurple,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Rank #${rival.ranking}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text('•', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                        const SizedBox(width: 4),
                        Text(
                          rival.price <= 0 ? 'Free' : '\$${rival.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: rival.price <= 0 ? AppColors.success : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
