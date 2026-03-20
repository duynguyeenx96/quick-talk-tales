import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'profile_screen.dart' show kAvatarOptions, AvatarWidget;

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<Map<String, dynamic>> _data = [];
  List<Map<String, dynamic>> _classroomData = [];
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final data = await ApiService.getLeaderboard();
      if (mounted) setState(() { _data = data; _loading = false; });
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
      return;
    } catch (_) {
      if (mounted) setState(() { _error = 'Cannot connect to server.'; _loading = false; });
      return;
    }
    // Load classroom leaderboard independently — failure won't break other tabs
    try {
      final classroomData = await ApiService.getClassroomAllTimeLeaderboard();
      if (mounted) setState(() { _classroomData = classroomData; });
    } catch (_) {
      // Classroom tab will show empty state, other tabs unaffected
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
            colors: [Color(0xFFFFFDE7), Color(0xFFF8FBFF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(context),
              _buildTabBar(),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          Text(
            '🏆 Leaderboard',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.accentOrange,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
            tooltip: 'Refresh',
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabs,
        indicator: BoxDecoration(
          color: AppTheme.accentOrange,
          borderRadius: BorderRadius.circular(14),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: AppTheme.textSecondary,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontFamily: 'Nunito',
          fontSize: 14,
        ),
        tabs: const [
          Tab(text: '⭐  Total Score'),
          Tab(text: '🎯  Challenges'),
          Tab(text: '🏫  Classroom'),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error,
                style: const TextStyle(color: AppTheme.accentPink),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_data.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🏆', style: TextStyle(fontSize: 64)),
            SizedBox(height: 16),
            Text(
              'No data yet!\nBe the first to play.',
              style: TextStyle(fontSize: 18, color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final myId = context.read<AuthProvider>().userId;

    // Sort copies for each tab
    final byScore = List<Map<String, dynamic>>.from(_data)
      ..sort((a, b) =>
          (b['totalScore'] as int).compareTo(a['totalScore'] as int));
    final byChallenges = List<Map<String, dynamic>>.from(_data)
      ..sort((a, b) =>
          (b['totalChallenges'] as int).compareTo(a['totalChallenges'] as int));

    return TabBarView(
      controller: _tabs,
      children: [
        _buildList(byScore, 'totalScore', myId),
        _buildList(byChallenges, 'totalChallenges', myId),
        _buildClassroomList(myId),
      ],
    );
  }

  Widget _buildClassroomList(String myId) {
    if (_classroomData.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🏫', style: TextStyle(fontSize: 64)),
            SizedBox(height: 16),
            Text(
              'No classroom sessions yet!\nJoin a session to appear here.',
              style: TextStyle(fontSize: 18, color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final myRank = _classroomData.indexWhere((e) => e['userId'] == myId);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: _classroomData.length + (myRank >= 3 ? 1 : 0),
        itemBuilder: (context, i) {
          if (i == 0 && myRank >= 3) {
            final me = _classroomData[myRank];
            return Column(
              children: [
                _MyRankBanner(
                  rank: myRank + 1,
                  entry: me,
                  valueKey: 'totalScore',
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 4),
                _ClassroomLeaderboardRow(
                  rank: 1,
                  entry: _classroomData[0],
                  isMe: _classroomData[0]['userId'] == myId,
                  index: 0,
                ),
              ],
            );
          }
          final adjustedI = (myRank >= 3) ? i - 1 : i;
          if (adjustedI < 0 || adjustedI >= _classroomData.length) return const SizedBox.shrink();
          return _ClassroomLeaderboardRow(
            rank: adjustedI + 1,
            entry: _classroomData[adjustedI],
            isMe: _classroomData[adjustedI]['userId'] == myId,
            index: adjustedI,
          );
        },
      ),
    );
  }

  Widget _buildList(
      List<Map<String, dynamic>> items, String valueKey, String myId) {
    // Find my rank
    final myRank = items.indexWhere((e) => e['userId'] == myId);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: items.length + (myRank >= 0 ? 1 : 0),
        itemBuilder: (context, i) {
          // Sticky "my rank" banner at top if I'm not in top display area
          if (i == 0 && myRank >= 3) {
            final me = items[myRank];
            return Column(
              children: [
                _MyRankBanner(
                  rank: myRank + 1,
                  entry: me,
                  valueKey: valueKey,
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 4),
                _LeaderboardRow(
                  rank: 1,
                  entry: items[0],
                  valueKey: valueKey,
                  isMe: items[0]['userId'] == myId,
                  index: 0,
                ),
              ],
            );
          }
          // Adjust index if banner was injected
          final adjustedI = (myRank >= 3) ? i - 1 : i;
          if (adjustedI < 0 || adjustedI >= items.length) return const SizedBox.shrink();
          return _LeaderboardRow(
            rank: adjustedI + 1,
            entry: items[adjustedI],
            valueKey: valueKey,
            isMe: items[adjustedI]['userId'] == myId,
            index: adjustedI,
          );
        },
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final int rank;
  final Map<String, dynamic> entry;
  final String valueKey;
  final bool isMe;
  final int index;

  const _LeaderboardRow({
    required this.rank,
    required this.entry,
    required this.valueKey,
    required this.isMe,
    required this.index,
  });

  static const _medals = ['🥇', '🥈', '🥉'];

  @override
  Widget build(BuildContext context) {
    final avatar = entry['avatarUrl'] as String? ?? '';
    final username = entry['username'] as String? ?? '?';
    final value = entry[valueKey] as int? ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isMe
            ? AppTheme.secondaryBlue.withOpacity(0.12)
            : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: isMe
            ? Border.all(color: AppTheme.secondaryBlue, width: 1.5)
            : Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 36,
            child: rank <= 3
                ? Text(_medals[rank - 1],
                    style: const TextStyle(fontSize: 24),
                    textAlign: TextAlign.center)
                : Text(
                    '$rank',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textSecondary,
                      fontFamily: 'Nunito',
                    ),
                    textAlign: TextAlign.center,
                  ),
          ),
          const SizedBox(width: 12),
          // Avatar
          AvatarWidget(avatarUrl: avatar, displayName: username, size: 44),
          const SizedBox(width: 12),
          // Username
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isMe ? AppTheme.secondaryBlue : AppTheme.textPrimary,
                    fontFamily: 'Nunito',
                  ),
                ),
                if (isMe)
                  Text(
                    'You',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.secondaryBlue,
                      fontFamily: 'Nunito',
                    ),
                  ),
              ],
            ),
          ),
          // Value
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: rank == 1
                  ? AppTheme.accentOrange.withOpacity(0.15)
                  : rank == 2
                      ? Colors.grey.shade200
                      : rank == 3
                          ? AppTheme.accentOrange.withOpacity(0.08)
                          : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$value',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                fontFamily: 'Nunito',
                color: rank <= 3 ? AppTheme.accentOrange : AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    ).animate(delay: (index * 40).ms).fadeIn(duration: 300.ms).slideX(begin: 0.1);
  }
}

