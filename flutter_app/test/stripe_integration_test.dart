import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_radar/core/config/stripe_config.dart';
import 'package:app_radar/services/subscription/subscription_service.dart';
import 'package:app_radar/widgets/pricing/pricing_modal.dart';

void main() {
  group('StripeConfig Unit Tests', () {
    test('buildCheckoutUrl appends client_reference_id and prefilled_email correctly', () {
      final url = StripeConfig.buildCheckoutUrl(
        isAnnual: true,
        userId: 'user-uuid-12345',
        userEmail: 'builder@example.com',
      );

      expect(url, contains('client_reference_id=user-uuid-12345'));
      expect(url, contains('prefilled_email=builder%40example.com'));
      expect(url, startsWith(StripeConfig.proAnnualLink));
    });

    test('buildCheckoutUrl supports monthly billing link and custom baseUrl', () {
      final monthlyUrl = StripeConfig.buildCheckoutUrl(
        isAnnual: false,
        userId: 'test-user-99',
      );
      expect(monthlyUrl, startsWith(StripeConfig.proMonthlyLink));
      expect(monthlyUrl, contains('client_reference_id=test-user-99'));

      final customUrl = StripeConfig.buildCheckoutUrl(
        isAnnual: false,
        customBaseUrl: 'https://buy.stripe.com/custom_link',
        userId: 'abc',
        userEmail: 'team@agency.com',
      );
      expect(customUrl, startsWith('https://buy.stripe.com/custom_link'));
      expect(customUrl, contains('client_reference_id=abc'));
      expect(customUrl, contains('prefilled_email=team%40agency.com'));
    });

    test('isConfigured detects placeholder vs live links', () {
      // With default placeholder, isConfigured should be false
      expect(StripeConfig.isConfigured, isFalse);
    });
  });

  group('SubscriptionService Stripe Integration Tests', () {
    test('launchStripeCheckout returns false when user is unauthenticated', () async {
      final service = SubscriptionService(); // null authService
      final launched = await service.launchStripeCheckout(isAnnual: true);
      expect(launched, isFalse);
    });

    test('Customer portal URL is configured in StripeConfig', () {
      expect(StripeConfig.customerPortalLink, isNotEmpty);
    });
  });

  group('PricingModal Stripe UI Tests', () {
    testWidgets('Toggling billing switches Stripe price display and updates button label', (tester) async {
      final subscriptionService = SubscriptionService();
      bool authModalTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PricingModal(
              subscriptionService: subscriptionService,
              onRequiresAuth: () {
                authModalTriggered = true;
              },
            ),
          ),
        ),
      );

      // Default is Annual billing ($23/mo, SAVE 20%)
      expect(find.text('Annual Billing'), findsOneWidget);
      expect(find.text('SAVE 20%'), findsOneWidget);
      expect(find.text('\$23'), findsOneWidget);
      expect(find.text('Upgrade to Pro Builder'), findsOneWidget);

      // Switch to Monthly billing
      await tester.tap(find.text('Monthly Billing'));
      await tester.pumpAndSettle();

      expect(find.text('\$29'), findsOneWidget);
      expect(find.text('Upgrade to Pro Builder'), findsOneWidget);

      // Tap Upgrade with Stripe when unauthenticated -> should trigger onRequiresAuth
      await tester.tap(find.text('Upgrade to Pro Builder'));
      await tester.pumpAndSettle();

      expect(authModalTriggered, isTrue);
    });

    testWidgets('Demo mode button provides instant local Pro activation', (tester) async {
      final subscriptionService = SubscriptionService();
      expect(subscriptionService.isFree, isTrue);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PricingModal(
              subscriptionService: subscriptionService,
            ),
          ),
        ),
      );

      // Tap Dev Mode Instant Pro button
      final devModeButton = find.text('Simulate instant Pro (Demo Mode)');
      expect(devModeButton, findsOneWidget);

      await tester.tap(devModeButton);
      await tester.pumpAndSettle();

      expect(subscriptionService.isPro, isTrue);
      expect(subscriptionService.canGenerateBlueprint(), isTrue);
    });

    testWidgets('Displays Manage Subscription (Stripe Portal) when user is already Pro', (tester) async {
      final subscriptionService = SubscriptionService();
      subscriptionService.upgradeToPro();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PricingModal(
              subscriptionService: subscriptionService,
            ),
          ),
        ),
      );

      expect(find.text('Manage Subscription (Stripe Portal)'), findsOneWidget);
    });
  });
}
