import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../services/subscription/subscription_service.dart';

class PricingModal extends StatefulWidget {
  final SubscriptionService subscriptionService;
  final String? featureTrigger;

  const PricingModal({
    super.key,
    required this.subscriptionService,
    this.featureTrigger,
  });

  static Future<void> show(
    BuildContext context, {
    required SubscriptionService subscriptionService,
    String? featureTrigger,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: PricingModal(
          subscriptionService: subscriptionService,
          featureTrigger: featureTrigger,
        ),
      ),
    );
  }

  @override
  State<PricingModal> createState() => _PricingModalState();
}

class _PricingModalState extends State<PricingModal> {
  bool _isAnnual = true;
  bool _isUpgrading = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 880;

        return Container(
          constraints: const BoxConstraints(maxWidth: 1000),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 32,
                offset: const Offset(0, 16),
              ),
            ],
          ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.aiPurpleLight,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.aiPurple.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.auto_awesome, size: 14, color: AppColors.aiPurple),
                            SizedBox(width: 6),
                            Text(
                              'SCALE YOUR APP EMPIRE',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.aiPurple,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Unlock Full Market Intelligence & AI Blueprints',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.featureTrigger ??
                            'Discover breakout opportunities, generate complete 14-section architectural blueprints, and track unlimited apps.',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20, color: AppColors.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Billing Toggle (Monthly vs Annual)
            Center(
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildToggleOption(label: 'Monthly Billing', isSelected: !_isAnnual, onSelect: () => setState(() => _isAnnual = false)),
                    _buildToggleOption(
                      label: 'Annual Billing',
                      isSelected: _isAnnual,
                      badge: 'SAVE 20%',
                      onSelect: () => setState(() => _isAnnual = true),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Pricing Cards Grid
            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildFreeCard()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildProCard()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildAgencyCard()),
                ],
              )
            else
              Column(
                children: [
                  _buildProCard(),
                  const SizedBox(height: 16),
                  _buildFreeCard(),
                  const SizedBox(height: 16),
                  _buildAgencyCard(),
                ],
              ),
            const SizedBox(height: 20),

            // Footer assurance
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified_user_outlined, size: 14, color: AppColors.textMuted),
                SizedBox(width: 6),
                Text(
                  'Cancel anytime with 1 click. No questions asked.',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
      },
    );
  }

  Widget _buildToggleOption({
    required String label,
    required bool isSelected,
    String? badge,
    required VoidCallback onSelect,
  }) {
    return InkWell(
      onTap: onSelect,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.success),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFreeCard() {
    final isCurrent = widget.subscriptionService.isFree;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Starter Free', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          const Text('For casual exploring', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 16),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('\$0', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              SizedBox(width: 4),
              Text('/ forever', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: isCurrent
                ? null
                : () {
                    widget.subscriptionService.downgradeToFree();
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Switched to Free tier for testing.')),
                    );
                  },
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(isCurrent ? 'Current Plan' : 'Downgrade to Free'),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          _featureRow('3 AI App Teardowns / day', isIncluded: true),
          _featureRow('Opportunity Radar Signals', isIncluded: true),
          _featureRow('Up to 3 Watchlist Items', isIncluded: true),
          _featureRow('14-Section Build Blueprints', isIncluded: false),
          _featureRow('Daily Automated Email Digest', isIncluded: false),
          _featureRow('Export Specs to JSON / MD', isIncluded: false),
        ],
      ),
    );
  }

  Widget _buildProCard() {
    final isCurrent = widget.subscriptionService.isPro;
    final price = _isAnnual ? '\$23' : '\$29';
    final billingNote = _isAnnual ? 'billed \$279/year' : 'billed monthly';

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 16,
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
              const Text('Pro Builder', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'MOST POPULAR',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text('For indie hackers & builders', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(price, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              const SizedBox(width: 4),
              const Text('/ month', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ],
          ),
          Text(billingNote, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: isCurrent || _isUpgrading
                ? null
                : () async {
                    final navigator = Navigator.of(context);
                    final messenger = ScaffoldMessenger.of(context);
                    setState(() => _isUpgrading = true);
                    await Future.delayed(const Duration(milliseconds: 600));
                    widget.subscriptionService.upgradeToPro();
                    if (mounted) {
                      navigator.pop();
                      messenger.showSnackBar(
                        const SnackBar(
                          backgroundColor: AppColors.primary,
                          content: Text('🎉 Welcome to Pro Builder! All features are unlocked.'),
                          duration: Duration(seconds: 4),
                        ),
                      );
                    }
                  },
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 44),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: _isUpgrading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text(isCurrent ? 'Active Plan (Pro)' : 'Upgrade to Pro Builder'),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          _featureRow('Unlimited AI App Teardowns', isIncluded: true, isHighlight: true),
          _featureRow('Complete 14-Section Build Blueprints', isIncluded: true, isHighlight: true),
          _featureRow('Unlimited Cloud-Synced Watchlists', isIncluded: true),
          _featureRow('Daily 8 AM Executive Intelligence Email', isIncluded: true),
          _featureRow('Export Architecture Specs to MD/JSON', isIncluded: true),
          _featureRow('Priority Scraper & Gemini AI Queue', isIncluded: true),
        ],
      ),
    );
  }

  Widget _buildAgencyCard() {
    final price = _isAnnual ? '\$63' : '\$79';
    final billingNote = _isAnnual ? 'billed \$759/year' : 'billed monthly';

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Agency & Team', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          const Text('For studios & development teams', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(price, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              const SizedBox(width: 4),
              const Text('/ month', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ],
          ),
          Text(billingNote, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          const SizedBox(height: 18),
          OutlinedButton(
            onPressed: () {
              widget.subscriptionService.upgradeToPro();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('🎉 Agency Plan Activated!')),
              );
            },
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Contact for Seats'),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          _featureRow('Everything in Pro Builder', isIncluded: true),
          _featureRow('5 Team Member Seats', isIncluded: true),
          _featureRow('Custom Webhook Dispatchers', isIncluded: true),
          _featureRow('Custom Store Category Scrapers', isIncluded: true),
          _featureRow('Dedicated Slack & Discord Channel', isIncluded: true),
        ],
      ),
    );
  }

  Widget _featureRow(String text, {required bool isIncluded, bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isIncluded ? Icons.check_circle : Icons.remove_circle_outline,
            size: 16,
            color: isIncluded ? (isHighlight ? AppColors.primary : AppColors.success) : AppColors.textMuted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w500,
                color: isIncluded ? AppColors.textPrimary : AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
