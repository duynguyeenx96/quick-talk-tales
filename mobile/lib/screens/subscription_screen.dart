import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'payment_screen.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  List<Map<String, dynamic>> _plans = [];
  bool _loading = true;
  String _selectedPlan = 'monthly'; // 'monthly' | 'yearly'

  @override
  void initState() {
    super.initState();
    _loadPlans();
    // Always fetch fresh profile so subscription status reflects server state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().refreshProfile();
    });
  }

  Future<void> _loadPlans() async {
    try {
      final plans = await ApiService.getSubscriptionPlans();
      if (mounted) setState(() { _plans = plans; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _goToPayment() {
    final planId = _selectedPlan == 'monthly' ? 'premium_monthly' : 'premium_yearly';
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PaymentScreen(planId: planId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = context.watch<AuthProvider>().user?['subscriptionPlan'] == 'premium';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFDE7), Color(0xFFF8FBFF)],
          ),
        ),
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : CustomScrollView(
                  slivers: [
                    _buildAppBar(context),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            if (isPremium)
                              _buildAlreadyPremium(context)
                                  .animate()
                                  .fadeIn(duration: 400.ms)
                            else ...[
                              _buildHero(context)
                                  .animate()
                                  .fadeIn(duration: 400.ms),
                              const SizedBox(height: 24),
                              _buildBillingToggle()
                                  .animate()
                                  .fadeIn(duration: 400.ms, delay: 100.ms),
                              const SizedBox(height: 24),
                              _buildPlanCards(context)
                                  .animate()
                                  .fadeIn(duration: 400.ms, delay: 200.ms),
                              const SizedBox(height: 24),
                              _buildFeatureComparison(context)
                                  .animate()
                                  .fadeIn(duration: 400.ms, delay: 300.ms),
                              const SizedBox(height: 24),
                              _buildCta(context)
                                  .animate()
                                  .fadeIn(duration: 400.ms, delay: 400.ms)
                                  .slideY(begin: 0.2),
                              const SizedBox(height: 12),
                              _buildPaymentNote()
                                  .animate()
                                  .fadeIn(duration: 400.ms, delay: 500.ms),
                            ],
                            const SizedBox(height: 32),
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

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        '⭐ Premium',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.accentOrange,
              fontWeight: FontWeight.bold,
            ),
      ),
      floating: true,
    );
  }

  Widget _buildAlreadyPremium(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: AppGradients.orangeGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentOrange.withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text('⭐', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          const Text(
            'You\'re already Premium!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontFamily: 'Nunito',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Enjoy unlimited stories, all difficulties, and detailed AI feedback.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontFamily: 'Nunito',
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    return Column(
      children: [
        const Text('✨', style: TextStyle(fontSize: 56)),
        const SizedBox(height: 12),
        Text(
          'Unlock Everything',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Unlimited stories, hard difficulty,\nfull AI feedback — zero limits.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBillingToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _toggleOption('monthly', 'Monthly', null),
          _toggleOption('yearly', 'Yearly', '🔥 Save 40%'),
        ],
      ),
    );
  }

  Widget _toggleOption(String key, String label, String? badge) {
    final selected = _selectedPlan == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPlan = key),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: selected ? AppTheme.textPrimary : AppTheme.textSecondary,
                  fontFamily: 'Nunito',
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 6),
                Text(badge,
                    style: const TextStyle(
                        fontSize: 11, fontFamily: 'Nunito', color: AppTheme.accentPink)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCards(BuildContext context) {
    final monthlyPrice = 4.99;
    final yearlyPrice = 2.99; // per month
    final price = _selectedPlan == 'monthly' ? monthlyPrice : yearlyPrice;
    final period = _selectedPlan == 'monthly' ? '/month' : '/month (billed yearly)';

    return Row(
      children: [
        // Free card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🆓', style: TextStyle(fontSize: 28)),
                const SizedBox(height: 8),
                const Text('Free',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        fontFamily: 'Nunito')),
                const SizedBox(height: 4),
                Text('\$0',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textSecondary,
                        fontFamily: 'Nunito')),
                Text('forever',
                    style:
                        TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontFamily: 'Nunito')),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Premium card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppGradients.orangeGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentOrange.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('⭐', style: TextStyle(fontSize: 28)),
                const SizedBox(height: 8),
                const Text('Premium',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        fontFamily: 'Nunito',
                        color: Colors.white)),
                const SizedBox(height: 4),
                Text('\$$price',
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Nunito')),
                Text(period,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 11,
                        fontFamily: 'Nunito')),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureComparison(BuildContext context) {
    final features = [
      ('Stories per day', '3', 'Unlimited'),
      ('Difficulty', 'Easy/Medium', 'All + Hard ⚡'),
      ('AI Feedback', 'Basic', 'Detailed'),
      ('Story History', 'Last 20', 'Full history'),
      ('Leaderboard badge', '—', '🏆 Yes'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Expanded(child: SizedBox()),
                Expanded(
                    child: Text('Free',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textSecondary,
                            fontFamily: 'Nunito'))),
                Expanded(
                    child: Text('Premium',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.accentOrange,
                            fontFamily: 'Nunito'))),
              ],
            ),
          ),
          const Divider(height: 1),
          ...features.asMap().entries.map((entry) {
            final i = entry.key;
            final f = entry.value;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                          child: Text(f.$1,
                              style: const TextStyle(fontFamily: 'Nunito', fontSize: 13))),
                      Expanded(
                          child: Text(f.$2,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 13,
                                  color: AppTheme.textSecondary))),
                      Expanded(
                          child: Text(f.$3,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 13,
                                  color: AppTheme.accentOrange,
                                  fontWeight: FontWeight.w600))),
                    ],
                  ),
                ),
                if (i < features.length - 1)
                  const Divider(height: 1, indent: 16, endIndent: 16),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCta(BuildContext context) {
    final priceLabel = _selectedPlan == 'monthly' ? '59.000 VND/tháng' : '499.000 VND/năm';
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _goToPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.accentOrange,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shadowColor: AppTheme.accentOrange.withOpacity(0.4),
          elevation: 6,
        ),
        child: Text(
          '⭐  Upgrade to Premium — $priceLabel',
          style: const TextStyle(fontSize: 16, fontFamily: 'Nunito'),
        ),
      ),
    );
  }

  Widget _buildPaymentNote() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Text('🏦', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Pay via bank transfer (VietQR). Your account upgrades automatically after payment is confirmed.',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontFamily: 'Nunito',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
