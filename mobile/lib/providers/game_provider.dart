import 'package:flutter/material.dart';
import '../services/api_service.dart';

enum GameState { idle, loadingWords, ready, submitting, completed, error }

class WordItem {
  final String id;
  final String text;
  final String category;
  final String difficulty;

  WordItem({
    required this.id,
    required this.text,
    required this.category,
    required this.difficulty,
  });

  factory WordItem.fromJson(Map<String, dynamic> j) => WordItem(
        id: j['id'] as String,
        text: j['text'] as String,
        category: j['category'] as String,
        difficulty: j['difficulty'] as String,
      );
}

class EvaluationResult {
  final int grammar;
  final int creativity;
  final int coherence;
  final int wordUsage;
  final int overall;
  final List<String> wordsUsed;
  final List<String> wordsMissing;
  final String feedback;
  final String encouragement;
  final bool challengeRewardGranted;

  EvaluationResult.fromJson(Map<String, dynamic> j)
      : grammar = j['scoreGrammar'] as int,
        creativity = j['scoreCreativity'] as int,
        coherence = j['scoreCoherence'] as int,
        wordUsage = j['scoreWordUsage'] as int,
        overall = j['scoreOverall'] as int,
        wordsUsed = _parseList(j['wordsUsed']),
        wordsMissing = _parseList(j['wordsMissing']),
        feedback = j['feedback'] as String? ?? '',
        encouragement = j['encouragement'] as String? ?? '',
        challengeRewardGranted = j['challengeRewardGranted'] as bool? ?? false;

  // Helper to safely parse a field that may be List or comma-separated String
  static List<String> _parseList(dynamic val) {
    if (val == null) return [];
    if (val is List) return val.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
    if (val is String) return val.split(',').where((s) => s.isNotEmpty).toList();
    return [];
  }
}

class GameProvider extends ChangeNotifier {
  GameState _state = GameState.idle;
  List<WordItem> _words = [];
  int _wordCount = 5;
  String _difficulty = 'easy';
  EvaluationResult? _result;
  String _error = '';

  GameState get state => _state;
  List<WordItem> get words => _words;
  int get wordCount => _wordCount;
  String get difficulty => _difficulty;
  EvaluationResult? get result => _result;
  String get error => _error;

  void setWordCount(int count) {
    _wordCount = count;
    notifyListeners();
  }

  void setDifficulty(String diff) {
    _difficulty = diff;
    notifyListeners();
  }

  Future<bool> loadRandomWords() async {
    _state = GameState.loadingWords;
    _error = '';
    notifyListeners();

    try {
      final data = await ApiService.getRandomWords(
        count: _wordCount,
        difficulty: _difficulty,
      );
      _words = data.map((j) => WordItem.fromJson(j)).toList();
      _state = GameState.ready;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _state = GameState.error;
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'Cannot connect to server. Check your connection.';
      _state = GameState.error;
      notifyListeners();
      return false;
    }
  }

  Future<EvaluationResult?> submitStory(String storyText) async {
    _state = GameState.submitting;
    _error = '';
    notifyListeners();

    try {
      final data = await ApiService.submitStory(
        storyText: storyText,
        targetWords: _words.map((w) => w.text).toList(),
      );
      _result = EvaluationResult.fromJson(data);
      _state = GameState.completed;
      notifyListeners();
      return _result;
    } on ApiException catch (e) {
      _error = e.message;
      _state = GameState.error;
      notifyListeners();
      return null;
    } catch (_) {
      _error = 'Cannot connect to server. Check your connection.';
      _state = GameState.error;
      notifyListeners();
      return null;
    }
  }

  void reset() {
    _state = GameState.idle;
    _words = [];
    _result = null;
    _error = '';
    notifyListeners();
  }
}
