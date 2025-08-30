import 'package:flutter/foundation.dart';
import '../services/audio_service.dart';
import '../models/verse.dart';

class AudioProvider with ChangeNotifier {
  final AudioService _audioService = AudioService();
  
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _isPaused = false;
  Verse? _currentVerse;
  List<Verse> _playlist = [];
  int _currentIndex = 0;
  bool _isAutoPlay = false;
  double _speechRate = 0.5;
  double _volume = 0.8;
  double _pitch = 1.0;
  bool _isOdiaSupported = false;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isPlaying => _isPlaying;
  bool get isPaused => _isPaused;
  Verse? get currentVerse => _currentVerse;
  List<Verse> get playlist => _playlist;
  int get currentIndex => _currentIndex;
  bool get isAutoPlay => _isAutoPlay;
  double get speechRate => _speechRate;
  double get volume => _volume;
  double get pitch => _pitch;
  bool get isOdiaSupported => _isOdiaSupported;
  bool get hasNext => _currentIndex < _playlist.length - 1;
  bool get hasPrevious => _currentIndex > 0;

  // Initialize audio service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await _audioService.initialize();
      _isOdiaSupported = await _audioService.isOdiaSupported();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing audio provider: $e');
    }
  }

  // Play a single verse
  Future<void> playVerse(Verse verse) async {
    if (!_isInitialized) await initialize();
    
    try {
      _currentVerse = verse;
      _playlist = [verse];
      _currentIndex = 0;
      
      // For web platforms, try to initialize with user interaction first
      if (kIsWeb) {
        bool webInitialized = await _audioService.initializeWithUserInteraction();
        if (!webInitialized) {
          debugPrint('Web TTS initialization failed - audio may not work');
        }
      }
      
      await _audioService.speak(verse.odiyaText);
      _isPlaying = true;
      _isPaused = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error playing verse: $e');
      
      // Show user-friendly error for web audio issues
      if (kIsWeb && (e.toString().contains('WebAudioError') || e.toString().contains('audio context'))) {
        debugPrint('Web audio requires user interaction - please tap the audio button again');
      }
      
      _isPlaying = false;
      _isPaused = false;
      notifyListeners();
    }
  }

  // Play multiple verses (chapter)
  Future<void> playChapter(List<Verse> verses, {int startIndex = 0}) async {
    if (!_isInitialized) await initialize();
    if (verses.isEmpty) return;
    
    try {
      _playlist = verses;
      _currentIndex = startIndex.clamp(0, verses.length - 1);
      _currentVerse = _playlist[_currentIndex];
      _isAutoPlay = true;
      
      // For web platforms, try to initialize with user interaction first
      if (kIsWeb) {
        bool webInitialized = await _audioService.initializeWithUserInteraction();
        if (!webInitialized) {
          debugPrint('Web TTS initialization failed - audio may not work');
        }
      }
      
      await _audioService.speak(_currentVerse!.odiyaText);
      _isPlaying = true;
      _isPaused = false;
      notifyListeners();
      
      // Set up auto-play for next verse
      _setupAutoPlay();
    } catch (e) {
      debugPrint('Error playing chapter: $e');
      
      // Show user-friendly error for web audio issues
      if (kIsWeb && (e.toString().contains('WebAudioError') || e.toString().contains('audio context'))) {
        debugPrint('Web audio requires user interaction - please tap the audio button again');
      }
      
      _isPlaying = false;
      _isPaused = false;
      _isAutoPlay = false;
      notifyListeners();
    }
  }

  // Setup auto-play for continuous reading
  void _setupAutoPlay() {
    _audioService.setCompletionHandler(() {
      _isPlaying = false;
      _isPaused = false;
      
      if (_isAutoPlay && hasNext) {
        // Auto-play next verse after a short delay
        Future.delayed(const Duration(milliseconds: 500), () {
          playNext();
        });
      } else {
        _isAutoPlay = false;
        notifyListeners();
      }
    });
  }

  // Play next verse
  Future<void> playNext() async {
    if (!hasNext) return;
    
    _currentIndex++;
    _currentVerse = _playlist[_currentIndex];
    
    try {
      await _audioService.speak(_currentVerse!.odiyaText);
      _isPlaying = true;
      _isPaused = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error playing next verse: $e');
    }
  }

  // Play previous verse
  Future<void> playPrevious() async {
    if (!hasPrevious) return;
    
    _currentIndex--;
    _currentVerse = _playlist[_currentIndex];
    
    try {
      await _audioService.speak(_currentVerse!.odiyaText);
      _isPlaying = true;
      _isPaused = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error playing previous verse: $e');
    }
  }

  // Pause playback
  Future<void> pause() async {
    try {
      await _audioService.pause();
      _isPaused = true;
      _isPlaying = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error pausing playback: $e');
    }
  }

  // Resume playback
  Future<void> resume() async {
    try {
      if (_currentVerse != null) {
        await _audioService.speak(_currentVerse!.odiyaText);
        _isPlaying = true;
        _isPaused = false;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error resuming playback: $e');
    }
  }

  // Stop playback
  Future<void> stop() async {
    try {
      await _audioService.stop();
      _isPlaying = false;
      _isPaused = false;
      _isAutoPlay = false;
      _currentVerse = null;
      _playlist.clear();
      _currentIndex = 0;
      notifyListeners();
    } catch (e) {
      debugPrint('Error stopping playback: $e');
    }
  }

  // Toggle auto-play
  void toggleAutoPlay() {
    _isAutoPlay = !_isAutoPlay;
    notifyListeners();
  }

  // Set speech rate
  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate;
    await _audioService.setSpeechRate(rate);
    notifyListeners();
  }

  // Set volume
  Future<void> setVolume(double volume) async {
    _volume = volume;
    await _audioService.setVolume(volume);
    notifyListeners();
  }

  // Set pitch
  Future<void> setPitch(double pitch) async {
    _pitch = pitch;
    await _audioService.setPitch(pitch);
    notifyListeners();
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }
}