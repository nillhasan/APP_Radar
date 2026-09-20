import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/config/stripe_config.dart';
import '../auth/auth_service.dart';

enum UserTier {
  free,
  pro,
  agency,
}

class SubscriptionService extends ChangeNotifier {
  final SupabaseClient? _supabaseClient;
  final AuthService? _authService;

  UserTier _tier = UserTier.free;
  String? _stripeCustomerId;
  String? _stripeSubscriptionId;
  DateTime? _currentPeriodEnd;

  final Set<String> _viewedAppIdsToday = {};
  static const int dailyTeardownsLimit = 3;

  SubscriptionService({
    SupabaseClient? supabaseClient,
    AuthService? authService,
  })  : _supabaseClient = supabaseClient,
        _authService = authService {
    _initSupabaseSync();
  }

  UserTier get currentTier => _tier;
  bool get isPro => _tier == UserTier.pro || _tier == UserTier.agency;
  bool get isFree => _tier == UserTier.free;
  bool get isAgency => _tier == UserTier.agency;

  String? get stripeCustomerId => _stripeCustomerId;
  String? get stripeSubscriptionId => _stripeSubscriptionId;
  DateTime? get currentPeriodEnd => _currentPeriodEnd;

  int get viewedCountToday => _viewedAppIdsToday.length;

  int get remainingFreeTeardowns {
    if (isPro) return 999;
    final remaining = dailyTeardownsLimit - _viewedAppIdsToday.length;
    return remaining > 0 ? remaining : 0;
  }

  void _initSupabaseSync() {
    if (_authService != null) {
      _authService.addListener(() {
        if (_authService.isAuthenticated) {
          fetchSubscriptionFromCloud();
        } else {
          _tier = UserTier.free;
          _stripeCustomerId = null;
          _stripeSubscriptionId = null;
          notifyListeners();
        }
      });

      if (_authService.isAuthenticated) {
        fetchSubscriptionFromCloud();
      }
    }
  }

  /// Queries the `user_subscriptions` table in Supabase for the authenticated user
  Future<void> fetchSubscriptionFromCloud() async {
    final client = _supabaseClient;
    final user = _authService?.currentUser;
    if (client == null || user == null) return;

    try {
      final response = await client
          .from('user_subscriptions')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (response != null) {
        final tierStr = response['tier'] as String? ?? 'free';
        final statusStr = response['status'] as String? ?? 'active';
        _stripeCustomerId = response['stripe_customer_id'] as String?;
        _stripeSubscriptionId = response['stripe_subscription_id'] as String?;

        if (response['current_period_end'] != null) {
          _currentPeriodEnd = DateTime.tryParse(response['current_period_end']);
        }

        if (statusStr == 'active') {
          if (tierStr == 'pro') {
            _tier = UserTier.pro;
          } else if (tierStr == 'agency') {
            _tier = UserTier.agency;
          } else {
            _tier = UserTier.free;
          }
        } else {
          _tier = UserTier.free;
        }
        notifyListeners();
      } else {
        // Create initial free record if not yet created
        await client.from('user_subscriptions').insert({
          'user_id': user.id,
          'tier': 'free',
          'status': 'active',
        }).catchError((_) {});
      }
    } catch (e) {
      debugPrint('Error syncing subscription with Supabase: $e');
    }
  }

  bool canViewTeardown(String appId) {
    if (isPro) return true;
    if (_viewedAppIdsToday.contains(appId)) return true;
    return _viewedAppIdsToday.length < dailyTeardownsLimit;
  }

  void recordTeardownView(String appId) {
    if (!_viewedAppIdsToday.contains(appId)) {
      _viewedAppIdsToday.add(appId);
      notifyListeners();
    }
  }

  bool canGenerateBlueprint() {
    return isPro;
  }

  /// Launches Stripe Checkout in a browser tab.
  /// Returns `true` if checkout URL was launched or simulated.
  /// Returns `false` if authentication is required first.
  Future<bool> launchStripeCheckout({
    required bool isAnnual,
    String? customBaseUrl,
  }) async {
    final user = _authService?.currentUser;
    if (user == null) {
      return false; // Authentication required first
    }

    final checkoutUrl = StripeConfig.buildCheckoutUrl(
      isAnnual: isAnnual,
      userId: user.id,
      userEmail: user.email,
      customBaseUrl: customBaseUrl,
    );

    if (checkoutUrl.isNotEmpty) {
      final uri = Uri.parse(checkoutUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      }
    }

    return false;
  }

  /// Launches Stripe Customer Portal for managing subscription, changing credit cards, or invoices.
  Future<bool> launchCustomerPortal() async {
    final portalUrl = StripeConfig.customerPortalLink;
    if (portalUrl.isNotEmpty) {
      final uri = Uri.parse(portalUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      }
    }
    return false;
  }

  Future<void> handlePaymentSuccess({String? sessionId}) async {
    _tier = UserTier.pro;
    notifyListeners();

    final client = _supabaseClient;
    final user = _authService?.currentUser;
    if (client != null && user != null) {
      try {
        await client.from('user_subscriptions').upsert({
          'user_id': user.id,
          'tier': 'pro',
          'status': 'active',
          'stripe_subscription_id': sessionId,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }, onConflict: 'user_id');
      } catch (e) {
        debugPrint('Note: unable to save subscription row to Supabase: $e');
      }
    }
  }

  void upgradeToPro() {
    _tier = UserTier.pro;
    notifyListeners();
  }

  void downgradeToFree() {
    _tier = UserTier.free;
    notifyListeners();
  }

  void toggleTier() {
    _tier = isPro ? UserTier.free : UserTier.pro;
    notifyListeners();
  }

  void resetDailyLimits() {
    _viewedAppIdsToday.clear();
    notifyListeners();
  }
}
