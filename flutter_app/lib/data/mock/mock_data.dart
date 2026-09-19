import '../models/app_item.dart';
import '../models/competitor.dart';
import '../models/market_trend.dart';
import '../models/report_item.dart';
import '../models/build_blueprint.dart';

class MockData {
  static final List<AppItem> apps = [
    const AppItem(
      id: 'app_1',
      name: 'AI Note Taker',
      developer: 'VocalTech Labs',
      category: 'Productivity',
      platform: 'iOS App Store',
      iconEmoji: '🎙️',
      description:
          'AI-powered meeting transcription, speaker separation, smart summaries, and automatic action item assignment.',
      rating: 4.7,
      reviewCount: 8200,
      ranking: 4,
      downloadsEstimate: 145000,
      revenueEstimate: 320000.0,
      growthRate: 180.0,
      opportunityScore: 82,
      signals: AppSignals(
        growthSignal: 90,
        revenueSignal: 72,
        rankingSignal: 92,
        reviewSignal: 80,
        marketSignal: 82,
      ),
      monetization: 'Freemium + \$14.99/mo Pro Subscription',
      whatItDoes:
          'Captures audio from online and in-person meetings, provides real-time transcription with timestamps, and generates structured executive briefs.',
      targetUser:
          'Busy project managers, consultants, startup founders, and students who attend frequent Zoom/Meet calls.',
      whyGrowing:
          'High demand for post-meeting documentation automation without needing a bot to visibly join the call.',
      coreValueProp:
          'Saves 4+ hours per week per user by replacing manual note-taking with automated CRM-ready action items.',
      coreFeatures: [
        'Real-time dual-channel audio recording',
        'Multi-speaker recognition and voice tagging',
        'Executive bullet-point summary generation',
        'Automatic action item extraction with assignee detection',
        '1-click export to Notion, Google Docs, and Slack',
      ],
      aiFeatures: [
        'Whisper-large v3 transcription fine-tuned for accents',
        'LLM context extraction for domain-specific terminology',
        'Sentiment and decision timeline analysis',
      ],
      userPainPoints: [
        'Overpriced subscription tier for individual freelancers',
        'Strict 30-minute free monthly limit leads to poor user retention',
        'Occasional failure to capture cross-talk in noisy rooms',
        'Lacks native Apple Watch and Android quick-record widgets',
      ],
      competitorGaps: [
        'Existing giants (Otter, Fireflies) force a bot into calls, which some companies ban for privacy',
        'No direct offline voice memo transcription',
        'Poor support for multilingual or code-switching meetings',
      ],
      suggestedMvp: [
        'Local-first voice recording with no bot required',
        'Zero-cloud privacy mode with on-device small Whisper model',
        'One-tap sync to Markdown/Obsidian/Apple Notes',
        'Affordable indie pricing (\$4.99/mo or lifetime tier)',
      ],
      screenshots: [
        'Meeting Summary Screen with Action Items',
        'Live Audio Waveform & Speaker Transcript',
        'Export Modal with Notion and Slack toggles',
        'Searchable Archive with Category Tags',
      ],
      isWatchlisted: true,
      notes: 'Huge potential for a privacy-first indie alternative.',
    ),
    const AppItem(
      id: 'app_2',
      name: 'Calorie AI',
      developer: 'NutriSmart Systems',
      category: 'Health & Fitness',
      platform: 'Google Play',
      iconEmoji: '🥗',
      description:
          'Take a photo of any plate of food and receive instant macronutrient breakdown and personalized health coaching.',
      rating: 4.6,
      reviewCount: 12000,
      ranking: 2,
      downloadsEstimate: 310000,
      revenueEstimate: 540000.0,
      growthRate: 120.0,
      opportunityScore: 78,
      signals: AppSignals(
        growthSignal: 85,
        revenueSignal: 78,
        rankingSignal: 88,
        reviewSignal: 74,
        marketSignal: 76,
      ),
      monetization: 'Subscription: \$9.99/mo or \$59.99/year',
      whatItDoes:
          'Utilizes multimodal computer vision to estimate portion sizes, ingredients, and calories from a single smartphone camera snapshot.',
      targetUser:
          'Fitness enthusiasts, gym goers, weight-loss trackers, and people managing diabetic dietary restrictions.',
      whyGrowing:
          'Eliminates the tedious friction of manually searching barcodes or entering food gram weights into MyFitnessPal.',
      coreValueProp:
          'Log full meals in under 3 seconds with visual confirmation and intelligent ingredient guesses.',
      coreFeatures: [
        'Instant photo plate scanner',
        'Macronutrient breakdown (Protein, Carbs, Fats, Fiber)',
        'Daily calorie budget progress ring',
        'Meal history and weekly nutrition trend charts',
        'Water tracking with smart notifications',
      ],
      aiFeatures: [
        'Vision AI portion estimation model',
        'Recipe decomposition for complex homemade stews and sauces',
        'Nutritional advice chatbot trained on clinical dietetics',
      ],
      userPainPoints: [
        'Struggles with non-Western ethnic cuisines and mixed curries',
        'Aggressive paywall blocks basic food logging after 3 free scans',
        'No direct sync with Apple Health or Garmin Connect without paid tier',
      ],
      competitorGaps: [
        'Niche food cultures (South Asian, Middle Eastern, Latin American) are poorly recognized',
        'Lack of grocery barcode fallbacks when food cannot be photographed',
      ],
      suggestedMvp: [
        'Vision snap + manual tweak slider',
        'Cultural food pack presets',
        'Free 10 snaps/day with rewarded ads or \$29/year flat subscription',
      ],
      screenshots: [
        'Camera View with Augmented Reality Food Tags',
        'Macro Breakdown Card with Protein Goal Ring',
        'Weekly Calorie Intake Trend Chart',
      ],
      isWatchlisted: true,
      notes: 'Strong revenue signal; opportunity in specialized ethnic diets.',
    ),
    const AppItem(
      id: 'app_3',
      name: 'PDF AI Assistant',
      developer: 'DocuPulse Software',
      category: 'Productivity',
      platform: 'Cross-platform',
      iconEmoji: '📄',
      description:
          'Chat with complex PDF documents, extract tables into spreadsheets, and generate cited research summaries.',
      rating: 4.5,
      reviewCount: 6200,
      ranking: 8,
      downloadsEstimate: 95000,
      revenueEstimate: 180000.0,
      growthRate: 95.0,
      opportunityScore: 75,
      signals: AppSignals(
        growthSignal: 80,
        revenueSignal: 70,
        rankingSignal: 76,
        reviewSignal: 75,
        marketSignal: 74,
      ),
      monetization: 'Freemium + \$12/mo Pro tier',
      whatItDoes:
          'Performs vector search and RAG over multi-hundred page research papers, legal contracts, and financial reports.',
      targetUser:
          'Law students, academic researchers, paralegals, equity analysts, and corporate employees.',
      whyGrowing:
          'Explosive rise of LLMs makes reading 80-page whitepapers manual and obsolete.',
      coreValueProp:
          'Ask questions in plain English and receive answers with highlighted page citations and exact paragraphs.',
      coreFeatures: [
        'Multi-document chat in a single thread',
        'Interactive citation links pointing to page highlights',
        'Table to CSV/Excel extraction',
        'Batch document Q&A comparison',
        'Offline encrypted storage',
      ],
      aiFeatures: [
        'Hybrid semantic + keyword vector retrieval (RAG)',
        'OCR for scanned image PDFs',
        'Multi-hop reasoning across sections',
      ],
      userPainPoints: [
        'File size limit capped at 25MB on standard tier',
        'Hallucinations when asking for exact financial percentages from tables',
        'Slow upload times on mobile connections',
      ],
      competitorGaps: [
        'Few apps offer native mobile tablet stylus annotation integration',
        'Lack of verifiable mathematical calculation verification',
      ],
      suggestedMvp: [
        'Lightweight mobile PDF viewer with floating chat drawer',
        'Dedicated contract risk audit checklist tool',
        'Pay-per-doc credit system for infrequent users',
      ],
      screenshots: [
        'Split Screen: PDF Document on Left, AI Chat on Right',
        'Highlighted Page Citation Popup',
        'Extracted Financial Table in CSV Viewer',
      ],
      isWatchlisted: false,
      notes: 'Stable B2B utility with strong willingness to pay.',
    ),
    const AppItem(
      id: 'app_4',
      name: 'Language Buddy',
      developer: 'Polyglot AI Inc',
      category: 'Education',
      platform: 'iOS App Store',
      iconEmoji: '🗣️',
      description:
          'Real-time voice conversation practice with empathetic AI language tutors in 24 languages with instant feedback.',
      rating: 4.8,
      reviewCount: 9000,
      ranking: 5,
      downloadsEstimate: 210000,
      revenueEstimate: 390000.0,
      growthRate: 90.0,
      opportunityScore: 73,
      signals: AppSignals(
        growthSignal: 78,
        revenueSignal: 74,
        rankingSignal: 80,
        reviewSignal: 84,
        marketSignal: 70,
      ),
      monetization: 'Subscription: \$12.99/mo',
      whatItDoes:
          'Offers realistic roleplay scenarios (e.g. ordering coffee in Paris, interviewing for a job in Tokyo) with audio feedback.',
      targetUser:
          'Intermediate language learners who know vocabulary but experience social anxiety speaking with native speakers.',
      whyGrowing:
          'Solves conversational anxiety at 1/10th the cost of human tutors on iTalki.',
      coreValueProp:
          'Unlimited judgment-free conversational practice with grammar corrections and natural pronunciation advice.',
      coreFeatures: [
        'Voice-to-voice bidirectional low latency dialog',
        'Situational roleplays with 50+ real-world environments',
        'Real-time grammar correction subtitles',
        'Personalized SRS flashcard deck generated from mistakes',
      ],
      aiFeatures: [
        'Ultra-low latency speech synthesizer (<300ms)',
        'Phoneme-level pronunciation acoustic modeling',
        'Adaptive vocabulary difficulty tuning',
      ],
      userPainPoints: [
        'Robotic voice inflection in languages other than Spanish/French',
        'Repetitive conversational patterns after 10+ sessions',
        'No offline mode for airplane practice',
      ],
      competitorGaps: [
        'Duolingo Max is expensive (\$30/mo) and heavily gamified rather than freeform',
        'Apps lack customized industry vocabulary (e.g. medical Spanish, engineering German)',
      ],
      suggestedMvp: [
        'Focus specifically on business professionals moving abroad',
        'Micro-sessions (5-minute daily conversation sprints)',
        'Direct connection to WhatsApp voice notes',
      ],
      screenshots: [
        'Voice Conversation Interface with Audio Waves',
        'Mistake Teardown & Suggested Better Phrasing',
        'Spoken Fluency Radar Chart',
      ],
      isWatchlisted: true,
      notes: 'High retention and viral social media sharing signals.',
    ),
    const AppItem(
      id: 'app_5',
      name: 'Budget AI',
      developer: 'FinPulse Labs',
      category: 'Finance',
      platform: 'iOS App Store',
      iconEmoji: '💳',
      description:
          'Personal finance copilot that tracks expenses via receipt snaps and bank sync, forecasting monthly cash flow.',
      rating: 4.4,
      reviewCount: 5100,
      ranking: 11,
      downloadsEstimate: 115000,
      revenueEstimate: 210000.0,
      growthRate: 70.0,
      opportunityScore: 71,
      signals: AppSignals(
        growthSignal: 72,
        revenueSignal: 75,
        rankingSignal: 68,
        reviewSignal: 69,
        marketSignal: 73,
      ),
      monetization: 'Freemium + \$7.99/mo Premium',
      whatItDoes:
          'Monitors subscriptions, detects recurring price increases, and predicts bank balance at the end of the month.',
      targetUser:
          'Young professionals, gig economy freelancers, and families trying to cut unnecessary recurring expenses.',
      whyGrowing:
          'Inflation and subscription fatigue create intense urgency to audit monthly spending.',
      coreValueProp:
          'Catches forgotten subscriptions and provides actionable savings recommendations before overdraft happens.',
      coreFeatures: [
        'Automated bank sync via Plaid and Open Banking',
        'Receipt photo scanning and auto-categorization',
        'Subscription audit radar with 1-click cancel guides',
        '30-day forward cash flow prediction model',
      ],
      aiFeatures: [
        'Transaction semantic classification',
        'Unusual spending anomaly detection',
        'Natural language financial advisor chatbot',
      ],
      userPainPoints: [
        'Users distrust third-party bank credential aggregators',
        'Frequent sync disconnections with credit unions',
        'Overly complex budgeting formulas intimidate casual users',
      ],
      competitorGaps: [
        'No simple privacy-first manual entry option without bank linking',
        'Zero support for multi-currency digital nomad accounts',
      ],
      suggestedMvp: [
        'Local encrypted budget tracker with receipt camera scanner',
        'No bank login required — 100% private and offline-first',
        'CSV bank export import with automated AI parsing',
      ],
      screenshots: [
        'Monthly Cash Flow Projection Line Chart',
        'Subscription Leak Radar with Price Hikes',
        'Receipt OCR Scanner Confirmation Dialog',
      ],
      isWatchlisted: false,
      notes: 'Privacy angle is a massive selling point.',
    ),
  ];

