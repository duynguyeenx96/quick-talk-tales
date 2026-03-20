import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class GroupChallengeDetailScreen extends StatefulWidget {
  final String challengeId;
  const GroupChallengeDetailScreen({super.key, required this.challengeId});

  @override
  State<GroupChallengeDetailScreen> createState() => _GroupChallengeDetailScreenState();
}

class _GroupChallengeDetailScreenState extends State<GroupChallengeDetailScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  final _storyCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _storyCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getGroupChallengeDetail(widget.challengeId);
      if (mounted) setState(() { _data = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _accept() async {
    await ApiService.acceptGroupChallenge(widget.challengeId);
    _load();
  }

  Future<void> _decline() async {
    await ApiService.declineGroupChallenge(widget.challengeId);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _submit() async {
    if (_storyCtrl.text.trim().isEmpty) return;
    setState(() => _submitting = true);
    try {
      final res = await ApiService.submitGroupChallengeStory(widget.challengeId, _storyCtrl.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submitted! Score: ${res['score']} 🎉'), backgroundColor: AppTheme.primaryGreen),
        );
        _storyCtrl.clear();
        _load();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.accentPink),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final myId = context.read<AuthProvider>().userId;

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
                      child: Text('⚔️ Challenge',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Nunito', color: AppTheme.primaryGreen)),
                    ),
                    IconButton(icon: const Icon(Icons.refresh, color: AppTheme.textSecondary), onPressed: _load),
                  ],
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _data == null
                        ? const Center(child: Text('Failed to load'))
                        : _buildContent(myId),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(String myId) {
    final d = _data!;
    final status = d['status'] as String? ?? 'pending';
    final myStatus = d['myStatus'] as String? ?? '';
    final words = (d['words'] as List? ?? []).cast<String>();
    final participants = (d['participants'] as List? ?? []).cast<Map<String, dynamic>>();
    final endsAt = d['endsAt'] != null ? DateTime.tryParse(d['endsAt'] as String) : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: AppGradients.blueGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('${d['wordCount']} words · ${d['difficulty']}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Nunito')),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                      child: Text('${d['durationDays']} days', style: const TextStyle(color: Colors.white, fontFamily: 'Nunito', fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                if (endsAt != null) ...[
                  const SizedBox(height: 6),
                  Text('Ends: ${endsAt.toLocal().toString().substring(0, 16)}',
                      style: TextStyle(color: Colors.white.withOpacity(0.85), fontFamily: 'Nunito', fontSize: 13)),
                ],
              ],
            ),
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 16),

          // Cancelled banner
          if (status == 'cancelled') ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.accentPink.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.accentPink.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Text('❌', style: TextStyle(fontSize: 20)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text('This challenge was cancelled because a participant declined.',
                        style: TextStyle(color: AppTheme.accentPink, fontFamily: 'Nunito', fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),
            const SizedBox(height: 16),
          ],

          // Invite actions
          if (myStatus == 'invited' && status != 'cancelled') ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _accept,
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen, padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: const Text('✅ Accept', style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _decline,
                    style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.accentPink),
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: const Text('❌ Decline', style: TextStyle(color: AppTheme.accentPink, fontFamily: 'Nunito', fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Words
          if (status == 'active' && words.isNotEmpty) ...[
            const Text('📖 Your Words', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Nunito', fontSize: 16, color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: words.map((w) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: AppGradients.blueGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(w, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Nunito')),
              )).toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Submit if active and accepted (not submitted)
          if (status == 'active' && myStatus == 'accepted') ...[
            const Text('✍️ Your Story', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Nunito', fontSize: 16, color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            TextField(
              controller: _storyCtrl,
              maxLines: 6,
              decoration: const InputDecoration(hintText: 'Write your story using all the words...'),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _submitting
                    ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Submit Story 🚀', style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Leaderboard
          const Text('🏆 Leaderboard', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Nunito', fontSize: 16, color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          ...participants.asMap().entries.map((entry) {
            final i = entry.key;
            final p = entry.value;
            final isMe = p['userId'] == myId;
            final score = p['score'];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe ? AppTheme.primaryGreen.withOpacity(0.08) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isMe ? AppTheme.primaryGreen.withOpacity(0.3) : Colors.transparent),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
              ),
              child: Row(
                children: [
                  Text(score != null ? '${i + 1}' : '-',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: i == 0 ? AppTheme.accentOrange : AppTheme.textSecondary)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(p['username'] as String? ?? '',
                        style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Nunito', color: isMe ? AppTheme.primaryGreen : AppTheme.textPrimary)),
                  ),
                  Text(
                    p['status'] == 'submitted' ? '${score ?? '-'}pts' : p['status'] as String? ?? '',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Nunito',
                      color: p['status'] == 'submitted' ? AppTheme.primaryGreen : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ).animate(delay: Duration(milliseconds: 60 * i)).fadeIn(duration: 250.ms);
          }),
        ],
      ),
    );
  }
}
