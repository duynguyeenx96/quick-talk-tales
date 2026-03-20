import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/classroom_provider.dart';
import '../providers/game_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/daily_challenges_widget.dart';
import '../widgets/premium_upgrade_dialog.dart';
import 'challenges_screen.dart';
import 'classroom_screen.dart';
import 'history_screen.dart';
import 'leaderboard_screen.dart';
import 'words_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEEF8F0), Color(0xFFE0F0FF), Color(0xFFF5EEF8)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Consumer<GameProvider>(
              builder: (context, game, _) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopBar(context),
                    const SizedBox(height: 32),
                    _buildWelcome(context),
                    const SizedBox(height: 16),
                    const DailyChallengesWidget(),
                    const SizedBox(height: 16),
                    _buildClassroomCard(context),
                    const SizedBox(height: 24),
                    _buildWordCountPicker(context, game),
                    const SizedBox(height: 24),
                    _buildDifficultyPicker(context, game),
                    const SizedBox(height: 24),
                    _buildTopicPicker(context, game),
                    const Spacer(),
                    _buildStartButton(context, game),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Quick Talk Tales',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.primaryGreen,
                fontWeight: FontWeight.bold,
              ),
        ),
        IconButton(
          icon: const Icon(Icons.history, color: AppTheme.textSecondary),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HistoryScreen()),
          ),
          tooltip: 'History',
        ),
        IconButton(
          icon: const Icon(Icons.emoji_events_outlined, color: AppTheme.textSecondary),
          onPressed: () async {
            try {
              final data = await ApiService.getDailyChallenges();
              if (context.mounted) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => ChallengesScreen(data: data)));
              }
            } catch (_) {}
          },
          tooltip: 'Daily Challenges',
        ),
        IconButton(
          icon: const Icon(Icons.leaderboard, color: AppTheme.textSecondary),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
          ),
          tooltip: 'Leaderboard',
        ),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildWelcome(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'New Story',
          style: Theme.of(context)
              .textTheme
              .headlineMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose your challenge level and get random words to build your story!',
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(color: AppTheme.textSecondary),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideX(begin: -0.2);
  }

  Widget _buildClassroomCard(BuildContext context) {
    return Consumer<ClassroomProvider>(
      builder: (context, classroom, _) {
        final session = classroom.currentSession;
        final bool hasSession = session != null;
        final bool isActive = hasSession && session.status == ClassroomSessionStatus.active;
        final bool isUpcoming = hasSession && session.status == ClassroomSessionStatus.upcoming;

        return GestureDetector(
          onTap: hasSession ? () => _openClassroom(context, classroom, session) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isActive
                    ? [const Color(0xFF1CB0F6), const Color(0xFF2196F3)]
                    : isUpcoming
                        ? [const Color(0xFFFF9600), const Color(0xFFFF6D00)]
                        : [Colors.grey.shade200, Colors.grey.shade300],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.class_rounded,
                  color: hasSession ? Colors.white : Colors.grey.shade500,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isActive
                            ? 'Classroom is LIVE'
                            : isUpcoming
                                ? 'Classroom in ${session.minutesUntilStart} min'
                                : 'No classroom right now',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Nunito',
                          color: hasSession ? Colors.white : Colors.grey.shade500,
                        ),
                      ),
                      if (hasSession)
                        Text(
                          '${session.participantCount} players · ${session.wordCount} words'
                          '${session.hasJoined ? ' · Joined ✓' : ''}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                            fontFamily: 'Nunito',
                          ),
                        ),
                    ],
                  ),
                ),
                if (hasSession)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      session.hasJoined ? 'View' : 'Join',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Nunito',
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ).animate().fadeIn(duration: 400.ms, delay: 150.ms);
      },
    );
  }

  Future<void> _openClassroom(
      BuildContext context, ClassroomProvider classroom, ClassroomSessionInfo session) async {
    if (session.hasJoined) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => ClassroomScreen(session: session)));
      return;
    }

    // Try to join
    final navigator = Navigator.of(context, rootNavigator: true);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await classroom.joinSession(session.id);

    if (!ok) {
      final err = classroom.error ?? '';
      messenger.showSnackBar(
        SnackBar(
          content: Text(err.isNotEmpty ? err : 'Could not join session'),
          backgroundColor: AppTheme.accentPink,
        ),
      );
      return;
    }

    final refreshed = classroom.currentSession;
    if (refreshed != null) {
      navigator.push(MaterialPageRoute(builder: (_) => ClassroomScreen(session: refreshed)));
    }
  }

  Widget _buildWordCountPicker(BuildContext context, GameProvider game) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How many words?',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Row(
          children: [3, 5, 7].map((count) {
            final selected = game.wordCount == count;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: () => game.setWordCount(count),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: selected ? AppTheme.primaryGreen : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: selected
                              ? AppTheme.primaryGreen.withOpacity(0.3)
                              : Colors.black.withOpacity(0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: selected ? Colors.white : AppTheme.textPrimary,
                            fontFamily: 'Nunito',
                          ),
                        ),
                        Text(
                          'words',
                          style: TextStyle(
                            fontSize: 13,
                            color: selected
                                ? Colors.white.withOpacity(0.85)
                                : AppTheme.textSecondary,
                            fontFamily: 'Nunito',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms, delay: 200.ms);
  }

  Widget _buildDifficultyPicker(BuildContext context, GameProvider game) {
    final isPremium =
        context.watch<AuthProvider>().subscriptionPlan == 'premium';

    final difficulties = [
      {
        'key': 'easy',
        'label': 'Easy',
        'sublabel': 'A2–B1',
        'color': AppTheme.primaryGreen,
        'locked': false,
      },
      {
        'key': 'medium',
        'label': 'Medium',
        'sublabel': 'B2',
        'color': AppTheme.accentOrange,
        'locked': !isPremium,
      },
      {
        'key': 'hard',
        'label': 'Hard',
        'sublabel': 'C1–C2',
        'color': AppTheme.accentPink,
        'locked': !isPremium,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Difficulty',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (!isPremium) ...[
              const SizedBox(width: 8),
              const Icon(Icons.lock_rounded, size: 14, color: Color(0xFFFFA000)),
              const SizedBox(width: 4),
              const Text(
                'Medium & Hard — Premium',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFFFFA000),
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: difficulties.map((d) {
            final key = d['key'] as String;
            final locked = d['locked'] as bool;
            final selected = game.difficulty == key;
            final color = d['color'] as Color;

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: () {
                    if (locked) {
                      PremiumUpgradeDialog.show(
                        context,
                        featureName: 'Unlock ${d['label']} Difficulty',
                        description:
                            'Challenge yourself with ${d['label']} (${d['sublabel']}) vocabulary.\nUpgrade to Premium to access all difficulty levels.',
                        icon: Icons.school_rounded,
                      );
                    } else {
                      game.setDifficulty(key);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: locked
                          ? Colors.grey.shade100
                          : selected
                              ? color
                              : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: locked
                          ? Border.all(color: Colors.grey.shade300, width: 1)
                          : null,
                      boxShadow: locked
                          ? null
                          : [
                              BoxShadow(
                                color: selected
                                    ? color.withOpacity(0.3)
                                    : Colors.black.withOpacity(0.06),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: Column(
                      children: [
                        if (locked)
                          const Icon(
                            Icons.lock_rounded,
                            size: 14,
                            color: Color(0xFFFFA000),
                          )
                        else
                          const SizedBox(height: 0),
                        Text(
                          d['label'] as String,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: locked
                                ? AppTheme.textSecondary
                                : selected
                                    ? Colors.white
                                    : AppTheme.textPrimary,
                            fontFamily: 'Nunito',
                          ),
                        ),
                        Text(
                          d['sublabel'] as String,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            color: locked
                                ? AppTheme.textSecondary.withOpacity(0.6)
                                : selected
                                    ? Colors.white.withOpacity(0.8)
                                    : AppTheme.textSecondary,
                            fontFamily: 'Nunito',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms, delay: 300.ms);
  }

  Widget _buildTopicPicker(BuildContext context, GameProvider game) {
    final isPremium =
        context.watch<AuthProvider>().subscriptionPlan == 'premium';

    const topics = [
      {'key': 'adventure', 'label': 'Adventure', 'icon': Icons.explore_rounded},
      {'key': 'fantasy',   'label': 'Fantasy',   'icon': Icons.auto_awesome_rounded},
      {'key': 'science',   'label': 'Science',   'icon': Icons.science_rounded},
      {'key': 'daily_life','label': 'Daily Life','icon': Icons.home_rounded},
      {'key': 'emotion',   'label': 'Emotion',   'icon': Icons.favorite_rounded},
      {'key': 'nature',    'label': 'Nature',    'icon': Icons.eco_rounded},
      {'key': 'mystery',   'label': 'Mystery',   'icon': Icons.psychology_rounded},
      {'key': 'sport',     'label': 'Sport',     'icon': Icons.sports_soccer_rounded},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Topic',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 8),
            if (!isPremium)
              const Row(
                children: [
                  Icon(Icons.lock_rounded, size: 14, color: Color(0xFFFFA000)),
                  SizedBox(width: 4),
                  Text(
                    'Premium',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFFFFA000),
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            else if (game.topic != null)
              GestureDetector(
                onTap: () => game.setTopic(null),
                child: const Text(
                  'Clear',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.secondaryBlue,
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: topics.map((t) {
              final key = t['key'] as String;
              final selected = game.topic == key;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    if (!isPremium) {
                      PremiumUpgradeDialog.show(
                        context,
                        featureName: 'Topic Selection',
                        description:
                            'Choose your story theme — Adventure, Fantasy, Science, and more.\nUpgrade to Premium to unlock topic selection.',
                        icon: Icons.auto_awesome_rounded,
                      );
                    } else {
                      game.setTopic(selected ? null : key);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTheme.accentPurple
                          : isPremium
                              ? Colors.white
                              : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: !isPremium
                          ? Border.all(color: Colors.grey.shade300, width: 1)
                          : null,
                      boxShadow: selected || !isPremium
                          ? null
                          : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!isPremium)
                          const Icon(Icons.lock_rounded,
                              size: 12, color: Color(0xFFFFA000)),
                        if (!isPremium) const SizedBox(width: 4),
                        Icon(
                          t['icon'] as IconData,
                          size: 14,
                          color: selected
                              ? Colors.white
                              : isPremium
                                  ? AppTheme.textSecondary
                                  : AppTheme.textSecondary.withOpacity(0.5),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          t['label'] as String,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Nunito',
                            color: selected
                                ? Colors.white
                                : isPremium
                                    ? AppTheme.textPrimary
                                    : AppTheme.textSecondary.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms, delay: 350.ms);
  }

  Widget _buildStartButton(BuildContext context, GameProvider game) {
    final isLoading = game.state == GameState.loadingWords;
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: isLoading
              ? null
              : const LinearGradient(
                  colors: [Color(0xFF1B9E4F), Color(0xFF2196F3)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
          color: isLoading ? Colors.grey.shade300 : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isLoading
              ? null
              : [BoxShadow(color: const Color(0xFF1B9E4F).withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : () => _startGame(context, game),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: isLoading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                )
              : const Text('Start Story', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 400.ms).slideY(begin: 0.3);
  }

  Future<void> _startGame(BuildContext context, GameProvider game) async {
    final ok = await game.loadRandomWords();
    if (ok && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const WordsScreen()),
      );
    } else if (context.mounted && game.error.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(game.error), backgroundColor: AppTheme.accentPink),
      );
    }
  }
}
