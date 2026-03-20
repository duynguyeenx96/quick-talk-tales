import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import 'email_verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _referralCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _referralCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final auth = context.read<AuthProvider>();
    final ok = await auth.register(
      _usernameCtrl.text.trim(),
      _emailCtrl.text.trim(),
      _passwordCtrl.text,
      referralCode: _referralCtrl.text.trim().isEmpty ? null : _referralCtrl.text.trim(),
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (ok) {
        // Replace this screen with email verification notice
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                EmailVerificationScreen(email: _emailCtrl.text.trim()),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF8FBFF), Color(0xFFE8F4FD)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Consumer<AuthProvider>(
              builder: (context, auth, _) {
                return Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      Text(
                        'Join Quick Talk Tales!',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: AppTheme.primaryGreen,
                            ),
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(duration: 400.ms),
                      const SizedBox(height: 32),

                      if (auth.error.isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.accentPink.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.accentPink.withOpacity(0.3)),
                          ),
                          child: Text(
                            auth.error,
                            style: TextStyle(color: AppTheme.accentPink, fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      TextFormField(
                        controller: _usernameCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Username',
                          prefixIcon: Icon(Icons.person_outlined),
                        ),
                        validator: (v) =>
                            (v == null || v.length < 3) ? 'At least 3 characters' : null,
                        onChanged: (_) => auth.clearError(),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          hintText: 'Email address',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (v) => (v == null || !v.contains('@'))
                            ? 'Enter a valid email'
                            : null,
                        onChanged: (_) => auth.clearError(),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: 'Password (min 6 characters)',
                          prefixIcon: const Icon(Icons.lock_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined),
                            onPressed: () =>
                                setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (v) =>
                            (v == null || v.length < 6) ? 'Password too short' : null,
                        onChanged: (_) => auth.clearError(),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _referralCtrl,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          hintText: 'Referral code (optional)',
                          prefixIcon: Icon(Icons.card_giftcard_outlined),
                        ),
                      ),
                      const SizedBox(height: 32),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _register,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Create Account'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
