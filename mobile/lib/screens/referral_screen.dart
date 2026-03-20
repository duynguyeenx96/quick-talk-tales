import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  String? _referralCode;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiService.getMyReferralCode();
      if (mounted) setState(() { _referralCode = data['referralCode'] as String?; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
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
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(icon: const Icon(Icons.arrow_back_ios_new), onPressed: () => Navigator.pop(context)),
                    const Expanded(
                      child: Text('🎁 Invite Friends',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Nunito', color: AppTheme.primaryGreen)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            const Text('🎉', style: TextStyle(fontSize: 72)).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                            const SizedBox(height: 16),
                            const Text('Invite Friends, Earn Premium!',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Nunito', color: AppTheme.textPrimary))
                                .animate().fadeIn(delay: 200.ms),
                            const SizedBox(height: 12),
                            const Text('Share your code with friends.\nWhen they sign up, you both get rewarded!',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppTheme.textSecondary, fontFamily: 'Nunito', fontSize: 15))
                                .animate().fadeIn(delay: 300.ms),
                            const SizedBox(height: 32),
                            // Rewards row
                            Row(
                              children: [
                                Expanded(
                                  child: _rewardCard('You get', '⭐ +3 Days\nPremium', AppGradients.orangeGradient),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _rewardCard('Friend gets', '🎁 +1 Day\nPremium', AppGradients.blueGradient),
                                ),
                              ],
                            ).animate().fadeIn(delay: 400.ms),
                            const SizedBox(height: 32),
                            // Code card
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 6))],
                              ),
                              child: Column(
                                children: [
                                  const Text('Your Referral Code', style: TextStyle(color: AppTheme.textSecondary, fontFamily: 'Nunito')),
                                  const SizedBox(height: 12),
                                  Text(
                                    _referralCode ?? '--------',
                                    style: const TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Nunito',
                                      color: AppTheme.primaryGreen,
                                      letterSpacing: 6,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          icon: const Icon(Icons.copy, size: 18),
                                          label: const Text('Copy', style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.bold)),
                                          onPressed: () {
                                            Clipboard.setData(ClipboardData(text: _referralCode ?? ''));
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Code copied! 📋')),
                                            );
                                          },
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: AppTheme.primaryGreen,
                                            side: const BorderSide(color: AppTheme.primaryGreen),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          icon: const Icon(Icons.share, size: 18),
                                          label: const Text('Share', style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.bold)),
                                          onPressed: () => Share.share(
                                            '🎉 Join me on Quick Talk Tales! Use my code "${_referralCode}" when signing up to get 1 free day of Premium! 🚀',
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppTheme.primaryGreen,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rewardCard(String title, String reward, LinearGradient gradient) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Text(title, style: TextStyle(color: Colors.white.withOpacity(0.85), fontFamily: 'Nunito', fontSize: 12)),
          const SizedBox(height: 6),
          Text(reward, textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Nunito', fontSize: 16)),
        ],
      ),
    );
  }
}
