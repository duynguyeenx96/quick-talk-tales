import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/share_card_widget.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _rewardShown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final result = context.read<GameProvider>().result;
    if (result != null && result.challengeRewardGranted && !_rewardShown) {
      _rewardShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _showRewardDialog());
    }
  }

  void _showRewardDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            const Text(
              'All Daily Challenges\nCompleted!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Nunito',
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: AppGradients.orangeGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                '⭐ +1 Day Premium Unlocked!',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Nunito',
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Come back tomorrow for more!',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontFamily: 'Nunito',
                fontSize: 13,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Awesome! 🚀',
                style: TextStyle(
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Nunito')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final result = game.result;

    if (result == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF0FFF4), Color(0xFFE8F4FD)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 16),
                _buildOverallScore(context, result).animate().scale(
                    begin: const Offset(0.5, 0.5), duration: 600.ms, curve: Curves.elasticOut),
                const SizedBox(height: 24),
                _buildEncouragement(context, result)
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 300.ms),
                const SizedBox(height: 24),
                _buildScoreBreakdown(context, result)
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 400.ms),
                const SizedBox(height: 20),
                _buildWordReport(context, result)
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 500.ms),
                const SizedBox(height: 20),
                _buildFeedback(context, result)
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 600.ms),
                const SizedBox(height: 32),
                _buildShareButton(context, result)
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 650.ms)
                    .slideY(begin: 0.3),
                const SizedBox(height: 12),
                _buildPlayAgainButton(context, game)
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 700.ms)
                    .slideY(begin: 0.3),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverallScore(BuildContext context, EvaluationResult result) {
    final score = result.overall;
    final emoji = score >= 80
        ? '🏆'
        : score >= 60
            ? '⭐'
            : score >= 40
                ? '👍'
                : '💪';
    final color = score >= 80
        ? AppTheme.primaryGreen
        : score >= 60
            ? AppTheme.accentOrange
            : score >= 40
                ? AppTheme.secondaryBlue
                : AppTheme.accentPink;

    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 72)),
        const SizedBox(height: 12),
        Text(
          '$score',
          style: TextStyle(
            fontSize: 72,
            fontWeight: FontWeight.bold,
            color: color,
            fontFamily: 'Nunito',
          ),
        ),
        Text(
          'out of 100',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildEncouragement(BuildContext context, EvaluationResult result) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppGradients.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Text(
        result.encouragement,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          fontFamily: 'Nunito',
          height: 1.4,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildScoreBreakdown(BuildContext context, EvaluationResult result) {
    final categories = [
      {'label': '📝 Grammar', 'score': result.grammar, 'color': AppTheme.secondaryBlue},
      {'label': '🎨 Creativity', 'score': result.creativity, 'color': AppTheme.accentPurple},
      {'label': '🔗 Coherence', 'score': result.coherence, 'color': AppTheme.accentOrange},
      {'label': '🎯 Word Usage', 'score': result.wordUsage, 'color': AppTheme.primaryGreen},
    ];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Score Breakdown',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...categories.map((c) => _ScoreBar(
                  label: c['label'] as String,
                  score: c['score'] as int,
                  color: c['color'] as Color,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildWordReport(BuildContext context, EvaluationResult result) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Word Report',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (result.wordsUsed.isNotEmpty) ...[
              Text('✅ Used:',
                  style: TextStyle(
                      color: AppTheme.primaryGreen, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: result.wordsUsed.map((w) => Chip(
                      label: Text(w,
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold)),
                      backgroundColor: AppTheme.primaryGreen,
                    )).toList(),
              ),
              const SizedBox(height: 12),
            ],
            if (result.wordsMissing.isNotEmpty) ...[
              Text('❌ Missed:',
                  style: TextStyle(
                      color: AppTheme.accentPink, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: result.wordsMissing.map((w) => Chip(
                      label: Text(w,
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold)),
                      backgroundColor: AppTheme.accentPink,
                    )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeedback(BuildContext context, EvaluationResult result) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.secondaryBlue.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('💬', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text('Teacher\'s Feedback',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            result.feedback,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(height: 1.6, color: AppTheme.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildShareButton(BuildContext context, EvaluationResult result) {
    final auth = context.read<AuthProvider>();
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.share, color: AppTheme.secondaryBlue),
        label: const Text(
          'Share Result',
          style: TextStyle(
            color: AppTheme.secondaryBlue,
            fontWeight: FontWeight.bold,
            fontFamily: 'Nunito',
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: const BorderSide(color: AppTheme.secondaryBlue),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        onPressed: () => ShareCardWidget.share(
          context: context,
          displayName: auth.fullName.isNotEmpty ? auth.fullName : auth.username,
          avatarUrl: auth.avatarUrl,
          streak: 0,
          score: result.overall,
        ),
      ),
    );
  }

  Widget _buildPlayAgainButton(BuildContext context, GameProvider game) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          game.reset();
          Navigator.popUntil(context, (route) => route.isFirst);
        },
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
        ),
        child: const Text('🎮  Play Again!', style: TextStyle(fontSize: 20)),
      ),
    );
  }
}

class _ScoreBar extends StatelessWidget {
  final String label;
  final int score;
  final Color color;

  const _ScoreBar({required this.label, required this.score, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontFamily: 'Nunito', fontSize: 14)),
              Text('$score/100',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: color, fontFamily: 'Nunito')),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: score / 100,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 10,
            ),
          ),
        ],
      ),
    );
  }
}
