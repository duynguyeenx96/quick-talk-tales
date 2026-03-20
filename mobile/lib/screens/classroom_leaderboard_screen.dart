import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class ClassroomLeaderboardScreen extends StatefulWidget {
  const ClassroomLeaderboardScreen({super.key});

  @override
  State<ClassroomLeaderboardScreen> createState() => _ClassroomLeaderboardScreenState();
}

class _ClassroomLeaderboardScreenState extends State<ClassroomLeaderboardScreen> {
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiService.getClassroomAllTimeLeaderboard();
      if (mounted) setState(() { _rows = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Classroom Leaderboard'),
        backgroundColor: AppTheme.secondaryBlue,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _rows.isEmpty
              ? const Center(
                  child: Text('No data yet — join a classroom session!',
                      style: TextStyle(color: AppTheme.textSecondary, fontFamily: 'Nunito')))
              : Column(
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: _rows.length,
                          itemBuilder: (_, i) => _buildRow(_rows[i], i),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: AppTheme.secondaryBlue.withOpacity(0.06),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: const Row(
        children: [
          SizedBox(width: 36),
          Expanded(child: Text('Player',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                  color: AppTheme.textSecondary, fontFamily: 'Nunito'))),
          SizedBox(
            width: 56,
            child: Text('Total', textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondary, fontFamily: 'Nunito')),
          ),
          SizedBox(
            width: 48,
            child: Text('Best', textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondary, fontFamily: 'Nunito')),
          ),
          SizedBox(
            width: 40,
            child: Text('Avg', textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondary, fontFamily: 'Nunito')),
          ),
          SizedBox(
            width: 40,
            child: Text('Sessions', textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondary, fontFamily: 'Nunito')),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(Map<String, dynamic> r, int index) {
    final rank = r['rank'] as int? ?? index + 1;
    final username = r['username'] as String? ?? 'Unknown';
    final totalScore = r['totalScore'] as int? ?? 0;
    final bestScore = r['bestScore'] as int?;
    final avgScore = r['avgScore'] as double?;
    final sessions = r['sessionsSubmitted'] as int? ?? 0;

    final isTop3 = rank <= 3;
    final rankColors = [const Color(0xFFFFB300), Colors.blueGrey, const Color(0xFFCD7F32)];
    final rankColor = isTop3 ? rankColors[rank - 1] : AppTheme.textSecondary;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: rank == 1 ? const Color(0xFFFFFDE7) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: rank == 1 ? const Color(0xFFFFD54F) : Colors.grey.shade100,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '#$rank',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: rankColor,
                fontFamily: 'Nunito',
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              username,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'Nunito',
              ),
            ),
          ),
          SizedBox(
            width: 56,
            child: Text(
              '$totalScore',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold,
                color: AppTheme.secondaryBlue, fontFamily: 'Nunito',
              ),
            ),
          ),
          SizedBox(
            width: 48,
            child: Text(
              bestScore != null ? '$bestScore' : '—',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, fontFamily: 'Nunito'),
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              avgScore != null ? avgScore.toStringAsFixed(0) : '—',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, fontFamily: 'Nunito'),
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              '$sessions',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontFamily: 'Nunito'),
            ),
          ),
        ],
      ),
    );
  }
}
