import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final data = await ApiService.getHistory();
      if (mounted) setState(() { _items = data; _loading = false; });
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _error = 'Cannot connect to server.'; _loading = false; });
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
          child: Column(
            children: [
              _buildTopBar(context),
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
          const SizedBox(width: 8),
          Text(
            '📜 Story History',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.primaryGreen,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error,
                style: TextStyle(color: AppTheme.accentPink, fontSize: 16),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🎭', style: TextStyle(fontSize: 64)),
            SizedBox(height: 16),
            Text(
              'No stories yet!\nPlay your first game.',
              style: TextStyle(fontSize: 18, color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _items.length,
      itemBuilder: (context, i) => _HistoryCard(item: _items[i], index: i),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final int index;

  const _HistoryCard({required this.item, required this.index});

  @override
  Widget build(BuildContext context) {
    final score = (item['scoreOverall'] as num?)?.toInt() ?? 0;
    final words = _parseList(item['targetWords']);
    final date = _formatDate(item['createdAt'] as String?);
    final scoreColor = score >= 80
        ? AppTheme.primaryGreen
        : score >= 60
            ? AppTheme.accentOrange
            : score >= 40
                ? AppTheme.secondaryBlue
                : AppTheme.accentPink;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _showDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(date,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          )),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: scoreColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$score / 100',
                      style: TextStyle(
                        color: scoreColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        fontFamily: 'Nunito',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: words
                    .map((w) => Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppTheme.secondaryBlue.withOpacity(0.3)),
                          ),
                          child: Text(
                            w,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.secondaryBlue,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Nunito',
                            ),
                          ),
                        ))
                    .toList(),
              ),
              if ((item['feedback'] as String?)?.isNotEmpty == true) ...[
                const SizedBox(height: 10),
                Text(
                  item['feedback'] as String,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(height: 1.4),
                ),
              ],
            ],
          ),
        ),
      ),
    ).animate(delay: (index * 60).ms).fadeIn(duration: 350.ms).slideY(begin: 0.15);
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetailSheet(item: item),
    );
  }

  static List<String> _parseList(dynamic val) {
    if (val == null) return [];
    if (val is List) return val.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
    if (val is String) return val.split(',').where((s) => s.isNotEmpty).toList();
    return [];
  }

  static String _formatDate(String? raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw;
    }
  }
}

class _DetailSheet extends StatelessWidget {
  final Map<String, dynamic> item;

  const _DetailSheet({required this.item});

  static List<String> _parseList(dynamic val) {
    if (val == null) return [];
    if (val is List) return val.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
    if (val is String) return val.split(',').where((s) => s.isNotEmpty).toList();
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final score = (item['scoreOverall'] as num?)?.toInt() ?? 0;
    final grammar = (item['scoreGrammar'] as num?)?.toInt() ?? 0;
    final creativity = (item['scoreCreativity'] as num?)?.toInt() ?? 0;
    final coherence = (item['scoreCoherence'] as num?)?.toInt() ?? 0;
    final wordUsage = (item['scoreWordUsage'] as num?)?.toInt() ?? 0;
    final wordsUsed = _parseList(item['wordsUsed']);
    final wordsMissing = _parseList(item['wordsMissing']);
    final feedback = item['feedback'] as String? ?? '';
    final encouragement = item['encouragement'] as String? ?? '';
    final storyText = item['storyText'] as String? ?? '';

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.all(24),
                children: [
                  // Overall score
                  Center(
                    child: Column(
                      children: [
                        Text(
                          '$score',
                          style: TextStyle(
                            fontSize: 64,
                            fontWeight: FontWeight.bold,
                            color: score >= 80
                                ? AppTheme.primaryGreen
                                : score >= 60
                                    ? AppTheme.accentOrange
                                    : AppTheme.accentPink,
                            fontFamily: 'Nunito',
                          ),
                        ),
                        Text('out of 100',
                            style: TextStyle(color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                  if (encouragement.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: AppGradients.primaryGradient,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        encouragement,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Nunito',
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  // Score breakdown
                  _sectionTitle(context, 'Score Breakdown'),
                  const SizedBox(height: 10),
                  _scoreRow(context, '📝 Grammar', grammar, AppTheme.secondaryBlue),
                  _scoreRow(context, '🎨 Creativity', creativity, AppTheme.accentPurple),
                  _scoreRow(context, '🔗 Coherence', coherence, AppTheme.accentOrange),
                  _scoreRow(context, '🎯 Word Usage', wordUsage, AppTheme.primaryGreen),
                  const SizedBox(height: 20),
                  // Word report
                  if (wordsUsed.isNotEmpty || wordsMissing.isNotEmpty) ...[
                    _sectionTitle(context, 'Word Report'),
                    const SizedBox(height: 10),
                    if (wordsUsed.isNotEmpty) ...[
                      Text('✅ Used:',
                          style: TextStyle(
                              color: AppTheme.primaryGreen,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: wordsUsed
                            .map((w) => Chip(
                                  label: Text(w,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold)),
                                  backgroundColor: AppTheme.primaryGreen,
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (wordsMissing.isNotEmpty) ...[
                      Text('❌ Missed:',
                          style: TextStyle(
                              color: AppTheme.accentPink,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: wordsMissing
                            .map((w) => Chip(
                                  label: Text(w,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold)),
                                  backgroundColor: AppTheme.accentPink,
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ],
                  // Feedback
                  if (feedback.isNotEmpty) ...[
                    _sectionTitle(context, '💬 Teacher\'s Feedback'),
                    const SizedBox(height: 10),
                    Text(feedback,
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(height: 1.6, color: AppTheme.textPrimary)),
                    const SizedBox(height: 20),
                  ],
                  // Story text
                  if (storyText.isNotEmpty) ...[
                    _sectionTitle(context, '📖 Your Story'),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Text(
                        storyText,
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(height: 1.6),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _scoreRow(BuildContext context, String label, int score, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Nunito',
                      fontSize: 14)),
              Text('$score/100',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontFamily: 'Nunito')),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: score / 100,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 10,
            ),
          ),
        ],
      ),
    );
  }
}
