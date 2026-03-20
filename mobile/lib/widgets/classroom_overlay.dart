import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/classroom_provider.dart';
import '../providers/auth_provider.dart';
import '../screens/classroom_screen.dart';
import '../theme/app_theme.dart';
import 'premium_upgrade_dialog.dart';

/// Floating overlay that appears over any screen when a classroom session is
/// within 5 minutes of starting (or already active and user hasn't joined).
class ClassroomOverlay extends StatelessWidget {
  final Widget child;
  const ClassroomOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer<ClassroomProvider>(
      builder: (context, classroom, _) {
        final session = classroom.currentSession;
        final show = classroom.shouldShowOverlay;

        return Stack(
          children: [
            child,
            if (show && session != null)
              Positioned(
                bottom: 80, // above bottom nav bar
                left: 16,
                right: 16,
                child: _ClassroomBanner(session: session),
              ),
          ],
        );
      },
    );
  }
}

class _ClassroomBanner extends StatelessWidget {
  final ClassroomSessionInfo session;
  const _ClassroomBanner({required this.session});

  @override
  Widget build(BuildContext context) {
    final isActive = session.status == ClassroomSessionStatus.active;
    final isPremium = context.read<AuthProvider>().subscriptionPlan == 'premium';

    return Material(
      elevation: 12,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isActive
                ? [const Color(0xFF1CB0F6), const Color(0xFF2196F3)]
                : [const Color(0xFFFF9600), const Color(0xFFFF6D00)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isActive ? Icons.class_rounded : Icons.access_time_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isActive ? 'Classroom is LIVE!' : 'Classroom in ${session.minutesUntilStart} min',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      fontFamily: 'Nunito',
                    ),
                  ),
                  Text(
                    '${session.participantCount} players · ${session.wordCount} words',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontFamily: 'Nunito',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Dismiss
            GestureDetector(
              onTap: () => context.read<ClassroomProvider>().dismissOverlay(),
              child: const Icon(Icons.close, color: Colors.white70, size: 18),
            ),
            const SizedBox(width: 8),
            // Join button
            ElevatedButton(
              onPressed: () => _onJoin(context, isPremium),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: isActive ? AppTheme.secondaryBlue : AppTheme.accentOrange,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Nunito',
                  fontSize: 13,
                ),
              ),
              child: const Text('Join'),
            ),
          ],
        ),
      ),
    ).animate().slideY(begin: 1.5, duration: 400.ms, curve: Curves.easeOutBack).fadeIn(duration: 300.ms);
  }

  Future<void> _onJoin(BuildContext context, bool isPremium) async {
    final classroom = context.read<ClassroomProvider>();
    final session = classroom.currentSession;
    if (session == null) return;

    // Capture navigator BEFORE any async gap so context stays valid
    final navigator = Navigator.of(context, rootNavigator: true);
    final messenger = ScaffoldMessenger.of(context);

    final ok = await classroom.joinSession(session.id);

    // Dismiss after join attempt regardless of result
    classroom.dismissOverlay();

    if (!ok) {
      final err = classroom.error ?? '';
      if (err.toLowerCase().contains('premium') || err.toLowerCase().contains('limit')) {
        navigator.push(MaterialPageRoute(
          builder: (_) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.class_rounded, size: 48, color: Color(0xFFFFA000)),
                const SizedBox(height: 16),
                const Text('Unlimited Classroom Access',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Nunito')),
                const SizedBox(height: 10),
                Text('Free users can join 1 classroom session per day.\nUpgrade to Premium for unlimited access.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontFamily: 'Nunito')),
              ]),
            ),
          ),
        ));
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(err.isNotEmpty ? err : 'Failed to join session'),
              backgroundColor: AppTheme.accentPink),
        );
      }
      return;
    }

    // Joined successfully — navigate to classroom screen
    final refreshed = classroom.currentSession;
    if (refreshed != null) {
      navigator.push(MaterialPageRoute(builder: (_) => ClassroomScreen(session: refreshed)));
    }
  }
}
