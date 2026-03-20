import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../providers/speech_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/microphone_button.dart';
import 'result_screen.dart';

class StoryInputScreen extends StatefulWidget {
  const StoryInputScreen({super.key});

  @override
  State<StoryInputScreen> createState() => _StoryInputScreenState();
}

class _StoryInputScreenState extends State<StoryInputScreen>
    with TickerProviderStateMixin {
  final _storyCtrl = TextEditingController();
  late AnimationController _pulseController;
  bool _useVoice = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SpeechProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _storyCtrl.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final words = game.words;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tell Your Story'),
        actions: [
          // Toggle text/voice mode
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: () => setState(() => _useVoice = !_useVoice),
              icon: Icon(_useVoice ? Icons.keyboard : Icons.mic),
              label: Text(_useVoice ? 'Type' : 'Voice'),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8FBFF), Color(0xFFE8F4FD)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Word reminder bar
                _buildWordBar(words).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2),
                const SizedBox(height: 20),

                // Input area
                Expanded(
                  child: _useVoice
                      ? _buildVoiceInput()
                      : _buildTextInput(),
                ),

                const SizedBox(height: 16),
                _buildSubmitButton(game),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWordBar(List<WordItem> words) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Use these words 👇',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: words.map((w) {
              final used = _storyCtrl.text
                  .toLowerCase()
                  .contains(w.text.toLowerCase());
              return Chip(
                label: Text(w.text,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: used ? Colors.white : AppTheme.primaryGreen,
                      fontSize: 13,
                    )),
                backgroundColor:
                    used ? AppTheme.primaryGreen : AppTheme.primaryGreen.withOpacity(0.1),
                side: BorderSide(
                    color: AppTheme.primaryGreen.withOpacity(0.4), width: 1.5),
                padding: const EdgeInsets.symmetric(horizontal: 4),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTextInput() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: _storyCtrl,
          maxLines: null,
          expands: true,
          textAlignVertical: TextAlignVertical.top,
          style: const TextStyle(fontSize: 17, height: 1.6, fontFamily: 'Nunito'),
          decoration: const InputDecoration(
            border: InputBorder.none,
            hintText: 'Once upon a time...',
            hintStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 17),
          ),
          onChanged: (_) => setState(() {}), // refresh chip colours
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 100.ms);
  }

  Widget _buildVoiceInput() {
    return Consumer<SpeechProvider>(
      builder: (context, speech, _) {
        // Sync voice transcription to text controller
        if (speech.transcribedText.isNotEmpty &&
            _storyCtrl.text != speech.transcribedText) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() => _storyCtrl.text = speech.transcribedText);
          });
        }

        if (speech.isListening) {
          _pulseController.repeat();
        } else {
          _pulseController.stop();
          _pulseController.reset();
        }

        final hasText = _storyCtrl.text.isNotEmpty;
        final isEditing = hasText && !speech.isListening;

        return Column(
          children: [
            // Status + mic row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                MicrophoneButton(
                  isListening: speech.isListening,
                  isProcessing: speech.isProcessing,
                  isConnected: speech.isConnected,
                  onPressed: () {
                    if (speech.isListening) {
                      speech.stopListening();
                    } else {
                      speech.startListening();
                    }
                  },
                  animationController: _pulseController,
                ),
                if (hasText && !speech.isListening) ...[
                  const SizedBox(width: 12),
                  // Clear & re-record button
                  IconButton(
                    onPressed: () {
                      setState(() => _storyCtrl.clear());
                      speech.reset();
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: 'Record again',
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.accentPink.withOpacity(0.1),
                      foregroundColor: AppTheme.accentPink,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Text(
              speech.isListening
                  ? '🎙 Listening...'
                  : isEditing
                      ? '✏️ Edit your story below, then submit!'
                      : 'Tap the mic and tell your story!',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // Editable text area shown after transcription
            if (hasText)
              Expanded(
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: _storyCtrl,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      style: const TextStyle(fontSize: 16, height: 1.6, fontFamily: 'Nunito'),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Edit your story here...',
                        hintStyle: TextStyle(color: AppTheme.textSecondary),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ),
              )
            else
              const Spacer(),
          ],
        );
      },
    );
  }

  Widget _buildSubmitButton(GameProvider game) {
    final isSubmitting = game.state == GameState.submitting;
    final hasText = _storyCtrl.text.trim().length >= 20;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (hasText && !isSubmitting) ? () => _submit(game) : null,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          backgroundColor: hasText ? AppTheme.accentPink : Colors.grey.shade300,
        ),
        child: isSubmitting
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
              )
            : Text(
                hasText ? '🚀  Submit Story!' : 'Write at least a few sentences...',
                style: TextStyle(
                  fontSize: 18,
                  color: hasText ? Colors.white : AppTheme.textSecondary,
                ),
              ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 300.ms);
  }

  Future<void> _submit(GameProvider game) async {
    final result = await game.submitStory(_storyCtrl.text.trim());
    if (result != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ResultScreen()),
      );
    } else if (mounted && game.error.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(game.error), backgroundColor: AppTheme.accentPink),
      );
    }
  }
}
