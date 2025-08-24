import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/app_settings.dart';
import '../services/settings_service.dart';

class SettingsProvider with ChangeNotifier {
  final SettingsService _settingsService = SettingsService();
  AppSettings _settings = AppSettings();
  bool _isInitialized = false;

  // Getters
  AppSettings get settings => _settings;
  bool get isInitialized => _isInitialized;
  bool get isDarkMode => _settings.isDarkMode;
  double get fontSize => _settings.fontSize;
  bool get showParallelBible => _settings.showParallelBible;
  String get parallelLanguage => _settings.parallelLanguage;
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
      seedColor: const Color(0xFF6B4E3D), // Brown color for Bible theme
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 2,
    ),
    cardTheme: CardThemeData(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    textTheme: TextTheme(
      bodyLarge: TextStyle(fontSize: _settings.fontSize),
      bodyMedium: TextStyle(fontSize: _settings.fontSize - 2),
      titleLarge: TextStyle(fontSize: _settings.fontSize + 4),
      titleMedium: TextStyle(fontSize: _settings.fontSize + 2),
    ),
  );

  ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF8D6E63), // Lighter brown for dark theme
      brightness: Brightness.dark,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 2,
    ),
    cardTheme: CardThemeData(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    textTheme: TextTheme(
      bodyLarge: TextStyle(fontSize: _settings.fontSize, color: Colors.white),
      bodyMedium: TextStyle(fontSize: _settings.fontSize - 2, color: Colors.white70),
      titleLarge: TextStyle(fontSize: _settings.fontSize + 4, color: Colors.white),
      titleMedium: TextStyle(fontSize: _settings.fontSize + 2, color: Colors.white),
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

  // Update audio settings
  Future<void> updateAudioSettings(bool autoPlay, double speed) async {
    try {
      _settings = _settings.copyWith(
        autoPlayAudio: autoPlay,
        audioSpeed: speed,
      );
      await _settingsService.saveSettings(_settings);
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

  // Font size setter for slider
  void setFontSize(double fontSize) {
    updateFontSize(fontSize);
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
}