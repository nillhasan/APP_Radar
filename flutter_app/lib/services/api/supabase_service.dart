/// Architecture placeholder and documentation for Supabase integration.
///
/// In Phase 2:
/// 1. Initialize Supabase client in `main.dart`:
///    ```dart
///    await Supabase.initialize(
///      url: const String.fromEnvironment('SUPABASE_URL'),
///      anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
///    );
///    ```
/// 2. Use table schemas defined in `supabase/schema.sql`:
///    - `apps`
///    - `app_metrics`
///    - `app_analysis`
///    - `reports`
/// 3. Inject `SupabaseAppRepository` implementing `AppRepository`.
class SupabaseConfig {
  static const bool isConfigured = false;
  static const String databaseSchemaVersion = '1.0.0';

  static Map<String, String> get requiredTables => {
        'apps': 'Core app registry, developer, store metrics and metadata',
        'app_metrics': 'Time-series ranking, downloads, revenue, review delta',
        'app_analysis': 'AI computed opportunity scores and teardown briefs',
        'reports': 'Daily, weekly, and monthly intelligence digests',
      };
}