  static final List<CategoryTrend> categoryTrends = [
    const CategoryTrend(
      category: 'AI & Machine Learning',
      growthRate: 120.0,
      totalApps: 48,
      avgOpportunityScore: 81.5,
      topApp: 'AI Note Taker',
      weeklySparkline: [20, 35, 45, 60, 78, 95, 120],
    ),
    const CategoryTrend(
      category: 'Productivity',
      growthRate: 85.0,
      totalApps: 32,
      avgOpportunityScore: 76.2,
      topApp: 'PDF AI Assistant',
      weeklySparkline: [30, 42, 50, 58, 65, 75, 85],
    ),
    const CategoryTrend(
      category: 'Health & Fitness',
      growthRate: 70.0,
      totalApps: 24,
      avgOpportunityScore: 74.0,
      topApp: 'Calorie AI',
      weeklySparkline: [25, 30, 38, 48, 55, 62, 70],
    ),
    const CategoryTrend(
      category: 'Education',
      growthRate: 65.0,
      totalApps: 16,
      avgOpportunityScore: 71.8,
      topApp: 'Language Buddy',
      weeklySparkline: [15, 22, 30, 40, 50, 58, 65],
    ),
    const CategoryTrend(
      category: 'Finance',
      growthRate: 50.0,
      totalApps: 12,
      avgOpportunityScore: 69.4,
      topApp: 'Budget AI',
      weeklySparkline: [10, 18, 25, 32, 38, 44, 50],
    ),
  ];

