import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import '../theme/app_theme.dart';

class StoryHeader extends StatelessWidget {
  const StoryHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // App title with animated text
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo/Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: AppGradients.primaryGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_stories,
                color: Colors.white,
                size: 28,
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Animated title
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DefaultTextStyle(
                  style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                  child: AnimatedTextKit(
                    animatedTexts: [
                      TyperAnimatedText(
                        'Quick Talk Tales',
                        speed: const Duration(milliseconds: 100),
                      ),
                    ],
                    totalRepeatCount: 1,
                    displayFullTextOnTap: true,
                  ),
                ),
                
                const SizedBox(height: 4),
                
                Text(
                  'Create magical stories with your voice',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Fun instruction with emoji
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.secondaryBlue.withOpacity(0.1),
                AppTheme.accentPurple.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.secondaryBlue.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎤', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                'Tell me a story using these words!',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              const Text('✨', style: TextStyle(fontSize: 20)),
            ],
          ),
        ),
      ],
    );
  }
}