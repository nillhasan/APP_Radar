import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_service.dart';

class LegalModal extends StatefulWidget {
  final int initialTabIndex; // 0: Privacy, 1: Terms, 2: Security

  const LegalModal({
    super.key,
    this.initialTabIndex = 0,
  });

  static Future<void> show(BuildContext context, {int initialTabIndex = 0}) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (ctx) => LegalModal(initialTabIndex: initialTabIndex),
    );
  }

  @override
  State<LegalModal> createState() => _LegalModalState();
}

class _LegalModalState extends State<LegalModal> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.instance.isDark;
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 768;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 40,
        vertical: isMobile ? 24 : 48,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 780, maxHeight: 720),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.carbon : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.rekkiBorderSubtle : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.graphite : const Color(0xFFF8FAFC),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? AppColors.rekkiBorderSubtle : const Color(0xFFE2E8F0),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.signalBlue.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.shield_outlined, color: AppColors.signalBlue, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AppRadar Legal & Trust Center',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.paper : const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'Enterprise-grade security and transparency',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? AppColors.smoke : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      color: isDark ? AppColors.steel : const Color(0xFF64748B),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // Tab Bar
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? AppColors.rekkiBorderSubtle : const Color(0xFFE2E8F0),
                    ),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.signalBlue,
                  indicatorWeight: 2,
                  labelColor: isDark ? AppColors.paper : AppColors.signalBlue,
                  unselectedLabelColor: isDark ? AppColors.steel : const Color(0xFF64748B),
                  labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  tabs: const [
                    Tab(text: 'Privacy Policy'),
                    Tab(text: 'Terms of Service'),
                    Tab(text: 'Security & Telemetry'),
                  ],
                ),
              ),

              // Tab Content Body
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPrivacyTab(isDark),
                    _buildTermsTab(isDark),
                    _buildSecurityTab(isDark),
                  ],
                ),
              ),

              // Footer
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.graphite : const Color(0xFFF8FAFC),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                  border: Border(
                    top: BorderSide(
                      color: isDark ? AppColors.rekkiBorderSubtle : const Color(0xFFE2E8F0),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Effective: October 2026',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.steel : const Color(0xFF94A3B8),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? AppColors.signalBlue : const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        elevation: 0,
                      ),
                      child: const Text('I Understand', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacyTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('1. Information We Collect', isDark),
          _sectionBody(
            'AppRadar ("we", "our") collects information necessary to provide market telemetry and competitive intelligence services. This includes account credentials (email, name), store search parameters, and telemetry tracking preferences.',
            isDark,
          ),
          const SizedBox(height: 16),
          _sectionTitle('2. How We Use Data', isDark),
          _sectionBody(
            'We use aggregated telemetry strictly to synthesize competitive teardowns, forecast opportunity ratings, and power our AI architectural blueprints. We NEVER sell your personal data or search habits to third-party ad networks.',
            isDark,
          ),
          const SizedBox(height: 16),
          _sectionTitle('3. Google User Data Policy', isDark),
          _sectionBody(
            'When you authenticate via Google Sign-In, we only request basic profile info (email address, full name, and avatar URL) to establish your secure user session. We adhere strictly to Google API Services User Data Policy, including the Limited Use requirements.',
            isDark,
          ),
          const SizedBox(height: 16),
          _sectionTitle('4. Data Retention and Deletion', isDark),
          _sectionBody(
            'Users may request permanent deletion of their account, saved watchlists, and generated AI blueprints at any time via Settings or by contacting support@appradar.dev.',
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildTermsTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('1. Service Usage', isDark),
          _sectionBody(
            'By accessing AppRadar, you agree to comply with our platform terms. AppRadar provides informational intelligence on public app stores. You agree not to abuse automated scrapers against AppRadar telemetry endpoints.',
            isDark,
          ),
          const SizedBox(height: 16),
          _sectionTitle('2. Subscriptions & Billing', isDark),
          _sectionBody(
            'Pro and Agency tier subscriptions are billed on a recurring monthly or annual basis via Stripe. You can cancel at any time directly through your billing portal with zero lock-in.',
            isDark,
          ),
          const SizedBox(height: 16),
          _sectionTitle('3. AI Blueprint Ownership', isDark),
          _sectionBody(
            'All technical architectures, database schemas, and product blueprints generated using our AI Blueprint Engine belong 100% to you. You are free to commercialize and build applications based on generated outputs.',
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('1. Encryption Standards', isDark),
          _sectionBody(
            'All data in transit is encrypted using TLS 1.3. User tokens, passwords, and sensitive keys are salted and hashed via Argon2id within our SOC2 Type II compliant Supabase infrastructure.',
            isDark,
          ),
          const SizedBox(height: 16),
          _sectionTitle('2. Row-Level Security (RLS)', isDark),
          _sectionBody(
            'Your saved watchlist items, custom competitor tracking matrices, and proprietary teardown notes are isolated with PostgreSQL Row Level Security policies so only you can access them.',
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: isDark ? AppColors.paper : const Color(0xFF0F172A),
      ),
    );
  }

  Widget _sectionBody(String body, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        body,
        style: TextStyle(
          fontSize: 12.5,
          height: 1.55,
          color: isDark ? AppColors.ash : const Color(0xFF475569),
        ),
      ),
    );
  }
}
