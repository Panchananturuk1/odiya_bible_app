import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/app_settings.dart';
import '../services/settings_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'audio_provider.dart';
import 'audio_streaming_provider.dart';

class SettingsProvider with ChangeNotifier {
  final SettingsService _settingsService = SettingsService();
  AppSettings _settings = AppSettings();
  bool _isInitialized = false;
  AudioProvider? _audioProvider;
  AudioStreamingProvider? _audioStreamingProvider;

  // Getters
  AppSettings get settings => _settings;
  bool get isInitialized => _isInitialized;
  bool get isDarkMode => _settings.isDarkMode;
  double get fontSize => _settings.fontSize;
  bool get showParallelBible => _settings.showParallelBible;
  String get parallelLanguage => _settings.parallelLanguage;
  // Primary reading language for verses: 'odiya' or 'english'
  String get readingLanguage => _settings.readingLanguage;
  bool get autoPlayAudio => _settings.autoPlayAudio;
  double get audioSpeed => _settings.audioSpeed;
  bool get keepScreenOn => _settings.keepScreenOn;
  bool get showVerseNumbers => _settings.showVerseNumbers;
  bool get enableSwipeNavigation => _settings.enableSwipeNavigation;
  bool get audioEnabled => _settings.autoPlayAudio;
  bool get autoScroll => false; // Placeholder - would need to be added to AppSettings
  double get scrollSpeed => 1.0; // Placeholder - would need to be added to AppSettings
  
  Map<String, int> get lastReadPosition => {
    'bookId': _settings.lastReadBookId,
    'chapter': _settings.lastReadChapter,
    'verse': _settings.lastReadVerse,
  };

