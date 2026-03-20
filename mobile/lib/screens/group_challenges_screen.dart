import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'group_challenge_create_screen.dart';
import 'group_challenge_detail_screen.dart';

class GroupChallengesScreen extends StatefulWidget {
  const GroupChallengesScreen({super.key});

  @override
  State<GroupChallengesScreen> createState() => _GroupChallengesScreenState();
}

class _GroupChallengesScreenState extends State<GroupChallengesScreen> {
  List<Map<String, dynamic>> _challenges = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getGroupChallenges();
      if (mounted) setState(() { _challenges = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active': return AppTheme.primaryGreen;
      case 'finished': return AppTheme.textSecondary;
      case 'cancelled': return AppTheme.accentPink;
      default: return AppTheme.accentOrange;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'active': return 'Active';
      case 'finished': return 'Finished';
      case 'cancelled': return 'Cancelled';
      default: return 'Pending';
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
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text('Group Challenges',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Nunito', color: AppTheme.primaryGreen)),
                    ),
                    IconButton(icon: const Icon(Icons.refresh, color: AppTheme.textSecondary), onPressed: _load),
                    if (auth.subscriptionPlan == 'premium')
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryGreen),
                        tooltip: 'Create Challenge',
                        onPressed: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const GroupChallengeCreateScreen()))
                            .then((_) => _load()),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _challenges.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('⚔️', style: TextStyle(fontSize: 64)),
                                const SizedBox(height: 16),
                                const Text('No challenges yet',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Nunito', color: AppTheme.textPrimary)),
                                const SizedBox(height: 8),
                                Text(auth.subscriptionPlan == 'premium'
                                    ? 'Create a challenge and invite friends!'
                                    : 'Ask a Premium friend to challenge you!',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: AppTheme.textSecondary, fontFamily: 'Nunito')),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _challenges.length,
                            itemBuilder: (_, i) {
                              final c = _challenges[i];
                              final status = c['status'] as String? ?? 'pending';
                              final myStatus = c['myStatus'] as String? ?? '';
                              final participants = (c['participants'] as List? ?? []).cast<Map<String, dynamic>>();

                              return GestureDetector(
                                onTap: () => Navigator.push(context,
                                    MaterialPageRoute(builder: (_) => GroupChallengeDetailScreen(challengeId: c['id'] as String)))
                                    .then((_) => _load()),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3))],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text('${c['wordCount']} words · ${c['difficulty']}',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Nunito', fontSize: 15)),
                                          const Spacer(),
                                          Text(_statusLabel(status),
                                              style: TextStyle(color: _statusColor(status), fontFamily: 'Nunito', fontWeight: FontWeight.bold, fontSize: 13)),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text('${c['durationDays']} day challenge',
                                          style: const TextStyle(color: AppTheme.textSecondary, fontFamily: 'Nunito', fontSize: 13)),
                                      if (myStatus == 'invited')
                                        Container(
                                          margin: const EdgeInsets.only(top: 8),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: AppTheme.accentOrange.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Text('You have been invited',
                                              style: TextStyle(color: AppTheme.accentOrange, fontFamily: 'Nunito', fontWeight: FontWeight.bold, fontSize: 13)),
                                        ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(Icons.people_outline, size: 16, color: AppTheme.textSecondary),
                                          const SizedBox(width: 4),
                                          Text('${participants.length} participants',
                                              style: const TextStyle(color: AppTheme.textSecondary, fontFamily: 'Nunito', fontSize: 13)),
                                          const Spacer(),
                                          const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
                                        ],
                                      ),
                                    ],
                                  ),
                                ).animate(delay: Duration(milliseconds: 60 * i)).fadeIn(duration: 300.ms),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
