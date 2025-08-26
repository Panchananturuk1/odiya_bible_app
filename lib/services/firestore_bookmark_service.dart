import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/bookmark.dart';

class FirestoreBookmarkService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get the current user's bookmarks collection reference
  CollectionReference? get _bookmarksCollection {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _firestore.collection('users').doc(user.uid).collection('bookmarks');
  }

  DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.parse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is double) return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    return DateTime.now();
  }

  String? _parseTags(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is List) {
      try {
        return value.whereType<String>().join(',');
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  // Add a new bookmark
  Future<String?> addBookmark(Bookmark bookmark) async {
    try {
      final collection = _bookmarksCollection;
      if (collection == null) throw Exception('User not authenticated');

      final docRef = await collection.add({
        'book_id': bookmark.bookId,
        'chapter': bookmark.chapter,
        'verse_number': bookmark.verseNumber,
        'verse_text': bookmark.verseText,
        'note': bookmark.note,
        'created_at': bookmark.createdAt.toIso8601String(),
        'updated_at': bookmark.updatedAt?.toIso8601String(),
        'tags': bookmark.tags,
      });
      
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add bookmark: $e');
    }
  }

  // Get all bookmarks for the current user
  Future<List<Bookmark>> getAllBookmarks() async {
    try {
      final collection = _bookmarksCollection;
      if (collection == null) return [];

      // Avoid server-side orderBy because mixed field types across docs can error
      final querySnapshot = await collection.get();

      final list = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Bookmark(
          id: doc.id.hashCode, // Use document ID hash as integer ID for compatibility
          documentId: doc.id, // Store the actual Firestore document ID
          bookId: data['book_id'],
          chapter: data['chapter'],
          verseNumber: data['verse_number'],
          verseText: data['verse_text'],
          note: data['note'],
          createdAt: _parseDate(data['created_at']),
          updatedAt: data['updated_at'] != null 
              ? _parseDate(data['updated_at']) 
              : null,
          tags: _parseTags(data['tags']),
        );
      }).toList();

      // Sort locally by createdAt desc
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (e) {
      throw Exception('Failed to get bookmarks: $e');
    }
  }

  // Update an existing bookmark
  Future<void> updateBookmark(String documentId, Bookmark bookmark) async {
    try {
      final collection = _bookmarksCollection;
      if (collection == null) throw Exception('User not authenticated');

      await collection.doc(documentId).update({
        'book_id': bookmark.bookId,
        'chapter': bookmark.chapter,
        'verse_number': bookmark.verseNumber,
        'verse_text': bookmark.verseText,
        'note': bookmark.note,
        'updated_at': DateTime.now().toIso8601String(),
        'tags': bookmark.tags,
      });
    } catch (e) {
      throw Exception('Failed to update bookmark: $e');
    }
  }

  // Delete a bookmark
  Future<void> deleteBookmark(String documentId) async {
    try {
      final collection = _bookmarksCollection;
      if (collection == null) throw Exception('User not authenticated');

      await collection.doc(documentId).delete();
    } catch (e) {
      throw Exception('Failed to delete bookmark: $e');
    }
  }

  // Check if a verse is bookmarked
  Future<bool> isVerseBookmarked(int bookId, int chapter, int verseNumber) async {
    try {
      final collection = _bookmarksCollection;
      if (collection == null) return false;

      final querySnapshot = await collection
          .where('book_id', isEqualTo: bookId)
          .where('chapter', isEqualTo: chapter)
          .where('verse_number', isEqualTo: verseNumber)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Get bookmark by verse reference
  Future<Bookmark?> getBookmarkByVerse(int bookId, int chapter, int verseNumber) async {
    try {
      final collection = _bookmarksCollection;
      if (collection == null) return null;

      final querySnapshot = await collection
          .where('book_id', isEqualTo: bookId)
          .where('chapter', isEqualTo: chapter)
          .where('verse_number', isEqualTo: verseNumber)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return null;

      final doc = querySnapshot.docs.first;
      final data = doc.data() as Map<String, dynamic>;
      
      return Bookmark(
        id: doc.id.hashCode,
        documentId: doc.id,
        bookId: data['book_id'],
        chapter: data['chapter'],
        verseNumber: data['verse_number'],
        verseText: data['verse_text'],
        note: data['note'],
        createdAt: _parseDate(data['created_at']),
        updatedAt: data['updated_at'] != null 
            ? _parseDate(data['updated_at']) 
            : null,
        tags: _parseTags(data['tags']),
      );
    } catch (e) {
      return null;
    }
  }

  // Listen to bookmarks changes in real-time
  Stream<List<Bookmark>> watchBookmarks() {
    final collection = _bookmarksCollection;
    if (collection == null) {
      return Stream.value([]);
    }

    // Avoid server-side orderBy; sort client-side to handle mixed field types safely
    return collection
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Bookmark(
          id: doc.id.hashCode,
          documentId: doc.id,
          bookId: data['book_id'],
          chapter: data['chapter'],
          verseNumber: data['verse_number'],
          verseText: data['verse_text'],
          note: data['note'],
          createdAt: _parseDate(data['created_at']),
          updatedAt: data['updated_at'] != null 
              ? _parseDate(data['updated_at']) 
              : null,
          tags: _parseTags(data['tags']),
        );
      }).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  // Sync local bookmarks to Firestore (for migration)
  Future<void> syncLocalBookmarksToFirestore(List<Bookmark> localBookmarks) async {
    try {
      final collection = _bookmarksCollection;
      if (collection == null) throw Exception('User not authenticated');

      final batch = _firestore.batch();
      
      for (final bookmark in localBookmarks) {
        final docRef = collection.doc();
        batch.set(docRef, {
          'book_id': bookmark.bookId,
          'chapter': bookmark.chapter,
          'verse_number': bookmark.verseNumber,
          'verse_text': bookmark.verseText,
          'note': bookmark.note,
          'created_at': bookmark.createdAt.toIso8601String(),
          'updated_at': bookmark.updatedAt?.toIso8601String(),
          'tags': bookmark.tags,
        });
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to sync bookmarks: $e');
    }
  }
}