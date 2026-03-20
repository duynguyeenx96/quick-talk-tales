import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/classroom_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'classroom_history_screen.dart';
import 'classroom_leaderboard_screen.dart';

class ClassroomScreen extends StatefulWidget {
  final ClassroomSessionInfo session;
  const ClassroomScreen({super.key, required this.session});

  @override
  State<ClassroomScreen> createState() => _ClassroomScreenState();
}

class _ClassroomScreenState extends State<ClassroomScreen> {
  late ClassroomSessionInfo _session;
  final _controller = TextEditingController();
  Timer? _countdownTimer;
  int _secondsLeft = 0;
  bool _submitting = false;
  bool _submitted = false;
  Map<String, dynamic>? _result;
  List<Map<String, dynamic>> _leaderboard = [];
  bool _loadingLeaderboard = false;

  @override
  void initState() {
    super.initState();
    _session = widget.session;
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startCountdown() {
    final endTime = _session.endTime;
    _updateSecondsLeft(endTime);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateSecondsLeft(endTime);
    });
  }

  void _updateSecondsLeft(DateTime endTime) {
    final remaining = endTime.difference(DateTime.now()).inSeconds;
    if (mounted) {
      setState(() => _secondsLeft = remaining.clamp(0, 99999));
      if (remaining <= 0 && !_submitted) {
        _countdownTimer?.cancel();
        _loadLeaderboard();
      }
    }
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.length < 10) return;
    setState(() => _submitting = true);
    try {
      final data = await ApiService.submitClassroomStory(
        sessionId: _session.id,
        storyText: text,
      );
      setState(() {
        _result = data;
        _submitted = true;
        _submitting = false;
      });
      // Refresh classroom provider so overlay knows user submitted
      if (mounted) context.read<ClassroomProvider>().fetchCurrent();
      await _loadLeaderboard();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppTheme.accentPink),
        );
      }
      setState(() => _submitting = false);
    }
  }

  Future<void> _loadLeaderboard() async {
    setState(() => _loadingLeaderboard = true);
    try {
      final data = await ApiService.getClassroomLeaderboard(_session.id);
      if (mounted) setState(() => _leaderboard = data);
    } catch (_) {}
    if (mounted) setState(() => _loadingLeaderboard = false);
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isEnded = _secondsLeft <= 0 || _session.status == ClassroomSessionStatus.ended;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Classroom Session'),
        backgroundColor: AppTheme.secondaryBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'My History',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ClassroomHistoryScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.emoji_events_rounded),
            tooltip: 'All-Time Leaderboard',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ClassroomLeaderboardScreen())),
          ),
        ],
      ),
      body: SafeArea(
        child: isEnded || _submitted
            ? _buildResultAndLeaderboard()
            : _buildActiveSession(),
      ),
    );
  }

  Widget _buildActiveSession() {
    final usedWords = _session.wordSet
        .where((w) => _controller.text.toLowerCase().contains(w.toLowerCase()))
        .toSet();

    return Column(
      children: [
        // Timer bar
        Container(
          color: _secondsLeft < 60
              ? AppTheme.accentPink.withOpacity(0.1)
              : AppTheme.secondaryBlue.withOpacity(0.08),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Icon(
                Icons.timer_outlined,
                color: _secondsLeft < 60 ? AppTheme.accentPink : AppTheme.secondaryBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _formatTime(_secondsLeft),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Nunito',
                  color: _secondsLeft < 60 ? AppTheme.accentPink : AppTheme.secondaryBlue,
                ),
              ),
              const Spacer(),
              Text(
                '${_session.participantCount} players',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  fontFamily: 'Nunito',
                ),
              ),
            ],
          ),
        ),

        // Word chips
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Use these words in your story:',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  fontFamily: 'Nunito',
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _session.wordSet.map((w) {
                  final used = usedWords.contains(w);
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: used ? AppTheme.primaryGreen : Colors.white,
                      border: Border.all(
                        color: used ? AppTheme.primaryGreen : Colors.grey.shade300,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      w,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Nunito',
                        color: used ? Colors.white : AppTheme.textPrimary,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        // Story input
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _controller,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Write your story here...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppTheme.secondaryBlue, width: 2),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Submit button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _submitting || _controller.text.trim().length < 10 ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondaryBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    )
                  : const Text('Submit Story',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Nunito')),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildResultAndLeaderboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_result != null) ...[
            _buildScoreCard(),
            const SizedBox(height: 24),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Session ended',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: AppTheme.textSecondary, fontFamily: 'Nunito'),
              ),
            ),
            const SizedBox(height: 24),
          ],
          Text(
            'Leaderboard',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (_loadingLeaderboard)
            const Center(child: CircularProgressIndicator())
          else if (_leaderboard.isEmpty)
            const Text('No submissions yet.', style: TextStyle(color: AppTheme.textSecondary, fontFamily: 'Nunito'))
          else
            ..._leaderboard.map((entry) => _buildLeaderboardRow(entry)),
        ],
      ),
    );
  }

  Widget _buildScoreCard() {
    final scores = _result!['scores'] as Map<String, dynamic>? ?? {};
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1CB0F6), Color(0xFF2196F3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            '${scores['overall'] ?? 0}',
            style: const TextStyle(
              fontSize: 56, fontWeight: FontWeight.bold,
              color: Colors.white, fontFamily: 'Nunito',
            ),
          ),
          const Text('Overall Score', style: TextStyle(color: Colors.white70, fontFamily: 'Nunito')),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _scoreChip('Grammar', scores['grammar']),
              _scoreChip('Creative', scores['creativity']),
              _scoreChip('Coherence', scores['coherence']),
              _scoreChip('Words', scores['word_usage']),
            ],
          ),
          if (_result!['feedback'] != null && (_result!['feedback'] as String).isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              _result!['feedback'] as String,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'Nunito'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _scoreChip(String label, dynamic value) {
    return Column(
      children: [
        Text(
          '${value ?? 0}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Nunito'),
        ),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white70, fontFamily: 'Nunito')),
      ],
    );
  }

  Widget _buildLeaderboardRow(Map<String, dynamic> entry) {
    final rank = entry['rank'] as int;
    final username = entry['username'] as String? ?? 'Unknown';
    final score = entry['scoreOverall'] as int? ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: rank == 1
            ? const Color(0xFFFFF8E1)
            : rank == 2
                ? const Color(0xFFF5F5F5)
                : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: rank == 1 ? const Color(0xFFFFD700) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '#$rank',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Nunito',
                color: rank == 1 ? const Color(0xFFFFB300) : AppTheme.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              username,
              style: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Nunito'),
            ),
          ),
          Text(
            '$score pts',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.secondaryBlue,
              fontFamily: 'Nunito',
            ),
          ),
        ],
      ),
    );
  }
}
