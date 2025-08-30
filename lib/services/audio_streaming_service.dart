import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'bible_brain_api_service.dart';
import 'usx_parser.dart';
import 'audio_service.dart';
import 'json_bible_service.dart';
import '../models/verse.dart';

enum AudioPlaybackMode {
  streaming, // Stream from Bible Brain API
  tts,       // Text-to-speech
  offline    // Play cached audio files
}

enum AudioPlayerState {
  stopped,
  playing,
  paused,
  loading,
  error
}

class AudioStreamingService {
  static final AudioStreamingService _instance = AudioStreamingService._internal();
  factory AudioStreamingService() => _instance;
  AudioStreamingService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  final BibleBrainApiService _bibleBrainApi = BibleBrainApiService();
  final AudioService _ttsService = AudioService();
  
  // State management
  AudioPlayerState _playerState = AudioPlayerState.stopped;
  AudioPlaybackMode _playbackMode = AudioPlaybackMode.streaming;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  double _playbackSpeed = 1.0;
  double _volume = 1.0;
  
  // Current playing content
  String? _currentBookName;
  String? _currentChapter;
  String? _currentAudioUrl;
  List<Map<String, dynamic>> _verseTimings = [];
  int _currentVerseIndex = 0;
  List<Verse> _currentVerses = [];
  Timer? _ttsTimer;
  
  // Stream controllers for UI updates
  final StreamController<AudioPlayerState> _stateController = StreamController<AudioPlayerState>.broadcast();
  final StreamController<Duration> _positionController = StreamController<Duration>.broadcast();
  final StreamController<Duration> _durationController = StreamController<Duration>.broadcast();
  final StreamController<int> _currentVerseController = StreamController<int>.broadcast();
  
  // Getters
  AudioPlayerState get playerState => _playerState;
  AudioPlaybackMode get playbackMode => _playbackMode;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;
  double get playbackSpeed => _playbackSpeed;
  double get volume => _volume;
  String? get currentBookName => _currentBookName;
  String? get currentChapter => _currentChapter;
  int get currentVerseIndex => _currentVerseIndex;
  String? get currentAudioUrl => _currentAudioUrl;
  List<Verse> get currentVerses => _currentVerses;
  
  // Streams
  Stream<AudioPlayerState> get stateStream => _stateController.stream;
  Stream<Duration> get positionStream => _positionController.stream;
  Stream<Duration> get durationStream => _durationController.stream;
  Stream<int> get currentVerseStream => _currentVerseController.stream;
  
  // Initialize the service
  Future<void> initialize() async {
    try {
      if (!kIsWeb) {
        await _bibleBrainApi.initialize();
      } else {
        debugPrint('Web platform detected: skipping BibleBrain API initialization to avoid CORS/422 noise');
      }

      // Initialize TTS service
      await _ttsService.initialize();

      // Set up audio player listeners
      _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
        switch (state) {
          case PlayerState.playing:
            _updatePlayerState(AudioPlayerState.playing);
            break;
          case PlayerState.paused:
            _updatePlayerState(AudioPlayerState.paused);
            break;
          case PlayerState.stopped:
            _updatePlayerState(AudioPlayerState.stopped);
            break;
          case PlayerState.completed:
            _updatePlayerState(AudioPlayerState.stopped);
            _onPlaybackCompleted();
            break;
          case PlayerState.disposed:
            _updatePlayerState(AudioPlayerState.stopped);
            break;
        }
      });

      _audioPlayer.onPositionChanged.listen((Duration position) {
        _currentPosition = position;
        _positionController.add(position);
        _updateCurrentVerse(position);
      });

