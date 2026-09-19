import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/app_repository.dart';
import 'data/repositories/supabase_app_repository.dart';
import 'data/repositories/opportunity_repository.dart';
import 'data/repositories/market_trend_repository.dart';
import 'data/repositories/report_repository.dart';
import 'data/repositories/watchlist_repository.dart';
import 'services/ai/ai_service.dart';
import 'widgets/app_shell.dart';

const String supabaseUrl = 'https://eqemignoxkftfwdoxcjs.supabase.co';
const String supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVxZW1pZ25veGtmdGZ3ZG94Y2pzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODk4MzExNzMsImV4cCI6MjEwNTQwNzE3M30.HBiotZ18zShR-c1hTprqhP9HXzC4RCUDHuWUz15Zfpc';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  } catch (e) {
    debugPrint('Supabase init note: $e');
  }

  runApp(const AppRadarApp());
}

class AppRadarApp extends StatefulWidget {
  const AppRadarApp({super.key});

  @override
  State<AppRadarApp> createState() => _AppRadarAppState();
}

class _AppRadarAppState extends State<AppRadarApp> {
  late final AppRepository _appRepo;
  late final OpportunityRepository _oppRepo;
  late final MarketTrendRepository _trendRepo;
  late final ReportRepository _reportRepo;
  late final WatchlistRepository _watchlistRepo;
  late final AIService _aiService;

  @override
  void initState() {
    super.initState();
    final mockRepo = MockAppRepository();

    try {
      final supabaseClient = Supabase.instance.client;
      _appRepo = SupabaseAppRepository(
        client: supabaseClient,
        fallbackRepo: mockRepo,
      );
    } catch (_) {
      _appRepo = mockRepo;
    }

    _oppRepo = MockOpportunityRepository(appRepository: _appRepo);
    _trendRepo = MockMarketTrendRepository();
    _reportRepo = MockReportRepository();
    _watchlistRepo = MockWatchlistRepository(appRepository: _appRepo);
    _aiService = MockAIService();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AppRadar — AI-Powered Mobile App Market Intelligence',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: AppShell(
        appRepo: _appRepo,
        oppRepo: _oppRepo,
        trendRepo: _trendRepo,
        reportRepo: _reportRepo,
        watchlistRepo: _watchlistRepo,
        aiService: _aiService,
      ),
    );
  }
}
