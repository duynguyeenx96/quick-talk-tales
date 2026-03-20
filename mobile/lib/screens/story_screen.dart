import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/speech_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/microphone_button.dart';
import '../widgets/speech_text_field.dart';
import '../widgets/story_header.dart';

class StoryScreen extends StatefulWidget {
  const StoryScreen({super.key});

  @override
  State<StoryScreen> createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    // Initialize speech provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SpeechProvider>().initialize();
    });
    
    _fadeController.forward();
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<SpeechProvider>(
        builder: (context, speechProvider, child) {
          // Control pulse animation based on speech state
          if (speechProvider.isListening) {
            _pulseController.repeat();
          } else {
            _pulseController.stop();
          }
          
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFF8FBFF),
                  Color(0xFFE8F4FD),
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    // Header
                    const SizedBox(height: 20),
                    const StoryHeader()
                        .animate()
                        .fadeIn(duration: 600.ms)
                        .slideY(begin: -0.3, end: 0),
                    
                    const SizedBox(height: 40),
                    
                    // Main content area
                    Expanded(
                      child: Column(
                        children: [
                          // Instruction text
                          _buildInstructionText(speechProvider),
                          
                          const SizedBox(height: 30),
                          
                          // Speech text field
                          Expanded(
                            flex: 2,
                            child: SpeechTextField(
                              text: speechProvider.transcribedText,
                              isListening: speechProvider.isListening,
                              isProcessing: speechProvider.isProcessing,
                              confidence: speechProvider.confidence,
                            ),
                          ),
                          
                          const SizedBox(height: 40),
                          
                          // Microphone button area
                          Expanded(
                            flex: 1,
                            child: Center(
                              child: MicrophoneButton(
                                isListening: speechProvider.isListening,
                                isProcessing: speechProvider.isProcessing,
                                isConnected: speechProvider.isConnected,
                                onPressed: () => _toggleSpeechRecognition(speechProvider),
                                animationController: _pulseController,
                              ),
                            ),
                          ),
                          
                          // Status and controls
                          const SizedBox(height: 20),
                          _buildStatusArea(speechProvider),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildInstructionText(SpeechProvider speechProvider) {
    String instruction = 'Tap the microphone and tell your story!';
    Color textColor = AppTheme.textSecondary;
    
    if (speechProvider.isListening) {
      instruction = 'Listening... Speak now!';
      textColor = AppTheme.primaryGreen;
    } else if (speechProvider.isProcessing) {
      instruction = 'Processing your story...';
      textColor = AppTheme.secondaryBlue;
    } else if (speechProvider.transcribedText.isNotEmpty) {
      instruction = 'Great story! Want to tell another?';
      textColor = AppTheme.accentPink;
    }
    
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Text(
        instruction,
        key: ValueKey(instruction),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
  
  Widget _buildStatusArea(SpeechProvider speechProvider) {
    return Column(
      children: [
        // Connection status
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: speechProvider.isConnected 
                    ? AppTheme.primaryGreen 
                    : AppTheme.accentPink,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              speechProvider.isConnected ? 'Connected' : 'Disconnected',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: speechProvider.isConnected 
                    ? AppTheme.primaryGreen 
                    : AppTheme.accentPink,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Action buttons
        if (speechProvider.transcribedText.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Clear button
              ElevatedButton.icon(
                onPressed: speechProvider.clearText,
                icon: const Icon(Icons.clear, size: 18),
                label: const Text('Clear'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.textSecondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
              ),
              
              // Share/Continue button
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Implement story submission
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Story submitted! 🎉'),
                      backgroundColor: AppTheme.primaryGreen,
                    ),
                  );
                },
                icon: const Icon(Icons.send, size: 18),
                label: const Text('Submit Story'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
              ),
            ],
          ),
        ],
        
        // Error message
        if (speechProvider.state == SpeechState.error) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.accentPink.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.accentPink.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: AppTheme.accentPink,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    speechProvider.errorMessage,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.accentPink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
  
  void _toggleSpeechRecognition(SpeechProvider speechProvider) {
    if (speechProvider.isListening) {
      speechProvider.stopListening();
    } else {
      speechProvider.startListening(
        challengeId: 'story_${DateTime.now().millisecondsSinceEpoch}',
      );
    }
  }
}