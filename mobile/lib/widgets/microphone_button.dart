import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

class MicrophoneButton extends StatefulWidget {
  final bool isListening;
  final bool isProcessing;
  final bool isConnected;
  final VoidCallback onPressed;
  final AnimationController animationController;

  const MicrophoneButton({
    super.key,
    required this.isListening,
    required this.isProcessing,
    required this.isConnected,
    required this.onPressed,
    required this.animationController,
  });

  @override
  State<MicrophoneButton> createState() => _MicrophoneButtonState();
}

class _MicrophoneButtonState extends State<MicrophoneButton>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _rotationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(
      CurvedAnimation(parent: widget.animationController, curve: Curves.easeInOut),
    );
  }
  
  @override
  void didUpdateWidget(MicrophoneButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isProcessing && !oldWidget.isProcessing) {
      _rotationController.repeat();
    } else if (!widget.isProcessing && oldWidget.isProcessing) {
      _rotationController.stop();
      _rotationController.reset();
    }
  }
  
  @override
  void dispose() {
    _scaleController.dispose();
    _rotationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) => _scaleController.reverse(),
      onTapCancel: () => _scaleController.reverse(),
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: Listenable.merge([_scaleAnimation, _pulseAnimation]),
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value * 
                  (widget.isListening ? _pulseAnimation.value : 1.0),
            child: _buildButton(),
          );
        },
      ),
    );
  }
  
  Widget _buildButton() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer pulse rings (when listening)
        if (widget.isListening) ...[
          _buildPulseRing(120, 0.1, 0.6),
          _buildPulseRing(140, 0.05, 0.4),
          _buildPulseRing(160, 0.02, 0.2),
        ],
        
        // Main button container
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: _getButtonGradient(),
            boxShadow: [
              BoxShadow(
                color: _getButtonColor().withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: _getButtonColor().withOpacity(0.2),
                blurRadius: 40,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: _buildButtonContent(),
        ),
        
        // Connection status indicator
        if (!widget.isConnected)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: AppTheme.accentPink,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.cloud_off,
                color: Colors.white,
                size: 10,
              ),
            ),
          ),
      ],
    );
  }
  
  Widget _buildPulseRing(double size, double opacity, double delay) {
    return AnimatedBuilder(
      animation: widget.animationController,
      builder: (context, child) {
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppTheme.primaryGreen.withOpacity(
                opacity * (1.0 - widget.animationController.value),
              ),
              width: 2,
            ),
          ),
        );
      },
    )
        .animate(delay: (delay * 1000).ms)
        .scaleXY(begin: 0.8, end: 1.0, duration: 1500.ms)
        .fadeIn(duration: 300.ms)
        .then()
        .fadeOut(duration: 300.ms);
  }
  
  Widget _buildButtonContent() {
    IconData icon;
    double iconSize = 36;
    
    if (widget.isProcessing) {
      icon = Icons.hourglass_empty;
    } else if (widget.isListening) {
      icon = Icons.stop;
      iconSize = 32;
    } else {
      icon = Icons.mic;
    }
    
    return AnimatedBuilder(
      animation: _rotationController,
      builder: (context, child) {
        return Transform.rotate(
          angle: widget.isProcessing ? _rotationController.value * 2 * 3.14159 : 0,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Icon(
              icon,
              key: ValueKey(icon),
              color: Colors.white,
              size: iconSize,
            ),
          ),
        );
      },
    );
  }
  
  LinearGradient _getButtonGradient() {
    if (widget.isListening) {
      return const LinearGradient(
        colors: [
          Color(0xFFFF6B6B),
          Color(0xFFEE5A24),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (widget.isProcessing) {
      return AppGradients.blueGradient;
    } else if (!widget.isConnected) {
      return const LinearGradient(
        colors: [
          AppTheme.textSecondary,
          Color(0xFF666666),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    return AppGradients.primaryGradient;
  }
  
  Color _getButtonColor() {
    if (widget.isListening) {
      return const Color(0xFFFF6B6B);
    } else if (widget.isProcessing) {
      return AppTheme.secondaryBlue;
    } else if (!widget.isConnected) {
      return AppTheme.textSecondary;
    }
    return AppTheme.primaryGreen;
  }
}