import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/config/stripe_config.dart';
import '../auth/auth_service.dart';
import 'subscription_storage.dart';

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

  final Set<String> _urlTeardownAppIds = {};
  static const int freeUrlTeardownLimit = 1;

  /// Privileged admin / owner emails that permanently maintain Pro status
  static const Set<String> _adminProEmails = {
    'metanestshop@gmail.com',
  };

  bool get _isAdminProUser {
    final email = _authService?.userEmail.trim().toLowerCase();
    if (email == null || email.isEmpty) return false;
    return _adminProEmails.contains(email);
  }

  SubscriptionService({
    SupabaseClient? supabaseClient,
    AuthService? authService,
  })  : _supabaseClient = supabaseClient,
        _authService = authService {
    final savedTier = SubscriptionStorage.getStoredTier();
    if (savedTier == 'pro' || _isAdminProUser) {
      _tier = UserTier.pro;
    } else if (savedTier == 'agency') {
      _tier = UserTier.agency;
    }
    final savedUrlTeardowns = SubscriptionStorage.getStoredUrlTeardowns();
    _urlTeardownAppIds.addAll(savedUrlTeardowns);
    _initSupabaseSync();
  }

  UserTier get currentTier {
    if (_tier == UserTier.agency) return UserTier.agency;
    if (_isAdminProUser) return UserTier.pro;
    return _tier;
  }

  bool get isPro => currentTier == UserTier.pro || currentTier == UserTier.agency;
  bool get isFree => currentTier == UserTier.free;
  bool get isAgency => currentTier == UserTier.agency;

  String? get stripeCustomerId => _stripeCustomerId;
  String? get stripeSubscriptionId => _stripeSubscriptionId;
  DateTime? get currentPeriodEnd => _currentPeriodEnd;

  int get viewedCountToday => _viewedAppIdsToday.length;

  int get remainingFreeTeardowns {
    if (isPro) return 999;
    final remaining = dailyTeardownsLimit - _viewedAppIdsToday.length;
    return remaining > 0 ? remaining : 0;
  }

  int get urlTeardownCount => _urlTeardownAppIds.length;

  int get remainingFreeUrlTeardowns {
    if (isPro) return 999;
    final remaining = freeUrlTeardownLimit - _urlTeardownAppIds.length;
    return remaining > 0 ? remaining : 0;
  }

  void _initSupabaseSync() {
    if (_authService != null) {
      _authService.addListener(() {
        if (_authService.isAuthenticated) {
          if (_isAdminProUser) {
            _tier = UserTier.pro;
            SubscriptionStorage.setStoredTier('pro');
            notifyListeners();
          }
          fetchSubscriptionFromCloud();
        } else {
          _tier = UserTier.free;
          _stripeCustomerId = null;
          _stripeSubscriptionId = null;
          SubscriptionStorage.setStoredTier(null);
          notifyListeners();
        }
      });

      if (_authService.isAuthenticated) {
        if (_isAdminProUser) {
          _tier = UserTier.pro;
          SubscriptionStorage.setStoredTier('pro');
        }
        fetchSubscriptionFromCloud();
      }
    }
  }

  /// Queries the `user_subscriptions` table in Supabase for the authenticated user
  Future<void> fetchSubscriptionFromCloud() async {
    final client = _supabaseClient;
    final user = _authService?.currentUser;
    final isAdmin = _isAdminProUser;

    if (isAdmin) {
      _tier = UserTier.pro;
      SubscriptionStorage.setStoredTier('pro');
      notifyListeners();
    }

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

        if (isAdmin) {
          _tier = UserTier.pro;
          SubscriptionStorage.setStoredTier('pro');
        } else if (statusStr == 'active') {
          if (tierStr == 'pro') {
            _tier = UserTier.pro;
            SubscriptionStorage.setStoredTier('pro');
          } else if (tierStr == 'agency') {
            _tier = UserTier.agency;
            SubscriptionStorage.setStoredTier('agency');
          } else {
            _tier = UserTier.free;
            SubscriptionStorage.setStoredTier('free');
          }
        } else {
          _tier = UserTier.free;
          SubscriptionStorage.setStoredTier('free');
        }
        notifyListeners();
      } else {
        // Create initial free record compliant with RLS policy
        await client.from('user_subscriptions').insert({
          'user_id': user.id,
          'tier': 'free',
          'status': 'active',
        }).catchError((err) {
          debugPrint('Note: default subscription init: $err');
        });

        if (isAdmin) {
          _tier = UserTier.pro;
          SubscriptionStorage.setStoredTier('pro');
        } else {
          _tier = UserTier.free;
          SubscriptionStorage.setStoredTier('free');
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error syncing subscription with Supabase: $e');
      if (isAdmin) {
        _tier = UserTier.pro;
        SubscriptionStorage.setStoredTier('pro');
        notifyListeners();
      }
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

  bool canPerformUrlTeardown(String identifier) {
    if (isPro) return true;
    final key = identifier.trim().toLowerCase();
    if (_urlTeardownAppIds.contains(key)) return true;
    return _urlTeardownAppIds.length < freeUrlTeardownLimit;
  }

  void recordUrlTeardown(String identifier) {
    final key = identifier.trim().toLowerCase();
    if (!_urlTeardownAppIds.contains(key)) {
      _urlTeardownAppIds.add(key);
      SubscriptionStorage.setStoredUrlTeardowns(_urlTeardownAppIds);
      notifyListeners();
    }
  }

  void resetUrlTeardowns() {
    _urlTeardownAppIds.clear();
    SubscriptionStorage.setStoredUrlTeardowns({});
    notifyListeners();
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
    SubscriptionStorage.setStoredTier('pro');
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

  @visibleForTesting
  void upgradeToPro() {
    _tier = UserTier.pro;
    SubscriptionStorage.setStoredTier('pro');
    notifyListeners();
  }

  @visibleForTesting
  void downgradeToFree() {
    _tier = UserTier.free;
    SubscriptionStorage.setStoredTier(null);
    notifyListeners();
  }

  void resetDailyLimits() {
    _viewedAppIdsToday.clear();
    _urlTeardownAppIds.clear();
    SubscriptionStorage.setStoredUrlTeardowns({});
    notifyListeners();
  }
}
