import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/app_item.dart';
import '../../data/models/build_blueprint.dart';
import '../../data/repositories/app_repository.dart';
import '../../services/ai/ai_service.dart';
import '../../services/subscription/subscription_service.dart';
import '../../widgets/pricing/pricing_modal.dart';
import '../../widgets/section_header.dart';
import '../../widgets/score_badge.dart';
import '../../widgets/app_icon_widget.dart';

class BuildWithAIView extends StatefulWidget {
  final AppRepository appRepo;
  final AIService aiService;
  final ValueChanged<BuildBlueprint> onBlueprintGenerated;
  final SubscriptionService? subscriptionService;

  const BuildWithAIView({
    super.key,
    required this.appRepo,
    required this.aiService,
    required this.onBlueprintGenerated,
    this.subscriptionService,
  });

  @override
  State<BuildWithAIView> createState() => _BuildWithAIViewState();
}

class _BuildWithAIViewState extends State<BuildWithAIView> {
  AppItem? _selectedApp;
  String _selectedCategory = 'All Categories';
  bool _isGenerating = false;
  String _generationStep = '';

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return FutureBuilder<List<AppItem>>(
      future: widget.appRepo.getAllApps(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final allApps = snapshot.data!;
        final filteredApps = allApps.where((a) {
          if (_selectedCategory == 'All Categories' || _selectedCategory == 'All') return true;
          return a.category.toLowerCase().contains(_selectedCategory.toLowerCase()) ||
                 _selectedCategory.toLowerCase().contains(a.category.toLowerCase());
        }).toList();

        final displayApps = filteredApps.isNotEmpty ? filteredApps : allApps;
        if (_selectedApp == null || !displayApps.any((a) => a.id == _selectedApp!.id)) {
          _selectedApp = displayApps.first;
        }

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SectionHeader(
              title: 'Build With AI Studio',
              subtitle: 'Transform verified market demand and user pain points into a complete, buildable MVP blueprint.',
            ),
            // Selection Card
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '1. Select Opportunity to Target',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${displayApps.length} Opportunities',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (isDesktop)
                    Row(
                      children: [
                        // Category Dropdown
                        Container(
                          width: 220,
                          height: 46,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSecondary,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedCategory,
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.textSecondary),
                              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                              items: AppConstants.categories.map((c) {
                                return DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis));
                              }).toList(),
                              onChanged: _isGenerating
                                  ? null
                                  : (cat) {
                                      if (cat != null) {
                                        setState(() {
                                          _selectedCategory = cat;
                                        });
                                      }
                                    },
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Opportunity App Dropdown
                        Expanded(
                          child: Container(
                            height: 46,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceSecondary,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<AppItem>(
                                value: _selectedApp,
                                isExpanded: true,
                                items: displayApps.map((a) {
                                  return DropdownMenuItem(
                                    value: a,
                                    child: Row(
                                      children: [
                                        AppIconWidget(
                                          iconUrl: a.iconUrl,
                                          iconEmoji: a.iconEmoji,
                                          size: 22,
                                          borderRadius: 5,
                                          fontSize: 14,
                                        ),
                                        const SizedBox(width: 10),
                                        Flexible(
                                          child: Text(
                                            a.name,
                                            style: const TextStyle(fontWeight: FontWeight.w700),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text('(${a.category} • Score: ${a.opportunityScore})', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: _isGenerating
                                    ? null
                                    : (app) {
                                        if (app != null) setState(() => _selectedApp = app);
                                      },
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  else ...[
                    // Category Dropdown (Mobile)
                    Container(
                      width: double.infinity,
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSecondary,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCategory,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.textSecondary),
                          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                          items: AppConstants.categories.map((c) {
                            return DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis));
                          }).toList(),
                          onChanged: _isGenerating
                              ? null
                              : (cat) {
                                  if (cat != null) {
                                    setState(() {
                                      _selectedCategory = cat;
                                    });
                                  }
                                },
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Opportunity App Dropdown (Mobile)
                    Container(
                      width: double.infinity,
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSecondary,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<AppItem>(
                          value: _selectedApp,
                          isExpanded: true,
                          items: displayApps.map((a) {
                            return DropdownMenuItem(
                              value: a,
                              child: Row(
                                children: [
                                  AppIconWidget(
                                    iconUrl: a.iconUrl,
                                    iconEmoji: a.iconEmoji,
                                    size: 20,
                                    borderRadius: 4,
                                    fontSize: 13,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      a.name,
                                      style: const TextStyle(fontWeight: FontWeight.w700),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text('(${a.opportunityScore})', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: _isGenerating
                              ? null
                              : (app) {
                                  if (app != null) setState(() => _selectedApp = app);
                                },
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (_selectedApp != null) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primaryBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Market Opportunity Signal: ${_selectedApp!.name}',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              ScoreBadge(score: _selectedApp!.opportunityScore, fontSize: 11),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _selectedApp!.description,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Primary User Pain Point: "${_selectedApp!.userPainPoints.first}"',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  if (_isGenerating)
                    Container(
                      padding: const EdgeInsets.all(20),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            _generationStep,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary),
                          ),
                        ],
                      ),
                    )
                  else
                    FilledButton.icon(
                      onPressed: () => _generateBlueprint(_selectedApp!),
                      icon: Icon(
                        (widget.subscriptionService?.isFree ?? false) ? Icons.lock_outline : Icons.auto_awesome,
                        size: 18,
                      ),
                      label: Text(
                        (widget.subscriptionService?.isFree ?? false)
                            ? 'Generate Blueprint (Unlock with Pro)'
                            : 'Generate Complete 14-Section Build Blueprint',
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: (widget.subscriptionService?.isFree ?? false) ? AppColors.aiPurple : AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Blueprint Checklist overview
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Blueprint Output Specifications',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  SizedBox(height: 14),
                  Text(
                    'AppRadar’s AI Product Architect generates a production-ready engineering specification:',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  SizedBox(height: 16),
                  Wrap(
                    spacing: 16,
                    runSpacing: 10,
                    children: [
                      _ChecklistItem('1. Product Overview & Thesis'),
                      _ChecklistItem('2. Problem Statement & Root Cause'),
                      _ChecklistItem('3. ICP & Target Personas'),
                      _ChecklistItem('4. Value Proposition & Positioning'),
                      _ChecklistItem('5. Core MVP Feature Scope'),
                      _ChecklistItem('6. 5-Step User Journey Flow'),
                      _ChecklistItem('7. Screen Architecture & Wireframes'),
                      _ChecklistItem('8. PostgreSQL / Supabase Schema'),
                      _ChecklistItem('9. REST & Streaming API Endpoints'),
                      _ChecklistItem('10. Edge-Cloud AI Architecture'),
                      _ChecklistItem('11. Flutter Clean Architecture'),
                      _ChecklistItem('12. Monetization & Pricing Tier'),
                      _ChecklistItem('13. Competitive Moats & Differentiation'),
                      _ChecklistItem('14. 5-Phase Development Roadmap'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _generateBlueprint(AppItem app) async {
    if (widget.subscriptionService != null && !widget.subscriptionService!.canGenerateBlueprint()) {
      PricingModal.show(
        context,
        subscriptionService: widget.subscriptionService!,
        featureTrigger:
            '14-Section AI Architecture Blueprints are an exclusive Pro Builder feature. Upgrade now to generate full product specifications, PostgreSQL database schemas, API endpoints, and engineering roadmaps.',
      );
      return;
    }

    setState(() {
      _isGenerating = true;
      _generationStep = 'Analyzing market telemetry and user pain points...';
    });

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _generationStep = 'Architecting database schema and API contracts...');

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _generationStep = 'Composing 14-section Build Blueprint...');

    final blueprint = await widget.aiService.generateBlueprint(app);

    if (mounted) {
      setState(() => _isGenerating = false);
      widget.onBlueprintGenerated(blueprint);
    }
  }
}

class _ChecklistItem extends StatelessWidget {
  final String text;
  const _ChecklistItem(this.text);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, size: 16, color: AppColors.success),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
