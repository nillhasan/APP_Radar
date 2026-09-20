/// Configuration class for Stripe Payment Links, Customer Portal, and Checkout Helpers.
///
/// You can paste your Stripe Dashboard Payment Links directly into the constants below,
/// or pass them via compile-time environment variables (`--dart-define=STRIPE_PRO_MONTHLY_LINK=...`).
class StripeConfig {
  StripeConfig._();

  // ---------------------------------------------------------------------------
  // ⚡ PASTE YOUR STRIPE PAYMENT LINKS HERE (From Stripe Dashboard -> Product catalog)
  // ---------------------------------------------------------------------------
  
  /// Pro Builder Monthly subscription link ($29/mo)
  static const String defaultProMonthlyLink = 'https://buy.stripe.com/test_00w28rcLA0Gy2rbgCP4ko00';

  /// Pro Builder Annual subscription link ($279/year)
  static const String defaultProAnnualLink = 'https://buy.stripe.com/test_6oUeVdfXM9d48Pz2LZ4ko01';

  /// Agency & Team Monthly subscription link ($79/mo)
  static const String defaultAgencyLink = '';

  /// Stripe Customer Billing Portal link (Stripe Dashboard -> Settings -> Customer portal)
  static const String defaultCustomerPortalLink = 'https://billing.stripe.com/p/login/test_placeholder';

  // ---------------------------------------------------------------------------
  // Environment variable overrides (Optional for CI/CD)
  // ---------------------------------------------------------------------------
  static const String _envProMonthly = String.fromEnvironment('STRIPE_PRO_MONTHLY_LINK');
  static const String _envProAnnual = String.fromEnvironment('STRIPE_PRO_ANNUAL_LINK');
  static const String _envAgency = String.fromEnvironment('STRIPE_AGENCY_LINK');
  static const String _envPortal = String.fromEnvironment('STRIPE_PORTAL_LINK');

  /// Active Pro Monthly Payment Link
  static String get proMonthlyLink => _envProMonthly.isNotEmpty ? _envProMonthly : defaultProMonthlyLink;

  /// Active Pro Annual Payment Link
  static String get proAnnualLink => _envProAnnual.isNotEmpty ? _envProAnnual : defaultProAnnualLink;

  /// Active Agency Payment Link
  static String get agencyLink => _envAgency.isNotEmpty ? _envAgency : defaultAgencyLink;

  /// Active Customer Portal Link
  static String get customerPortalLink => _envPortal.isNotEmpty ? _envPortal : defaultCustomerPortalLink;

  /// Returns true if valid custom Stripe payment links have been configured
  /// (i.e. not empty and does not contain "placeholder").
  static bool get isConfigured {
    final link = proMonthlyLink;
    return link.isNotEmpty && !link.contains('placeholder');
  }

  /// Builds a fully-parameterized Stripe Checkout URL with:
  /// - `client_reference_id`: Supabase Auth User ID (so webhook can credit the right account)
  /// - `prefilled_email`: User's authenticated email (so checkout pre-populates email)
  static String buildCheckoutUrl({
    required bool isAnnual,
    String? userId,
    String? userEmail,
    String? customBaseUrl,
  }) {
    final baseUrl = customBaseUrl ?? (isAnnual ? proAnnualLink : proMonthlyLink);
    if (baseUrl.isEmpty) return '';

    final uri = Uri.parse(baseUrl);
    final queryParameters = Map<String, String>.from(uri.queryParameters);

    if (userId != null && userId.isNotEmpty) {
      queryParameters['client_reference_id'] = userId;
    }
    if (userEmail != null && userEmail.isNotEmpty) {
      queryParameters['prefilled_email'] = userEmail;
    }

    return uri.replace(queryParameters: queryParameters).toString();
  }
}
