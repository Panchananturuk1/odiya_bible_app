import 'package:flutter/foundation.dart';
import '../models/book.dart';
import '../models/verse.dart';
import '../models/bookmark.dart';
import '../services/database_service.dart';
import '../services/json_bible_service.dart';

class BibleProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  // Using JSON service for Bible data, database for bookmarks only
  
  List<Book> _books = [];
  List<Verse> _currentChapterVerses = [];
  Book? _currentBook;
  int _currentChapter = 1;
  int _currentVerse = 1;
  List<Bookmark> _bookmarks = [];
  List<Verse> _searchResults = [];
  bool _isLoading = false;
  String _searchQuery = '';

  // Getters
  List<Book> get books => _books;
  List<Verse> get currentChapterVerses => _currentChapterVerses;
  Book? get currentBook => _currentBook;
  int get currentChapter => _currentChapter;
  int get currentVerse => _currentVerse;
  List<Bookmark> get bookmarks => _bookmarks;
  List<Verse> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;

  List<Book> get oldTestamentBooks => _books.where((book) => book.testament == 1).toList();
  List<Book> get newTestamentBooks => _books.where((book) => book.testament == 2).toList();

  // Initialize data
  Future<void> initialize() async {
    _setLoading(true);
    try {
      await loadBooks();
      await loadBookmarks();
      // Load the first book and chapter by default
      if (_books.isNotEmpty) {
        await selectBook(_books.first.id);
        await loadChapter(_books.first.id, 1);
      }
    } catch (e) {
      debugPrint('Error initializing Bible provider: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load all books
  Future<void> loadBooks() async {
    try {
      _books = JsonBibleService.getAllBooks();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading books: $e');
    }
  }

  // Select a book
  Future<void> selectBook(int bookId) async {
    try {
      _currentBook = _books.firstWhere((book) => book.id == bookId);
      _currentChapter = 1;
      _currentVerse = 1;
      notifyListeners();
    } catch (e) {
      debugPrint('Error selecting book: $e');
    }
  }

  // Load chapter verses
  Future<void> loadChapter(int bookId, int chapter) async {
    _setLoading(true);
    try {
      final book = _books.firstWhere((b) => b.id == bookId);
      _currentChapterVerses = await JsonBibleService.getVersesByChapter(book.name, chapter);
      _currentChapter = chapter;
      _currentVerse = 1;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading chapter: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Navigate to next chapter
  Future<void> nextChapter() async {
    if (_currentBook != null && _currentChapter < _currentBook!.totalChapters) {
      await loadChapter(_currentBook!.id, _currentChapter + 1);
    }
  }

  // Navigate to previous chapter
  Future<void> previousChapter() async {
    if (_currentBook != null && _currentChapter > 1) {
      await loadChapter(_currentBook!.id, _currentChapter - 1);
    }
  }

  // Navigate to specific verse
  void goToVerse(int verseNumber) {
    if (verseNumber > 0 && verseNumber <= _currentChapterVerses.length) {
      _currentVerse = verseNumber;
      notifyListeners();
    }
  }

  // Search verses
  Future<void> searchVerses(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      _searchQuery = '';
      notifyListeners();
      return;
    }

    _setLoading(true);
    try {
      _searchResults = await JsonBibleService.searchVerses(query);
      _searchQuery = query;
      notifyListeners();
    } catch (e) {
      debugPrint('Error searching verses: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Clear search
  void clearSearch() {
    _searchResults = [];
    _searchQuery = '';
    notifyListeners();
  }

  // Highlight verse
  Future<void> toggleVerseHighlight(int verseId) async {
    try {
      final verse = _currentChapterVerses.firstWhere((v) => v.id == verseId);
      final newHighlightState = !verse.isHighlighted;
      
      await _databaseService.updateVerseHighlight(verseId, newHighlightState);
      
      // Update local state
      final index = _currentChapterVerses.indexWhere((v) => v.id == verseId);
      if (index != -1) {
        _currentChapterVerses[index] = verse.copyWith(isHighlighted: newHighlightState);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error toggling verse highlight: $e');
    }
  }

  // Add/update verse note
  Future<void> updateVerseNote(int verseId, String? note) async {
    try {
      await _databaseService.updateVerseNote(verseId, note);
      
      // Update local state
      final index = _currentChapterVerses.indexWhere((v) => v.id == verseId);
      if (index != -1) {
        final verse = _currentChapterVerses[index];
        _currentChapterVerses[index] = verse.copyWith(note: note);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating verse note: $e');
    }
  }

  // Bookmark operations
  Future<void> loadBookmarks() async {
    try {
      _bookmarks = await _databaseService.getAllBookmarks();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading bookmarks: $e');
    }
  }

  Future<void> addBookmark(Verse verse, String? note) async {
    try {
      final bookmark = Bookmark(
        bookId: verse.bookId,
        chapter: verse.chapter,
        verseNumber: verse.verseNumber,
        verseText: verse.odiyaText,
        note: note,
        createdAt: DateTime.now(),
      );
      
      await _databaseService.insertBookmark(bookmark);
      await loadBookmarks();
    } catch (e) {
      debugPrint('Error adding bookmark: $e');
    }
  }

  Future<void> removeBookmark(int bookmarkId) async {
    try {
      await _databaseService.deleteBookmark(bookmarkId);
      await loadBookmarks();
    } catch (e) {
      debugPrint('Error removing bookmark: $e');
    }
  }

  Future<void> updateBookmark(Bookmark bookmark) async {
    try {
      final updatedBookmark = bookmark.copyWith(updatedAt: DateTime.now());
      await _databaseService.updateBookmark(updatedBookmark);
      await loadBookmarks();
    } catch (e) {
      debugPrint('Error updating bookmark: $e');
    }
  }

  // Alias for removeBookmark to match bookmarks_screen.dart usage
  Future<void> deleteBookmark(int bookmarkId) async {
    await removeBookmark(bookmarkId);
  }

  // Toggle bookmark for a verse
  Future<void> toggleBookmark(Verse verse) async {
    try {
      // Check if verse is already bookmarked
      final existingBookmark = _bookmarks.firstWhere(
        (bookmark) => bookmark.bookId == verse.bookId && 
                     bookmark.chapter == verse.chapter && 
                     bookmark.verseNumber == verse.verseNumber,
        orElse: () => throw StateError('Not found'),
      );
      
      // If found, remove it
      await removeBookmark(existingBookmark.id!);
    } catch (e) {
      // If not found, add it
      await addBookmark(verse, null);
    }
  }

  // Update note for a verse (placeholder implementation)
  Future<void> updateNote(int verseId, String note) async {
    try {
      // This would need proper implementation to find and update verse notes
      // For now, just notify listeners
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating note: $e');
    }
  }

  // Clear search results
  void clearSearchResults() {
    _searchResults.clear();
    notifyListeners();
  }

  // Toggle highlight for a verse (placeholder implementation)
  Future<void> toggleHighlight(int verseId) async {
    try {
      // This would need proper implementation to manage verse highlights
      // For now, just notify listeners
      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling highlight: $e');
    }
  }

  // Chapter navigation helpers
  bool get canGoToPreviousChapter {
    if (_currentBook == null) return false;
    return _currentChapter > 1;
  }

  bool get canGoNextChapter {
    if (_currentBook == null) return false;
    return _currentChapter < _currentBook!.totalChapters;
  }

  Future<void> goToPreviousChapter() async {
    if (canGoToPreviousChapter) {
      await loadChapter(_currentBook!.id, _currentChapter - 1);
    }
  }

  Future<void> goToNextChapter() async {
    if (canGoNextChapter) {
      await loadChapter(_currentBook!.id, _currentChapter + 1);
    }
  }

  // Navigate to bookmarked verse
  Future<void> goToBookmark(Bookmark bookmark) async {
    await selectBook(bookmark.bookId);
    await loadChapter(bookmark.bookId, bookmark.chapter);
    goToVerse(bookmark.verseNumber);
  }

  // Helper method
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Get verse reference string
  String getVerseReference(Verse verse) {
    final book = _books.firstWhere((b) => b.id == verse.bookId, orElse: () => Book(
      id: 0, name: 'Unknown', odiyaName: 'ଅଜଣା', abbreviation: 'Unk', 
      testament: 1, totalChapters: 1, order: 0
    ));
    return '${book.odiyaName} ${verse.chapter}:${verse.verseNumber}';
  }
}