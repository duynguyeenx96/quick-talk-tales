import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class PaymentScreen extends StatefulWidget {
  /// 'premium_monthly' or 'premium_yearly'
  final String planId;

  const PaymentScreen({super.key, required this.planId});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  Map<String, dynamic>? _order;
  bool _loading = true;
  String _error = '';

  // Countdown
  Timer? _countdownTimer;
  Duration _remaining = Duration.zero;

  // Polling
  Timer? _pollTimer;
  String _status = 'pending'; // pending | completed | expired

  @override
  void initState() {
    super.initState();
    _createOrder();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _createOrder() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final order = await ApiService.createOrder(widget.planId);
      if (!mounted) return;
      setState(() {
        _order = order;
        _loading = false;
        _status = 'pending';
      });
      _startCountdown(order['expiresAt'] as String);
      _startPolling(order['orderId'] as String);
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _error = 'Cannot connect to server.'; _loading = false; });
    }
  }

  void _startCountdown(String expiresAtStr) {
    final expiresAt = DateTime.parse(expiresAtStr).toLocal();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final rem = expiresAt.difference(DateTime.now());
      if (!mounted) return;
      setState(() => _remaining = rem.isNegative ? Duration.zero : rem);
      if (rem.isNegative) _countdownTimer?.cancel();
    });
    _remaining = expiresAt.difference(DateTime.now());
  }

  void _startPolling(String orderId) {
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (_status != 'pending') { _pollTimer?.cancel(); return; }
      try {
        final res = await ApiService.getOrderStatus(orderId);
        final newStatus = res['status'] as String? ?? 'pending';
        if (!mounted) return;
        setState(() => _status = newStatus);
        if (newStatus == 'completed') {
          _pollTimer?.cancel();
          _countdownTimer?.cancel();
          // Refresh auth profile so subscriptionPlan updates
          await context.read<AuthProvider>().updateProfile();
          if (mounted) _showSuccessSheet();
        } else if (newStatus == 'expired') {
          _pollTimer?.cancel();
          _countdownTimer?.cancel();
        }
      } catch (_) {}
    });
  }

  void _showSuccessSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            const Text(
              'Payment Confirmed!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                fontFamily: 'Nunito',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'You now have access to all Premium features.',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontFamily: 'Nunito',
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // close sheet
                  Navigator.pop(context); // close payment screen
                  Navigator.pop(context); // close subscription screen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  '🚀  Start Exploring',
                  style: TextStyle(fontSize: 16, fontFamily: 'Nunito'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCountdown(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  int _formatVnd(int amount) => amount; // VND displayed as-is

  @override
  Widget build(BuildContext context) {
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
              : _error.isNotEmpty
                  ? _buildError()
                  : _buildContent(),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('😕', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              _error,
              style: const TextStyle(color: AppTheme.accentPink),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _createOrder, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final order = _order!;
    final amount = order['amount'] as int? ?? 0;
    final transferContent = order['transferContent'] as String? ?? '';
    final accountNumber = order['accountNumber'] as String? ?? '';
    final accountName = order['accountName'] as String? ?? '';
    final bankCode = order['bankCode'] as String? ?? '';
    final qrUrl = order['qrUrl'] as String? ?? '';

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            '💳 Bank Transfer',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.accentOrange,
                  fontWeight: FontWeight.bold,
                ),
          ),
          floating: true,
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            child: Column(
              children: [
                // Status banner
                if (_status == 'expired')
                  _buildBanner(
                    '⏰ Order expired',
                    'This order has expired.',
                    AppTheme.accentPink,
                  ).animate().fadeIn()
                else if (_status == 'completed')
                  _buildBanner(
                    '✅ Payment received!',
                    'Your account has been upgraded.',
                    AppTheme.primaryGreen,
                  ).animate().fadeIn()
                else ...[
                  // Countdown
                  _buildCountdown().animate().fadeIn(duration: 400.ms),
                  const SizedBox(height: 20),
                ],

                // QR code
                if (qrUrl.isNotEmpty)
                  _buildQrCard(qrUrl).animate().fadeIn(duration: 400.ms, delay: 100.ms),
                const SizedBox(height: 20),

                // Bank details
                _buildBankCard(
                  amount: amount,
                  bankCode: bankCode,
                  accountNumber: accountNumber,
                  accountName: accountName,
                  transferContent: transferContent,
                ).animate().fadeIn(duration: 400.ms, delay: 200.ms),

                if (_status == 'expired') ...[
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _createOrder,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentOrange,
                          padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: const Text('🔄  Generate New QR',
                          style: TextStyle(fontSize: 16, fontFamily: 'Nunito')),
                    ),
                  ),
                ],

                if (_status == 'pending') ...[
                  const SizedBox(height: 24),
                  _buildNote(),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCountdown() {
    final color = _remaining.inMinutes < 5 ? AppTheme.accentPink : AppTheme.accentOrange;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          height: 16,
          width: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: 8),
        Text(
          'Waiting for payment · ',
          style: TextStyle(color: AppTheme.textSecondary, fontFamily: 'Nunito'),
        ),
        Text(
          _formatCountdown(_remaining),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontFamily: 'Nunito',
            fontSize: 16,
          ),
        ),
        Text(
          ' left',
          style: TextStyle(color: AppTheme.textSecondary, fontFamily: 'Nunito'),
        ),
      ],
    );
  }

  Widget _buildQrCard(String qrUrl) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Scan with banking app',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'Nunito',
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              qrUrl,
              width: 220,
              height: 220,
              fit: BoxFit.contain,
              loadingBuilder: (_, child, progress) =>
                  progress == null ? child : const SizedBox(
                    height: 220,
                    child: Center(child: CircularProgressIndicator()),
                  ),
              errorBuilder: (_, __, ___) => const SizedBox(
                height: 100,
                child: Center(child: Text('QR unavailable')),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankCard({
    required int amount,
    required String bankCode,
    required String accountNumber,
    required String accountName,
    required String transferContent,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _bankRow('Bank', bankCode),
          const Divider(height: 20),
          _bankRow('Account number', accountNumber, copyable: true),
          const Divider(height: 20),
          _bankRow('Account name', accountName),
          const Divider(height: 20),
          _bankRow(
            'Amount',
            '${_formatAmount(amount)} VND',
            highlight: true,
          ),
          const Divider(height: 20),
          _bankRow(
            'Transfer content',
            transferContent,
            copyable: true,
            highlight: true,
          ),
        ],
      ),
    );
  }

  Widget _bankRow(String label, String value, {bool copyable = false, bool highlight = false}) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontFamily: 'Nunito',
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontWeight: highlight ? FontWeight.bold : FontWeight.w600,
                    fontFamily: 'Nunito',
                    fontSize: highlight ? 15 : 14,
                    color: highlight ? AppTheme.accentOrange : AppTheme.textPrimary,
                  ),
                ),
              ),
              if (copyable)
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: value));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Copied!'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  child: const Icon(Icons.copy_outlined, size: 18, color: Colors.grey),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBanner(String title, String subtitle, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Text(title,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontFamily: 'Nunito',
                  fontSize: 16)),
          const SizedBox(height: 4),
          Text(subtitle,
              style: TextStyle(color: color.withOpacity(0.8), fontFamily: 'Nunito')),
        ],
      ),
    );
  }

  Widget _buildNote() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ℹ️', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Transfer the exact amount with the transfer content shown above. '
              'Your account will be upgraded automatically once payment is confirmed.',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontFamily: 'Nunito',
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(int amount) {
    // Format as "59.000" (Vietnamese style)
    final s = amount.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write('.');
      buffer.write(s[i]);
    }
    return buffer.toString();
  }
}
