import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../services/auth/auth_service.dart';
import '../../services/subscription/subscription_service.dart';
import 'agency_inquiry_modal.dart';

class PricingModal extends StatefulWidget {
  final SubscriptionService subscriptionService;
  final String? featureTrigger;
  final VoidCallback? onRequiresAuth;
  final AuthService? authService;
  final SupabaseClient? supabaseClient;

  const PricingModal({
    super.key,
    required this.subscriptionService,
    this.featureTrigger,
    this.onRequiresAuth,
    this.authService,
    this.supabaseClient,
  });

  static Future<void> show(
    BuildContext context, {
    required SubscriptionService subscriptionService,
    String? featureTrigger,
    VoidCallback? onRequiresAuth,
    AuthService? authService,
    SupabaseClient? supabaseClient,
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
          onRequiresAuth: onRequiresAuth,
          authService: authService,
          supabaseClient: supabaseClient,
        ),
      ),
    );
  }

  @override
  State<PricingModal> createState() => _PricingModalState();
}

class _PricingModalState extends State<PricingModal> {
  bool _isAnnual = false;
  bool _isUpgrading = false;
  bool _awaitingPaymentConfirmation = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 880;

        return Container(
          constraints: BoxConstraints(maxWidth: _awaitingPaymentConfirmation ? 520 : 1000),
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
          child: _awaitingPaymentConfirmation
              ? _buildAwaitingPaymentView()
              : SingleChildScrollView(
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
                          if (widget.featureTrigger != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.lock_open, size: 14, color: AppColors.primary),
                                  const SizedBox(width: 6),
                                  Text(
                                    widget.featureTrigger!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const Text(
                            'Unlock Full Market Intelligence & AI Blueprints',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Get instant access to deep architectural teardowns, 14-section specifications, and daily market intelligence.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textMuted),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Monthly vs Annual Toggle
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildToggleOption(
                          label: 'Monthly Billing',
                          isSelected: !_isAnnual,
                          onSelect: () => setState(() => _isAnnual = false),
                        ),
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

                // Tier Cards Grid / Column
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
                const Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Icon(Icons.verified_user_outlined, size: 14, color: AppColors.textMuted),
                    Text(
                      'Secured by Stripe. Cancel anytime with 1 click. No questions asked.',
                      textAlign: TextAlign.center,
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
                color: isSelected ? AppColors.textPrimary : AppColors.textMuted,
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
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.success,
                  ),
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
                : () async {
                    final launched = await widget.subscriptionService.launchCustomerPortal();
                    if (!launched && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('To manage or downgrade your subscription, please visit the Stripe Customer Portal.')),
                      );
                    }
                  },
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(isCurrent ? 'Current Plan' : 'Manage Subscription'),
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

          // Main Pro Action: Stripe Checkout or Customer Portal
          if (isCurrent)
            OutlinedButton.icon(
              onPressed: () => widget.subscriptionService.launchCustomerPortal(),
              icon: const Icon(Icons.credit_card, size: 16, color: AppColors.primary),
              label: const Text('Manage Subscription (Stripe Portal)'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            )
          else
            FilledButton.icon(
              onPressed: _isUpgrading ? null : _handleStripeCheckout,
              icon: _isUpgrading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.bolt, size: 16),
              label: Text(_isUpgrading ? 'Connecting Stripe...' : 'Upgrade to Pro Builder'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),



          const SizedBox(height: 16),
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

  Future<void> _handleStripeCheckout() async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _isUpgrading = true);
    final launched = await widget.subscriptionService.launchStripeCheckout(
      isAnnual: _isAnnual,
    );
    if (mounted) setState(() => _isUpgrading = false);

    if (!launched) {
      // User is not logged in
      if (navigator.canPop()) {
        navigator.pop();
      }
      if (widget.onRequiresAuth != null) {
        widget.onRequiresAuth!();
      } else {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Please sign in first so your Pro subscription can be linked to your account.'),
            duration: Duration(seconds: 4),
          ),
        );
      }
    } else {
      if (mounted) {
        setState(() => _awaitingPaymentConfirmation = true);
      }
    }
  }

  Widget _buildAwaitingPaymentView() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt, size: 14, color: AppColors.primary),
                    SizedBox(width: 6),
                    Text(
                      'PRO BUILDER CHECKOUT',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textMuted),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF2563EB)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.credit_card, size: 40, color: Colors.white),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Checkout Opened in New Tab',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We launched Stripe in your browser. Please enter your card details on Stripe (${_isAnnual ? "\$23/month billed annually" : "\$29/month billed monthly"}).',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () async {
              await widget.subscriptionService.handlePaymentSuccess();
              if (mounted) {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: AppColors.primary,
                    duration: Duration(seconds: 5),
                    content: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '🎉 Payment Verified! Welcome to Pro Builder. All features unlocked.',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
            },
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: const Text(
              '✓ I Have Completed Payment — Activate Pro',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: _handleStripeCheckout,
                icon: const Icon(Icons.open_in_new, size: 14),
                label: const Text('Re-open Stripe Tab', style: TextStyle(fontSize: 12)),
              ),
              const Text(' • ', style: TextStyle(color: AppColors.textMuted)),
              TextButton(
                onPressed: () => setState(() => _awaitingPaymentConfirmation = false),
                child: const Text('Back to Plans', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ),
            ],
          ),
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
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
              AgencyInquiryModal.show(
                context,
                authService: widget.authService,
                supabaseClient: widget.supabaseClient,
              );
            },
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Contact for Custom Seats'),
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
