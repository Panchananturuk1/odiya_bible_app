class AppConstants {
  // App Information
  static const String appName = 'Odiya Bible';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Read the Holy Bible in Odiya language';
  
  // Database
  static const String databaseName = 'odiya_bible.db';
  static const int databaseVersion = 1;
  
  // Table Names
  static const String booksTable = 'books';
  static const String versesTable = 'verses';
  static const String bookmarksTable = 'bookmarks';
  
  // SharedPreferences Keys
  static const String keyFontSize = 'font_size';
  static const String keyDarkMode = 'dark_mode';
  static const String keyParallelBible = 'parallel_bible';
  static const String keyLastBookId = 'last_book_id';
  static const String keyLastChapter = 'last_chapter';
  static const String keyKeepScreenOn = 'keep_screen_on';
  static const String keyAutoScroll = 'auto_scroll';
  static const String keyAutoScrollSpeed = 'auto_scroll_speed';
  static const String keyAudioPlayback = 'audio_playback';
  static const String keyAudioSpeed = 'audio_speed';
  static const String keyFirstLaunch = 'first_launch';
  
  // Default Values
  static const double defaultFontSize = 16.0;
  static const double minFontSize = 12.0;
  static const double maxFontSize = 24.0;
  static const bool defaultDarkMode = false;
  static const bool defaultParallelBible = false;
  static const bool defaultKeepScreenOn = false;
  static const bool defaultAutoScroll = false;
  static const double defaultAutoScrollSpeed = 1.0;
  static const bool defaultAudioPlayback = false;
  static const double defaultAudioSpeed = 1.0;
  static const int defaultBookId = 1; // Genesis
  static const int defaultChapter = 1;
  
  // UI Constants
  static const double cardBorderRadius = 12.0;
  static const double buttonBorderRadius = 8.0;
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
  
  // Search
  static const int minSearchLength = 2;
  static const int maxSearchResults = 100;
  
  // Bookmarks
  static const int maxBookmarkNote = 500;
  static const int maxBookmarkTags = 5;
  
  // Export/Import
  static const String exportFileName = 'odiya_bible_bookmarks';
  static const String exportFileExtension = '.json';
  
  // URLs
  static const String privacyPolicyUrl = 'https://example.com/privacy-policy';
  static const String supportUrl = 'https://example.com/support';
  static const String playStoreUrl = 'https://play.google.com/store/apps/details?id=com.example.odiya_bible';
  
  // Error Messages
  static const String errorGeneral = 'Something went wrong. Please try again.';
  static const String errorNetwork = 'Please check your internet connection.';
  static const String errorDatabase = 'Database error occurred.';
  static const String errorFileNotFound = 'File not found.';
  static const String errorInvalidData = 'Invalid data format.';
  
  // Success Messages
  static const String successBookmarkAdded = 'Bookmark added successfully';
  static const String successBookmarkRemoved = 'Bookmark removed successfully';
  static const String successNoteAdded = 'Note added successfully';
  static const String successNoteUpdated = 'Note updated successfully';
  static const String successSettingsSaved = 'Settings saved successfully';
  static const String successDataExported = 'Data exported successfully';
  static const String successDataImported = 'Data imported successfully';
  
  // Confirmation Messages
  static const String confirmDeleteBookmark = 'Are you sure you want to delete this bookmark?';
  static const String confirmDeleteNote = 'Are you sure you want to delete this note?';
  static const String confirmResetSettings = 'Are you sure you want to reset all settings to default?';
  static const String confirmClearCache = 'Are you sure you want to clear all cached data?';
}

class AppColors {
  // Primary Colors
  static const int primaryColorValue = 0xFF2E7D32;
  static const int secondaryColorValue = 0xFF388E3C;
  
  // Text Colors
  static const int textPrimaryLight = 0xFF212121;
  static const int textSecondaryLight = 0xFF757575;
  static const int textPrimaryDark = 0xFFFFFFFF;
  static const int textSecondaryDark = 0xFFBDBDBD;
  
  // Background Colors
  static const int backgroundLight = 0xFFFAFAFA;
  static const int backgroundDark = 0xFF121212;
  static const int surfaceLight = 0xFFFFFFFF;
  static const int surfaceDark = 0xFF1E1E1E;
  
  // Accent Colors
  static const int highlightColor = 0xFFFFEB3B;
  static const int bookmarkColor = 0xFFFF5722;
  static const int noteColor = 0xFF2196F3;
}

class AppTextStyles {
  static const String fontFamily = 'Roboto';
  static const String odiyaFontFamily = 'NotoSansOriya';
}