import '../services/json_bible_service.dart';

class Verse {
  final int id;
  final int bookId;
  final int chapter;
  final int verseNumber;
  final String odiyaText;
  final String? englishText;
  final String? hindiText;
  final bool isHighlighted;
  final String? note;
  final bool isBookmarked;

  Verse({
    required this.id,
    required this.bookId,
    required this.chapter,
    required this.verseNumber,
    required this.odiyaText,
    this.englishText,
    this.hindiText,
    this.isHighlighted = false,
    this.note,
    this.isBookmarked = false,
  });

  factory Verse.fromJson(Map<String, dynamic> json) {
    return Verse(
      id: json['id'],
      bookId: json['book_id'],
      chapter: json['chapter'],
      verseNumber: json['verse_number'],
      odiyaText: json['odiya_text'],
      englishText: json['english_text'],
      hindiText: json['hindi_text'],
      isHighlighted: json['is_highlighted'] == 1,
      note: json['note'],
      isBookmarked: json['is_bookmarked'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'book_id': bookId,
      'chapter': chapter,
      'verse_number': verseNumber,
      'odiya_text': odiyaText,
      'english_text': englishText,
      'hindi_text': hindiText,
      'is_highlighted': isHighlighted ? 1 : 0,
      'note': note,
      'is_bookmarked': isBookmarked ? 1 : 0,
    };
  }

  Verse copyWith({
    int? id,
    int? bookId,
    int? chapter,
    int? verseNumber,
    String? odiyaText,
    String? englishText,
    String? hindiText,
    bool? isHighlighted,
    String? note,
    bool? isBookmarked,
  }) {
    return Verse(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      chapter: chapter ?? this.chapter,
      verseNumber: verseNumber ?? this.verseNumber,
      odiyaText: odiyaText ?? this.odiyaText,
      englishText: englishText ?? this.englishText,
      hindiText: hindiText ?? this.hindiText,
      isHighlighted: isHighlighted ?? this.isHighlighted,
      note: note ?? this.note,
      isBookmarked: isBookmarked ?? this.isBookmarked,
    );
  }

  // Get the proper reference including book name
  String get reference {
    // Get book name from the bookId using a lookup method
    String bookName = JsonBibleService.getBookNameById(bookId);
    return '$bookName $chapter:$verseNumber';
  }

  @override
  String toString() {
    return 'Verse{id: $id, reference: $reference, text: ${odiyaText.substring(0, odiyaText.length > 50 ? 50 : odiyaText.length)}...}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Verse && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}