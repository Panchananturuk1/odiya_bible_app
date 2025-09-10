import 'package:flutter/foundation.dart';
import '../services/audio_streaming_service.dart';
import '../services/bible_brain_api_service.dart';
import '../services/json_bible_service.dart';
import '../models/verse.dart';
import 'dart:async';

class AudioStreamingProvider with ChangeNotifier {
  final AudioStreamingService _audioService = AudioStreamingService();
  final BibleBrainApiService _apiService = BibleBrainApiService();
  
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _isPaused = false;
  bool _isLoading = false;
  bool _isBuffering = false;
  bool _isVisible = false;
  bool _isExpanded = false;
  
  // Current playback state
  String? _currentBookId;
  int? _currentChapter;
  int? _currentVerse;
  List<Verse> _currentChapterVerses = [];
  
  // Audio file info
  String? _currentAudioUrl;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  double _playbackSpeed = 1.0;
  double _volume = 1.0;
  
  // Removed: provider-level verse timings; AudioStreamingService manages timings internally

  // Small delay to better sync visual highlight with perceived audio speech
  // Positive value means the highlight will switch a bit later (prevents being ahead of audio)
  int _highlightDelayMs = 250; // default ~250ms visual delay
  int get highlightDelayMs => _highlightDelayMs;
  void setHighlightDelay(int milliseconds) {
    final clamped = milliseconds < 0 ? 0 : (milliseconds > 2000 ? 2000 : milliseconds);
    _highlightDelayMs = clamped;
    // Also inform the service so its internal verse index (fallback path) stays consistent
    _audioService.setHighlightDelayMs(_highlightDelayMs);
    notifyListeners();
  }
  
  // Download progress
  double _downloadProgress = 0.0;
  bool _isDownloading = false;
  
  // Getters
  bool get isInitialized => _isInitialized;
  bool get isApiServiceInitialized => _apiService.isInitialized;
  bool get isPlaying => _isPlaying;
  bool get isPaused => _isPaused;
  bool get isLoading => _isLoading;
  bool get isBuffering => _isBuffering;
  bool get isVisible => _isVisible;
  bool get isExpanded => _isExpanded;
  
  String? get currentBookId => _currentBookId;
  int? get currentChapter => _currentChapter;
  int? get currentVerse => _currentVerse;
  List<Verse> get currentChapterVerses => _currentChapterVerses;
  
  String? get currentAudioUrl => _currentAudioUrl;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;
  double get playbackSpeed => _playbackSpeed;
  double get volume => _volume;
  
  // Removed verseTimings getter; timings handled by AudioStreamingService
  
  double get downloadProgress => _downloadProgress;
  bool get isDownloading => _isDownloading;
  
  // Computed getters
  bool get hasAudio => _currentAudioUrl != null || (_audioService.currentVerses.isNotEmpty && _audioService.playbackMode == AudioPlaybackMode.tts);
  double get progress => _totalDuration.inMilliseconds > 0 
      ? _currentPosition.inMilliseconds / _totalDuration.inMilliseconds 
      : 0.0;
  
  // Get currently playing verse for UI highlight
  // Prefer the AudioStreamingService's verse index (already adjusted with highlight delay and end-time windows)
  int get currentPlayingVerse {
    if (_currentVerse != null) {
      // Service emits 0-based index; verse numbers are 1-based
      return (_currentVerse! + 1).clamp(1, _currentChapterVerses.isNotEmpty ? _currentChapterVerses.length : _currentVerse! + 1);
    }
    // Nothing to highlight yet
    return 0;
  }
  
