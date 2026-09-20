import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService extends ChangeNotifier {
  final SupabaseClient? _client;

  AuthService({SupabaseClient? client}) : _client = client {
    _client?.auth.onAuthStateChange.listen((data) {
      notifyListeners();
    });
  }

  User? get currentUser => _client?.auth.currentUser;

  bool get isAuthenticated => currentUser != null;

  String get userEmail => currentUser?.email ?? '';

  String get userDisplayName {
    final meta = currentUser?.userMetadata;
    if (meta != null && meta['full_name'] != null) {
      return meta['full_name'].toString();
    }
    if (userEmail.isNotEmpty) {
      final namePart = userEmail.split('@').first;
      return namePart.substring(0, 1).toUpperCase() + namePart.substring(1);
    }
    return 'Guest User';
  }

  String get userInitials {
    final name = userDisplayName;
    if (name.isEmpty) return 'AR';
    final parts = name.trim().split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length > 1 ? 2 : 1).toUpperCase();
  }

  Stream<AuthState>? get authStateChanges => _client?.auth.onAuthStateChange;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    if (_client == null) throw Exception('Supabase client not initialized');
    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password,
    );
    notifyListeners();
    return response;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    if (_client == null) throw Exception('Supabase client not initialized');
    final response = await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    notifyListeners();
    return response;
  }

  Future<bool> signInWithGoogle() async {
    if (_client == null) throw Exception('Supabase client not initialized');
    return await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? null : 'io.supabase.appradar://login-callback/',
    );
  }

  Future<void> signOut() async {
    if (_client == null) return;
    await _client.auth.signOut();
    notifyListeners();
  }
}