  static final List<EmergingKeyword> emergingKeywords = [
    const EmergingKeyword(
      keyword: 'Voice Memo Summarizer',
      category: 'Productivity',
      searchVolumeGrowth: 240.0,
      competitionLevel: 'Low',
    ),
    const EmergingKeyword(
      keyword: 'Photo Calorie Tracker',
      category: 'Health & Fitness',
      searchVolumeGrowth: 185.0,
      competitionLevel: 'Medium',
    ),
    const EmergingKeyword(
      keyword: 'Offline PDF Q&A',
      category: 'Productivity',
      searchVolumeGrowth: 160.0,
      competitionLevel: 'Low',
    ),
    const EmergingKeyword(
      keyword: 'Conversational Fluency AI',
      category: 'Education',
      searchVolumeGrowth: 145.0,
      competitionLevel: 'Medium',
    ),
    const EmergingKeyword(
      keyword: 'Private Subscription Audit',
      category: 'Finance',
      searchVolumeGrowth: 110.0,
      competitionLevel: 'Low',
    ),
  ];

  static final List<ReportItem> reports = [
    ReportItem(
      id: 'rep_1',
      title: 'Daily App Opportunity Intelligence — Sep 19, 2026',
      type: 'Daily',
      date: DateTime(2026, 9, 19),
      appsAnalyzed: 128,
      opportunitiesFound: 24,
      topOpportunityName: 'AI Note Taker',
      topOpportunityScore: 82,
      marketSummary:
          'Surge in privacy-first productivity utilities. Strong user backlash against in-call transcription bots presents immediate indie opportunity.',
      status: 'Published',
    ),
    ReportItem(
      id: 'rep_2',
      title: 'Weekly Market Velocity Digest — Week 38, 2026',
      type: 'Weekly',
      date: DateTime(2026, 9, 15),
      appsAnalyzed: 640,
      opportunitiesFound: 86,
      topOpportunityName: 'Calorie AI',
      topOpportunityScore: 78,
      marketSummary:
          'Multimodal computer vision apps in health and lifestyle categories saw average revenue growth of +42% week-over-week.',
      status: 'Published',
    ),
    ReportItem(
      id: 'rep_3',
      title: 'Monthly AI Ecosystem Teardown — August 2026',
      type: 'Monthly',
      date: DateTime(2026, 9, 1),
      appsAnalyzed: 2450,
      opportunitiesFound: 310,
      topOpportunityName: 'PDF AI Assistant',
      topOpportunityScore: 75,
      marketSummary:
          'B2B document extraction and localized niche assistants capture highest customer lifetime value with annual prepay plans.',
      status: 'Published',
    ),
  ];

