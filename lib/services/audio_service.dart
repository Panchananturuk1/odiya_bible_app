import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isPlaying = false;
  bool _isPaused = false;
  double _speechRate = 0.5;
  double _volume = 0.8;
  double _pitch = 1.0;
  String _currentLanguage = 'or-IN'; // Odia language code

  // Getters
  bool get isPlaying => _isPlaying;
  bool get isPaused => _isPaused;
  double get speechRate => _speechRate;
  double get volume => _volume;
  double get pitch => _pitch;
  String get currentLanguage => _currentLanguage;

  // Initialize TTS
  Future<void> initialize() async {
    try {
      await _flutterTts.setLanguage(_currentLanguage);
      await _flutterTts.setSpeechRate(_speechRate);
      await _flutterTts.setVolume(_volume);
      await _flutterTts.setPitch(_pitch);

      // Set up handlers
      _flutterTts.setStartHandler(() {
        _isPlaying = true;
        _isPaused = false;
      });

      _flutterTts.setCompletionHandler(() {
        _isPlaying = false;
        _isPaused = false;
      });

      _flutterTts.setCancelHandler(() {
        _isPlaying = false;
        _isPaused = false;
      });

      _flutterTts.setPauseHandler(() {
        _isPaused = true;
      });

      _flutterTts.setContinueHandler(() {
        _isPaused = false;
      });

      _flutterTts.setErrorHandler((msg) {
        debugPrint('TTS Error: $msg');
        _isPlaying = false;
        _isPaused = false;
      });
    } catch (e) {
      debugPrint('Error initializing TTS: $e');
    }
  }

  // Check if TTS is available for Odia
  Future<bool> isOdiaSupported() async {
    try {
      List<dynamic> languages = await _flutterTts.getLanguages;
      return languages.contains('or-IN') || languages.contains('or');
    } catch (e) {
      debugPrint('Error checking Odia support: $e');
      return false;
    }
  }

  // Speak text
  Future<void> speak(String text) async {
    try {
      if (_isPlaying) {
        await stop();
      }
      
      // If Odia is not supported, fallback to English
      bool odiaSupported = await isOdiaSupported();
      if (!odiaSupported) {
        await _flutterTts.setLanguage('en-US');
      }
      
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('Error speaking text: $e');
    }
  }

  // Pause speech
  Future<void> pause() async {
    try {
      await _flutterTts.pause();
    } catch (e) {
      debugPrint('Error pausing speech: $e');
    }
  }

  // Resume speech
  Future<void> resume() async {
    try {
      await _flutterTts.speak('');
    } catch (e) {
      debugPrint('Error resuming speech: $e');
    }
  }

  // Stop speech
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      _isPlaying = false;
      _isPaused = false;
    } catch (e) {
      debugPrint('Error stopping speech: $e');
    }
  }

  // Set speech rate (0.0 to 1.0)
  Future<void> setSpeechRate(double rate) async {
    try {
      _speechRate = rate.clamp(0.0, 1.0);
      await _flutterTts.setSpeechRate(_speechRate);
    } catch (e) {
      debugPrint('Error setting speech rate: $e');
    }
  }

  // Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    try {
      _volume = volume.clamp(0.0, 1.0);
      await _flutterTts.setVolume(_volume);
    } catch (e) {
      debugPrint('Error setting volume: $e');
    }
  }

  // Set pitch (0.5 to 2.0)
  Future<void> setPitch(double pitch) async {
    try {
      _pitch = pitch.clamp(0.5, 2.0);
      await _flutterTts.setPitch(_pitch);
    } catch (e) {
      debugPrint('Error setting pitch: $e');
    }
  }

  // Set language
  Future<void> setLanguage(String language) async {
    try {
      _currentLanguage = language;
      await _flutterTts.setLanguage(_currentLanguage);
    } catch (e) {
      debugPrint('Error setting language: $e');
    }
  }

  // Get available languages
  Future<List<String>> getAvailableLanguages() async {
    try {
      List<dynamic> languages = await _flutterTts.getLanguages;
      return languages.cast<String>();
    } catch (e) {
      debugPrint('Error getting available languages: $e');
      return [];
    }
  }

  // Set completion handler
  void setCompletionHandler(Function() handler) {
    _flutterTts.setCompletionHandler(handler);
  }

  // Dispose
  void dispose() {
    _flutterTts.stop();
  }
}