      _audioPlayer.onDurationChanged.listen((Duration duration) {
        _totalDuration = duration;
        _durationController.add(duration);
      });
    } catch (e) {
      debugPrint('Error initializing AudioStreamingService: $e');
    }
  }
  
  // Load audio for a specific chapter (without auto-playing)
  Future<void> loadChapterAudio(String bookName, String chapterNumber, {AudioPlaybackMode? mode, List<Verse>? verses}) async {
    try {
      debugPrint('=== Loading audio for $bookName chapter $chapterNumber ===');
      debugPrint('Requested mode: $mode');
      debugPrint('Verses provided: ${verses?.length ?? 0}');
      
      _updatePlayerState(AudioPlayerState.loading);
      
      _currentBookName = bookName;
      _currentChapter = chapterNumber;
      _currentVerses = verses ?? [];
      _playbackMode = mode ?? AudioPlaybackMode.streaming;
      
      debugPrint('Current playback mode: $_playbackMode');
      debugPrint('Current verses count: ${_currentVerses.length}');
      
      // Removed web-specific forced TTS to allow streaming on web as well
      // if (kIsWeb) {
      //   debugPrint('Web platform detected - using TTS mode directly');
      //   _playbackMode = AudioPlaybackMode.tts;
      //   _currentAudioUrl = null;
      //   if (_currentVerses.isNotEmpty) {
      //     String allText = _currentVerses.map((v) => v.odiyaText).join(' ');
      //     _totalDuration = _calculateTtsDuration(allText);
      //     _durationController.add(_totalDuration);
      //     debugPrint('Set TTS duration for web: ${_totalDuration.inSeconds} seconds');
      //   }
      //   _updatePlayerState(AudioPlayerState.paused);
      //   return;
      // }
      
      String? audioSource;
      
      switch (_playbackMode) {
        case AudioPlaybackMode.offline:
          debugPrint('Attempting to get offline audio source...');
          audioSource = await _getOfflineAudioSource(bookName, chapterNumber);
          debugPrint('Offline audio source result: $audioSource');
          break;
        case AudioPlaybackMode.streaming:
          debugPrint('Attempting to get streaming audio source...');
          audioSource = await _getStreamingAudioSource(bookName, chapterNumber);
          debugPrint('Streaming audio source result: $audioSource');
          break;
        case AudioPlaybackMode.tts:
          debugPrint('TTS mode selected - will be handled separately');
          // TTS will be handled separately
          break;
      }
      
      if (audioSource != null) {
        try {
          debugPrint('Setting audio source: $audioSource');
          // Set the audio source without playing
          if (kIsWeb && audioSource.startsWith('http')) {
            // On web, defer setting the source until play() to avoid long load timeouts
            debugPrint('Web detected: deferring setting source until play()');
            _currentAudioUrl = audioSource;
          } else if (audioSource.startsWith('http')) {
            debugPrint('Loading URL source...');
            final _mime = _guessMimeType(audioSource);
            await _audioPlayer.setSource(UrlSource(audioSource, mimeType: _mime));
            _currentAudioUrl = audioSource;
          } else {
            debugPrint('Loading device file source...');
            await _audioPlayer.setSource(DeviceFileSource(audioSource));
            _currentAudioUrl = audioSource;
          }
          debugPrint('Loading verse timings...');
          await _loadVerseTimings(bookName, chapterNumber);
          _updatePlayerState(AudioPlayerState.paused); // Ready to play
          debugPrint('Audio loaded successfully for $bookName chapter $chapterNumber');
        } catch (e) {
          debugPrint('Error setting audio source: $e - falling back to TTS');
          // If setting audio source fails and we have verses, switch to TTS
          if (_currentVerses.isNotEmpty) {
            _playbackMode = AudioPlaybackMode.tts;
            _currentAudioUrl = null;
            String allText = _currentVerses.map((v) => v.odiyaText).join(' ');
            _totalDuration = _calculateTtsDuration(allText);
            _durationController.add(_totalDuration);
            debugPrint('Set TTS duration after audio source error: ${_totalDuration.inSeconds} seconds');
            _updatePlayerState(AudioPlayerState.paused);
          } else {
            _currentAudioUrl = null;
            _updatePlayerState(AudioPlayerState.error);
          }
        }
      } else {
        // If no audio source and we have verses, automatically switch to TTS
        if (_currentVerses.isNotEmpty) {
          debugPrint('No audio source available, switching to TTS mode for $bookName chapter $chapterNumber');
          _playbackMode = AudioPlaybackMode.tts;
          _currentAudioUrl = null;
          // Calculate and set TTS duration
          String allText = _currentVerses.map((v) => v.odiyaText).join(' ');
          _totalDuration = _calculateTtsDuration(allText);
          _durationController.add(_totalDuration);
          debugPrint('Set TTS duration: ${_totalDuration.inSeconds} seconds for ${_currentVerses.length} verses');
          _updatePlayerState(AudioPlayerState.paused); // Ready to play with TTS
        } else {
          _currentAudioUrl = null;
          _updatePlayerState(AudioPlayerState.error);
        }
      }
    } catch (e) {
      debugPrint('Error loading audio: $e');
      _currentAudioUrl = null;
      _updatePlayerState(AudioPlayerState.error);
    }
  }
  
  // Play audio for a specific chapter (loads and plays immediately)
  Future<void> playChapter(String bookName, String chapterNumber, {AudioPlaybackMode? mode, List<Verse>? verses}) async {
    await loadChapterAudio(bookName, chapterNumber, mode: mode, verses: verses);
    await play();
  }
  
  // Get offline audio source
  Future<String?> _getOfflineAudioSource(String bookName, String chapterNumber) async {
    if (kIsWeb) {
      // On web, no offline audio caching is available
      return null;
    }
    return await _bibleBrainApi.getCachedAudioPath(bookName, chapterNumber);
  }
  
  // Get streaming audio source
  Future<String?> _getStreamingAudioSource(String bookName, String chapterNumber) async {
    debugPrint('=== Getting streaming audio source ===');
    debugPrint('Input book name: $bookName');
    debugPrint('Chapter number: $chapterNumber');
    
    // Normalize book name if an ID is passed
    String actualBookName = bookName;
    if (RegExp(r'^\d+\x00?$').hasMatch(bookName)) {
      // Some sources may include a stray null char; handle both pure digits and digits with null
      final normalized = bookName.replaceAll('\u0000', '');
      int bookId = int.parse(normalized);
      actualBookName = _getBookNameById(bookId);
      debugPrint('🔍 BOOK CONVERSION: Book ID $bookName -> Book Name: "$actualBookName"');
    } else {
      debugPrint('🔍 BOOK INPUT: Using book name directly: "$actualBookName"');
    }

    // First check if cached (non-web only)
    if (!kIsWeb) {
      debugPrint('Checking for cached audio...');
      String? cachedPath = await _bibleBrainApi.getCachedAudioPath(actualBookName, chapterNumber);
      if (cachedPath != null) {
        debugPrint('Found cached audio: $cachedPath');
        return cachedPath;
      }
      debugPrint('No cached audio found');
    } else {
      debugPrint('Web platform - skipping cache check');
    }

    // Try to get from Bible Brain API with timeout
    try {
      debugPrint('Attempting to get audio from Bible Brain API...');
      
      // Check if Bible Brain API is initialized
      if (!_bibleBrainApi.isInitialized) {
        debugPrint('Bible Brain API not initialized, attempting to initialize...');
        bool initialized = await _bibleBrainApi.initialize().timeout(Duration(seconds: 10));
        if (!initialized) {
          debugPrint('Failed to initialize Bible Brain API - falling back to TTS');
          return null;
        }
        debugPrint('Bible Brain API initialized successfully');
      }
      
      // Map to USX/USFM-like code if available for API compatibility
      final String? usxCode = USXParser.getUSXCodeFromBookName(actualBookName);
      final String bookIdForApi = usxCode ?? actualBookName;
      debugPrint('🔍 USX CONVERSION: Book Name "$actualBookName" -> USX Code: "$usxCode"');
      debugPrint('🔍 API CALL: Using Book ID for API: "$bookIdForApi"');
      debugPrint('🔍 BIBLE ID: ${_bibleBrainApi.defaultBibleId}');
      
      // Check if this is an Old Testament book
      final isOldTestament = ['Genesis', 'Exodus', 'Leviticus', 'Numbers', 'Deuteronomy', 'Joshua', 'Judges', 'Ruth', '1 Samuel', '2 Samuel', '1 Kings', '2 Kings', '1 Chronicles', '2 Chronicles', 'Ezra', 'Nehemiah', 'Esther', 'Job', 'Psalms', 'Proverbs', 'Ecclesiastes', 'Song of Solomon', 'Isaiah', 'Jeremiah', 'Lamentations', 'Ezekiel', 'Daniel', 'Hosea', 'Joel', 'Amos', 'Obadiah', 'Jonah', 'Micah', 'Nahum', 'Habakkuk', 'Zephaniah', 'Haggai', 'Zechariah', 'Malachi'].contains(actualBookName);
      debugPrint('🔍 TESTAMENT: $actualBookName is ${isOldTestament ? "OLD" : "NEW"} Testament');

      // Try to load verse timings (non-fatal if it fails)
      // NOTE: We no longer pre-fetch verse timings here to avoid extra network calls (esp. 404s on OT).
      // Verse timings will be loaded after the source is set.
      _verseTimings = [];
      _currentVerseIndex = 0;

      // Get the actual streaming audio url with timeout
      debugPrint('Requesting audio URL...');
      final String? audioUrl = await _bibleBrainApi.getChapterAudioUrl(_bibleBrainApi.defaultBibleId, bookIdForApi, chapterNumber).timeout(Duration(seconds: 20));
      debugPrint('Received audio URL: $audioUrl');
      
      if (audioUrl != null && audioUrl.isNotEmpty) {
        debugPrint('Successfully obtained streaming audio URL');
        return audioUrl;
      }
      debugPrint('No audio URL received or URL is empty - falling back to TTS');
      return null;
    } catch (e) {
      debugPrint('Error getting streaming audio source: $e - falling back to TTS');
      debugPrint('Stack trace: ${StackTrace.current}');
      return null;
    }
  }
  
  // Update current verse based on playback position
  void _updateCurrentVerse(Duration position) {
    if (_verseTimings.isEmpty) return;
    
    for (int i = 0; i < _verseTimings.length; i++) {
      final timing = _verseTimings[i];
      final num startSec = (timing['start_time'] ?? 0) as num;
      final num endSec = (timing['end_time'] ?? 0) as num;
      final startTime = Duration(milliseconds: (startSec * 1000).round());
      final endTime = Duration(milliseconds: (endSec * 1000).round());
      
      if (position >= startTime && position <= endTime) {
        if (_currentVerseIndex != i) {
          _currentVerseIndex = i;
          _currentVerseController.add(_currentVerseIndex);
        }
        break;
      }
    }
  }
  
  // Playback controls
  Future<void> play() async {
    try {
      debugPrint('Play method called. hasAudio: ${_currentAudioUrl != null}, currentAudioUrl: $_currentAudioUrl');
      debugPrint('Current playback mode: $_playbackMode');
      debugPrint('Current verses count: ${_currentVerses.length}');
      
      // Allow Bible Brain API on web platform since it's working correctly
      // if (kIsWeb) {
      //   debugPrint('Web platform detected - forcing TTS mode');
      //   _playbackMode = AudioPlaybackMode.tts;
      // }
      
      if (_playbackMode == AudioPlaybackMode.tts && _currentVerses.isNotEmpty) {
        debugPrint('Starting TTS playback with ${_currentVerses.length} verses');
        try {
          await _playTTS();
        } catch (e) {
          debugPrint('TTS playback failed: $e');
          if (kIsWeb && e.toString().contains('autoplay')) {
            debugPrint('Browser autoplay policy blocked TTS - user interaction required');
            // Set state to paused so user can try again
            _updatePlayerState(AudioPlayerState.paused);
          } else {
            _updatePlayerState(AudioPlayerState.error);
          }
        }
      } else if (_currentAudioUrl != null) {
        debugPrint('Starting regular audio playback');
        try {
          if (kIsWeb) {
            // On web, explicitly call play with the source to ensure a user-gesture bound start
            if (_currentAudioUrl!.startsWith('http')) {
              // Detect HLS (m3u8) which is not natively supported in most browsers without hls.js
              final isHls = _currentAudioUrl!.toLowerCase().contains('m3u8');
              if (isHls) {
                debugPrint('Web: detected HLS (m3u8) source; switching to TTS fallback');
                if (_currentVerses.isNotEmpty) {
                  try {
                    _playbackMode = AudioPlaybackMode.tts;
                    _currentAudioUrl = null;
                    String allText = _currentVerses.map((v) => v.odiyaText).join(' ');
                    _totalDuration = _calculateTtsDuration(allText);
                    _durationController.add(_totalDuration);
                    _updatePlayerState(AudioPlayerState.paused);
                    await _playTTS();
                    return;
                  } catch (e3) {
                    debugPrint('TTS fallback failed after HLS detection: $e3');
                    if (e3.toString().contains('autoplay')) {
                      _updatePlayerState(AudioPlayerState.paused);
                      return;
                    }
                    rethrow;
                  }
                } else {
                  throw Exception('HLS source not supported on web and no verses available for TTS');
                }
              }
              
              // Test the URL first on web to avoid format errors
              debugPrint('Web: testing audio URL before playing...');
              final isPlayable = await _testWebAudioUrl(_currentAudioUrl!);
              if (!isPlayable && _currentVerses.isNotEmpty) {
                debugPrint('Web: audio URL test failed, switching to TTS fallback');
                try {
                  _playbackMode = AudioPlaybackMode.tts;
                  _currentAudioUrl = null;
                  String allText = _currentVerses.map((v) => v.odiyaText).join(' ');
                  _totalDuration = _calculateTtsDuration(allText);
                  _durationController.add(_totalDuration);
                  _updatePlayerState(AudioPlayerState.paused);
                  await _playTTS();
                  return;
                } catch (e3) {
                  debugPrint('TTS fallback failed after URL test: $e3');
                  if (e3.toString().contains('autoplay')) {
                    _updatePlayerState(AudioPlayerState.paused);
                    return;
                  }
                  rethrow;
                }
              }
              
              debugPrint('Web: playing via UrlSource');
              final _mime = _guessMimeType(_currentAudioUrl!);
              await _audioPlayer.play(UrlSource(_currentAudioUrl!, mimeType: _mime));
            } else {
              debugPrint('Web: playing via DeviceFileSource');
              await _audioPlayer.play(DeviceFileSource(_currentAudioUrl!));
            }
          } else {
            // Mobile/desktop: resume works fine after setSource
            await _audioPlayer.resume();
          }
        } catch (e) {
          debugPrint('Error starting playback: $e');
          final isNotSupported = e.toString().contains('NotSupportedError') || 
                                e.toString().contains('no supported sources') ||
                                e.toString().contains('Format error') ||
                                e.toString().contains('MEDIA_ELEMENT_ERROR');
          // If browser reports unsupported source, immediately fall back to TTS if we have text
          if (kIsWeb && isNotSupported && _currentVerses.isNotEmpty) {
            debugPrint('Web source unsupported (${e.toString()}); switching to TTS fallback');
            try {
              _playbackMode = AudioPlaybackMode.tts;
              _currentAudioUrl = null;
              String allText = _currentVerses.map((v) => v.odiyaText).join(' ');
              _totalDuration = _calculateTtsDuration(allText);
              _durationController.add(_totalDuration);
              _updatePlayerState(AudioPlayerState.paused);
              await _playTTS();
              return;
            } catch (e3) {
              debugPrint('TTS fallback failed after unsupported source: $e3');
              if (e3.toString().contains('autoplay')) {
                _updatePlayerState(AudioPlayerState.paused);
                return;
              }
              rethrow;
            }
          }
          // Fallback attempt: try play with source on all platforms
          try {
            if (_currentAudioUrl!.startsWith('http')) {
              final _mime = _guessMimeType(_currentAudioUrl!);
              await _audioPlayer.play(UrlSource(_currentAudioUrl!, mimeType: _mime));
            } else {
              await _audioPlayer.play(DeviceFileSource(_currentAudioUrl!));
            }
          } catch (e2) {
            debugPrint('Fallback play failed: $e2');
            // If fallback also fails on web due to unsupported formats, switch to TTS when possible
            final isFallbackNotSupported = e2.toString().contains('NotSupportedError') || 
                                          e2.toString().contains('no supported sources') ||
                                          e2.toString().contains('Format error') ||
                                          e2.toString().contains('MEDIA_ELEMENT_ERROR');
            if (kIsWeb && isFallbackNotSupported && _currentVerses.isNotEmpty) {
              try {
                debugPrint('Fallback also unsupported (${e2.toString()}); switching to TTS');
                _playbackMode = AudioPlaybackMode.tts;
                _currentAudioUrl = null;
                String allText = _currentVerses.map((v) => v.odiyaText).join(' ');
                _totalDuration = _calculateTtsDuration(allText);
                _durationController.add(_totalDuration);
                _updatePlayerState(AudioPlayerState.paused);
                await _playTTS();
                return;
              } catch (e4) {
                debugPrint('TTS fallback after second failure failed: $e4');
                if (e4.toString().contains('autoplay')) {
                  _updatePlayerState(AudioPlayerState.paused);
                  return;
                }
              }
            }
            rethrow;
          }
        }
      } else if (_currentVerses.isNotEmpty) {
        // No audio URL but we have verses - switch to TTS
        debugPrint('No audio available, switching to TTS fallback');
        try {
          await _playTTS();
        } catch (e) {
          debugPrint('TTS fallback failed: $e');
          if (kIsWeb) {
            debugPrint('Browser may require user interaction for audio - try clicking play again');
            _updatePlayerState(AudioPlayerState.paused);
          } else {
            _updatePlayerState(AudioPlayerState.error);
          }
        }
      } else {
        debugPrint('No audio available to play. Audio player shown but no playback will start.');
        // Show audio player UI but don't start playback
        _updatePlayerState(AudioPlayerState.paused);
      }
    } catch (e) {
      debugPrint('Error playing audio: $e');
      // Rethrow autoplay policy errors so UI can handle them appropriately
      if (e.toString().contains('NotAllowedError') || e.toString().contains('play() failed')) {
        rethrow;
      }
      // For other errors, just log them
    }
  }
  
  Future<void> pause() async {
    try {
      if (_playbackMode == AudioPlaybackMode.tts) {
        await _pauseTTS();
      } else {
        await _audioPlayer.pause();
      }
    } catch (e) {
      debugPrint('Error pausing audio: $e');
    }
  }
  
  Future<void> stop() async {
    try {
      if (_playbackMode == AudioPlaybackMode.tts) {
        await _stopTTS();
      } else {
        await _audioPlayer.stop();
      }
      _currentPosition = Duration.zero;
      _currentVerseIndex = 0;
      _positionController.add(_currentPosition);
      _currentVerseController.add(_currentVerseIndex);
    } catch (e) {
      debugPrint('Error stopping audio: $e');
    }
  }
  
  Future<void> seekTo(Duration position) async {
    try {
      // Ensure we have a valid duration before seeking (especially important on web)
      if (_totalDuration == Duration.zero) {
        final completer = Completer<void>();
        late StreamSubscription<Duration> sub;
        sub = _audioPlayer.onDurationChanged.listen((d) {
          if (d > Duration.zero && !completer.isCompleted) {
            completer.complete();
          }
        });
        // If already available, complete immediately
        if (_totalDuration > Duration.zero && !completer.isCompleted) {
          completer.complete();
        }
        // Wait up to 3s for duration; if not available, continue gracefully
        await completer.future.timeout(const Duration(seconds: 3), onTimeout: () {
          if (!completer.isCompleted) {
            completer.complete();
          }
        });
        await sub.cancel();
      }

      final clamped = _clampPosition(position);
      await _audioPlayer.seek(clamped).timeout(const Duration(seconds: 3));
    } catch (e) {
      debugPrint('Error seeking audio: $e');
    }
  }

  // Clamp a desired position to a safe range based on current duration
  Duration _clampPosition(Duration p) {
    if (_totalDuration == Duration.zero) {
      return p < Duration.zero ? Duration.zero : p;
    }
    if (p < Duration.zero) return Duration.zero;
    if (p > _totalDuration) return _totalDuration;
    return p;
  }
  
  Future<void> setPlaybackSpeed(double speed) async {
    try {
      _playbackSpeed = speed.clamp(0.5, 2.0);
      await _audioPlayer.setPlaybackRate(_playbackSpeed);
    } catch (e) {
      debugPrint('Error setting playback speed: $e');
    }
  }
  
  Future<void> setVolume(double volume) async {
    try {
      _volume = volume.clamp(0.0, 1.0);
      await _audioPlayer.setVolume(_volume);
    } catch (e) {
      debugPrint('Error setting volume: $e');
    }
  }
  
  // Jump to specific verse
  Future<void> jumpToVerse(int verseIndex) async {
    if (_verseTimings.isEmpty || verseIndex >= _verseTimings.length) return;
    
    try {
      final timing = _verseTimings[verseIndex];
      final num startSec = (timing['start_time'] ?? 0) as num;
      final startTime = Duration(milliseconds: (startSec * 1000).round());
      await seekTo(startTime);
    } catch (e) {
      debugPrint('Error jumping to verse: $e');
    }
  }
  
  // Download chapter for offline use
  Future<bool> downloadChapterForOffline(String bookName, String chapterNumber) async {
    try {
      // Normalize book name if numeric ID passed
      String actualBookName = bookName;
      if (RegExp(r'^\d+ ?$').hasMatch(bookName)) {
        final normalized = bookName.replaceAll('\u0000', '');
        int bookId = int.parse(normalized);
        actualBookName = _getBookNameById(bookId);
      }
      // Check if already cached
      if (await _bibleBrainApi.isAudioCached(actualBookName, chapterNumber)) {
        return true;
      }
      // Get audio URL and download (map to USX/USFM-like code for API)
      final String bookIdForApi = USXParser.getUSXCodeFromBookName(actualBookName) ?? actualBookName;
      String? audioUrl = await _bibleBrainApi.getChapterAudioUrl(_bibleBrainApi.defaultBibleId, bookIdForApi, chapterNumber);
      if (audioUrl != null) {
        String? downloadedPath = await _bibleBrainApi.downloadAndCacheAudio(audioUrl, actualBookName, chapterNumber);
        return downloadedPath != null;
      }
      return false;
    } catch (e) {
      debugPrint('Error downloading chapter: $e');
      return false;
    }
  }
  
  // Check if chapter is available offline
  Future<bool> isChapterAvailableOffline(String bookName, String chapterNumber) async {
    // Normalize book name if numeric ID passed
    String actualBookName = bookName;
    if (RegExp(r'^\d+\x00?$').hasMatch(bookName)) {
      final normalized = bookName.replaceAll('\u0000', '');
      int bookId = int.parse(normalized);
      actualBookName = _getBookNameById(bookId);
    }
    return await _bibleBrainApi.isAudioCached(actualBookName, chapterNumber);
  }
  
  // Private methods
  void _updatePlayerState(AudioPlayerState state) {
    _playerState = state;
    _stateController.add(state);
  }
  
  void _onPlaybackCompleted() {
    _currentPosition = Duration.zero;
    _currentVerseIndex = 0;
    _positionController.add(_currentPosition);
    _currentVerseController.add(_currentVerseIndex);
  }

  // Load verse timings for the current chapter (non-fatal on failure)
  Future<void> _loadVerseTimings(String bookName, String chapterNumber) async {
    try {
      final String bookIdForApi = USXParser.getUSXCodeFromBookName(bookName) ?? bookName;
      final timings = await _bibleBrainApi.getVerseTimings(_bibleBrainApi.defaultBibleId, bookIdForApi, chapterNumber);
      if (timings.isNotEmpty) {
        _verseTimings = timings;
        _currentVerseIndex = 0;
        _currentVerseController.add(_currentVerseIndex);
        return;
      }

      // If no timings available from API, synthesize approximate timings so verse highlighting still works.
      // Wait briefly for totalDuration to be known (set by onDurationChanged when source loads)
      const int maxWaitMs = 2000;
      int waited = 0;
      while (_totalDuration == Duration.zero && waited < maxWaitMs) {
        await Future.delayed(const Duration(milliseconds: 50));
        waited += 50;
      }

      if (_currentVerses.isNotEmpty) {
        final int verseCount = _currentVerses.length;
        Duration effectiveDuration = _totalDuration;
        if (effectiveDuration == Duration.zero) {
          // Fallback estimate: 4 seconds per verse if duration unknown
          effectiveDuration = Duration(seconds: verseCount * 4);
        }
        final double perVerseSeconds = effectiveDuration.inMilliseconds / 1000.0 / verseCount;
        final List<Map<String, dynamic>> synthetic = [];
        for (int i = 0; i < verseCount; i++) {
          final double start = i * perVerseSeconds;
          final double end = (i + 1) * perVerseSeconds;
          synthetic.add({
            'start_time': start,
            'end_time': end,
            'verse_number': i + 1,
          });
        }
        _verseTimings = synthetic;
        debugPrint('No API verse timings. Generated ${_verseTimings.length} synthetic timings');
      } else {
        _verseTimings = [];
      }

      _currentVerseIndex = 0;
      _currentVerseController.add(_currentVerseIndex);
    } catch (e) {
      debugPrint('Failed to load verse timings for $bookName $chapterNumber: $e');
      _verseTimings = [];
      _currentVerseIndex = 0;
      _currentVerseController.add(_currentVerseIndex);
    }
  }

  // Resolve a book name from its numeric ID using JsonBibleService
  String _getBookNameById(int bookId) {
    return JsonBibleService.getBookNameById(bookId);
  }

  // Infer MIME type from a URL for web playback reliability
  String? _guessMimeType(String url) {
    final l = url.toLowerCase();
    if (l.contains('.mp3') || l.contains('format=mp3')) return 'audio/mpeg';
    if (l.contains('opus') || l.contains('.ogg')) return 'audio/ogg';
    if (l.contains('.m4a') || l.contains('.mp4') || l.contains('format=m4a')) return 'audio/mp4';
    if (l.contains('.m3u8') || l.contains('m3u8')) return 'application/vnd.apple.mpegurl';
    return null; // Let plugin/browser detect
  }

  // Test if a URL is playable on web by attempting to load it
  Future<bool> _testWebAudioUrl(String url) async {
    if (!kIsWeb) return true; // Non-web platforms handle this differently
    
    try {
      debugPrint('Testing web audio URL: $url');
      final testPlayer = AudioPlayer();
      final mime = _guessMimeType(url);
      
      // Set a short timeout for testing
      await testPlayer.setSource(UrlSource(url, mimeType: mime)).timeout(Duration(seconds: 5));
      await testPlayer.dispose();
      debugPrint('Web audio URL test successful');
      return true;
    } catch (e) {
      debugPrint('Web audio URL test failed: $e');
      return false;
    }
  }

  Duration _calculateTtsDuration(String text) {
    // Estimate 150 words per minute (2.5 words per second)
    final wordCount = text.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
    final estimatedSeconds = (wordCount / 2.5).round();
    debugPrint('Text word count: $wordCount, estimated duration: ${estimatedSeconds}s');
    return Duration(seconds: estimatedSeconds.clamp(1, 3600)); // At least 1 second, max 1 hour
  }
  
  // TTS playback methods
  Future<void> _playTTS() async {
    if (_currentVerses.isEmpty) return;
    debugPrint('Starting TTS playback with ${_currentVerses.length} verses');
    debugPrint('First verse text: ${_currentVerses.first.odiyaText}');
    
    try {
      // Calculate total duration for all verses
      String allText = _currentVerses.map((v) => v.odiyaText).join(' ');
      _totalDuration = _calculateTtsDuration(allText);
      _durationController.add(_totalDuration);
      debugPrint('Calculated TTS duration: ${_totalDuration.inSeconds} seconds');
      
      _updatePlayerState(AudioPlayerState.playing);
      _currentVerseIndex = 0;
      _currentPosition = Duration.zero;
      _positionController.add(_currentPosition);
      
      for (int i = 0; i < _currentVerses.length; i++) {
        if (_playerState != AudioPlayerState.playing) break;
        
        final verse = _currentVerses[i];
        _currentVerseIndex = i;
        _currentVerseController.add(i);
        
        debugPrint('Speaking verse ${i + 1}: ${verse.odiyaText}');
        
        try {
          // Calculate estimated duration for this verse
          Duration verseDuration = _calculateTtsDuration(verse.odiyaText);
          Duration verseStartPosition = _currentPosition;
          
          debugPrint('Speaking verse ${i + 1} with estimated duration: ${verseDuration.inSeconds}s');
          
          // Create a completer to wait for TTS completion
          Completer<void> ttsCompleter = Completer<void>();
          bool ttsCompleted = false;
          
          // Set up completion handler for this specific TTS call
          _ttsService.setCompletionHandler(() {
            debugPrint('TTS completed for verse ${i + 1}');
            ttsCompleted = true;
            if (!ttsCompleter.isCompleted) {
              ttsCompleter.complete();
            }
          });
          
          // Start speaking
          await _ttsService.speak(verse.odiyaText);
          
          // Track position while TTS is playing
          DateTime startTime = DateTime.now();
          Timer? positionTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
            if (_playerState != AudioPlayerState.playing || ttsCompleted) {
              timer.cancel();
              return;
            }
            
            Duration elapsed = DateTime.now().difference(startTime);
            if (elapsed < verseDuration) {
              _currentPosition = verseStartPosition + elapsed;
            } else {
              _currentPosition = verseStartPosition + verseDuration;
            }
            _positionController.add(_currentPosition);
          });
          
          // Wait for TTS to complete or timeout
          try {
            await ttsCompleter.future.timeout(verseDuration + const Duration(seconds: 2));
          } catch (e) {
            debugPrint('TTS timeout for verse ${i + 1}: $e');
          } finally {
            positionTimer?.cancel();
          }
          
          // Ensure we set position to the end of this verse
          _currentPosition = verseStartPosition + verseDuration;
          _positionController.add(_currentPosition);
          
          // Add pause between verses if not stopped
          if (_playerState == AudioPlayerState.playing && i < _currentVerses.length - 1) {
            await Future.delayed(const Duration(milliseconds: 500));
            _currentPosition += const Duration(milliseconds: 500);
            _positionController.add(_currentPosition);
          }
        } catch (e) {
          debugPrint('Error speaking verse ${i + 1}: $e');
          // If this is the first verse and it fails, it might be due to autoplay policy
          if (i == 0 && kIsWeb) {
            debugPrint('TTS failed on first verse - likely browser autoplay policy');
            _updatePlayerState(AudioPlayerState.error);
            rethrow; // Let the UI handle this error
          }
          // For other verses, continue to next verse
          continue;
        }
      }
      
      if (_playerState == AudioPlayerState.playing) {
        _updatePlayerState(AudioPlayerState.stopped);
        _onPlaybackCompleted();
      }
    } catch (e) {
      debugPrint('TTS playback failed: $e');
      _updatePlayerState(AudioPlayerState.error);
      rethrow;
    }
  }
  
  Future<void> _pauseTTS() async {
    await _ttsService.pause();
    _updatePlayerState(AudioPlayerState.paused);
  }
  
  Future<void> _stopTTS() async {
    await _ttsService.stop();
    _ttsTimer?.cancel();
    _ttsTimer = null;
    _updatePlayerState(AudioPlayerState.stopped);
  }

  // Test if audio player works with a simple test URL
  Future<bool> testAudioPlayer() async {
    try {
      debugPrint('Testing audio player with sample URL...');
      // Use a simple test audio URL
      const testUrl = 'https://www.soundjay.com/misc/sounds/bell-ringing-05.wav';
      await _audioPlayer.setSource(UrlSource(testUrl));
      debugPrint('Audio player test successful');
      return true;
    } catch (e) {
      debugPrint('Audio player test failed: $e');
      return false;
    }
  }

  // Dispose
  void dispose() {
    _ttsTimer?.cancel();
    _audioPlayer.dispose();
    _stateController.close();
    _positionController.close();
    _durationController.close();
    _currentVerseController.close();
  }
}