  // Initialize the audio streaming service
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    try {
      // Initialize audio service
      await _audioService.initialize();
      // Keep service delay in sync with provider setting
      _audioService.setHighlightDelayMs(_highlightDelayMs);
      
      // Initialize Bible Brain API service with error handling (skip on web)
      if (!kIsWeb) {
        final apiInitialized = await _apiService.initialize();
        if (!apiInitialized) {
          debugPrint('Warning: Bible Brain API service failed to initialize');
          // Continue without API - app can still work with TTS
        }
      } else {
        debugPrint('Skipping Bible Brain API initialization on web platform');
      }
      
      // Set up listeners for audio service events
      _audioService.positionStream.listen((position) {
        _currentPosition = position;
        notifyListeners();
      });
      
      _audioService.durationStream.listen((duration) {
        _totalDuration = duration;
        notifyListeners();
      });
      
      _audioService.stateStream.listen((state) {
        _isPlaying = state == AudioPlayerState.playing;
        _isPaused = state == AudioPlayerState.paused;
        _isLoading = state == AudioPlayerState.loading;
        notifyListeners();
      });
      
      _audioService.currentVerseStream.listen((verseIndex) {
        _currentVerse = verseIndex;
        notifyListeners();
      });
      
      _isInitialized = true;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error initializing audio streaming provider: $e');
      _isInitialized = false;
      notifyListeners();
      return false;
    }
  }
  
  // Load audio for a specific chapter
  Future<void> loadChapterAudio(String bookId, int chapter, List<Verse> verses) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        debugPrint('Failed to initialize audio streaming provider');
        return;
      }
    }
    
    _setLoading(true);
    
    try {
      // Stop current playbook
      await stop();
      
      // Do NOT convert to abbreviation here; the service will resolve numeric IDs to English names and USX codes
      debugPrint('Loading chapter audio for book input "$bookId" (will normalize in service)');
      
      // Update current chapter info
      _currentBookId = bookId;
      _currentChapter = chapter;
      _currentChapterVerses = verses;
      _currentVerse = null;
      
      // Try to load audio using the AudioStreamingService (which has fallback logic)
      try {
        // The AudioStreamingService will try Bible Brain API first, then fallback to TTS
        await _audioService.loadChapterAudio(bookId, chapter.toString(), mode: AudioPlaybackMode.streaming, verses: verses);
        
        // Capture the resolved audio URL from the service so UI knows audio is available
        _currentAudioUrl = _audioService.currentAudioUrl;
        debugPrint('Audio URL set to: $_currentAudioUrl');
        notifyListeners();
        
        // On web, show the audio player UI as soon as audio is loaded,
        // so the user can press Play (required due to autoplay policies)
        if (kIsWeb && (_currentAudioUrl != null || _audioService.playbackMode == AudioPlaybackMode.tts)) {
          _isVisible = true;
          debugPrint('Audio player visibility set to true on web after load');
          notifyListeners();
        }
        
        // Verse timings are handled by AudioStreamingService; avoid duplicate fetching here
        // (no-op)
      } catch (e) {
        debugPrint('Failed to load audio for $bookId chapter $chapter: $e');
        _currentAudioUrl = null;
        // no-op for verse timings
      }
      
    } catch (e) {
      debugPrint('Error loading chapter audio: $e');
      _currentAudioUrl = null;
      // no-op for verse timings
      
      // Show user-friendly error message based on exception type
      if (e.toString().contains('Authentication failed')) {
        debugPrint('Audio service authentication failed');
      } else if (e.toString().contains('Connection timeout')) {
        debugPrint('Audio service connection timeout');
      } else if (e.toString().contains('Rate limit exceeded')) {
        debugPrint('Audio service rate limit exceeded');
      }
    } finally {
      _setLoading(false);
    }
  }
  
  // Play audio
  Future<void> play() async {
    debugPrint('Play method called. hasAudio: $hasAudio, currentAudioUrl: $_currentAudioUrl, isInitialized: $_isInitialized');
    
    // Always show the audio player when play is clicked, even if no audio is available
    _isVisible = true;
    debugPrint('Audio player visibility set to true');
    notifyListeners();
    
    if (!hasAudio) {
      debugPrint('No audio available to play. Audio player shown but no playback will start.');
      return;
    }
    
    try {
      await _audioService.play();
      debugPrint('Audio service play() completed successfully');
    } catch (e) {
      debugPrint('Error playing audio: $e');
    }
  }
  
  // Pause audio
  Future<void> pause() async {
    try {
      await _audioService.pause();
    } catch (e) {
      debugPrint('Error pausing audio: $e');
    }
  }
  
  // Stop audio
  Future<void> stop() async {
    try {
      await _audioService.stop();
      _currentPosition = Duration.zero;
      _currentVerse = null;
      _isVisible = false; // Hide the audio player when stopped
      notifyListeners();
    } catch (e) {
      debugPrint('Error stopping audio: $e');
    }
  }
  
  // Hide audio player
  void hideAudioPlayer() {
    _isVisible = false;
    notifyListeners();
  }
  
  // Toggle expanded state
  void toggleExpanded() {
    _isExpanded = !_isExpanded;
    notifyListeners();
  }
  
  // Seek to position
  Future<void> seek(Duration position) async {
    // Avoid seeking when we don't have an active audio or known duration
    if (!hasAudio || _isLoading || _totalDuration == Duration.zero) {
      return;
    }

    // Clamp target within valid range
    final clamped = position < Duration.zero
        ? Duration.zero
        : (position > _totalDuration ? _totalDuration : position);

    try {
      await _audioService.seekTo(clamped);
    } catch (e) {
      debugPrint('Error seeking audio: $e');
    }
  }
  
  // Seek to specific verse
  Future<void> seekToVerse(int verseNumber) async {
    if (verseNumber <= 0) return;
    try {
      // If the service hasn't emitted any verse index yet, wait briefly for it.
      if (_currentVerse == null) {
        try {
          await _audioService.currentVerseStream.first.timeout(const Duration(seconds: 3));
        } catch (_) {
          // Timeout or stream error; proceed to attempt jump anyway
        }
      }
      await _audioService.jumpToVerse(verseNumber - 1);
    } catch (e) {
      debugPrint('Error seeking to verse $verseNumber: $e');
    }
  }
  
  // Skip forward 10 seconds
  Future<void> skipForward() async {
    final newPosition = _currentPosition + const Duration(seconds: 10);
    if (newPosition <= _totalDuration) {
      await seek(newPosition);
    }
  }
  
  // Skip backward 10 seconds
  Future<void> skipBackward() async {
    final newPosition = _currentPosition - const Duration(seconds: 10);
    if (newPosition >= Duration.zero) {
      await seek(newPosition);
    } else {
      await seek(Duration.zero);
    }
  }
  
  // Set playback speed
  Future<void> setPlaybackSpeed(double speed) async {
    try {
      await _audioService.setPlaybackSpeed(speed);
      _playbackSpeed = speed;
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting playback speed: $e');
    }
  }
  
  // Set volume
  Future<void> setVolume(double volume) async {
    try {
      await _audioService.setVolume(volume);
      _volume = volume;
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting volume: $e');
    }
  }
  
  // Download chapter for offline playback
  Future<bool> downloadChapter(String bookId, int chapter) async {
    if (_isDownloading) return false;
    
    if (kIsWeb || !_apiService.isInitialized) {
      debugPrint('Bible Brain API not available on web or not initialized for download');
      return false;
    }
    
    _isDownloading = true;
    _downloadProgress = 0.0;
    notifyListeners();
    
    try {
      // Use the service to normalize book and handle USX/URL creation and caching consistently
      final success = await _audioService.downloadChapterForOffline(bookId, chapter.toString());
      if (success) {
        debugPrint('Chapter $bookId:$chapter downloaded successfully');
        return true;
      } else {
        debugPrint('Failed to download chapter $bookId:$chapter');
        return false;
      }
    } catch (e) {
      debugPrint('Error downloading chapter: $e');
      return false;
    } finally {
      _isDownloading = false;
      _downloadProgress = 0.0;
      notifyListeners();
    }
  }
  
  // Check if chapter is downloaded
  Future<bool> isChapterDownloaded(String bookId, int chapter) async {
    if (kIsWeb || !_apiService.isInitialized) return false;
    
    try {
      // Route through service so numeric IDs are converted to English book names correctly
      return await _audioService.isChapterAvailableOffline(bookId, chapter.toString());
    } catch (e) {
      debugPrint('Error checking if chapter is downloaded: $e');
      return false;
    }
  }
  
  // Helper method to load cached audio
  Future<bool> _loadCachedAudio(String bookId, String chapter) async {
    if (kIsWeb || !_apiService.isInitialized) return false;
    
    try {
      // Normalize bookId to English book name for cache filename consistency
      final normalizedBookName = RegExp(r'^\d+$').hasMatch(bookId)
          ? JsonBibleService.getBookNameById(int.parse(bookId))
          : bookId;
      final cachedPath = await _apiService.getCachedAudioPath(normalizedBookName, chapter);
      if (cachedPath != null) {
        await _audioService.loadChapterAudio(bookId, chapter, mode: AudioPlaybackMode.offline);
        debugPrint('Loaded cached audio from: $cachedPath');
        return true;
      }
    } catch (e) {
      debugPrint('Error loading cached audio: $e');
    }
    return false;
  }
  
  // Get available Odia Bible versions
  Future<List<Map<String, dynamic>>> getOdiaBibleVersions() async {
    if (kIsWeb || !_apiService.isInitialized) {
      debugPrint('Bible Brain API not available on web or not initialized');
      return [];
    }
    
    try {
      return await _apiService.getOdiaBibleVersions();
    } catch (e) {
      debugPrint('Error fetching Odia Bible versions: $e');
      return [];
    }
  }
  
  // Cache management methods
  Future<Map<String, dynamic>> getCacheStats() async {
    if (kIsWeb || !_apiService.isInitialized) {
      return {
        'fileCount': 0,
        'totalSize': 0,
        'files': <Map<String, dynamic>>[],
      };
    }
    
    try {
      return await _apiService.getCacheStats();
    } catch (e) {
      debugPrint('Error getting cache stats: $e');
      return {
        'fileCount': 0,
        'totalSize': 0,
        'files': <Map<String, dynamic>>[],
      };
    }
  }
  
  Future<bool> clearAudioCache() async {
    if (kIsWeb || !_apiService.isInitialized) return false;
    
    try {
      return await _apiService.clearAudioCache();
    } catch (e) {
      debugPrint('Error clearing audio cache: $e');
      return false;
    }
  }
  
  Future<bool> clearCachedAudio(String bookId, String chapter) async {
    if (kIsWeb || !_apiService.isInitialized) return false;
    
    try {
      // Normalize to English name before clearing specific cached file
      final normalizedBookName = RegExp(r'^\d+$').hasMatch(bookId)
          ? JsonBibleService.getBookNameById(int.parse(bookId))
          : bookId;
      return await _apiService.clearCachedAudio(normalizedBookName, chapter);
    } catch (e) {
      debugPrint('Error clearing cached audio: $e');
      return false;
    }
  }
  
  Future<int> cleanupCache() async {
    if (kIsWeb || !_apiService.isInitialized) return 0;
    
    try {
      return await _apiService.cleanupCache();
    } catch (e) {
      debugPrint('Error cleaning up cache: $e');
      return 0;
    }
  }
  
  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }
}