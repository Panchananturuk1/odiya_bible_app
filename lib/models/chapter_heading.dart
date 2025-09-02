class ChapterHeading {
  final int chapter;
  final String heading;
  final String? englishHeading;

  ChapterHeading({
    required this.chapter,
    required this.heading,
    this.englishHeading,
  });

  factory ChapterHeading.fromJson(Map<String, dynamic> json) {
    return ChapterHeading(
      chapter: json['chapter'],
      heading: json['heading'],
      englishHeading: json['english_heading'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chapter': chapter,
      'heading': heading,
      'english_heading': englishHeading,
    };
  }

  ChapterHeading copyWith({
    int? chapter,
    String? heading,
    String? englishHeading,
  }) {
    return ChapterHeading(
      chapter: chapter ?? this.chapter,
      heading: heading ?? this.heading,
      englishHeading: englishHeading ?? this.englishHeading,
    );
  }

  @override
  String toString() {
    return 'ChapterHeading(chapter: $chapter, heading: $heading, englishHeading: $englishHeading)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChapterHeading &&
        other.chapter == chapter &&
        other.heading == heading &&
        other.englishHeading == englishHeading;
  }

  @override
  int get hashCode {
    return chapter.hashCode ^ heading.hashCode ^ englishHeading.hashCode;
  }
}