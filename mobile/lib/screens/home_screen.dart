import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/daily_challenges_widget.dart';
import 'challenges_screen.dart';
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
                    const SizedBox(height: 24),
                    _buildWordCountPicker(context, game),
                    const SizedBox(height: 24),
                    _buildDifficultyPicker(context, game),
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
    final difficulties = [
      {'key': 'easy', 'label': 'Easy', 'color': AppTheme.primaryGreen},
      {'key': 'medium', 'label': 'Medium', 'color': AppTheme.accentOrange},
      {'key': 'hard', 'label': 'Hard', 'color': AppTheme.accentPink},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Difficulty',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Row(
          children: difficulties.map((d) {
            final selected = game.difficulty == d['key'];
            final color = d['color'] as Color;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: () => game.setDifficulty(d['key'] as String),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: selected ? color : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: selected
                              ? color.withOpacity(0.3)
                              : Colors.black.withOpacity(0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      d['label'] as String,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: selected ? Colors.white : AppTheme.textPrimary,
                        fontFamily: 'Nunito',
                      ),
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
