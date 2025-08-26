class Bookmark {
  final int? id;
  final String? documentId; // Firestore document ID
  final int bookId;
  final int chapter;
  final int verseNumber;
  final String verseText;
  final String? note;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? tags;

  Bookmark({
    this.id,
    this.documentId,
    required this.bookId,
    required this.chapter,
    required this.verseNumber,
    required this.verseText,
    this.note,
    required this.createdAt,
    this.updatedAt,
    this.tags,
  });

  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      id: json['id'],
      documentId: json['document_id'],
      bookId: json['book_id'],
      chapter: json['chapter'],
      verseNumber: json['verse_number'],
      verseText: json['verse_text'],
      note: json['note'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
      tags: json['tags'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'document_id': documentId,
      'book_id': bookId,
      'chapter': chapter,
      'verse_number': verseNumber,
      'verse_text': verseText,
      'note': note,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'tags': tags,
    };
  }

  Bookmark copyWith({
    int? id,
    String? documentId,
    int? bookId,
    int? chapter,
    int? verseNumber,
    String? verseText,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? tags,
  }) {
    return Bookmark(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      bookId: bookId ?? this.bookId,
      chapter: chapter ?? this.chapter,
      verseNumber: verseNumber ?? this.verseNumber,
      verseText: verseText ?? this.verseText,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
    );
  }

  String get reference => '$bookId:$chapter:$verseNumber';

  @override
  String toString() {
    return 'Bookmark{id: $id, reference: $reference, note: $note}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Bookmark && 
           other.bookId == bookId && 
           other.chapter == chapter && 
           other.verseNumber == verseNumber;
  }

  @override
  int get hashCode => Object.hash(bookId, chapter, verseNumber);
}