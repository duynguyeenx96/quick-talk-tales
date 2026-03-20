import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../theme/app_theme.dart';

class ShareCardWidget {
  static Future<void> share({
    required BuildContext context,
    required String displayName,
    required String avatarUrl,
    required int streak,
    int? score,
    int? challengesCompleted,
    int? totalChallenges,
  }) async {
    final key = GlobalKey();
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => Positioned(
        left: -9999,
        top: -9999,
        child: Material(
          child: RepaintBoundary(
            key: key,
            child: _ShareCard(
              displayName: displayName,
              avatarUrl: avatarUrl,
              streak: streak,
              score: score,
              challengesCompleted: challengesCompleted,
              totalChallenges: totalChallenges,
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(entry);
    await Future.delayed(const Duration(milliseconds: 200));

    try {
      final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/achievement_card.png');
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: '🎉 Check out my progress on Quick Talk Tales!',
      );
    } finally {
      entry.remove();
    }
  }
}

class _ShareCard extends StatelessWidget {
  final String displayName;
  final String avatarUrl;
  final int streak;
  final int? score;
  final int? challengesCompleted;
  final int? totalChallenges;

  const _ShareCard({
    required this.displayName,
    required this.avatarUrl,
    required this.streak,
    this.score,
    this.challengesCompleted,
    this.totalChallenges,
  });

  @override
  Widget build(BuildContext context) {
    const List<String> kAvatarOptions = [
      '🐱', '🐶', '🐸', '🐻', '🦊', '🐼', '🐯', '🦁',
      '🐺', '🦄', '🐮', '🐷', '🐙', '🦋', '🐢', '🦖',
    ];
    final isEmoji = kAvatarOptions.contains(avatarUrl);

    return Container(
      width: 360,
      padding: const EdgeInsets.all(28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1CB0F6), Color(0xFF58CC02)],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '🎉 Quick Talk Tales',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 2,
            width: 120,
            color: Colors.white.withOpacity(0.4),
          ),
          const SizedBox(height: 20),
          // Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: Center(
              child: isEmoji
                  ? Text(avatarUrl, style: const TextStyle(fontSize: 40))
                  : Text(
                      displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            displayName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (streak > 0) ...[
                _StatBadge(icon: '🔥', label: '$streak days', subtitle: 'Streak'),
                const SizedBox(width: 16),
              ],
              if (score != null) ...[
                _StatBadge(icon: '⭐', label: '$score', subtitle: 'Score'),
                const SizedBox(width: 16),
              ],
              if (challengesCompleted != null && totalChallenges != null)
                _StatBadge(
                  icon: '🎯',
                  label: '$challengesCompleted/$totalChallenges',
                  subtitle: 'Daily',
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Play at: quicktalktalles.app',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String icon;
  final String label;
  final String subtitle;
  const _StatBadge({required this.icon, required this.label, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
