import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'group_challenge_detail_screen.dart';
import 'friends_screen.dart';

// Items visible per page (determines prefetch size = pageSize * 2)
const _kPageSize = 6;

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _scrollCtrl = ScrollController();
  final List<Map<String, dynamic>> _items = [];
  bool _initialLoading = true;
  bool _loadingMore = false;
  int _currentPage = 1;
  int _total = 0;
  bool _didPrefetchNext = false; // guard: only prefetch once per "batch"

  // How many pages we load at once
  static const _pagesPerBatch = 2;
  static const _limit = _kPageSize * _pagesPerBatch; // 12 per request

  @override
  void initState() {
    super.initState();
    _load(reset: true);
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final pos = _scrollCtrl.position;
    final pct = pos.pixels / pos.maxScrollExtent;
    if (pct >= 0.6 && !_loadingMore && !_didPrefetchNext && _hasMore) {
      _didPrefetchNext = true;
      _loadMore();
    }
  }

  bool get _hasMore => _items.length < _total;

  Future<void> _load({bool reset = false}) async {
    if (reset) {
      _currentPage = 1;
      _items.clear();
      _didPrefetchNext = false;
    }
    if (reset) setState(() => _initialLoading = true);

    try {
      final data = await ApiService.getNotifications(page: _currentPage, limit: _limit);
      final list = (data['notifications'] as List? ?? []).cast<Map<String, dynamic>>();
      if (mounted) {
        setState(() {
          _items.addAll(list);
          _total = data['total'] as int? ?? 0;
          _currentPage++;
          _initialLoading = false;
          _didPrefetchNext = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _initialLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final data = await ApiService.getNotifications(page: _currentPage, limit: _limit);
      final list = (data['notifications'] as List? ?? []).cast<Map<String, dynamic>>();
      if (mounted) {
        setState(() {
          _items.addAll(list);
          _total = data['total'] as int? ?? 0;
          _currentPage++;
          _loadingMore = false;
          _didPrefetchNext = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _loadingMore = false; _didPrefetchNext = false; });
    }
  }

  Future<void> _markRead(Map<String, dynamic> notif) async {
    if (notif['isRead'] == true) return;
    try {
      await ApiService.markNotificationRead(notif['id'] as String);
      final idx = _items.indexWhere((n) => n['id'] == notif['id']);
      if (idx != -1 && mounted) {
        setState(() => _items[idx] = {..._items[idx], 'isRead': true});
      }
    } catch (_) {}
  }

  Future<void> _markAllRead() async {
    try {
      await ApiService.markAllNotificationsRead();
      if (mounted) {
        setState(() {
          for (int i = 0; i < _items.length; i++) {
            _items[i] = {..._items[i], 'isRead': true};
          }
        });
      }
    } catch (_) {}
  }

  void _onTap(Map<String, dynamic> notif) {
    _markRead(notif);
    final type = notif['type'] as String? ?? '';
    final data = (notif['data'] as Map?)?.cast<String, dynamic>() ?? {};

    if (type == 'challenge_invite') {
      final challengeId = data['challengeId'] as String? ?? '';
      if (challengeId.isNotEmpty) {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => GroupChallengeDetailScreen(challengeId: challengeId),
        )).then((_) => _load(reset: true));
      }
    } else if (type == 'friend_request') {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => const FriendsScreen(),
      )).then((_) => _load(reset: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _items.where((n) => n['isRead'] != true).length;

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
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                child: Row(
                  children: [
                    const Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Nunito',
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    if (unreadCount > 0)
                      TextButton(
                        onPressed: _markAllRead,
                        child: const Text(
                          'Mark all read',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 12,
                            color: AppTheme.secondaryBlue,
                          ),
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: AppTheme.textSecondary, size: 20),
                      onPressed: () => _load(reset: true),
                    ),
                  ],
                ),
              ),
              // List
              Expanded(
                child: _initialLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _items.isEmpty
                        ? _buildEmpty()
                        : RefreshIndicator(
                            onRefresh: () => _load(reset: true),
                            child: ListView.builder(
                              controller: _scrollCtrl,
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              itemCount: _items.length + (_loadingMore ? 1 : 0),
                              itemBuilder: (_, i) {
                                if (i == _items.length) {
                                  return const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                  );
                                }
                                return _NotifTile(
                                  notif: _items[i],
                                  onTap: () => _onTap(_items[i]),
                                ).animate(delay: Duration(milliseconds: 40 * i.clamp(0, 10)))
                                    .fadeIn(duration: 250.ms)
                                    .slideX(begin: 0.08);
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('🔔', style: TextStyle(fontSize: 64)),
          SizedBox(height: 16),
          Text('All caught up!',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Nunito',
                  color: AppTheme.textPrimary)),
          SizedBox(height: 8),
          Text('No notifications yet',
              style: TextStyle(color: AppTheme.textSecondary, fontFamily: 'Nunito')),
        ],
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final Map<String, dynamic> notif;
  final VoidCallback onTap;
  const _NotifTile({required this.notif, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isRead = notif['isRead'] as bool? ?? false;
    final type = notif['type'] as String? ?? '';
    final isChallenge = type == 'challenge_invite';
    final title = notif['title'] as String? ?? '';
    final body = notif['message'] as String? ?? '';
    final createdAt = notif['createdAt'] as String?;

    final accentColor = isChallenge ? AppTheme.primaryGreen : AppTheme.secondaryBlue;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : accentColor.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRead
                ? Colors.grey.withOpacity(0.12)
                : accentColor.withOpacity(0.3),
            width: isRead ? 1 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isRead ? 0.04 : 0.07),
              blurRadius: isRead ? 6 : 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon with unread dot
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(isRead ? 0.08 : 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      isChallenge ? '⚔️' : '👥',
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
                if (!isRead)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(
                        color: AppTheme.accentPink,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                      fontFamily: 'Nunito',
                      fontSize: 14,
                      color: isRead ? AppTheme.textPrimary : AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    body,
                    style: TextStyle(
                      color: isRead ? AppTheme.textSecondary : AppTheme.textPrimary.withOpacity(0.75),
                      fontFamily: 'Nunito',
                      fontSize: 13,
                      fontWeight: isRead ? FontWeight.normal : FontWeight.w500,
                    ),
                  ),
                  if (createdAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(createdAt),
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontFamily: 'Nunito',
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: isRead ? AppTheme.textSecondary : accentColor,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }
}
