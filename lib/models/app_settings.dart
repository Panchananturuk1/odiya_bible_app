class AppSettings {
  final double fontSize;
  final bool isDarkMode;
  final bool showParallelBible;
  final String parallelLanguage; // 'english' or 'hindi'
  final bool autoPlayAudio;
  final double audioSpeed;
  final bool keepScreenOn;
  final String defaultTranslation;
  final bool showVerseNumbers;
  final bool enableSwipeNavigation;
  final int lastReadBookId;
  final int lastReadChapter;
  final int lastReadVerse;

  AppSettings({
    this.fontSize = 16.0,
    this.isDarkMode = false,
    this.showParallelBible = false,
    this.parallelLanguage = 'english',
    this.autoPlayAudio = false,
    this.audioSpeed = 1.0,
    this.keepScreenOn = false,
    this.defaultTranslation = 'odiya_irv',
    this.showVerseNumbers = true,
    this.enableSwipeNavigation = true,
    this.lastReadBookId = 1,
    this.lastReadChapter = 1,
    this.lastReadVerse = 1,
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      fontSize: json['font_size']?.toDouble() ?? 16.0,
      isDarkMode: json['is_dark_mode'] ?? false,
      showParallelBible: json['show_parallel_bible'] ?? false,
      parallelLanguage: json['parallel_language'] ?? 'english',
      autoPlayAudio: json['auto_play_audio'] ?? false,
      audioSpeed: json['audio_speed']?.toDouble() ?? 1.0,
      keepScreenOn: json['keep_screen_on'] ?? false,
      defaultTranslation: json['default_translation'] ?? 'odiya_irv',
      showVerseNumbers: json['show_verse_numbers'] ?? true,
      enableSwipeNavigation: json['enable_swipe_navigation'] ?? true,
      lastReadBookId: json['last_read_book_id'] ?? 1,
      lastReadChapter: json['last_read_chapter'] ?? 1,
      lastReadVerse: json['last_read_verse'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'font_size': fontSize,
      'is_dark_mode': isDarkMode,
      'show_parallel_bible': showParallelBible,
      'parallel_language': parallelLanguage,
      'auto_play_audio': autoPlayAudio,
      'audio_speed': audioSpeed,
      'keep_screen_on': keepScreenOn,
      'default_translation': defaultTranslation,
      'show_verse_numbers': showVerseNumbers,
      'enable_swipe_navigation': enableSwipeNavigation,
      'last_read_book_id': lastReadBookId,
      'last_read_chapter': lastReadChapter,
      'last_read_verse': lastReadVerse,
    };
  }

  AppSettings copyWith({
    double? fontSize,
    bool? isDarkMode,
    bool? showParallelBible,
    String? parallelLanguage,
    bool? autoPlayAudio,
    double? audioSpeed,
    bool? keepScreenOn,
    String? defaultTranslation,
    bool? showVerseNumbers,
    bool? enableSwipeNavigation,
    int? lastReadBookId,
    int? lastReadChapter,
    int? lastReadVerse,
  }) {
    return AppSettings(
      fontSize: fontSize ?? this.fontSize,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      showParallelBible: showParallelBible ?? this.showParallelBible,
      parallelLanguage: parallelLanguage ?? this.parallelLanguage,
      autoPlayAudio: autoPlayAudio ?? this.autoPlayAudio,
      audioSpeed: audioSpeed ?? this.audioSpeed,
      keepScreenOn: keepScreenOn ?? this.keepScreenOn,
      defaultTranslation: defaultTranslation ?? this.defaultTranslation,
      showVerseNumbers: showVerseNumbers ?? this.showVerseNumbers,
      enableSwipeNavigation: enableSwipeNavigation ?? this.enableSwipeNavigation,
      lastReadBookId: lastReadBookId ?? this.lastReadBookId,
      lastReadChapter: lastReadChapter ?? this.lastReadChapter,
      lastReadVerse: lastReadVerse ?? this.lastReadVerse,
    );
  }

  @override
  String toString() {
    return 'AppSettings{fontSize: $fontSize, isDarkMode: $isDarkMode, lastRead: $lastReadBookId:$lastReadChapter:$lastReadVerse}';
  }
}