  // Theme data based on settings
  ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF4A90E2), // Modern blue for spiritual theme
      brightness: Brightness.light,
      primary: const Color(0xFF4A90E2),
      secondary: const Color(0xFF7B68EE),
      tertiary: const Color(0xFF50C878),
      surface: const Color(0xFFFAFBFF),
      background: const Color(0xFFF8F9FA),
    ),
    appBarTheme: AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: const Color(0xFF2C3E50),
      titleTextStyle: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF2C3E50),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    textTheme: GoogleFonts.interTextTheme(
      ThemeData(brightness: Brightness.light).textTheme.copyWith(
        // Display styles for large headings
        displayLarge: GoogleFonts.inter(
          fontSize: _settings.fontSize + 16,
          fontWeight: FontWeight.w800,
          height: 1.2,
          letterSpacing: -0.5,
          color: const Color(0xFF1A202C),
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: _settings.fontSize + 12,
          fontWeight: FontWeight.w700,
          height: 1.3,
          letterSpacing: -0.25,
          color: const Color(0xFF2D3748),
        ),
        displaySmall: GoogleFonts.inter(
          fontSize: _settings.fontSize + 8,
          fontWeight: FontWeight.w600,
          height: 1.4,
          color: const Color(0xFF2D3748),
        ),
        // Headline styles
        headlineLarge: GoogleFonts.inter(
          fontSize: _settings.fontSize + 10,
          fontWeight: FontWeight.w700,
          height: 1.3,
          letterSpacing: -0.25,
          color: const Color(0xFF2C3E50),
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: _settings.fontSize + 6,
          fontWeight: FontWeight.w600,
          height: 1.4,
          color: const Color(0xFF2C3E50),
        ),
        headlineSmall: GoogleFonts.inter(
          fontSize: _settings.fontSize + 4,
          fontWeight: FontWeight.w600,
          height: 1.4,
          color: const Color(0xFF4A90E2),
        ),
        // Title styles
        titleLarge: GoogleFonts.inter(
          fontSize: _settings.fontSize + 6,
          fontWeight: FontWeight.w700,
          height: 1.3,
          letterSpacing: 0.15,
          color: const Color(0xFF2C3E50),
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: _settings.fontSize + 2,
          fontWeight: FontWeight.w600,
          height: 1.4,
          letterSpacing: 0.1,
          color: const Color(0xFF34495E),
        ),
        titleSmall: GoogleFonts.inter(
          fontSize: _settings.fontSize,
          fontWeight: FontWeight.w500,
          height: 1.4,
          letterSpacing: 0.1,
          color: const Color(0xFF4A5568),
        ),
        // Body styles for main content
        bodyLarge: GoogleFonts.notoSansOriya(
          fontSize: _settings.fontSize,
          fontWeight: FontWeight.w400,
          height: 1.7,
          letterSpacing: 0.25,
          color: const Color(0xFF2C3E50),
        ),
        bodyMedium: GoogleFonts.notoSansOriya(
          fontSize: _settings.fontSize - 2,
          fontWeight: FontWeight.w400,
          height: 1.6,
          letterSpacing: 0.25,
          color: const Color(0xFF34495E),
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: _settings.fontSize - 4,
          fontWeight: FontWeight.w400,
          height: 1.5,
          letterSpacing: 0.4,
          color: const Color(0xFF718096),
        ),
        // Label styles for UI elements
        labelLarge: GoogleFonts.inter(
          fontSize: _settings.fontSize - 2,
          fontWeight: FontWeight.w500,
          height: 1.4,
          letterSpacing: 0.1,
          color: const Color(0xFF4A5568),
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: _settings.fontSize - 4,
          fontWeight: FontWeight.w500,
          height: 1.3,
          letterSpacing: 0.5,
          color: const Color(0xFF718096),
        ),
        labelSmall: GoogleFonts.inter(
           fontSize: _settings.fontSize - 6,
           fontWeight: FontWeight.w500,
           height: 1.3,
           letterSpacing: 0.5,
           color: const Color(0xFFA0AEC0),
         ),
      ),
    ),
  );

  ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF6366F1), // Modern indigo for dark theme
      brightness: Brightness.dark,
      primary: const Color(0xFF6366F1),
      secondary: const Color(0xFF8B5CF6),
      tertiary: const Color(0xFF06D6A0),
      surface: const Color(0xFF1E1E2E),
      background: const Color(0xFF181825),
      onSurface: const Color(0xFFE5E7EB),
      onBackground: const Color(0xFFF3F4F6),
    ),
    appBarTheme: AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: const Color(0xFFF3F4F6),
      titleTextStyle: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: const Color(0xFFF3F4F6),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.3),
      color: const Color(0xFF2A2A3E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.4),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    textTheme: GoogleFonts.interTextTheme(
      ThemeData(brightness: Brightness.dark).textTheme.copyWith(
        // Display styles for large headings
        displayLarge: GoogleFonts.inter(
          fontSize: _settings.fontSize + 16,
          fontWeight: FontWeight.w800,
          height: 1.2,
          letterSpacing: -0.5,
          color: const Color(0xFFF9FAFB),
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: _settings.fontSize + 12,
          fontWeight: FontWeight.w700,
          height: 1.3,
          letterSpacing: -0.25,
          color: const Color(0xFFF3F4F6),
        ),
        displaySmall: GoogleFonts.inter(
          fontSize: _settings.fontSize + 8,
          fontWeight: FontWeight.w600,
          height: 1.4,
          color: const Color(0xFFE5E7EB),
        ),
        // Headline styles
        headlineLarge: GoogleFonts.inter(
          fontSize: _settings.fontSize + 10,
          fontWeight: FontWeight.w700,
          height: 1.3,
          letterSpacing: -0.25,
          color: const Color(0xFFF3F4F6),
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: _settings.fontSize + 6,
          fontWeight: FontWeight.w600,
          height: 1.4,
          color: const Color(0xFFE5E7EB),
        ),
        headlineSmall: GoogleFonts.inter(
          fontSize: _settings.fontSize + 4,
          fontWeight: FontWeight.w600,
          height: 1.4,
          color: const Color(0xFF6366F1),
        ),
        // Title styles
        titleLarge: GoogleFonts.inter(
          fontSize: _settings.fontSize + 6,
          fontWeight: FontWeight.w700,
          height: 1.3,
          letterSpacing: 0.15,
          color: const Color(0xFFF3F4F6),
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: _settings.fontSize + 2,
          fontWeight: FontWeight.w600,
          height: 1.4,
          letterSpacing: 0.1,
          color: const Color(0xFFE5E7EB),
        ),
        titleSmall: GoogleFonts.inter(
          fontSize: _settings.fontSize,
          fontWeight: FontWeight.w500,
          height: 1.4,
          letterSpacing: 0.1,
          color: const Color(0xFFD1D5DB),
        ),
        // Body styles for main content
        bodyLarge: GoogleFonts.notoSansOriya(
          fontSize: _settings.fontSize,
          fontWeight: FontWeight.w400,
          height: 1.7,
          letterSpacing: 0.25,
          color: const Color(0xFFE5E7EB),
        ),
        bodyMedium: GoogleFonts.notoSansOriya(
          fontSize: _settings.fontSize - 2,
          fontWeight: FontWeight.w400,
          height: 1.6,
          letterSpacing: 0.25,
          color: const Color(0xFFD1D5DB),
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: _settings.fontSize - 4,
          fontWeight: FontWeight.w400,
          height: 1.5,
          letterSpacing: 0.4,
          color: const Color(0xFF9CA3AF),
        ),
        // Label styles for UI elements
        labelLarge: GoogleFonts.inter(
          fontSize: _settings.fontSize - 2,
          fontWeight: FontWeight.w500,
          height: 1.4,
          letterSpacing: 0.1,
          color: const Color(0xFFD1D5DB),
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: _settings.fontSize - 4,
          fontWeight: FontWeight.w500,
          height: 1.3,
          letterSpacing: 0.5,
          color: const Color(0xFF9CA3AF),
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: _settings.fontSize - 6,
          fontWeight: FontWeight.w500,
          height: 1.3,
          letterSpacing: 0.5,
          color: const Color(0xFF6B7280),
        ),
      ),
    ),
  );

  // Initialize settings
  Future<void> initialize() async {
    try {
      await _settingsService.init();
      _settings = await _settingsService.getSettings();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing settings: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  // Update font size
  Future<void> updateFontSize(double fontSize) async {
    try {
      _settings = _settings.copyWith(fontSize: fontSize);
      await _settingsService.saveSettings(_settings);
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating font size: $e');
    }
  }

  // Toggle dark mode
  Future<void> toggleDarkMode() async {
    try {
      _settings = _settings.copyWith(isDarkMode: !_settings.isDarkMode);
      await _settingsService.saveSettings(_settings);
      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling dark mode: $e');
    }
  }

  // Update dark mode
  Future<void> updateDarkMode(bool isDarkMode) async {
    try {
      _settings = _settings.copyWith(isDarkMode: isDarkMode);
      await _settingsService.saveSettings(_settings);
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating dark mode: $e');
    }
  }

  // Update parallel Bible settings
  Future<void> updateParallelBible(bool showParallel, [String? language]) async {
    try {
      _settings = _settings.copyWith(
        showParallelBible: showParallel,
        parallelLanguage: language ?? _settings.parallelLanguage,
      );
      await _settingsService.saveSettings(_settings);
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating parallel Bible settings: $e');
    }
  }

  // Set AudioProvider reference for syncing audio settings
  void setAudioProvider(AudioProvider audioProvider) {
    _audioProvider = audioProvider;
    // Sync current settings to provider on linkage
    final mappedTtsRate = _toTtsRate(_settings.audioSpeed);
    _audioProvider?.updateAudioSettings(speechRate: mappedTtsRate);
  }

  // Set AudioStreamingProvider reference for syncing audio settings
  void setAudioStreamingProvider(AudioStreamingProvider audioStreamingProvider) {
    _audioStreamingProvider = audioStreamingProvider;
    // Sync current settings to streaming provider on linkage
    _audioStreamingProvider?.setPlaybackSpeed(_settings.audioSpeed);
  }
  
  // Update audio settings
  Future<void> updateAudioSettings(bool autoPlay, double speed) async {
    try {
      _settings = _settings.copyWith(
        autoPlayAudio: autoPlay,
        audioSpeed: speed,
      );
      await _settingsService.saveSettings(_settings);
      
      // Update AudioProvider (TTS) if available with normalized rate
      if (_audioProvider != null) {
        await _audioProvider!.updateAudioSettings(speechRate: _toTtsRate(speed));
      }
      
      // Update AudioStreamingProvider (media playback) if available
      if (_audioStreamingProvider != null) {
        await _audioStreamingProvider!.setPlaybackSpeed(speed);
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating audio settings: $e');
    }
  }

  // Update display settings
  Future<void> updateDisplaySettings({
    bool? showVerseNumbers,
    bool? enableSwipeNavigation,
    bool? keepScreenOn,
  }) async {
    try {
      _settings = _settings.copyWith(
        showVerseNumbers: showVerseNumbers ?? _settings.showVerseNumbers,
        enableSwipeNavigation: enableSwipeNavigation ?? _settings.enableSwipeNavigation,
        keepScreenOn: keepScreenOn ?? _settings.keepScreenOn,
      );
      await _settingsService.saveSettings(_settings);
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating display settings: $e');
    }
  }

  // Update last read position
  Future<void> updateLastReadPosition(int bookId, int chapter, int verse) async {
    try {
      _settings = _settings.copyWith(
        lastReadBookId: bookId,
        lastReadChapter: chapter,
        lastReadVerse: verse,
      );
      await _settingsService.saveSettings(_settings);
      // Don't notify listeners for this as it's updated frequently
    } catch (e) {
      debugPrint('Error updating last read position: $e');
    }
  }

  // Reset all settings
  Future<void> resetSettings() async {
    try {
      await _settingsService.resetSettings();
      _settings = AppSettings();
      notifyListeners();
    } catch (e) {
      debugPrint('Error resetting settings: $e');
    }
  }

  // Alias for resetSettings to match settings_screen.dart usage
  Future<void> resetToDefaults() async {
    await resetSettings();
  }

  // Audio speed setter for slider
  void setAudioSpeed(double speed) {
    updateAudioSettings(_settings.autoPlayAudio, speed);
  }

  // Auto scroll speed setter for slider
  void setScrollSpeed(double speed) {
    // For now, we'll store this in audioSpeed as a placeholder
    // In a real app, you'd add autoScrollSpeed to AppSettings
    updateAudioSettings(_settings.autoPlayAudio, speed);
  }

  // Toggle audio playback
  void toggleAudio(bool enabled) {
    updateAudioSettings(enabled, _settings.audioSpeed);
  }

  // Toggle auto scroll (placeholder implementation)
  void toggleAutoScroll(bool enabled) {
    // This would need proper implementation with AppSettings update
    notifyListeners();
  }

  // Toggle parallel Bible display
  void toggleParallelBible(bool enabled) {
    updateParallelBible(enabled);
  }

  // Toggle keep screen on
  void toggleKeepScreenOn(bool enabled) {
    updateDisplaySettings(keepScreenOn: enabled);
  }

  // Helper: map UI playback speed (0.5-2.0) to TTS rate (0.0-1.0)
  double _toTtsRate(double playbackSpeed) {
    final clamped = playbackSpeed.clamp(0.5, 2.0);
    return clamped / 2.0; // 1.0x -> 0.5 (TTS default), 2.0x -> 1.0, 0.5x -> 0.25
  }

  // Font size setter for slider
  void setFontSize(double size) {
    updateFontSize(size);
  }

  // Font size helpers
  void increaseFontSize() {
    if (_settings.fontSize < 24) {
      updateFontSize(_settings.fontSize + 1);
    }
  }

  void decreaseFontSize() {
    if (_settings.fontSize > 12) {
      updateFontSize(_settings.fontSize - 1);
    }
  }

  // Audio speed helpers
  void increaseAudioSpeed() {
    if (_settings.audioSpeed < 2.0) {
      updateAudioSettings(_settings.autoPlayAudio, _settings.audioSpeed + 0.1);
    }
  }

  void decreaseAudioSpeed() {
    if (_settings.audioSpeed > 0.5) {
      updateAudioSettings(_settings.autoPlayAudio, _settings.audioSpeed - 0.1);
    }
  }

  // Get formatted audio speed
  String get formattedAudioSpeed => '${(_settings.audioSpeed * 100).round()}%';

  // Check if settings are at default values
  bool get isDefaultSettings {
    final defaultSettings = AppSettings();
    return _settings.fontSize == defaultSettings.fontSize &&
           _settings.isDarkMode == defaultSettings.isDarkMode &&
           _settings.showParallelBible == defaultSettings.showParallelBible &&
           _settings.parallelLanguage == defaultSettings.parallelLanguage &&
           _settings.autoPlayAudio == defaultSettings.autoPlayAudio &&
           _settings.audioSpeed == defaultSettings.audioSpeed &&
           _settings.keepScreenOn == defaultSettings.keepScreenOn &&
           _settings.showVerseNumbers == defaultSettings.showVerseNumbers &&
           _settings.enableSwipeNavigation == defaultSettings.enableSwipeNavigation;
  }

  // Update primary reading language
  Future<void> updateReadingLanguage(String language) async {
    try {
      _settings = _settings.copyWith(readingLanguage: language);
      await _settingsService.saveSettings(_settings);
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating reading language: $e');
    }
  }

  // Toggle reading language between Odiya and English
  Future<void> toggleReadingLanguage() async {
    final newLang = _settings.readingLanguage == 'odiya' ? 'english' : 'odiya';
    await updateReadingLanguage(newLang);
  }
}