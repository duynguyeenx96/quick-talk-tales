import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'group_challenge_create_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<Map<String, dynamic>> _friends = [];
  List<Map<String, dynamic>> _pending = [];
  List<Map<String, dynamic>> _searchResults = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      ApiService.getFriends().catchError((_) => <Map<String, dynamic>>[]),
      ApiService.getPendingRequests().catchError((_) => <Map<String, dynamic>>[]),
    ]);
    if (mounted) {
      setState(() {
        _friends = results[0];
        _pending = results[1];
        _loading = false;
      });
    }
  }

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _searching = true);
    try {
      final results = await ApiService.searchUsers(q.trim());
      if (mounted) setState(() { _searchResults = results; _searching = false; });
    } catch (_) {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _sendRequest(String usernameOrId) async {
    try {
      await ApiService.sendFriendRequest(usernameOrId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Friend request sent! ✅'), backgroundColor: AppTheme.primaryGreen),
        );
        setState(() => _searchResults = []);
        _searchCtrl.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.accentPink),
        );
      }
    }
  }

  Future<void> _accept(String friendshipId) async {
    await ApiService.acceptFriendRequest(friendshipId);
    _load();
  }

  Future<void> _remove(String friendshipId) async {
    await ApiService.removeFriend(friendshipId);
    _load();
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
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Friends',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Nunito',
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: AppTheme.textSecondary),
                      onPressed: _load,
                    ),
                  ],
                ),
              ),
              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search by username or ID...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searching
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                          )
                        : null,
                  ),
                  onChanged: _search,
                ),
              ),
              if (_searchResults.isNotEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    children: _searchResults.map((u) {
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primaryGreen.withOpacity(0.15),
                          child: Text(
                            (u['username'] as String? ?? '?')[0].toUpperCase(),
                            style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(u['username'] as String? ?? '', style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.bold)),
                        subtitle: Text(u['fullName'] as String? ?? '', style: const TextStyle(fontFamily: 'Nunito')),
                        trailing: SizedBox(
                          height: 32,
                          child: ElevatedButton(
                            onPressed: () => _sendRequest(u['username'] as String? ?? u['id'] as String),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                              textStyle: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            child: const Text('Add'),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              // Tabs
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TabBar(
                  controller: _tabs,
                  indicator: BoxDecoration(
                    color: AppTheme.primaryGreen,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: AppTheme.primaryGreen.withOpacity(0.25), blurRadius: 6, offset: const Offset(0, 2))],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppTheme.textSecondary,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Nunito', fontSize: 13),
                  unselectedLabelStyle: const TextStyle(fontFamily: 'Nunito', fontSize: 13),
                  splashFactory: NoSplash.splashFactory,
                  overlayColor: WidgetStateProperty.all(Colors.transparent),
                  tabs: [
                    Tab(text: 'Friends (${_friends.length})'),
                    Tab(text: 'Requests (${_pending.length})'),
                  ],
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : TabBarView(
                        controller: _tabs,
                        children: [
                          _buildFriendsList(),
                          _buildPendingList(),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFriendsList() {
    if (_friends.isEmpty) {
      return const Center(
        child: Text('No friends yet.\nSearch above to add friends!',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, fontFamily: 'Nunito', fontSize: 16)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _friends.length,
      itemBuilder: (_, i) {
        final f = _friends[i];
        final isPremium = f['subscriptionPlan'] == 'premium';
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.secondaryBlue.withOpacity(0.15),
                child: Text((f['username'] as String? ?? '?')[0].toUpperCase(),
                    style: const TextStyle(color: AppTheme.secondaryBlue, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(f['username'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Nunito')),
                      if (isPremium) ...[
                        const SizedBox(width: 6),
                        const Text('⭐', style: TextStyle(fontSize: 12)),
                      ],
                    ]),
                    if ((f['fullName'] as String? ?? '').isNotEmpty)
                      Text(f['fullName'] as String, style: const TextStyle(color: AppTheme.textSecondary, fontFamily: 'Nunito', fontSize: 12)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.sports_esports_outlined, color: AppTheme.secondaryBlue),
                tooltip: 'Challenge',
                onPressed: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => GroupChallengeCreateScreen(preselectedFriendId: f['id'] as String?, preselectedFriendName: f['username'] as String?),
                )),
              ),
              IconButton(
                icon: const Icon(Icons.person_remove_outlined, color: AppTheme.accentPink),
                tooltip: 'Remove',
                onPressed: () => _remove(f['friendshipId'] as String),
              ),
            ],
          ),
        ).animate(delay: Duration(milliseconds: 50 * i)).fadeIn(duration: 300.ms);
      },
    );
  }

  Widget _buildPendingList() {
    if (_pending.isEmpty) {
      return const Center(
        child: Text('No pending requests', style: TextStyle(color: AppTheme.textSecondary, fontFamily: 'Nunito', fontSize: 16)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pending.length,
      itemBuilder: (_, i) {
        final req = _pending[i];
        final requester = req['requester'] as Map<String, dynamic>? ?? {};
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.accentOrange.withOpacity(0.15),
                child: Text((requester['username'] as String? ?? '?')[0].toUpperCase(),
                    style: const TextStyle(color: AppTheme.accentOrange, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(requester['username'] as String? ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Nunito')),
              ),
              TextButton(
                onPressed: () => _accept(req['id'] as String),
                child: const Text('Accept', style: TextStyle(color: AppTheme.primaryGreen, fontFamily: 'Nunito', fontWeight: FontWeight.bold)),
              ),
              TextButton(
                onPressed: () => _remove(req['id'] as String),
                child: const Text('Decline', style: TextStyle(color: AppTheme.accentPink, fontFamily: 'Nunito')),
              ),
            ],
          ),
        );
      },
    );
  }
}