class _ClassroomLeaderboardRow extends StatelessWidget {
  final int rank;
  final Map<String, dynamic> entry;
  final bool isMe;
  final int index;

  const _ClassroomLeaderboardRow({
    required this.rank,
    required this.entry,
    required this.isMe,
    required this.index,
  });

  static const _medals = ['🥇', '🥈', '🥉'];

  @override
  Widget build(BuildContext context) {
    final avatar = entry['avatarUrl'] as String? ?? '';
    final username = entry['username'] as String? ?? '?';
    final totalScore = entry['totalScore'] as int? ?? 0;
    final bestScore = entry['bestScore'] as int?;
    final avgScore = entry['avgScore'] as num?;
    final sessions = entry['sessionsSubmitted'] as int? ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isMe
            ? AppTheme.secondaryBlue.withOpacity(0.12)
            : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: isMe
            ? Border.all(color: AppTheme.secondaryBlue, width: 1.5)
            : Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: rank <= 3
                ? Text(_medals[rank - 1],
                    style: const TextStyle(fontSize: 24),
                    textAlign: TextAlign.center)
                : Text(
                    '$rank',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textSecondary,
                      fontFamily: 'Nunito',
                    ),
                    textAlign: TextAlign.center,
                  ),
          ),
          const SizedBox(width: 12),
          AvatarWidget(avatarUrl: avatar, displayName: username, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isMe ? AppTheme.secondaryBlue : AppTheme.textPrimary,
                    fontFamily: 'Nunito',
                  ),
                ),
                Text(
                  'Best: ${bestScore ?? '-'}  Avg: ${avgScore?.toStringAsFixed(1) ?? '-'}  Sessions: $sessions',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                    fontFamily: 'Nunito',
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: rank == 1
                  ? AppTheme.accentOrange.withOpacity(0.15)
                  : rank == 2
                      ? Colors.grey.shade200
                      : rank == 3
                          ? AppTheme.accentOrange.withOpacity(0.08)
                          : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$totalScore',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                fontFamily: 'Nunito',
                color: rank <= 3 ? AppTheme.accentOrange : AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    ).animate(delay: (index * 40).ms).fadeIn(duration: 300.ms).slideX(begin: 0.1);
  }
}

class _MyRankBanner extends StatelessWidget {
  final int rank;
  final Map<String, dynamic> entry;
  final String valueKey;

  const _MyRankBanner({
    required this.rank,
    required this.entry,
    required this.valueKey,
  });

  @override
  Widget build(BuildContext context) {
    final value = entry[valueKey] as int? ?? 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppGradients.blueGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.secondaryBlue.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text('👤', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Rank',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontFamily: 'Nunito',
                  ),
                ),
                Text(
                  '#$rank',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Nunito',
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$value pts',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Nunito',
            ),
          ),
        ],
      ),
    );
  }
}
