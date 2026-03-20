import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart';
import '../providers/game_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../l10n/app_strings.dart';
import 'referral_screen.dart';
import 'subscription_screen.dart';

// Predefined avatar set — emoji stored directly in avatarUrl
const List<String> kAvatarOptions = [
  '🐱', '🐶', '🐸', '🐻', '🦊', '🐼', '🐯', '🦁',
  '🐺', '🦄', '🐮', '🐷', '🐙', '🦋', '🐢', '🦖',
];

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameCtrl;
  bool _saving = false;
  bool _dirty = false;
  Map<String, dynamic>? _stats;
  bool _statsLoading = true;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _nameCtrl = TextEditingController(text: auth.fullName);
    _nameCtrl.addListener(() => setState(() => _dirty = true));
    _loadStats();
    // Always refresh profile so subscription status is up-to-date
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().refreshProfile();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    try {
      final s = await ApiService.getMyStats();
      if (mounted) setState(() { _stats = s; _statsLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _statsLoading = false);
    }
  }

  Future<void> _save() async {
    if (!_dirty) return;
    setState(() => _saving = true);
    final auth = context.read<AuthProvider>();
    final ok = await auth.updateProfile(
      fullName: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
    );
    if (mounted) {
      setState(() { _saving = false; _dirty = false; });
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save. Try again.'),
            backgroundColor: AppTheme.accentPink,
          ),
        );
      }
    }
  }

  Future<void> _pickAvatar() async {
    final auth = context.read<AuthProvider>();
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _AvatarSourceSheet(current: auth.avatarUrl),
    );
    if (choice == null) return;

    if (choice == '__gallery__' || choice == '__camera__') {
      await _uploadPhoto(
        choice == '__gallery__' ? ImageSource.gallery : ImageSource.camera,
      );
    } else {
      // Emoji chosen
      if (choice != auth.avatarUrl) {
        await auth.updateProfile(avatarUrl: choice);
      }
    }
  }

  Future<void> _uploadPhoto(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      // On macOS, picked.name may be a UUID with no extension.
      // Ensure the filename always has a valid image extension.
      String filename = picked.name.isNotEmpty ? picked.name : 'avatar.jpg';
      if (!filename.contains('.')) filename = '$filename.jpg';

      final auth = context.read<AuthProvider>();
      final updated = await ApiService.uploadAvatar(bytes, filename);
      // updateProfile internally calls notifyListeners via _fetchProfile equivalent
      // but since uploadAvatar returns updated user, we refresh profile
      await auth.updateProfile(avatarUrl: updated['avatarUrl'] as String?);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: AppTheme.accentPink,
          ),
        );
      }
    }
  }

  Future<void> _setLanguage(String lang) async {
    final auth = context.read<AuthProvider>();
    if (auth.language == lang) return;
    try {
      await auth.updateProfile(language: lang);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save language: $e'),
              backgroundColor: AppTheme.accentPink),
        );
      }
    }
  }

  Future<void> _logout() async {
    context.read<GameProvider>().reset();
    await context.read<AuthProvider>().logout();
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
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
          child: Consumer<AuthProvider>(
            builder: (context, auth, _) {
              return CustomScrollView(
                slivers: [
                  _buildAppBar(context, auth),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _buildAvatarSection(auth)
                              .animate()
                              .fadeIn(duration: 400.ms)
                              .scale(begin: const Offset(0.85, 0.85)),
                          const SizedBox(height: 24),
                          _buildAccountSection(context, auth)
                              .animate()
                              .fadeIn(duration: 400.ms, delay: 100.ms),
                          const SizedBox(height: 16),
                          _buildLanguageSection(context, auth)
                              .animate()
                              .fadeIn(duration: 400.ms, delay: 200.ms),
                          const SizedBox(height: 16),
                          _buildStatsSection(context, auth)
                              .animate()
                              .fadeIn(duration: 400.ms, delay: 300.ms),
                          const SizedBox(height: 32),
                          _buildReferralButton(context)
                              .animate()
                              .fadeIn(duration: 400.ms, delay: 480.ms),
                          const SizedBox(height: 12),
                          _buildLogoutButton(context)
                              .animate()
                              .fadeIn(duration: 400.ms, delay: 500.ms),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, AuthProvider auth) {
    return SliverAppBar(
      pinned: false,
      floating: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Text(
        '👤 Profile',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.primaryGreen,
              fontWeight: FontWeight.bold,
            ),
      ),
      actions: [
        if (_dirty)
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    AppStrings.of(context).saveChanges,
                    style: const TextStyle(
                      color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      fontFamily: 'Nunito',
                    ),
                  ),
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildAvatarSection(AuthProvider auth) {
    final isPremium = auth.subscriptionPlan == 'premium';
    return GestureDetector(
      onTap: _pickAvatar,
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            clipBehavior: Clip.none,
            children: [
              // Premium fire ring
              Container(
                padding: EdgeInsets.all(isPremium ? 3 : 0),
                decoration: BoxDecoration(
                  gradient: isPremium ? AppGradients.orangeGradient : null,
                  shape: BoxShape.circle,
                ),
                child: AvatarWidget(
                  avatarUrl: auth.avatarUrl,
                  displayName: auth.fullName.isNotEmpty ? auth.fullName : auth.username,
                  size: 100,
                ),
              ),
              if (isPremium)
                const Positioned(
                  top: -10,
                  right: -10,
                  child: Text('🔥', style: TextStyle(fontSize: 26)),
                ),
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit, size: 16, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  auth.fullName.isNotEmpty ? auth.fullName : auth.username,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                    fontFamily: 'Nunito',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: isPremium ? AppGradients.orangeGradient : AppGradients.blueGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isPremium ? '⭐ Premium' : '🆓 Free',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Nunito',
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            auth.email,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontFamily: 'Nunito',
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Change Avatar',
            style: const TextStyle(
              color: AppTheme.secondaryBlue,
              fontWeight: FontWeight.w600,
              fontFamily: 'Nunito',
            ),
          ),
          if (!isPremium)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: OutlinedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.accentOrange,
                  side: const BorderSide(color: AppTheme.accentOrange),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                ),
                child: const Text('⭐ Upgrade to Premium', style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAccountSection(BuildContext context, AuthProvider auth) {
    final shortId = auth.userId.length > 8 ? auth.userId.substring(0, 8) : auth.userId;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel(context, 'Account'),
          const SizedBox(height: 12),
          // Full name
          TextField(
            controller: _nameCtrl,
            decoration: InputDecoration(
              labelText: AppStrings.of(context).displayName,
              prefixIcon: const Icon(Icons.person_outline),
              hintText: auth.username,
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 12),
          // Username + ID (read-only)
          _infoRow(context, Icons.alternate_email, '@${auth.username}', copyable: false),
          const SizedBox(height: 8),
          _infoRow(context, Icons.fingerprint, 'ID: $shortId…', copyable: true,
              copyValue: auth.userId),
          const SizedBox(height: 8),
          _infoRow(context, Icons.email_outlined, auth.email, copyable: false),
        ],
      ),
    );
  }

  Widget _buildLanguageSection(BuildContext context, AuthProvider auth) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel(context, AppStrings.of(context).languageLabel),
          const SizedBox(height: 12),
          Row(
            children: [
              _LangChip(
                flag: '🇺🇸',
                label: 'English',
                selected: auth.language == 'en',
                onTap: () => _setLanguage('en'),
              ),
              const SizedBox(width: 12),
              _LangChip(
                flag: '🇻🇳',
                label: 'Tiếng Việt',
                selected: auth.language == 'vi',
                onTap: () => _setLanguage('vi'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context, AuthProvider auth) {
    if (_statsLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final total = _stats?['totalChallenges'] as int? ?? 0;
    final avg = _stats?['avgScore'] as int? ?? 0;
    final best = _stats?['bestScore'] as int? ?? 0;
    final streak = _stats?['currentStreak'] as int? ?? auth.user?['currentStreak'] as int? ?? 0;
    final longest = _stats?['longestStreak'] as int? ?? auth.user?['longestStreak'] as int? ?? 0;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel(context, 'My Stats'),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatCell(label: 'Challenges', value: '$total', icon: '🎯'),
              _divider(),
              _StatCell(label: 'Avg Score', value: '$avg', icon: '📊'),
              _divider(),
              _StatCell(label: 'Best', value: '$best', icon: '🏆'),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.accentOrange.withOpacity(0.1), AppTheme.accentPink.withOpacity(0.08)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Text('🔥', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Text(
                  '$streak day streak',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accentOrange,
                    fontFamily: 'Nunito',
                  ),
                ),
                const Spacer(),
                Text(
                  'Best: $longest',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    fontFamily: 'Nunito',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferralButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.card_giftcard, color: Colors.white),
        label: const Text(
          '🎁 Invite Friends & Earn Premium',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Nunito', fontSize: 15),
        ),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReferralScreen())),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: AppTheme.accentOrange,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.logout, color: AppTheme.accentPink),
        label: Text(
          AppStrings.of(context).logoutLabel,
          style: const TextStyle(
            color: AppTheme.accentPink,
            fontWeight: FontWeight.bold,
            fontFamily: 'Nunito',
            fontSize: 16,
          ),
        ),
        onPressed: _logout,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: const BorderSide(color: AppTheme.accentPink, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String label) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.textSecondary,
          ),
    );
  }

  Widget _infoRow(BuildContext context, IconData icon, String value,
      {bool copyable = false, String? copyValue}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (copyable)
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: copyValue ?? value));
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('Copied!')));
            },
            child: const Icon(Icons.copy, size: 16, color: AppTheme.textSecondary),
          ),
      ],
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 40,
        color: Colors.grey.shade200,
        margin: const EdgeInsets.symmetric(horizontal: 12),
      );
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _LangChip extends StatelessWidget {
  final String flag;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LangChip({
    required this.flag,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppTheme.secondaryBlue : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppTheme.secondaryBlue : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(flag, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
                fontFamily: 'Nunito',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final String icon;

  const _StatCell({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
              fontFamily: 'Nunito',
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              fontFamily: 'Nunito',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Reusable avatar widget (handles emoji, HTTP photo, initials fallback) ────

class AvatarWidget extends StatelessWidget {
  final String avatarUrl;
  final String displayName;
  final double size;

  const AvatarWidget({
    required this.avatarUrl,
    required this.displayName,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    final isEmoji = kAvatarOptions.contains(avatarUrl);
    final isUrl = avatarUrl.startsWith('http');
    final initials = displayName
        .split(' ')
        .where((s) => s.isNotEmpty)
        .map((s) => s[0].toUpperCase())
        .take(2)
        .join();

    Widget inner;
    if (isEmoji) {
      inner = Text(avatarUrl, style: TextStyle(fontSize: size * 0.52));
    } else if (isUrl) {
      inner = ClipOval(
        child: Image.network(
          avatarUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Text(
            initials.isEmpty ? '?' : initials,
            style: TextStyle(
              fontSize: size * 0.36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Nunito',
            ),
          ),
        ),
      );
    } else {
      inner = Text(
        initials.isEmpty ? '?' : initials,
        style: TextStyle(
          fontSize: size * 0.36,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontFamily: 'Nunito',
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppGradients.blueGradient,
        boxShadow: [
          BoxShadow(
            color: AppTheme.secondaryBlue.withOpacity(0.3),
            blurRadius: size * 0.2,
            offset: Offset(0, size * 0.08),
          ),
        ],
      ),
      child: Center(child: inner),
    );
  }
}

// ── Avatar source picker: photo or emoji ─────────────────────────────────────

class _AvatarSourceSheet extends StatefulWidget {
  final String current;
  const _AvatarSourceSheet({required this.current});

  @override
  State<_AvatarSourceSheet> createState() => _AvatarSourceSheetState();
}

class _AvatarSourceSheetState extends State<_AvatarSourceSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Change Avatar',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              fontFamily: 'Nunito',
            ),
          ),
          const SizedBox(height: 12),
          // Tab bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(14),
            ),
            child: TabBar(
              controller: _tabs,
              indicator: BoxDecoration(
                color: AppTheme.primaryGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: AppTheme.textSecondary,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Nunito'),
              tabs: const [Tab(text: '📷  Photo'), Tab(text: '😸  Emoji')],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                // Photo tab
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      _photoOption(
                        icon: Icons.photo_library_outlined,
                        label: 'Choose from Gallery',
                        onTap: () => Navigator.pop(context, '__gallery__'),
                      ),
                      const SizedBox(height: 16),
                      _photoOption(
                        icon: Icons.camera_alt_outlined,
                        label: 'Take a Photo',
                        onTap: () => Navigator.pop(context, '__camera__'),
                      ),
                    ],
                  ),
                ),
                // Emoji tab
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                    ),
                    itemCount: kAvatarOptions.length,
                    itemBuilder: (context, i) {
                      final emoji = kAvatarOptions[i];
                      final isSelected = emoji == widget.current;
                      return GestureDetector(
                        onTap: () => Navigator.pop(context, emoji),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryGreen.withOpacity(0.15)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? AppTheme.primaryGreen : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(emoji, style: const TextStyle(fontSize: 36)),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _photoOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        decoration: BoxDecoration(
          color: AppTheme.backgroundLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryGreen, size: 28),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Nunito',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