  static final List<CompetitorApp> competitorsForNoteTaker = [
    const CompetitorApp(
      name: 'AI Note Taker (Focus App)',
      category: 'Productivity',
      rating: 4.7,
      reviews: 8200,
      pricing: '\$14.99/mo',
      marketPosition: 'High growth challenger with strong mobile UX',
      featureMatrix: {
        'AI Summary': true,
        'Action Item Extraction': true,
        'Speaker Diarization': true,
        'Bot-Free Audio Recording': true,
        'Offline Transcription': false,
        'Notion & Slack Export': true,
        'Custom Vocabulary': true,
      },
    ),
    const CompetitorApp(
      name: 'Otter.ai',
      category: 'Productivity',
      rating: 4.4,
      reviews: 42000,
      pricing: '\$16.99/mo',
      marketPosition: 'Enterprise market leader, requires meeting bot',
      featureMatrix: {
        'AI Summary': true,
        'Action Item Extraction': true,
        'Speaker Diarization': true,
        'Bot-Free Audio Recording': false,
        'Offline Transcription': false,
        'Notion & Slack Export': true,
        'Custom Vocabulary': false,
      },
    ),
    const CompetitorApp(
      name: 'Fireflies.ai',
      category: 'Productivity',
      rating: 4.3,
      reviews: 18500,
      pricing: '\$18.00/mo',
      marketPosition: 'Sales team CRM automation specialist',
      featureMatrix: {
        'AI Summary': true,
        'Action Item Extraction': true,
        'Speaker Diarization': true,
        'Bot-Free Audio Recording': false,
        'Offline Transcription': false,
        'Notion & Slack Export': true,
        'Custom Vocabulary': true,
      },
    ),
    const CompetitorApp(
      name: 'Pebble Voice (Indie)',
      category: 'Utilities',
      rating: 4.6,
      reviews: 2100,
      pricing: '\$4.99/mo',
      marketPosition: 'Minimalist memo recorder with basic summaries',
      featureMatrix: {
        'AI Summary': true,
        'Action Item Extraction': false,
        'Speaker Diarization': false,
        'Bot-Free Audio Recording': true,
        'Offline Transcription': true,
        'Notion & Slack Export': false,
        'Custom Vocabulary': false,
      },
    ),
  ];

