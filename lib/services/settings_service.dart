import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings.dart';

class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  static const String _settingsKey = 'app_settings';
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<AppSettings> getSettings() async {
    if (_prefs == null) await init();
    
    final settingsJson = _prefs!.getString(_settingsKey);
    if (settingsJson != null) {
      try {
        final Map<String, dynamic> settingsMap = json.decode(settingsJson);
        return AppSettings.fromJson(settingsMap);
      } catch (e) {
        // If there's an error parsing, return default settings
        return AppSettings();
      }
    }
    return AppSettings();
  }

  Future<void> saveSettings(AppSettings settings) async {
    if (_prefs == null) await init();
    
    final settingsJson = json.encode(settings.toJson());
    await _prefs!.setString(_settingsKey, settingsJson);
  }

  Future<void> updateFontSize(double fontSize) async {
    final settings = await getSettings();
    final updatedSettings = settings.copyWith(fontSize: fontSize);
    await saveSettings(updatedSettings);
  }

  Future<void> updateDarkMode(bool isDarkMode) async {
    final settings = await getSettings();
    final updatedSettings = settings.copyWith(isDarkMode: isDarkMode);
    await saveSettings(updatedSettings);
  }

  Future<void> updateParallelBible(bool showParallel, String? language) async {
    final settings = await getSettings();
    final updatedSettings = settings.copyWith(
      showParallelBible: showParallel,
      parallelLanguage: language ?? settings.parallelLanguage,
    );
    await saveSettings(updatedSettings);
  }

  Future<void> updateLastReadPosition(int bookId, int chapter, int verse) async {
    final settings = await getSettings();
    final updatedSettings = settings.copyWith(
      lastReadBookId: bookId,
      lastReadChapter: chapter,
      lastReadVerse: verse,
    );
    await saveSettings(updatedSettings);
  }

  Future<void> updateAudioSettings(bool autoPlay, double speed) async {
    final settings = await getSettings();
    final updatedSettings = settings.copyWith(
      autoPlayAudio: autoPlay,
      audioSpeed: speed,
    );
    await saveSettings(updatedSettings);
  }

  Future<void> updateDisplaySettings({
    bool? showVerseNumbers,
    bool? enableSwipeNavigation,
    bool? keepScreenOn,
  }) async {
    final settings = await getSettings();
    final updatedSettings = settings.copyWith(
      showVerseNumbers: showVerseNumbers ?? settings.showVerseNumbers,
      enableSwipeNavigation: enableSwipeNavigation ?? settings.enableSwipeNavigation,
      keepScreenOn: keepScreenOn ?? settings.keepScreenOn,
    );
    await saveSettings(updatedSettings);
  }

  Future<void> resetSettings() async {
    if (_prefs == null) await init();
    await _prefs!.remove(_settingsKey);
  }

  // Quick access methods for commonly used settings
  Future<double> getFontSize() async {
    final settings = await getSettings();
    return settings.fontSize;
  }

  Future<bool> isDarkMode() async {
    final settings = await getSettings();
    return settings.isDarkMode;
  }

  Future<Map<String, int>> getLastReadPosition() async {
    final settings = await getSettings();
    return {
      'bookId': settings.lastReadBookId,
      'chapter': settings.lastReadChapter,
      'verse': settings.lastReadVerse,
    };
  }

  Future<bool> isParallelBibleEnabled() async {
    final settings = await getSettings();
    return settings.showParallelBible;
  }

  Future<String> getParallelLanguage() async {
    final settings = await getSettings();
    return settings.parallelLanguage;
  }
}