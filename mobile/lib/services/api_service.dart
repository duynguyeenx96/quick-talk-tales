import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static String get baseUrl => kIsWeb ? Uri.base.origin : 'http://localhost:3000';
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  /// Called when refresh fails (token expired) → AuthProvider should logout
  static void Function()? onUnauthorized;

  // ── Token management ───────────────────────────────────────────────────────

  static Future<String?> getToken() async =>
      (await SharedPreferences.getInstance()).getString(_accessTokenKey);

  static Future<void> saveToken(String token) async =>
      (await SharedPreferences.getInstance()).setString(_accessTokenKey, token);

  static Future<String?> _getRefreshToken() async =>
      (await SharedPreferences.getInstance()).getString(_refreshTokenKey);

  static Future<void> _saveRefreshToken(String token) async =>
      (await SharedPreferences.getInstance()).setString(_refreshTokenKey, token);

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
  }

  // ── HTTP helpers ───────────────────────────────────────────────────────────

  static Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Map<String, dynamic> _decode(http.Response res) {
    final body = jsonDecode(res.body);
    if (res.statusCode >= 400) {
      final msg = body['message'] ?? body['error'] ?? 'Request failed';
      throw ApiException(msg is List ? msg.join(', ') : msg.toString(), res.statusCode);
    }
    return body as Map<String, dynamic>;
  }

  /// Tries to call `makeRequest`. If 401 → attempts token refresh and retries once.
  /// If refresh also fails → calls [onUnauthorized] and rethrows.
  static Future<http.Response> _withRefresh(
      Future<http.Response> Function() makeRequest) async {
    var res = await makeRequest();
    if (res.statusCode != 401) return res;

    // Try to silently refresh
    final refreshed = await _tryRefresh();
    if (!refreshed) {
      onUnauthorized?.call();
      return res; // caller will see 401 and throw via _decode
    }

    // Retry with new access token
    return makeRequest();
  }

  static bool _isRefreshing = false;

  static Future<bool> _tryRefresh() async {
    if (_isRefreshing) return false;
    _isRefreshing = true;
    try {
      final refreshToken = await _getRefreshToken();
      if (refreshToken == null) return false;

      final res = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );
      if (res.statusCode != 200) return false;

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      await saveToken(data['accessToken'] as String);
      if (data['refreshToken'] != null) {
        await _saveRefreshToken(data['refreshToken'] as String);
      }
      return true;
    } catch (_) {
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  // ── Auth ───────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = _decode(res);
    await saveToken(data['accessToken'] as String);
    if (data['refreshToken'] != null) {
      await _saveRefreshToken(data['refreshToken'] as String);
    }
    return data;
  }

  static Future<Map<String, dynamic>> register(
      String username, String email, String password,
      {String? referralCode}) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
        if (referralCode != null && referralCode.isNotEmpty) 'referralCode': referralCode,
      }),
    );
    final data = _decode(res);
    if (data['accessToken'] != null) await saveToken(data['accessToken'] as String);
    if (data['refreshToken'] != null) await _saveRefreshToken(data['refreshToken'] as String);
    return data;
  }

  static Future<void> logout() => clearToken();

  static Future<Map<String, dynamic>> googleLogin(String idToken) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/google'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'idToken': idToken}),
    );
    final data = _decode(res);
    await saveToken(data['accessToken'] as String);
    if (data['refreshToken'] != null) {
      await _saveRefreshToken(data['refreshToken'] as String);
    }
    return data;
  }

  static Future<Map<String, dynamic>> verifyEmail(String token) async {
    final res = await http.get(Uri.parse('$baseUrl/auth/verify-email?token=$token'));
    return _decode(res);
  }

  static Future<Map<String, dynamic>> resendVerification() async {
    final res = await _withRefresh(() async {
      final h = await _authHeaders();
      return http.post(Uri.parse('$baseUrl/auth/resend-verification'), headers: h);
    });
    return _decode(res);
  }

  // ── User Profile ───────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getProfile() async {
    final res = await _withRefresh(() async {
      final h = await _authHeaders();
      return http.get(Uri.parse('$baseUrl/users/profile'), headers: h);
    });
    return _decode(res);
  }

  static Future<Map<String, dynamic>> uploadAvatar(List<int> bytes, String filename) async {
    // Multipart — handle 401 manually (can't use _withRefresh easily)
    Future<http.Response> doUpload() async {
      final token = await getToken();
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/users/avatar'));
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      final ext = filename.split('.').last.toLowerCase();
      final mime = switch (ext) {
        'png' => 'image/png',
        'gif' => 'image/gif',
        'webp' => 'image/webp',
        _ => 'image/jpeg',
      };
      request.files.add(http.MultipartFile.fromBytes('file', bytes,
          filename: filename, contentType: MediaType.parse(mime)));
      final streamed = await request.send();
      return http.Response.fromStream(streamed);
    }

    var res = await doUpload();
    if (res.statusCode == 401) {
      final refreshed = await _tryRefresh();
      if (!refreshed) { onUnauthorized?.call(); }
      else { res = await doUpload(); }
    }
    return _decode(res);
  }

  static Future<List<Map<String, dynamic>>> getSubscriptionPlans() async {
    final res = await _withRefresh(() async {
      final h = await _authHeaders();
      return http.get(Uri.parse('$baseUrl/users/subscription/plans'), headers: h);
    });
    final data = jsonDecode(res.body);
    if (res.statusCode >= 400) throw ApiException('Failed to fetch plans', res.statusCode);
    return (data as List).cast<Map<String, dynamic>>();
  }

  static Future<Map<String, dynamic>> mockUpgrade(String planId) async {
    final res = await _withRefresh(() async {
      final h = await _authHeaders();
      return http.post(Uri.parse('$baseUrl/users/subscription/mock-upgrade'),
          headers: h, body: jsonEncode({'planId': planId}));
    });
    return _decode(res);
  }

  static Future<Map<String, dynamic>> updateProfile({
    String? fullName,
    String? avatarUrl,
    Map<String, dynamic>? preferences,
  }) async {
    final body = <String, dynamic>{};
    if (fullName != null) body['fullName'] = fullName;
    if (avatarUrl != null) body['avatarUrl'] = avatarUrl;
    if (preferences != null) body['preferences'] = preferences;
    final res = await _withRefresh(() async {
      final h = await _authHeaders();
      return http.put(Uri.parse('$baseUrl/users/profile'), headers: h, body: jsonEncode(body));
    });
    return _decode(res);
  }

  // ── Words ──────────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getRandomWords({
    required int count,
    String? difficulty,
  }) async {
    final query = 'count=$count${difficulty != null ? '&difficulty=$difficulty' : ''}';
    final res = await _withRefresh(() async {
      final h = await _authHeaders();
      return http.get(Uri.parse('$baseUrl/words/random?$query'), headers: h);
    });
    final data = jsonDecode(res.body);
    if (res.statusCode >= 400) throw ApiException('Failed to fetch words', res.statusCode);
    return (data as List).cast<Map<String, dynamic>>();
  }

  // ── Evaluation ─────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> submitStory({
    required String storyText,
    required List<String> targetWords,
  }) async {
    final res = await _withRefresh(() async {
      final h = await _authHeaders();
      return http.post(Uri.parse('$baseUrl/evaluation/submit'),
          headers: h,
          body: jsonEncode({'storyText': storyText, 'targetWords': targetWords}));
    });
    return _decode(res);
  }

  // ── Leaderboard & Stats ────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getLeaderboard() async {
    final res = await _withRefresh(() async {
      final h = await _authHeaders();
      return http.get(Uri.parse('$baseUrl/evaluation/leaderboard'), headers: h);
    });
    final data = jsonDecode(res.body);
    if (res.statusCode >= 400) throw ApiException('Failed to fetch leaderboard', res.statusCode);
    return (data as List).cast<Map<String, dynamic>>();
  }

  static Future<Map<String, dynamic>> getMyStats() async {
    final res = await _withRefresh(() async {
      final h = await _authHeaders();
      return http.get(Uri.parse('$baseUrl/evaluation/my-stats'), headers: h);
    });
    return _decode(res);
  }

  static Future<Map<String, dynamic>> getDailyChallenges() async {
    final res = await _withRefresh(() async {
      final h = await _authHeaders();
      return http.get(Uri.parse('$baseUrl/challenges/daily'), headers: h);
    });
    return _decode(res);
  }

  // ── Friends ────────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getFriends() async {
    final res = await _withRefresh(() async {
      final h = await _authHeaders();
      return http.get(Uri.parse('$baseUrl/friends'), headers: h);
    });
    final data = jsonDecode(res.body);
    if (res.statusCode >= 400) throw ApiException('Failed to fetch friends', res.statusCode);
    return (data as List).cast<Map<String, dynamic>>();
  }

  static Future<List<Map<String, dynamic>>> getPendingRequests() async {
    final res = await _withRefresh(() async {
      final h = await _authHeaders();
      return http.get(Uri.parse('$baseUrl/friends/pending'), headers: h);
    });
    final data = jsonDecode(res.body);
    if (res.statusCode >= 400) throw ApiException('Failed', res.statusCode);
    return (data as List).cast<Map<String, dynamic>>();
  }

  static Future<List<Map<String, dynamic>>> searchUsers(String q) async {
    final res = await _withRefresh(() async {
      final h = await _authHeaders();
      return http.get(Uri.parse('$baseUrl/friends/search?q=${Uri.encodeComponent(q)}'), headers: h);
    });
    final data = jsonDecode(res.body);
    if (res.statusCode >= 400) throw ApiException('Failed', res.statusCode);
    return (data as List).cast<Map<String, dynamic>>();
  }

  static Future<Map<String, dynamic>> sendFriendRequest(String usernameOrId) async {
    final res = await _withRefresh(() async {
      final h = await _authHeaders();
      return http.post(Uri.parse('$baseUrl/friends/request'),
          headers: h, body: jsonEncode({'usernameOrId': usernameOrId}));
    });
    return _decode(res);
  }

  static Future<Map<String, dynamic>> acceptFriendRequest(String friendshipId) async {
    final res = await _withRefresh(() async {
      final h = await _authHeaders();
      return http.post(Uri.parse('$baseUrl/friends/$friendshipId/accept'), headers: h);
    });
    return _decode(res);
  }

  static Future<void> removeFriend(String friendshipId) async {
    await _withRefresh(() async {
      final h = await _authHeaders();
      return http.delete(Uri.parse('$baseUrl/friends/$friendshipId'), headers: h);
    });
  }

  // ── Group Challenges ───────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getGroupChallenges() async {
    final res = await _withRefresh(() async {
      final h = await _authHeaders();
      return http.get(Uri.parse('$baseUrl/group-challenges'), headers: h);
    });
    final data = jsonDecode(res.body);
    if (res.statusCode >= 400) throw ApiException('Failed', res.statusCode);
    return (data as List).cast<Map<String, dynamic>>();
  }

  static Future<Map<String, dynamic>> getGroupChallengeDetail(String id) async {
    final res = await _withRefresh(() async {
      final h = await _authHeaders();
      return http.get(Uri.parse('$baseUrl/group-challenges/$id'), headers: h);
    });
    return _decode(res);
  }

  static Future<Map<String, dynamic>> createGroupChallenge({
    required int wordCount,
    required String difficulty,
    required int durationDays,
    required List<String> inviteUserIds,
    required List<String> words,
  }) async {
    final res = await _withRefresh(() async {
      final h = await _authHeaders();
      return http.post(Uri.parse('$baseUrl/group-challenges'),
          headers: h,
          body: jsonEncode({
            'wordCount': wordCount,
            'difficulty': difficulty,
            'durationDays': durationDays,
            'inviteUserIds': inviteUserIds,
            'words': words,
          }));
    });
    return _decode(res);
  }

  static Future<Map<String, dynamic>> acceptGroupChallenge(String id) async {
    final res = await _withRefresh(() async {
      final h = await _authHeaders();
      return http.post(Uri.parse('$baseUrl/group-challenges/$id/accept'), headers: h);
    });
    return _decode(res);
  }

  static Future<Map<String, dynamic>> declineGroupChallenge(String id) async {
    final res = await _withRefresh(() async {
      final h = await _authHeaders();
      return http.post(Uri.parse('$baseUrl/group-challenges/$id/decline'), headers: h);
    });
    return _decode(res);
  }

  static Future<Map<String, dynamic>> submitGroupChallengeStory(
      String id, String storyText) async {
    final res = await _withRefresh(() async {
      final h = await _authHeaders();
      return http.post(Uri.parse('$baseUrl/group-challenges/$id/submit'),
          headers: h, body: jsonEncode({'storyText': storyText}));
    });
    return _decode(res);
  }

  // ── Referral ───────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getMyReferralCode() async {
    final res = await _withRefresh(() async {
      final h = await _authHeaders();
      return http.get(Uri.parse('$baseUrl/users/referral-code'), headers: h);
    });
    return _decode(res);
  }

  // ── Notifications ──────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getNotifications(
      {int page = 1, int limit = 12}) async {
    final uri = Uri.parse('$baseUrl/notifications')
        .replace(queryParameters: {'page': '$page', 'limit': '$limit'});
    final res = await _withRefresh(() async {
      final h = await _authHeaders();
      return http.get(uri, headers: h);
    });
    return _decode(res);
  }

  static Future<void> markNotificationRead(String id) async {
    await _withRefresh(() async {
      final h = await _authHeaders();
      return http.patch(Uri.parse('$baseUrl/notifications/$id/read'), headers: h);
    });
  }

  static Future<void> markAllNotificationsRead() async {
    await _withRefresh(() async {
      final h = await _authHeaders();
      return http.patch(Uri.parse('$baseUrl/notifications/read-all/all'), headers: h);
    });
  }

  // ── History ────────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getHistory() async {
    final res = await _withRefresh(() async {
      final h = await _authHeaders();
      return http.get(Uri.parse('$baseUrl/evaluation/history'), headers: h);
    });
    final data = jsonDecode(res.body);
    if (res.statusCode >= 400) throw ApiException('Failed to fetch history', res.statusCode);
    return (data as List).cast<Map<String, dynamic>>();
  }

  // ── Payments ───────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> createOrder(String planId) async {
    final res = await _withRefresh(() async {
      final h = await _authHeaders();
      return http.post(Uri.parse('$baseUrl/payments/create-order'),
          headers: h, body: jsonEncode({'planId': planId}));
    });
    return _decode(res);
  }

  static Future<Map<String, dynamic>> getOrderStatus(String orderId) async {
    final res = await _withRefresh(() async {
      final h = await _authHeaders();
      return http.get(Uri.parse('$baseUrl/payments/status/$orderId'), headers: h);
    });
    return _decode(res);
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}
