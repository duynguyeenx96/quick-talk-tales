import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

enum SpeechState { idle, listening, processing, completed, error }

class SpeechProvider extends ChangeNotifier {
  final SpeechToText _speechToText = SpeechToText();

  SpeechState _state = SpeechState.idle;
  String _transcribedText = '';
  bool _isConnected = false; // kept for UI compatibility
  String _errorMessage = '';

  // Getters
  SpeechState get state => _state;
  String get transcribedText => _transcribedText;
  bool get isConnected => _isConnected;
  bool get isListening => _state == SpeechState.listening;
  bool get isProcessing => _state == SpeechState.processing;
  String get errorMessage => _errorMessage;

  Future<void> initialize() async {
    try {
      final available = await _speechToText.initialize(
        onError: (e) => _handleError(e.errorMsg),
        onStatus: (status) {
          if (status == 'notListening' && _state == SpeechState.listening) {
            _setState(SpeechState.completed);
            notifyListeners();
          }
        },
      );
      _isConnected = available;
      _setState(SpeechState.idle);
      notifyListeners();
    } catch (e) {
      _handleError(e.toString());
    }
  }

  Future<void> startListening() async {
    if (!_isConnected) {
      await initialize();
      if (!_isConnected) return;
    }

    _transcribedText = '';
    _setState(SpeechState.listening);

    await _speechToText.listen(
      onResult: (result) {
        _transcribedText = result.recognizedWords;
        notifyListeners();
      },
      listenMode: ListenMode.dictation,
      cancelOnError: false,
      partialResults: true,
    );

    notifyListeners();
  }

  Future<void> stopListening() async {
    if (_state != SpeechState.listening) return;
    _setState(SpeechState.processing);
    await _speechToText.stop();
    _setState(SpeechState.completed);
    notifyListeners();
  }

  void _handleError(String error) {
    _errorMessage = error;
    _setState(SpeechState.error);
    notifyListeners();
  }

  void _setState(SpeechState newState) {
    _state = newState;
    if (newState != SpeechState.error) _errorMessage = '';
  }

  void reset() {
    _transcribedText = '';
    _errorMessage = '';
    _setState(SpeechState.idle);
    notifyListeners();
  }

  @override
  void dispose() {
    _speechToText.stop();
    super.dispose();
  }
}
