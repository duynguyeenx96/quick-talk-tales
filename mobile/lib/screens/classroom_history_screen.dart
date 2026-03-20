import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class ClassroomHistoryScreen extends StatefulWidget {
  const ClassroomHistoryScreen({super.key});

  @override
  State<ClassroomHistoryScreen> createState() => _ClassroomHistoryScreenState();
}

class _ClassroomHistoryScreenState extends State<ClassroomHistoryScreen> {
  List<Map<String, dynamic>> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiService.getClassroomMyHistory();
      if (mounted) setState(() { _history = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Classroom History'),
        backgroundColor: AppTheme.secondaryBlue,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _history.length,
                    itemBuilder: (_, i) => _buildRow(_history[i]),
                  ),
                ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.class_outlined, size: 64, color: AppTheme.textSecondary),
          SizedBox(height: 16),
          Text('No classroom sessions yet',
              style: TextStyle(fontSize: 16, color: AppTheme.textSecondary, fontFamily: 'Nunito')),
          SizedBox(height: 8),
          Text('Join a live session from the home screen!',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontFamily: 'Nunito')),
        ],
      ),
    );
  }

  Widget _buildRow(Map<String, dynamic> entry) {
    final words = (entry['wordSet'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    final score = entry['scoreOverall'] as int?;
    final rank = entry['rank'] as int?;
    final total = entry['participantCount'] as int? ?? 0;
    final submitted = entry['submitted'] as bool? ?? false;
    final startTime = entry['startTime'] != null
        ? DateTime.tryParse(entry['startTime'] as String)
        : null;

    final rankColor = rank == 1
        ? const Color(0xFFFFB300)
        : rank != null && rank <= 3
            ? AppTheme.secondaryBlue
            : AppTheme.textSecondary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: date + rank badge
            Row(
              children: [
                Icon(Icons.class_rounded, size: 18, color: AppTheme.secondaryBlue),
                const SizedBox(width: 6),
                Text(
                  startTime != null ? _formatDate(startTime) : 'Session',
                  style: const TextStyle(
                    fontSize: 13, color: AppTheme.textSecondary, fontFamily: 'Nunito',
                  ),
                ),
                const Spacer(),
                if (rank != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: rankColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '#$rank of $total',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: rankColor,
                        fontFamily: 'Nunito',
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      submitted ? 'No score' : 'Did not submit',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontFamily: 'Nunito'),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            // Words
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: words.map((w) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryBlue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(w,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: AppTheme.secondaryBlue, fontFamily: 'Nunito')),
              )).toList(),
            ),
            if (score != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.star_rounded, size: 16, color: Color(0xFFFFB300)),
                  const SizedBox(width: 4),
                  Text('$score pts',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary, fontFamily: 'Nunito')),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d).inDays;
    if (diff == 0) return 'Today ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    if (diff == 1) return 'Yesterday';
    return '${d.day}/${d.month}/${d.year}';
  }
}
