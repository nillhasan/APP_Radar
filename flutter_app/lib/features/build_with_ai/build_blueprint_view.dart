import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/build_blueprint.dart';
import '../../services/export/file_export_service.dart';
import '../../services/subscription/subscription_service.dart';

class BuildBlueprintView extends StatelessWidget {
  final BuildBlueprint blueprint;
  final VoidCallback onBack;
  final SubscriptionService? subscriptionService;

  const BuildBlueprintView({
    super.key,
    required this.blueprint,
    required this.onBack,
    this.subscriptionService,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Top Toolbar
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            OutlinedButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Back to Studio'),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // 1. Copy Prompt for Cursor / Claude
                OutlinedButton.icon(
                  onPressed: () {
                    final prompt = const FileExportService().generateCursorPrompt(blueprint);
                    Clipboard.setData(ClipboardData(text: prompt));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: AppColors.primary,
                        content: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.white, size: 16),
                            SizedBox(width: 8),
                            Text('📋 15-Section Agent Prompt copied to clipboard! (Ready for Cursor/Claude)'),
                          ],
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copy Prompt for AI'),
                ),

                // 2. Export JSON Spec
                OutlinedButton.icon(
                  onPressed: () {
                    const FileExportService().downloadBlueprintJson(blueprint);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: AppColors.primary,
                        content: Text('📥 Structured Blueprint JSON downloaded!'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.data_object, size: 16),
                  label: const Text('Export JSON'),
                ),

                // 3. One-Click PROMPT.md Download (Primary CTA)
                FilledButton.icon(
                  onPressed: () {
                    const FileExportService().downloadPromptMarkdown(blueprint);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.primary,
                        duration: const Duration(seconds: 4),
                        content: Row(
                          children: [
                            const Icon(Icons.download_done, color: Colors.white, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '📥 Downloaded ${blueprint.appName}_PROMPT.md! Ready for Cursor, Claude Code, or Antigravity.',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('Download PROMPT.md'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Header Banner
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'ENGINEERING & PRODUCT BLUEPRINT',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                blueprint.appName,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5),
              ),
              const SizedBox(height: 6),
              Text(
                blueprint.valueProposition,
                style: const TextStyle(fontSize: 14, color: Color(0xFFDBEAFE), height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Section 1: Overview & Problem & Target Users
        _buildSectionCard('1. Product Overview', blueprint.productOverview),
        _buildSectionCard('2. Problem Statement', blueprint.problem),
        _buildSectionCard('3. Target Users & ICP', blueprint.targetUsers),
        _buildSectionCard('4. Value Proposition', blueprint.valueProposition),

        // Section 5: Core MVP Features
        _buildListSectionCard('5. Core MVP Features', blueprint.coreMvpFeatures, Icons.check_circle, AppColors.success),

        // Section 6: User Flow
        _buildListSectionCard('6. 5-Step User Journey Flow', blueprint.userFlow, Icons.play_arrow, AppColors.primary),

        // Section 7: Screen Architecture
        _buildListSectionCard('7. Key Screen Architecture', blueprint.screens, Icons.smartphone, AppColors.primary),

        // Section 8: Database Design
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '8. Database Schema (PostgreSQL / Supabase)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  Text('SQL DDL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  blueprint.databaseDesign.trim(),
                  style: const TextStyle(
                    fontFamily: 'Consolas',
                    fontSize: 13,
                    color: Color(0xFF38BDF8),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Section 9: API Requirements
        _buildListSectionCard('9. API Endpoint Requirements', blueprint.apiRequirements, Icons.api, AppColors.primary),

        // Section 10 & 11: AI & Flutter Architecture
        _buildSectionCard('10. AI Architecture & Inference Strategy', blueprint.aiArchitecture),
        _buildSectionCard('11. Flutter Client Architecture', blueprint.flutterArchitecture),

        // Section 12: Monetization
        _buildSectionCard('12. Monetization Strategy & Pricing', blueprint.monetization),

        // Section 13: Competitive Differentiation
        _buildListSectionCard('13. Competitive Moats & Differentiation', blueprint.competitiveDifferentiation, Icons.shield_outlined, AppColors.primary),

        // Section 14: MVP Roadmap
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '14. MVP Development Roadmap',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 14),
              for (final phase in blueprint.roadmap) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(phase.phase, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceSecondary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(phase.duration, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      for (final m in phase.milestones)
                        Padding(
                          padding: const EdgeInsets.only(left: 12, bottom: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.circle, size: 6, color: AppColors.textMuted),
                              const SizedBox(width: 8),
                              Expanded(child: Text(m, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const Divider(height: 1),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 10),
          Text(content, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildListSectionCard(String title, List<String> items, IconData icon, Color iconColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 14),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 16, color: iconColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(item, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
