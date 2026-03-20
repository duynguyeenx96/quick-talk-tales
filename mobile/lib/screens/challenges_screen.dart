import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../widgets/share_card_widget.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class ChallengesScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  const ChallengesScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final challenges = (data['challenges'] as List).cast<Map<String, dynamic>>();
    final completed = data['completedCount'] as int? ?? 0;
    final total = data['totalCount'] as int? ?? 0;
    final streak = data['currentStreak'] as int? ?? 0;
    final longest = data['longestStreak'] as int? ?? 0;
    final date = data['date'] as String? ?? '';
    final submissionsToday = data['submissionsToday'] as int? ?? 0;
    final auth = context.read<AuthProvider>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8FBFF), Color(0xFFE8F4FD)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // AppBar
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Daily Challenges',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Nunito',
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ),
                    Text(
                      date,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontFamily: 'Nunito',
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Streak banner
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: AppGradients.orangeGradient,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Text('🔥', style: TextStyle(fontSize: 40)),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$streak Day Streak!',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Nunito',
                                  ),
                                ),
                                Text(
                                  'Best: $longest days',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.85),
                                    fontFamily: 'Nunito',
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95)),
                      const SizedBox(height: 12),
                      // Day Challenges area
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$submissionsToday',
                                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, fontFamily: 'Nunito', color: AppTheme.primaryGreen),
                                  ),
                                  const Text('Day Challenges', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontFamily: 'Nunito')),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$completed/$total',
                                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, fontFamily: 'Nunito', color: AppTheme.secondaryBlue),
                                  ),
                                  const Text('Goals Done', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontFamily: 'Nunito')),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ).animate(delay: 200.ms).fadeIn(duration: 300.ms),
                      const SizedBox(height: 20),
                      // Challenge list
                      ...challenges.asMap().entries.map((entry) {
                        final i = entry.key;
                        final c = entry.value;
                        final isDone = c['completed'] as bool;
                        final progress = c['progress'] as num? ?? 0;
                        final target = c['target'] as num? ?? 1;
                        final type = c['type'] as String;

                        String progressText;
                        double progressValue;
                        if (type == 'count') {
                          progressText = '${progress.toInt()}/${target.toInt()}';
                          progressValue = (progress / target).clamp(0.0, 1.0).toDouble();
                        } else if (type == 'avg_score' || type == 'max_score') {
                          progressText = '${progress.toInt()}/${target.toInt()} pts';
                          progressValue = (progress / target).clamp(0.0, 1.0).toDouble();
                        } else {
                          progressText = isDone ? 'Done!' : 'Not yet';
                          progressValue = isDone ? 1.0 : 0.0;
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDone ? AppTheme.primaryGreen.withOpacity(0.06) : Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isDone ? AppTheme.primaryGreen.withOpacity(0.3) : Colors.grey.shade200,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: isDone
                                        ? AppTheme.primaryGreen.withOpacity(0.12)
                                        : Colors.grey.shade100,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      isDone ? '✅' : c['icon'] as String,
                                      style: const TextStyle(fontSize: 22),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        c['title'] as String,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Nunito',
                                          color: isDone ? AppTheme.primaryGreen : AppTheme.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        c['description'] as String,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textSecondary,
                                          fontFamily: 'Nunito',
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(4),
                                              child: LinearProgressIndicator(
                                                value: progressValue,
                                                minHeight: 5,
                                                backgroundColor: Colors.grey.shade200,
                                                valueColor: AlwaysStoppedAnimation<Color>(
                                                  isDone ? AppTheme.primaryGreen : AppTheme.secondaryBlue,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            progressText,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppTheme.textSecondary,
                                              fontFamily: 'Nunito',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ).animate(delay: Duration(milliseconds: 100 * i)).fadeIn(duration: 300.ms).slideX(begin: 0.2),
                        );
                      }),
                      const SizedBox(height: 20),
                      // Share button
                      if (completed > 0)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.share),
                            label: const Text('Share My Progress'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.secondaryBlue,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () => ShareCardWidget.share(
                              context: context,
                              displayName: auth.fullName.isNotEmpty ? auth.fullName : auth.username,
                              avatarUrl: auth.avatarUrl,
                              streak: streak,
                              score: null,
                              challengesCompleted: completed,
                              totalChallenges: total,
                            ),
                          ),
                        ).animate(delay: 400.ms).fadeIn(duration: 400.ms).slideY(begin: 0.3),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
