import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../data/models/app_item.dart';
import '../../data/models/build_blueprint.dart';
import '../../data/mock/mock_data.dart';
import 'ai_service.dart';

class GeminiAIService implements AIService {
  final String? apiKey;
  final AIService fallbackService;

  GeminiAIService({
    this.apiKey,
    AIService? fallback,
  }) : fallbackService = fallback ?? MockAIService();

  static const String _envKey = String.fromEnvironment('GEMINI_API_KEY');
  String get _activeKey => (apiKey != null && apiKey!.isNotEmpty) ? apiKey! : _envKey;

  @override
  Future<BuildBlueprint> generateBlueprint(AppItem app) async {
    final key = _activeKey;
    if (key.isEmpty) {
      return await fallbackService.generateBlueprint(app);
    }

    final prompt = '''
You are AppRadar's Principal AI Software Architect.
Generate an execution-ready MVP software build specification and PRD for a new competitor entering the market to compete with ${app.name} (${app.category}).

TARGET APP DATA:
Name: ${app.name}
Category: ${app.category}
Rating: ${app.rating} (${app.reviewCount} reviews)
Current Monetization: ${app.monetization}
User Pain Points: ${app.userPainPoints.join('; ')}
Competitor Gaps: ${app.competitorGaps.join('; ')}

Return ONLY valid JSON matching this exact structure with NO markdown backticks:
{
  "appName": "Competitive App Name",
  "productOverview": "Executive summary of product vision",
  "problem": "Core user pain points being addressed",
  "targetUsers": "Primary user personas and target market",
  "valueProposition": "Unfair advantage and why users will switch",
  "coreMvpFeatures": ["Feature 1", "Feature 2", "Feature 3", "Feature 4", "Feature 5"],
  "userFlow": ["1. Step one", "2. Step two", "3. Step three", "4. Step four"],
  "screens": ["Screen 1", "Screen 2", "Screen 3", "Screen 4"],
  "databaseDesign": "CREATE TABLE items (\\n  id UUID PRIMARY KEY,\\n  title TEXT\\n);",
  "apiRequirements": ["POST /api/items", "GET /api/metrics"],
  "aiArchitecture": "AI model pipelines and prompting setup",
  "flutterArchitecture": "State management and presentation pattern",
  "monetization": "Pricing tiers and billing strategy",
  "competitiveDifferentiation": ["Moat 1", "Moat 2", "Moat 3"],
  "roadmap": [
    {
      "phase": "Phase 1: MVP Core",
      "duration": "Weeks 1-2",
      "milestones": ["Milestone 1", "Milestone 2"]
    },
    {
      "phase": "Phase 2: Beta Launch",
      "duration": "Weeks 3-4",
      "milestones": ["Milestone 3", "Milestone 4"]
    }
  ]
}''';

    for (final model in ['gemini-2.0-flash', 'gemini-1.5-flash']) {
      try {
        final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$key');
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'parts': [{'text': prompt}]
              }
            ],
            'generationConfig': {
              'temperature': 0.3,
              'responseMimeType': 'application/json'
            }
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final rawText = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
          if (rawText != null) {
            final parsed = jsonDecode(rawText) as Map<String, dynamic>;
            return _parseBlueprintJson(parsed, app);
          }
        }
      } catch (e) {
        debugPrint('Gemini attempt ($model) error: $e');
      }
    }

    return await fallbackService.generateBlueprint(app);
  }

  @override
  Future<String> analyzeMarketGap(String category) async {
    final key = _activeKey;
    if (key.isEmpty) {
      return await fallbackService.analyzeMarketGap(category);
    }

    try {
      final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$key');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': 'In 2 sentences, explain the highest-opportunity market gap for new apps entering the $category space.'}
              ]
            }
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
        if (text != null && text.toString().trim().isNotEmpty) {
          return text.toString().trim();
        }
      }
    } catch (_) {}

    return await fallbackService.analyzeMarketGap(category);
  }

  BuildBlueprint _parseBlueprintJson(Map<String, dynamic> json, AppItem app) {
    final rawRoadmap = json['roadmap'] as List<dynamic>? ?? [];
    final roadmap = rawRoadmap.map((r) {
      final rMap = r as Map<String, dynamic>;
      final rawMilestones = rMap['milestones'] as List<dynamic>? ?? [];
      return RoadmapPhase(
        phase: rMap['phase']?.toString() ?? 'Phase 1: MVP',
        duration: rMap['duration']?.toString() ?? '2 Weeks',
        milestones: rawMilestones.map((m) => m.toString()).toList(),
      );
    }).toList();

    return BuildBlueprint(
      appName: json['appName']?.toString() ?? '${app.name} Pro',
      productOverview: json['productOverview']?.toString() ?? app.whatItDoes,
      problem: json['problem']?.toString() ?? app.userPainPoints.join(', '),
      targetUsers: json['targetUsers']?.toString() ?? app.targetUser,
      valueProposition: json['valueProposition']?.toString() ?? app.coreValueProp,
      coreMvpFeatures: _parseList(json['coreMvpFeatures']),
      userFlow: _parseList(json['userFlow']),
      screens: _parseList(json['screens']),
      databaseDesign: json['databaseDesign']?.toString() ?? 'CREATE TABLE items (id UUID PRIMARY KEY);',
      apiRequirements: _parseList(json['apiRequirements']),
      aiArchitecture: json['aiArchitecture']?.toString() ?? 'Edge AI & Cloud LLM pipeline',
      flutterArchitecture: json['flutterArchitecture']?.toString() ?? 'Clean Architecture with Feature-First structure',
      monetization: json['monetization']?.toString() ?? app.monetization,
      competitiveDifferentiation: _parseList(json['competitiveDifferentiation']),
      roadmap: roadmap.isNotEmpty ? roadmap : MockData.createBlueprintForApp(app).roadmap,
    );
  }

  List<String> _parseList(dynamic list) {
    if (list is List) {
      return list.map((e) => e.toString()).toList();
    }
    return ['Core MVP feature', 'Offline storage', '1-tap export'];
  }
}
