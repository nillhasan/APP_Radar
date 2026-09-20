import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class RegionalBreakdownBar extends StatelessWidget {
  final Map<String, double> regionalBreakdown;
  final double totalRevenue;

  const RegionalBreakdownBar({
    super.key,
    required this.regionalBreakdown,
    required this.totalRevenue,
  });

  static const Map<String, _RegionMeta> _regionMetadata = {
    'US': _RegionMeta(name: 'United States', flag: '🇺🇸', color: Color(0xFF2563EB)),
    'UK': _RegionMeta(name: 'United Kingdom', flag: '🇬🇧', color: Color(0xFF10B981)),
    'DE': _RegionMeta(name: 'Germany', flag: '🇩🇪', color: Color(0xFFF59E0B)),
    'JP': _RegionMeta(name: 'Japan', flag: '🇯🇵', color: Color(0xFF8B5CF6)),
    'Other': _RegionMeta(name: 'Other Markets', flag: '🌐', color: Color(0xFF94A3B8)),
  };

  @override
  Widget build(BuildContext context) {
    if (regionalBreakdown.isEmpty) return const SizedBox.shrink();

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
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.public_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '30-Day Regional Revenue & Market Share',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Geographic revenue distribution estimated from store download velocity and regional ARPU',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Multi-color Stacked Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 16,
              child: Row(
                children: regionalBreakdown.entries.map((entry) {
                  final meta = _regionMetadata[entry.key] ??
                      const _RegionMeta(name: 'Region', flag: '🌐', color: Color(0xFF64748B));
                  final flex = (entry.value * 1000).toInt().clamp(1, 1000);

                  return Expanded(
                    flex: flex,
                    child: Tooltip(
                      message: '${meta.name} (${entry.key}): ${(entry.value * 100).toStringAsFixed(1)}% '
                          '(~\$${_formatCompactCurrency(totalRevenue * entry.value)})',
                      child: Container(
                        color: meta.color,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Region Legend Badges
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: regionalBreakdown.entries.map((entry) {
              final meta = _regionMetadata[entry.key] ??
                  const _RegionMeta(name: 'Region', flag: '🌐', color: Color(0xFF64748B));
              final pct = (entry.value * 100).toStringAsFixed(0);
              final shareRevenue = totalRevenue * entry.value;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: meta.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${meta.flag} ${entry.key}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$pct%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: meta.color,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(~\$${_formatCompactCurrency(shareRevenue)})',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
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

  String _formatCompactCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}k';
    }
    return amount.toStringAsFixed(0);
  }
}

class _RegionMeta {
  final String name;
  final String flag;
  final Color color;

  const _RegionMeta({
    required this.name,
    required this.flag,
    required this.color,
  });
}
