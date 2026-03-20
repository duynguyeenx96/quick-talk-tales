import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../screens/challenges_screen.dart';

class DailyChallengesWidget extends StatefulWidget {
  const DailyChallengesWidget({super.key});

  @override
  State<DailyChallengesWidget> createState() => _DailyChallengesWidgetState();
}

class _DailyChallengesWidgetState extends State<DailyChallengesWidget> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiService.getDailyChallenges();
      if (mounted) setState(() { _data = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (_data == null) return const SizedBox.shrink();

    final challenges = (_data!['challenges'] as List).cast<Map<String, dynamic>>();
    final completed = _data!['completedCount'] as int? ?? 0;
    final total = _data!['totalCount'] as int? ?? 0;
    final streak = _data!['currentStreak'] as int? ?? 0;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChallengesScreen(data: _data!)),
      ).then((_) => _load()),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Daily Challenges',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Nunito',
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                if (streak > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.accentOrange.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '🔥 $streak',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accentOrange,
                        fontFamily: 'Nunito',
                        fontSize: 13,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                Text(
                  '$completed/$total',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                    fontFamily: 'Nunito',
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, color: AppTheme.textSecondary, size: 20),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: total > 0 ? completed / total : 0,
                minHeight: 6,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: challenges.take(5).map((c) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Tooltip(
                      message: c['title'] as String,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: (c['completed'] as bool)
                              ? AppTheme.primaryGreen.withOpacity(0.12)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: (c['completed'] as bool)
                                ? AppTheme.primaryGreen.withOpacity(0.3)
                                : Colors.transparent,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(c['icon'] as String, style: const TextStyle(fontSize: 18)),
                            if (c['completed'] as bool)
                              const Text('✓', style: TextStyle(fontSize: 10, color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
