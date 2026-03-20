import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/api_service.dart';

enum AuthState { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthState _state = AuthState.unknown;
  String _error = '';
  Map<String, dynamic>? _user;

  AuthState get state => _state;
  String get error => _error;
  bool get isAuthenticated => _state == AuthState.authenticated;
  Map<String, dynamic>? get user => _user;

  String get username => _user?['username'] as String? ?? '';
  String get email => _user?['email'] as String? ?? '';
  String get fullName => _user?['fullName'] as String? ?? '';
  String get avatarUrl => _user?['avatarUrl'] as String? ?? '';
  String get userId => _user?['id'] as String? ?? '';
  String get language =>
      ((_user?['preferences'] as Map?)?.cast<String, dynamic>() ?? {})['language']
          as String? ??
      'en';
  String get subscriptionPlan => _user?['subscriptionPlan'] as String? ?? 'free';
  String get createdAt => _user?['createdAt'] as String? ?? '';

  Future<void> checkAuth() async {
    // Register force-logout callback: called when refresh token is expired
    ApiService.onUnauthorized = () {
      ApiService.clearToken();
      _user = null;
      _state = AuthState.unauthenticated;
      notifyListeners();
    };

    final token = await ApiService.getToken();
    if (token != null) {
      _state = AuthState.authenticated;
      notifyListeners();
      await _fetchProfile();
    } else {
      _state = AuthState.unauthenticated;
      notifyListeners();
    }
  }

  Future<void> _fetchProfile() async {
    try {
      _user = await ApiService.getProfile();
      notifyListeners();
    } catch (_) {
      // Silently ignore — token might be stale; user will see empty profile fields
    }
  }

  /// Re-fetches profile from server — call when returning from subscription screens
  Future<void> refreshProfile() => _fetchProfile();

  Future<bool> login(String email, String password) async {
    _error = '';
    try {
      final data = await ApiService.login(email, password);
      _user = data['user'] as Map<String, dynamic>?;
      _state = AuthState.authenticated;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'Cannot connect to server. Check your connection.';
      notifyListeners();
      return false;
    }
  }

  // ── Google SSO ─────────────────────────────────────────────────────────────

  Future<bool> googleLogin() async {
    _error = '';
    try {
      // clientId needed for macOS/Web; iOS uses GoogleService-Info.plist automatically
      // For macOS: create a "Web" OAuth client in Google Console, use that client ID here
      const macOsClientId = String.fromEnvironment('GOOGLE_CLIENT_ID', defaultValue: '');
      final googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        clientId: macOsClientId.isNotEmpty ? macOsClientId : null,
      );
      final account = await googleSignIn.signIn();
      if (account == null) return false; // user cancelled

      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        _error = 'Failed to get Google ID token';
        notifyListeners();
        return false;
      }

      final data = await ApiService.googleLogin(idToken);
      _user = data['user'] as Map<String, dynamic>?;
      _state = AuthState.authenticated;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Google sign-in failed. Try again.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String username, String email, String password, {String? referralCode}) async {
    _error = '';
    try {
      await ApiService.register(username, email, password, referralCode: referralCode);
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'Cannot connect to server. Check your connection.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile({
    String? fullName,
    String? avatarUrl,
    String? language,
  }) async {
    try {
      Map<String, dynamic>? prefs;
      if (language != null) {
        final current = Map<String, dynamic>.from(
            (_user?['preferences'] as Map?)?.cast<String, dynamic>() ?? {});
        current['language'] = language;
        prefs = current;
      }
      final updated = await ApiService.updateProfile(
        fullName: fullName,
        avatarUrl: avatarUrl,
        preferences: prefs,
      );
      _user = updated;
      notifyListeners();
      return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    await ApiService.logout();
    _state = AuthState.unauthenticated;
    _user = null;
    notifyListeners();
  }

  void clearError() {
    _error = '';
    notifyListeners();
  }
}
