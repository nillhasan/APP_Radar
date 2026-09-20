import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_radar/services/auth/auth_service.dart';
import 'package:app_radar/data/repositories/app_repository.dart';
import 'package:app_radar/data/repositories/supabase_watchlist_repository.dart';
import 'package:app_radar/widgets/auth/auth_modal.dart';
import 'package:app_radar/main.dart';

void main() {
  group('AuthService Unit Tests', () {
    test('Defaults to unauthenticated when client is null', () {
      final auth = AuthService();
      expect(auth.isAuthenticated, false);
      expect(auth.currentUser, isNull);
      expect(auth.userDisplayName, 'Guest User');
      expect(auth.userInitials, 'GU');
    });
  });

  group('SupabaseWatchlistRepository Tests', () {
    test('Falls back gracefully to local MockWatchlistRepository when unauthenticated', () async {
      final appRepo = MockAppRepository();
      final auth = AuthService();
      final watchlistRepo = SupabaseWatchlistRepository(
        appRepository: appRepo,
        authService: auth,
      );

      final initialWatchlist = await watchlistRepo.getWatchlistedApps();
      expect(initialWatchlist.length, greaterThanOrEqualTo(2));

      final apps = await appRepo.getAllApps();
      final appToToggle = apps.first;

      await watchlistRepo.removeFromWatchlist(appToToggle.id);
      final afterRemove = await watchlistRepo.getWatchlistedApps();
      expect(afterRemove.any((a) => a.id == appToToggle.id), false);

      await watchlistRepo.addToWatchlist(appToToggle.id);
      final afterAdd = await watchlistRepo.getWatchlistedApps();
      expect(afterAdd.any((a) => a.id == appToToggle.id), true);
    });
  });

  group('AuthModal & AppShell UI Tests', () {
    testWidgets('Shows Sign In button in header when unauthenticated and opens AuthModal', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const AppRadarApp());
      await tester.pumpAndSettle();

      // Verify header "Sign In" button is visible
      final signInButton = find.text('Sign In');
      expect(signInButton, findsOneWidget);

      // Tap "Sign In" to open AuthModal
      await tester.tap(signInButton);
      await tester.pumpAndSettle();

      // AuthModal dialog should appear
      expect(find.byType(AuthModal), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });
  });
}
