import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_radar/services/export/file_export_service.dart';
import 'package:app_radar/data/models/build_blueprint.dart';
import 'package:app_radar/data/models/negative_review_mining.dart';
import 'package:app_radar/data/mock/mock_data.dart';
import 'package:app_radar/features/app_detail/widgets/negative_review_mining_card.dart';
import 'package:app_radar/features/build_with_ai/build_blueprint_view.dart';
import 'package:app_radar/services/subscription/subscription_service.dart';

void main() {
  const testBlueprint = BuildBlueprint(
    appName: 'SuperAI Notes',
    productOverview: 'AI-first real-time markdown editor with vector graph.',
    problem: 'Existing note apps lack automated semantic linking.',
    targetUsers: 'Knowledge workers, students, researchers',
    valueProposition: 'Saves 5 hours a week linking ideas.',
    coreMvpFeatures: [
      'Smart Synapses',
      'Real-time markdown editing',
      'Instant cloud sync',
    ],
    userFlow: [
      'User opens note',
      'AI extracts entities',
      'Graph links created',
    ],
    screens: [
      'Dashboard & Workspace',
      'Editor Canvas',
      'Graph Visualization Screen',
    ],
    databaseDesign: 'CREATE TABLE notes (id UUID PRIMARY KEY, title TEXT, body TEXT);',
    apiRequirements: [
      'POST /api/v1/extract-entities',
      'POST /api/v1/vector-search',
    ],
    aiArchitecture: 'Gemini 1.5 Pro via Google AI Dart SDK with streaming tokens.',
    flutterArchitecture: 'Clean Architecture with Repository Pattern and Provider.',
    monetization: r'$12/month Pro tier, $99/year lifetime access.',
    competitiveDifferentiation: [
      '10x faster local-first sync',
      'Native pgvector search',
    ],
    roadmap: [
      RoadmapPhase(
        phase: 'Research & Architecture',
        duration: 'Week 1',
        milestones: ['Schema design', 'Prototyping'],
      ),
      RoadmapPhase(
        phase: 'MVP Core Build',
        duration: 'Weeks 2-3',
        milestones: ['Editor', 'Sync engine'],
      ),
    ],
  );

  group('FileExportService Unit Tests', () {
    const exportService = FileExportService();

    test('generateCursorPrompt produces complete 15-section markdown specification', () {
      final prompt = exportService.generateCursorPrompt(testBlueprint);

      expect(prompt, contains('# 🚀 System Specification & Agent Prompt: SuperAI Notes'));
      expect(prompt, contains('## 🎯 1. Mission & Overview'));
      expect(prompt, contains('## 🛑 2. Problem Statement'));
      expect(prompt, contains('## 👥 3. Target User & Persona'));
      expect(prompt, contains('## 💡 4. Core Value Proposition'));
      expect(prompt, contains('## ⚡ 5. Core MVP Features (Phase 1 Scope)'));
      expect(prompt, contains('## 🔄 6. User Journey & Navigation Flow'));
      expect(prompt, contains('## 📱 7. UI Screen Hierarchy'));
      expect(prompt, contains('## 🗄️ 8. Database Architecture (PostgreSQL / Supabase DDL)'));
      expect(prompt, contains('## 🔌 9. API Requirements & Backend Contracts'));
      expect(prompt, contains('## 🧠 10. AI Architecture & Prompt Pipelines'));
      expect(prompt, contains('## 🏗️ 11. Flutter Mobile & Web Architecture'));
      expect(prompt, contains('## 💳 12. Monetization & Stripe Setup'));
      expect(prompt, contains('## 🛡️ 13. Competitive Moats & Differentiation'));
      expect(prompt, contains('## 🗓️ 14. Phased Engineering Roadmap'));
      expect(prompt, contains('## 🤖 15. Execution Directives for Coding Agent'));
      expect(prompt, contains('CREATE TABLE notes'));
      expect(prompt, contains('POST /api/v1/extract-entities'));
    });

    test('generateBlueprintJson produces valid JSON with all fields', () {
      final jsonString = exportService.generateBlueprintJson(testBlueprint);
      final decoded = json.decode(jsonString) as Map<String, dynamic>;

      expect(decoded['appName'], 'SuperAI Notes');
      expect(decoded['productOverview'], contains('AI-first real-time'));
      expect(decoded['coreMvpFeatures'], contains('Smart Synapses'));
      expect(decoded['roadmap'], isNotEmpty);
      expect(decoded['metadata']['engine'], 'AppRadar SaaS v1.0');
    });

    test('generateTeardownCsv produces valid CSV with headers and app data', () {
      final app = MockData.apps.first;
      final csv = exportService.generateTeardownCsv(app);

      expect(csv, contains('App ID,App Name,Category,Platform,Rating,Review Count'));
      expect(csv, contains(app.id));
      expect(csv, contains(app.name));
      expect(csv, contains(app.category));
    });

    test('generateTeardownMarkdown produces structured teardown report', () {
      final app = MockData.apps.first;
      final md = exportService.generateTeardownMarkdown(app);

      expect(md, contains('# Teardown Report: ${app.name}'));
      expect(md, contains('## What It Does'));
      expect(md, contains('## 1★ & 2★ Negative Review Intelligence & User Dissatisfaction'));
      expect(md, contains('The Golden Opportunity (How to Win Their Users):'));
    });
  });

  group('NegativeReviewMiningCard Widget Tests', () {
    testWidgets('Renders dissatisfaction rate, golden opportunity, categories, and review filtering', (tester) async {
      const miningData = NegativeReviewMining(
        totalAnalyzed: 100,
        dissatisfactionRate: 28,
        goldenOpportunitySummary: 'Build a transparent paywall and offline sync to win dissatisfied users.',
        categoryDistribution: {
          'Hidden Pricing': 40,
          'Sync Bugs': 35,
          'Bad UX': 25,
        },
        sampleReviews: [
          StoreReview(
            author: 'AngryUser',
            rating: 1,
            date: '2026-09-18',
            category: 'Hidden Pricing',
            comment: 'Forced subscription without warning!',
            builderOpportunity: 'Provide upfront pricing with transparent trials.',
          ),
          StoreReview(
            author: 'FrustratedDev',
            rating: 2,
            date: '2026-09-15',
            category: 'Sync Bugs',
            comment: 'Lost notes when offline.',
            builderOpportunity: 'Use local-first SQLite sync with conflict resolution.',
          ),
        ],
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: NegativeReviewMiningCard(
                mining: miningData,
                appName: 'SuperAI Notes',
              ),
            ),
          ),
        ),
      );

      // Verify title & dissatisfaction badge
      expect(find.text('1★ & 2★ Review & Pain Point Mining'), findsOneWidget);
      expect(find.text('28% Dissatisfaction (100 Analyzed)'), findsOneWidget);

      // Verify Golden Opportunity
      expect(find.text('THE GOLDEN OPPORTUNITY — HOW TO WIN THEIR USERS'), findsOneWidget);
      expect(find.text(miningData.goldenOpportunitySummary), findsOneWidget);

      // Verify reviews are shown
      expect(find.text('AngryUser'), findsOneWidget);
      expect(find.text('FrustratedDev'), findsOneWidget);
      expect(find.textContaining('Forced subscription without warning!'), findsOneWidget);
      expect(find.textContaining('Lost notes when offline.'), findsOneWidget);

      // Filter by 'Hidden Pricing' category
      final hiddenPricingChip = find.widgetWithText(ChoiceChip, 'Hidden Pricing');
      expect(hiddenPricingChip, findsOneWidget);
      await tester.tap(hiddenPricingChip);
      await tester.pumpAndSettle();

      // 'AngryUser' should still be visible, 'FrustratedDev' should be filtered out
      expect(find.text('AngryUser'), findsOneWidget);
      expect(find.text('FrustratedDev'), findsNothing);
    });
  });

  group('BuildBlueprintView Toolbar Export Tests', () {
    testWidgets('Renders download and export buttons on top toolbar', (tester) async {
      final sub = SubscriptionService();
      sub.upgradeToPro();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BuildBlueprintView(
              blueprint: testBlueprint,
              subscriptionService: sub,
              onBack: () {},
            ),
          ),
        ),
      );

      // Verify export buttons exist
      expect(find.text('Download PROMPT.md'), findsOneWidget);
      expect(find.text('Copy Prompt for AI'), findsOneWidget);
      expect(find.text('Export JSON'), findsOneWidget);
    });
  });
}
