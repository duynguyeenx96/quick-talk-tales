import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  const EmailVerificationScreen({super.key, required this.email});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _resending = false;
  bool _resent = false;
  int _cooldown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _resend() async {
    setState(() { _resending = true; });
    try {
      await ApiService.resendVerification();
      if (mounted) {
        setState(() { _resending = false; _resent = true; _cooldown = 60; });
        _startCooldown();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _resending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to resend: $e'),
            backgroundColor: AppTheme.accentPink,
          ),
        );
      }
    }
  }

  void _startCooldown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        _cooldown--;
        if (_cooldown <= 0) { t.cancel(); _resent = false; }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                _buildIllustration()
                    .animate()
                    .scale(begin: const Offset(0.8, 0.8), duration: 600.ms, curve: Curves.elasticOut),
                const SizedBox(height: 32),
                _buildText(context)
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 200.ms),
                const Spacer(),
                _buildActions(context)
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 400.ms)
                    .slideY(begin: 0.3),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIllustration() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        gradient: AppGradients.blueGradient,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppTheme.secondaryBlue.withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: const Icon(Icons.mark_email_unread_outlined, color: Colors.white, size: 60),
    );
  }

  Widget _buildText(BuildContext context) {
    return Column(
      children: [
        Text(
          'Check your inbox! ✉️',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: AppTheme.textSecondary, height: 1.6),
            children: [
              const TextSpan(text: "We sent a verification link to\n"),
              TextSpan(
                text: widget.email,
                style: const TextStyle(
                  color: AppTheme.secondaryBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const TextSpan(text: "\n\nClick the link to activate your account. The link expires in 24 hours."),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.accentOrange.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.accentOrange.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              const Text('💡', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Using Gmail? Check Spam or Promotions folder if you don\'t see it.',
                  style: TextStyle(
                    color: AppTheme.accentOrange,
                    fontSize: 13,
                    fontFamily: 'Nunito',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        if (_resent) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '✅ Verification email resent! Check your inbox.',
              style: TextStyle(
                  color: AppTheme.primaryGreen, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
        ],
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: (_resending || _cooldown > 0) ? null : _resend,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: AppTheme.secondaryBlue.withOpacity(0.5)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
            ),
            child: _resending
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    _cooldown > 0
                        ? 'Resend in ${_cooldown}s'
                        : '📧  Resend Verification Email',
                    style: const TextStyle(
                      color: AppTheme.secondaryBlue,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Nunito',
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () async {
            // Clear auth so user can re-login (already has account, just needs to verify)
            await context.read<AuthProvider>().logout();
            if (context.mounted) {
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
          },
          child: const Text(
            'Already verified? Sign in',
            style: TextStyle(
              color: AppTheme.primaryGreen,
              fontWeight: FontWeight.bold,
              fontFamily: 'Nunito',
            ),
          ),
        ),
      ],
    );
  }
}
