import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';
import 'story_input_screen.dart';

class WordsScreen extends StatefulWidget {
  const WordsScreen({super.key});

  @override
  State<WordsScreen> createState() => _WordsScreenState();
}

class _WordsScreenState extends State<WordsScreen> {
  static const _studySeconds = 30;
  int _secondsLeft = _studySeconds;
  Timer? _timer;
  bool _canSkip = false;

  @override
  void initState() {
    super.initState();
    // Allow skip after 5 seconds; auto-navigate at 0
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        _secondsLeft--;
        if (_secondsLeft <= _studySeconds - 5) _canSkip = true;
        if (_secondsLeft <= 0) {
          t.cancel();
          _goToStoryInput();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _goToStoryInput() {
    _timer?.cancel();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const StoryInputScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final words = game.words;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF8E8), Color(0xFFFFEDD5)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildTimer(),
                const SizedBox(height: 24),
                _buildTitle(context),
                const SizedBox(height: 32),
                Expanded(child: _buildWordGrid(words)),
                const SizedBox(height: 24),
                _buildStartButton(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimer() {
    final progress = _secondsLeft / _studySeconds;
    final color = _secondsLeft > 10
        ? AppTheme.primaryGreen
        : _secondsLeft > 5
            ? AppTheme.accentOrange
            : AppTheme.accentPink;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 60,
          height: 60,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.shade200,
                color: color,
                strokeWidth: 5,
              ),
              Text(
                '$_secondsLeft',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontFamily: 'Nunito',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Memorise your words!',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildTitle(BuildContext context) {
    return Column(
      children: [
        Text(
          '🎯 Your Story Words',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.accentOrange,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Use ALL these words in your story!',
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(color: AppTheme.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    ).animate().fadeIn(duration: 400.ms, delay: 100.ms);
  }

  Widget _buildWordGrid(List<WordItem> words) {
    final colors = [
      AppTheme.primaryGreen,
      AppTheme.secondaryBlue,
      AppTheme.accentPink,
      AppTheme.accentOrange,
      AppTheme.accentPurple,
      AppTheme.primaryGreen,
      AppTheme.secondaryBlue,
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: words.asMap().entries.map((entry) {
        final i = entry.key;
        final word = entry.value;
        final color = colors[i % colors.length];

        return _WordChip(word: word, color: color, index: i);
      }).toList(),
    );
  }

  Widget _buildStartButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _canSkip ? _goToStoryInput : null,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          backgroundColor: _canSkip ? AppTheme.accentOrange : Colors.grey.shade300,
        ),
        child: Text(
          _canSkip ? '✏️  I\'m Ready! Start Writing' : 'Study your words... ($_secondsLeft s)',
          style: TextStyle(
            fontSize: 18,
            color: _canSkip ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 400.ms);
  }
}

class _WordChip extends StatelessWidget {
  final WordItem word;
  final Color color;
  final int index;

  const _WordChip({required this.word, required this.color, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            word.text,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'Nunito',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            word.category,
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
              fontFamily: 'Nunito',
            ),
          ),
        ],
      ),
    )
        .animate(delay: (index * 80).ms)
        .fadeIn(duration: 400.ms)
        .scale(begin: const Offset(0.8, 0.8));
  }
}
