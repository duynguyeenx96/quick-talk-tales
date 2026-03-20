import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class GroupChallengeCreateScreen extends StatefulWidget {
  final String? preselectedFriendId;
  final String? preselectedFriendName;

  const GroupChallengeCreateScreen({
    super.key,
    this.preselectedFriendId,
    this.preselectedFriendName,
  });

  @override
  State<GroupChallengeCreateScreen> createState() => _GroupChallengeCreateScreenState();
}

class _GroupChallengeCreateScreenState extends State<GroupChallengeCreateScreen> {
  int _wordCount = 5;
  String _difficulty = 'easy';
  int _durationDays = 3;
  final List<Map<String, dynamic>> _invitees = [];
  final _inviteCtrl = TextEditingController();
  bool _creating = false;
  List<Map<String, dynamic>> _friends = [];

  @override
  void initState() {
    super.initState();
    _loadFriends();
    if (widget.preselectedFriendId != null) {
      _invitees.add({'id': widget.preselectedFriendId, 'username': widget.preselectedFriendName ?? widget.preselectedFriendId});
    }
  }

  @override
  void dispose() {
    _inviteCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFriends() async {
    try {
      final friends = await ApiService.getFriends();
      if (mounted) setState(() => _friends = friends);
    } catch (_) {}
  }

  Future<void> _addInvitee(Map<String, dynamic> user) async {
    if (_invitees.length >= 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 4 invitees'), backgroundColor: AppTheme.accentPink),
      );
      return;
    }
    if (_invitees.any((i) => i['id'] == user['id'])) return;
    setState(() => _invitees.add(user));
  }

  Future<void> _create() async {
    if (_invitees.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invite at least 1 friend'), backgroundColor: AppTheme.accentPink),
      );
      return;
    }
    setState(() => _creating = true);
    try {
      final words = await ApiService.getRandomWords(count: _wordCount, difficulty: _difficulty);
      final wordTexts = words.map((w) => w['text'] as String).toList();

      await ApiService.createGroupChallenge(
        wordCount: _wordCount,
        difficulty: _difficulty,
        durationDays: _durationDays,
        inviteUserIds: _invitees.map((i) => i['id'] as String).toList(),
        words: wordTexts,
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Challenge created! ⚔️'), backgroundColor: AppTheme.primaryGreen),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _creating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.accentPink),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final isPremium = auth.subscriptionPlan == 'premium';

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
                      child: Text('⚔️ Create Challenge',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Nunito', color: AppTheme.primaryGreen)),
                    ),
                  ],
                ),
              ),
              if (!isPremium)
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: AppGradients.orangeGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    children: [
                      Text('⭐', style: TextStyle(fontSize: 20)),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text('Creating group challenges is a Premium feature',
                            style: TextStyle(color: Colors.white, fontFamily: 'Nunito', fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionLabel('Word Count'),
                      const SizedBox(height: 10),
                      Row(
                        children: [3, 5, 7].map((c) {
                          final sel = _wordCount == c;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: GestureDetector(
                                onTap: () => setState(() => _wordCount = c),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    color: sel ? AppTheme.primaryGreen : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
                                  ),
                                  child: Text('$c words', textAlign: TextAlign.center,
                                      style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Nunito',
                                          color: sel ? Colors.white : AppTheme.textPrimary)),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      _sectionLabel('Difficulty'),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          {'key': 'easy', 'label': '🌟 Easy', 'color': AppTheme.primaryGreen},
                          {'key': 'medium', 'label': '🔥 Medium', 'color': AppTheme.accentOrange},
                          {'key': 'hard', 'label': '⚡ Hard', 'color': AppTheme.accentPink},
                        ].map((d) {
                          final sel = _difficulty == d['key'];
                          final color = d['color'] as Color;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: GestureDetector(
                                onTap: () => setState(() => _difficulty = d['key'] as String),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    color: sel ? color : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
                                  ),
                                  child: Text(d['label'] as String, textAlign: TextAlign.center,
                                      style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Nunito', fontSize: 13,
                                          color: sel ? Colors.white : AppTheme.textPrimary)),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      _sectionLabel('Duration'),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children: [1, 2, 3, 5, 7].map((d) {
                          final sel = _durationDays == d;
                          return GestureDetector(
                            onTap: () => setState(() => _durationDays = d),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                color: sel ? AppTheme.secondaryBlue : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
                              ),
                              child: Text('$d day${d > 1 ? 's' : ''}',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Nunito',
                                      color: sel ? Colors.white : AppTheme.textPrimary)),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      _sectionLabel('Invite Friends (max 4)'),
                      const SizedBox(height: 10),
                      if (_friends.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _friends.map((f) {
                            final already = _invitees.any((i) => i['id'] == f['id']);
                            return GestureDetector(
                              onTap: already ? null : () => _addInvitee(f),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: already ? AppTheme.primaryGreen : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: already ? AppTheme.primaryGreen : Colors.grey.shade300,
                                  ),
                                ),
                                child: Text(f['username'] as String? ?? '',
                                    style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.bold,
                                        color: already ? Colors.white : AppTheme.textPrimary)),
                              ),
                            );
                          }).toList(),
                        ),
                      if (_invitees.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          children: _invitees.map((inv) {
                            return Chip(
                              label: Text(inv['username'] as String? ?? '', style: const TextStyle(fontFamily: 'Nunito')),
                              deleteIcon: const Icon(Icons.close, size: 16),
                              onDeleted: () => setState(() => _invitees.removeWhere((i) => i['id'] == inv['id'])),
                              backgroundColor: AppTheme.secondaryBlue.withOpacity(0.12),
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: (!isPremium || _creating) ? null : _create,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: AppTheme.primaryGreen,
                          ),
                          child: _creating
                              ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('⚔️  Create Challenge', style: TextStyle(fontSize: 18, fontFamily: 'Nunito', fontWeight: FontWeight.bold)),
                        ),
                      ),
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

  Widget _sectionLabel(String label) => Text(label,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Nunito', color: AppTheme.textSecondary));
}
