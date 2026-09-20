import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_radar/services/subscription/subscription_service.dart';
import 'package:app_radar/widgets/pricing/pricing_modal.dart';
import 'package:app_radar/main.dart';

void main() {
  group('SubscriptionService Unit Tests', () {
    test('Default state is Free tier with 3 daily teardowns', () {
      final sub = SubscriptionService();
      expect(sub.isFree, true);
      expect(sub.isPro, false);
      expect(sub.remainingFreeTeardowns, 3);
      expect(sub.canGenerateBlueprint(), false);
    });

    test('Tracks viewed apps and enforces daily teardown limit of 3', () {
      final sub = SubscriptionService();

      expect(sub.canViewTeardown('app_1'), true);
      sub.recordTeardownView('app_1');
      expect(sub.remainingFreeTeardowns, 2);

      sub.recordTeardownView('app_2');
      expect(sub.remainingFreeTeardowns, 1);

      sub.recordTeardownView('app_3');
      expect(sub.remainingFreeTeardowns, 0);

      // Already viewed apps are still viewable
      expect(sub.canViewTeardown('app_1'), true);
      expect(sub.canViewTeardown('app_2'), true);

      // A 4th app is locked on Free tier
      expect(sub.canViewTeardown('app_4'), false);
    });

    test('Upgrading to Pro unlocks unlimited teardowns and blueprints', () {
      final sub = SubscriptionService();
      sub.upgradeToPro();

      expect(sub.isPro, true);
      expect(sub.isFree, false);
      expect(sub.canGenerateBlueprint(), true);
      expect(sub.canViewTeardown('app_99'), true);

      sub.downgradeToFree();
      expect(sub.isFree, true);
    });
  });

  group('PricingModal Widget Tests', () {
    testWidgets('Renders all tiers, billing switcher, and upgrades to Pro', (WidgetTester tester) async {
      final sub = SubscriptionService();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PricingModal(subscriptionService: sub),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check tier headings
      expect(find.text('Starter Free'), findsOneWidget);
      expect(find.text('Pro Builder'), findsOneWidget);
      expect(find.text('Agency & Team'), findsOneWidget);
      expect(find.text('SAVE 20%'), findsOneWidget);

      // Toggle billing
      await tester.tap(find.text('Monthly Billing'));
      await tester.pumpAndSettle();
      expect(find.text('\$29'), findsOneWidget);

      await tester.tap(find.text('Annual Billing'));
      await tester.pumpAndSettle();
      expect(find.text('\$23'), findsOneWidget);

      // Tap Upgrade
      final upgradeBtn = find.text('Upgrade to Pro Builder');
      expect(upgradeBtn, findsOneWidget);
      await tester.tap(upgradeBtn);
      await tester.pump(const Duration(milliseconds: 700));

      expect(sub.isPro, true);
    });
  });

  group('AppShell Feature Gating Integration Test', () {
    testWidgets('Header displays Upgrade Pro button for Free tier and opens modal', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const AppRadarApp());
      await tester.pumpAndSettle();

      // Find the Upgrade Pro button in header
      final upgradeProBtn = find.text('Upgrade Pro');
      expect(upgradeProBtn, findsOneWidget);

      // Click to open PricingModal
      await tester.tap(upgradeProBtn);
      await tester.pumpAndSettle();

      expect(find.byType(PricingModal), findsOneWidget);
      expect(find.text('Unlock Full Market Intelligence & AI Blueprints'), findsOneWidget);
    });
  });
}
