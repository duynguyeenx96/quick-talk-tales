import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

class SpeechTextField extends StatefulWidget {
  final String text;
  final bool isListening;
  final bool isProcessing;
  final double confidence;

  const SpeechTextField({
    super.key,
    required this.text,
    required this.isListening,
    required this.isProcessing,
    required this.confidence,
  });

  @override
  State<SpeechTextField> createState() => _SpeechTextFieldState();
}

class _SpeechTextFieldState extends State<SpeechTextField>
    with TickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _shimmerAnimation = Tween<double>(
      begin: -2,
      end: 2,
    ).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.linear),
    );
  }

  @override
  void didUpdateWidget(SpeechTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Update text controller
    if (widget.text != oldWidget.text) {
      _textController.text = widget.text;
    }
    
    // Control shimmer animation
    if (widget.isListening && !oldWidget.isListening) {
      _shimmerController.repeat();
    } else if (!widget.isListening && oldWidget.isListening) {
      _shimmerController.stop();
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.white.withOpacity(0.9),
              ],
            ),
            border: Border.all(
              color: _getBorderColor(),
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status
              _buildHeader(),
              
              const SizedBox(height: 16),
              
              // Text content area
              Expanded(
                child: _buildTextArea(),
              ),
              
              // Confidence indicator
              if (widget.text.isNotEmpty && widget.confidence > 0)
                _buildConfidenceIndicator(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    IconData icon = Icons.text_fields;
    String title = 'Your Story';
    Color iconColor = AppTheme.textSecondary;

    if (widget.isListening) {
      icon = Icons.mic;
      title = 'Listening...';
      iconColor = AppTheme.primaryGreen;
    } else if (widget.isProcessing) {
      icon = Icons.hourglass_empty;
      title = 'Processing...';
      iconColor = AppTheme.secondaryBlue;
    } else if (widget.text.isNotEmpty) {
      icon = Icons.check_circle;
      title = 'Story Complete!';
      iconColor = AppTheme.accentPink;
    }

    return Row(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Icon(
            icon,
            key: ValueKey(icon),
            color: iconColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              title,
              key: ValueKey(title),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: iconColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        
        // Word count
        if (widget.text.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${widget.text.split(' ').length} words',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.primaryGreen,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTextArea() {
    if (widget.text.isEmpty && !widget.isListening && !widget.isProcessing) {
      return _buildPlaceholder();
    }

    return SingleChildScrollView(
      child: widget.isListening 
          ? _buildListeningAnimation()
          : widget.isProcessing
              ? _buildProcessingAnimation()
              : _buildTextContent(),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.backgroundLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.auto_stories_outlined,
              size: 48,
              color: AppTheme.textSecondary.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Your story will appear here...',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.textSecondary.withOpacity(0.7),
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the microphone to start!',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListeningAnimation() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Pulsing microphone icon
          AnimatedBuilder(
            animation: _shimmerController,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (_shimmerAnimation.value.abs() * 0.1),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mic,
                    color: AppTheme.primaryGreen,
                    size: 40,
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 20),
          
          // Animated dots
          DefaultTextStyle(
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
              color: AppTheme.primaryGreen,
              fontWeight: FontWeight.w600,
            ),
            child: AnimatedTextKit(
              animatedTexts: [
                WavyAnimatedText('Listening'),
              ],
              repeatForever: true,
            ),
          ),
          
          // Live transcription if available
          if (widget.text.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.backgroundLight.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProcessingAnimation() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Spinning loading indicator
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.secondaryBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.secondaryBlue),
            ),
          ),
          
          const SizedBox(height: 20),
          
          DefaultTextStyle(
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
              color: AppTheme.secondaryBlue,
              fontWeight: FontWeight.w600,
            ),
            child: AnimatedTextKit(
              animatedTexts: [
                TyperAnimatedText(
                  'Processing your story...',
                  speed: const Duration(milliseconds: 100),
                ),
              ],
              repeatForever: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextContent() {
    return SelectableText(
      widget.text,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        height: 1.6,
        color: AppTheme.textPrimary,
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms)
        .slideY(begin: 0.3, end: 0);
  }

  Widget _buildConfidenceIndicator() {
    return Column(
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            const Icon(
              Icons.sentiment_satisfied,
              color: AppTheme.primaryGreen,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              'Confidence: ${(widget.confidence * 100).toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.primaryGreen,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: LinearProgressIndicator(
                value: widget.confidence,
                backgroundColor: AppTheme.primaryGreen.withOpacity(0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getBorderColor() {
    if (widget.isListening) {
      return AppTheme.primaryGreen;
    } else if (widget.isProcessing) {
      return AppTheme.secondaryBlue;
    } else if (widget.text.isNotEmpty) {
      return AppTheme.accentPink;
    }
    return Colors.transparent;
  }
}