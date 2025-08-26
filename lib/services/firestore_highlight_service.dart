import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreHighlightService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>>? get _highlightsCollection {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _firestore.collection('users').doc(user.uid).collection('highlights');
  }

  String _refKey(int bookId, int chapter, int verseNumber) => '$bookId:$chapter:$verseNumber';

  Future<void> setHighlight(int bookId, int chapter, int verseNumber, String colorHex) async {
    final coll = _highlightsCollection;
    if (coll == null) throw Exception('User not authenticated');

    // Use a deterministic document id for idempotency
    final docId = _refKey(bookId, chapter, verseNumber);
    await coll.doc(docId).set({
      'book_id': bookId,
      'chapter': chapter,
      'verse_number': verseNumber,
      'color': colorHex,
      'created_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> removeHighlight(int bookId, int chapter, int verseNumber) async {
    final coll = _highlightsCollection;
    if (coll == null) throw Exception('User not authenticated');

    final docId = _refKey(bookId, chapter, verseNumber);
    await coll.doc(docId).delete();
  }

  // Stream of refs for quick lookup. Could be extended to map of ref->color
  Stream<Set<String>> watchHighlights() {
    final coll = _highlightsCollection;
    if (coll == null) {
      return Stream.value(<String>{});
    }

    return coll.snapshots().map((snapshot) {
      final refs = <String>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final bookId = data['book_id'] as int?;
        final chapter = data['chapter'] as int?;
        final verseNumber = data['verse_number'] as int?;
        if (bookId != null && chapter != null && verseNumber != null) {
          refs.add(_refKey(bookId, chapter, verseNumber));
        }
      }
      return refs;
    });
  }
}