  static BuildBlueprint createBlueprintForApp(AppItem app) {
    return BuildBlueprint(
      appName: '${app.name} Pro',
      productOverview:
          'A modern, lightweight, privacy-first mobile & desktop client solving ${app.name}\'s primary user pain points: ${app.userPainPoints.first}.',
      problem:
          'Users need the core power of ${app.name} without paying bloated enterprise fees or compromising meeting privacy. Current tools charge \$15-20/mo and suffer from: ${app.userPainPoints.join(', ')}.',
      targetUsers:
          'Solo founders, consultants, freelancers, developers, and remote workers who want instant, reliable results with no bot invasion.',
      valueProposition:
          'All the speed of ${app.name} at 1/3 the cost, with 100% offline-ready local processing and seamless 1-tap exports to Notion and Markdown.',
      coreMvpFeatures: [
        'Zero-latency local audio / input capture',
        'Instant AI executive summary generation',
        'Key action items extraction with checkbox status',
        'Local encrypted cache with biometric lock',
        'Markdown and clipboard instant sharing',
      ],
      userFlow: [
        '1. Launch App -> Tap single large "Record / Capture" button',
        '2. Live waveform & real-time keywords display on screen',
        '3. Tap "Finish" -> AI processes summary in under 4 seconds',
        '4. View Executive Brief, Action Items, and Transcript',
        '5. 1-Tap Export to Notion, Obsidian, or copy as Markdown',
      ],
      screens: [
        'Home / Active Sessions Screen',
        'Live Capture Screen with audio visualization',
        'AI Teardown & Summary Detail View',
        'Archive / Tagged Workspace Library',
        'Settings & AI Model Selection',
      ],
      databaseDesign: '''
CREATE TABLE items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id),
  title TEXT NOT NULL,
  summary TEXT,
  action_items JSONB DEFAULT '[]'::jsonb,
  raw_transcript TEXT,
  duration_seconds INT,
  is_favorite BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_items_user_created ON items(user_id, created_at DESC);
''',
      apiRequirements: [
        'POST /api/ai/transcribe — Streaming Whisper transcription',
        'POST /api/ai/summarize — Structured JSON executive brief generation',
        'POST /api/export/notion — OAuth Notion database page creation',
      ],
      aiArchitecture:
          'Hybrid Edge-Cloud Architecture: On-device lightweight models for voice activity detection and local indexing. Cloud edge workers running Gemini Flash / Whisper for heavy inference when network is available.',
      flutterArchitecture:
          'Clean Architecture with Feature-First modules (presentation, domain, data). State management via InheritedWidget/Riverpod. Local persistence using SQLite/Isar with Supabase sync.',
      monetization:
          'Freemium with 10 free summaries/month. \$4.99/month Pro subscription or \$49 Lifetime indie deal for early adopters.',
      competitiveDifferentiation: [
        'No visible bot needed to join Zoom/Meet calls',
        '100% client-side encryption option',
        'Direct Obsidian and local Markdown vault support',
        '10x faster startup time than Electron-based competitors',
      ],
      roadmap: [
        const RoadmapPhase(
          phase: 'Phase 1: Research & UX Specs',
          duration: 'Week 1-2',
          milestones: [
            'Validate user pain points with 20 user interviews',
            'Finalize Stitch UI design system and Figma tokens',
            'Test on-device audio capture latency on iOS/Android',
          ],
        ),
        const RoadmapPhase(
          phase: 'Phase 2: MVP Development',
          duration: 'Week 3-5',
          milestones: [
            'Implement Flutter UI and responsive layout',
            'Wire local audio recording and AI summary edge endpoint',
            'Implement local database storage and Markdown export',
          ],
        ),
        const RoadmapPhase(
          phase: 'Phase 3: Beta & User Testing',
          duration: 'Week 6-7',
          milestones: [
            'TestFlight & Google Play Internal Beta with 100 testers',
            'Refine AI summary prompt for accuracy and conciseness',
            'Fix audio edge cases (background noise, interruptions)',
          ],
        ),
        const RoadmapPhase(
          phase: 'Phase 4: Public Launch',
          duration: 'Week 8',
          milestones: [
            'Launch on Product Hunt and Twitter/X with video demo',
            'Publish landing page with live interactive demo',
            'Enable Stripe / In-App Purchase subscriptions',
          ],
        ),
        const RoadmapPhase(
          phase: 'Phase 5: Growth & Scale',
          duration: 'Week 9+',
          milestones: [
            'Introduce team workspaces and shared libraries',
            'Integrate CRM workflows (HubSpot, Salesforce, Notion)',
            'Localized multilingual transcription support',
          ],
        ),
      ],
    );
  }
}
