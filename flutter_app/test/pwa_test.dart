import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_radar/services/pwa/pwa_service.dart';
import 'package:app_radar/widgets/pwa/pwa_install_modal.dart';

void main() {
  group('PWA Service & Integration Tests', () {
    test('PwaService provides safe cross-platform defaults', () async {
      expect(PwaService.isWeb, isFalse); // Running in Flutter VM test environment
      expect(PwaService.isPwaInstalled(), isFalse);

      final result = await PwaService.promptInstall();
      expect(result, isFalse);
    });

    testWidgets('PwaInstallModal renders PWA benefits and instructions', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PwaInstallModal(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Header and Badges
      expect(find.text('Install AppRadar PWA'), findsOneWidget);
      expect(find.text('STANDALONE'), findsOneWidget);

      // Verify Benefits
      expect(find.text('Native Desktop Window'), findsOneWidget);
      expect(find.text('Instant Offline Caching'), findsOneWidget);
      expect(find.text('1-Tap Launch'), findsOneWidget);

      // Verify Install Button
      final installButton = find.text('Install AppRadar to Device');
      expect(installButton, findsOneWidget);

      // Verify Manual Instructions
      expect(find.textContaining('Chrome & Edge'), findsOneWidget);
      expect(find.textContaining('Safari (iPhone & iPad)'), findsOneWidget);

      // Tap install button
      await tester.tap(installButton);
      await tester.pumpAndSettle();
    });
  });
}
