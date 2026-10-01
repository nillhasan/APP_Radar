import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_service.dart';
import '../../widgets/section_header.dart';
import '../../widgets/pwa/pwa_install_modal.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  bool _dailyEmail = true;
  bool _weeklyDigest = true;
  bool _highPotentialAlerts = true;
  String _selectedAiModel = 'Gemini 3.8 Flash (Recommended)';
  final String _reportScheduleTime = '08:00 AM UTC';

  @override
  void initState() {
    super.initState();
    ThemeService.instance.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    ThemeService.instance.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SectionHeader(
          title: 'Platform Settings & Configurations',
          subtitle: 'Manage telemetry feeds, AI model providers, delivery schedules, and API access.',
        ),

        // Appearance & Theme Card
        _buildSettingsCard(
          title: 'Appearance & Theme',
          icon: Icons.palette_outlined,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.currentPrimaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  ThemeService.instance.isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                  color: ThemeService.instance.isDark ? const Color(0xFFFBBF24) : AppColors.primary,
                  size: 22,
                ),
              ),
              title: Text(
                'Interface Theme Mode',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.currentTextPrimary),
              ),
              subtitle: Text(
                ThemeService.instance.isDark
                    ? 'Dark Mode active. Deep charcoal palette optimized for low light & OLED.'
                    : 'Light Mode active. Clean, high-clarity interface for daylight operations.',
                style: TextStyle(fontSize: 12, color: AppColors.currentTextMuted),
              ),
              trailing: SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.light,
                    icon: Icon(Icons.light_mode, size: 16),
                    label: Text('Light'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    icon: Icon(Icons.dark_mode, size: 16),
                    label: Text('Dark'),
                  ),
                ],
                selected: {ThemeService.instance.themeMode},
                onSelectionChanged: (Set<ThemeMode> newSelection) {
                  ThemeService.instance.setThemeMode(newSelection.first);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Profile Card
        _buildSettingsCard(
          title: 'Account Profile',
          icon: Icons.person_outline,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: AppColors.primaryLight,
                child: Text('AR', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
              ),
              title: Text('Admin Workspace (Founder Tier)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.currentTextPrimary)),
              subtitle: Text('admin@appradar.ai • Active Pro License', style: TextStyle(fontSize: 12, color: AppColors.currentTextMuted)),
              trailing: OutlinedButton(onPressed: () {}, child: const Text('Manage')),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // AI Provider Settings
        _buildSettingsCard(
          title: 'AI & Inference Engine',
          icon: Icons.auto_awesome,
          children: [
            Text(
              'Select primary language model used for opportunity score computation, feature teardowns, and blueprint synthesis.',
              style: TextStyle(fontSize: 12, color: AppColors.currentTextSecondary),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.currentSurfaceSecondary,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.currentBorder),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedAiModel,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'Gemini 3.8 Flash (Recommended)', child: Text('Gemini 3.8 Flash (Recommended)')),
                    DropdownMenuItem(value: 'GPT-5-mini', child: Text('OpenAI GPT-5-mini')),
                    DropdownMenuItem(value: 'Claude 3.5 Sonnet', child: Text('Anthropic Claude 3.5 Sonnet')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedAiModel = val);
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Data Sources
        _buildSettingsCard(
          title: 'Data Sources & Scrapers',
          icon: Icons.hub_outlined,
          children: [
            _toggleItem('iOS App Store RSS & Search API', 'Live connection to US, UK, and CA store feeds', true),
            _toggleItem('Google Play Store RSS Feeds', 'Telemetry polling for Top Grossing and Trending charts', true),
            _toggleItem('Social Signal Aggregator (Reddit & X)', 'Sentiment monitoring for app complaints and gaps', false),
          ],
        ),
        const SizedBox(height: 16),

        // Report Schedules
        _buildSettingsCard(
          title: 'Daily Report & Email Delivery',
          icon: Icons.schedule,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Automated Dispatch Schedule', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              subtitle: Text('Current trigger time: $_reportScheduleTime', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              trailing: TextButton(
                onPressed: () {},
                child: const Text('Edit Cron'),
              ),
            ),
            _toggleItem('Send Daily Intelligence Brief via Resend', 'Deliver HTML digest to admin@appradar.ai every morning', _dailyEmail, (v) => setState(() => _dailyEmail = v)),
            _toggleItem('Weekly Macro Velocity Digest', 'Consolidated Sunday market overview', _weeklyDigest, (v) => setState(() => _weeklyDigest = v)),
            _toggleItem('Instant Alerts for High-Potential Apps (>80)', 'Push notifications when breakout scores are detected', _highPotentialAlerts, (v) => setState(() => _highPotentialAlerts = v)),
          ],
        ),
        const SizedBox(height: 16),

        // API & Backend Configuration
        _buildSettingsCard(
          title: 'Supabase & API Configuration',
          icon: Icons.security,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('PostgreSQL / Supabase Connection', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              subtitle: const Text('Schema version 1.0.0 • 4 tables initialized', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('READY', style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Progressive Web App (PWA) & Offline Access
        _buildSettingsCard(
          title: 'Progressive Web App (PWA) & Offline Access',
          icon: Icons.install_desktop_rounded,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.install_mobile_rounded, color: AppColors.primary, size: 22),
              ),
              title: const Text(
                'Install AppRadar to Desktop / Mobile',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              subtitle: const Text(
                'Run as a frameless standalone application with offline telemetry caching and 1-tap launch.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              trailing: ElevatedButton.icon(
                onPressed: () => PwaInstallModal.show(context),
                icon: const Icon(Icons.download_rounded, size: 14, color: Colors.white),
                label: const Text('Install App', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSettingsCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Material(
      color: AppColors.currentSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.currentBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.currentTextPrimary)),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _toggleItem(String title, String subtitle, bool value, [ValueChanged<bool>? onChanged]) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.currentTextPrimary)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 11, color: AppColors.currentTextMuted)),
      value: value,
      activeThumbColor: AppColors.primary,
      onChanged: onChanged ?? (_) {},
    );
  }
}
