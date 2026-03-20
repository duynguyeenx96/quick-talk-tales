import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

enum ClassroomSessionStatus { upcoming, active, ended }

class ClassroomSessionInfo {
  final String id;
  final List<String> wordSet;
  final int wordCount;
  final DateTime startTime;
  final DateTime endTime;
  final ClassroomSessionStatus status;
  final int participantCount;
  final bool hasJoined;
  final String? submissionId;
  final int minutesUntilStart;

  ClassroomSessionInfo({
    required this.id,
    required this.wordSet,
    required this.wordCount,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.participantCount,
    required this.hasJoined,
    this.submissionId,
    required this.minutesUntilStart,
  });

  factory ClassroomSessionInfo.fromJson(Map<String, dynamic> j) {
    final statusStr = j['status'] as String? ?? 'ended';
    final status = statusStr == 'upcoming'
        ? ClassroomSessionStatus.upcoming
        : statusStr == 'active'
            ? ClassroomSessionStatus.active
            : ClassroomSessionStatus.ended;
    return ClassroomSessionInfo(
      id: j['id'] as String,
      wordSet: (j['wordSet'] as List<dynamic>).map((e) => e.toString()).toList(),
      wordCount: j['wordCount'] as int? ?? 5,
      startTime: DateTime.parse(j['startTime'] as String),
      endTime: DateTime.parse(j['endTime'] as String),
      status: status,
      participantCount: j['participantCount'] as int? ?? 0,
      hasJoined: j['hasJoined'] as bool? ?? false,
      submissionId: j['submissionId'] as String?,
      minutesUntilStart: j['minutesUntilStart'] as int? ?? 0,
    );
  }

  bool get isVisible => status == ClassroomSessionStatus.active ||
      (status == ClassroomSessionStatus.upcoming && minutesUntilStart <= 5);
}

class ClassroomProvider extends ChangeNotifier {
  ClassroomSessionInfo? _currentSession;
  bool _loading = false;
  String? _error;

  // Track dismissed overlay per session so we can re-show at T-1min
  String? _dismissedSessionId;
  int _dismissedAtMinute = 999;

  ClassroomSessionInfo? get currentSession => _currentSession;
  bool get loading => _loading;
  String? get error => _error;

  /// Whether the overlay should be shown right now.
  bool get shouldShowOverlay {
    final s = _currentSession;
    if (s == null || !s.isVisible || s.hasJoined) return false;

    // Re-show at T-1 even if previously dismissed
    if (_dismissedSessionId == s.id) {
      if (s.minutesUntilStart <= 1 && _dismissedAtMinute > 1) return true;
      return false;
    }
    return true;
  }

  Timer? _pollTimer;

  void startPolling() {
    _pollTimer?.cancel();
    fetchCurrent();
    // Poll every 30 seconds
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) => fetchCurrent());
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> fetchCurrent() async {
    try {
      final data = await ApiService.getClassroomCurrent();
      final previous = _currentSession;
      _currentSession = data != null ? ClassroomSessionInfo.fromJson(data) : null;

      // If new session appeared and different from previous, reset dismiss state
      if (_currentSession != null && previous?.id != _currentSession!.id) {
        _dismissedSessionId = null;
        _dismissedAtMinute = 999;
      }

      _error = null;
    } catch (_) {
      // Silently ignore poll failures — overlay just won't show
    }
    notifyListeners();
  }

  void dismissOverlay() {
    if (_currentSession != null) {
      _dismissedSessionId = _currentSession!.id;
      _dismissedAtMinute = _currentSession!.minutesUntilStart;
    }
    notifyListeners();
  }

  Future<bool> joinSession(String sessionId) async {
    try {
      await ApiService.joinClassroomSession(sessionId);
      await fetchCurrent(); // refresh hasJoined
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
