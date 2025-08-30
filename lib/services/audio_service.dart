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
      debugPrint('Initializing TTS service...');
      
      // Check available languages first
      List<dynamic> languages = await _flutterTts.getLanguages;
      debugPrint('Available TTS languages: $languages');
      
      await _flutterTts.setLanguage(_currentLanguage);
      await _flutterTts.setSpeechRate(_speechRate);
      await _flutterTts.setVolume(_volume);
      await _flutterTts.setPitch(_pitch);
      
      debugPrint('TTS settings applied: language=$_currentLanguage, rate=$_speechRate, volume=$_volume, pitch=$_pitch');

      // Set up handlers
      _flutterTts.setStartHandler(() {
        debugPrint('TTS started speaking');
        _isPlaying = true;
        _isPaused = false;
      });

      _flutterTts.setCompletionHandler(() {
        debugPrint('TTS completed speaking');
        _isPlaying = false;
        _isPaused = false;
      });

      _flutterTts.setCancelHandler(() {
        debugPrint('TTS cancelled');
        _isPlaying = false;
        _isPaused = false;
      });

      _flutterTts.setPauseHandler(() {
        debugPrint('TTS paused');
        _isPaused = true;
      });

      _flutterTts.setContinueHandler(() {
        debugPrint('TTS resumed');
        _isPaused = false;
      });

      _flutterTts.setErrorHandler((msg) {
        debugPrint('TTS Error: $msg');
        _isPlaying = false;
        _isPaused = false;
      });
      
      debugPrint('TTS service initialized successfully');
      
      // Test TTS on web platform
      if (kIsWeb) {
        debugPrint('Testing TTS on web platform...');
        // Note: This test speak might not work due to browser autoplay policy
        // but it will help us see if TTS is properly initialized
      }
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

  // Test if TTS is working (for web platform user interaction)
  Future<bool> testTTS() async {
    try {
      debugPrint('Testing TTS functionality...');
      
      if (kIsWeb) {
        // On web, test with a very short text and timeout
        await _flutterTts.speak('').timeout(Duration(seconds: 2));
        await Future.delayed(Duration(milliseconds: 100));
        await _flutterTts.speak('Test').timeout(Duration(seconds: 3));
      } else {
        await _flutterTts.speak('Test');
      }
      
      return true;
    } catch (e) {
      debugPrint('TTS test failed: $e');
      return false;
    }
  }

  // Initialize TTS with user interaction (for web platforms)
  Future<bool> initializeWithUserInteraction() async {
    if (!kIsWeb) return true;
    
    try {
      debugPrint('Initializing TTS with user interaction for web...');
      
      // First, try to speak an empty string to initialize the audio context
      await _flutterTts.speak('');
      await Future.delayed(Duration(milliseconds: 100));
      
      // Then test with actual speech
      await _flutterTts.speak('Audio ready');
      
      debugPrint('TTS initialized successfully with user interaction');
      return true;
    } catch (e) {
      debugPrint('Failed to initialize TTS with user interaction: $e');
      return false;
    }
  }

  // Speak text
  Future<void> speak(String text) async {
    try {
      debugPrint('TTS speak called with text: ${text.substring(0, text.length > 50 ? 50 : text.length)}...');
      
      if (_isPlaying) {
        debugPrint('TTS already playing, stopping current speech');
        await stop();
      }
      
      // If Odia is not supported, fallback to English
      bool odiaSupported = await isOdiaSupported();
      debugPrint('Odia language supported: $odiaSupported');
      if (!odiaSupported) {
        debugPrint('Falling back to English language');
        await _flutterTts.setLanguage('en-US');
      }
      
      // On web, add additional error handling for audio context issues
      if (kIsWeb) {
        try {
          // Test if TTS is available before speaking
          await _flutterTts.awaitSpeakCompletion(false);
          debugPrint('Web TTS: awaitSpeakCompletion set to false');
          
          // Try to initialize audio context if not already done
          await _flutterTts.speak('');
          await Future.delayed(Duration(milliseconds: 50));
        } catch (e) {
          debugPrint('Web TTS: Could not set awaitSpeakCompletion or initialize audio context: $e');
        }
      }
      
      debugPrint('Calling _flutterTts.speak()...');
      await _flutterTts.speak(text);
      debugPrint('_flutterTts.speak() call completed');
    } catch (e) {
      debugPrint('Error speaking text: $e');
      
      // On web, if TTS fails due to audio context issues, provide helpful error
      if (kIsWeb && (e.toString().contains('WebAudioError') || e.toString().contains('Failed to set source'))) {
        debugPrint('Web TTS failed - likely due to browser audio policy or audio context issues');
        throw Exception('Web TTS unavailable - browser may require user interaction for audio');
      }
      
      rethrow; // Rethrow to let caller handle the error
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