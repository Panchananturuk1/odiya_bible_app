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
      // Attempt to load bookmarks, but don't block initialization on failure (e.g., web without sqflite)
      try {
        await loadBookmarks();
      } catch (e) {
        debugPrint('Bookmarks not available on this platform: $e');
      }
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
      // Use JSON-based search on Web where sqflite is not available; use database-backed search on other platforms
      if (kIsWeb) {
        _searchResults = await JsonBibleService.searchVerses(query);
      } else {
        _searchResults = await _databaseService.searchVerses(query);
      }
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

  // Helper to update a verse in memory across both current chapter and search results
  void _updateVerseInMemory(int verseId, {bool? isHighlighted, String? note, bool? isBookmarked}) {
    final idxCurrent = _currentChapterVerses.indexWhere((v) => v.id == verseId);
    if (idxCurrent != -1) {
      final v = _currentChapterVerses[idxCurrent];
      _currentChapterVerses[idxCurrent] = v.copyWith(
        isHighlighted: isHighlighted ?? v.isHighlighted,
        note: note ?? v.note,
        isBookmarked: isBookmarked ?? v.isBookmarked,
      );
    }

    final idxSearch = _searchResults.indexWhere((v) => v.id == verseId);
    if (idxSearch != -1) {
      final v = _searchResults[idxSearch];
      _searchResults[idxSearch] = v.copyWith(
        isHighlighted: isHighlighted ?? v.isHighlighted,
        note: note ?? v.note,
        isBookmarked: isBookmarked ?? v.isBookmarked,
      );
    }
  }

  // Highlight verse (web-safe and updates both current and search lists)
  Future<void> toggleVerseHighlight(int verseId) async {
    try {
      // Determine current highlight state from either list
      bool current = false;
      final idxCurrent = _currentChapterVerses.indexWhere((v) => v.id == verseId);
      if (idxCurrent != -1) {
        current = _currentChapterVerses[idxCurrent].isHighlighted;
      } else {
        final idxSearch = _searchResults.indexWhere((v) => v.id == verseId);
        if (idxSearch != -1) {
          current = _searchResults[idxSearch].isHighlighted;
        }
      }

      final newHighlightState = !current;

      if (!kIsWeb) {
        await _databaseService.updateVerseHighlight(verseId, newHighlightState);
      }

      _updateVerseInMemory(verseId, isHighlighted: newHighlightState);
      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling verse highlight: $e');
    }
  }

  // Add/update verse note (web-safe and updates both current and search lists)
  Future<void> updateVerseNote(int verseId, String? note) async {
    try {
      if (!kIsWeb) {
        await _databaseService.updateVerseNote(verseId, note);
      }

      _updateVerseInMemory(verseId, note: note);
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating verse note: $e');
    }
  }

  // Bookmark operations
  Future<void> loadBookmarks() async {
    try {
      if (kIsWeb) {
        // On web, keep in-memory bookmarks as-is
        notifyListeners();
        return;
      }
      _bookmarks = await _databaseService.getAllBookmarks();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading bookmarks: $e');
    }
  }

  Future<void> addBookmark(Verse verse, String? note) async {
    try {
      final bookmark = Bookmark(
        id: kIsWeb ? DateTime.now().millisecondsSinceEpoch : null,
        bookId: verse.bookId,
        chapter: verse.chapter,
        verseNumber: verse.verseNumber,
        verseText: verse.odiyaText,
        note: note,
        createdAt: DateTime.now(),
      );

      if (kIsWeb) {
        _bookmarks.add(bookmark);
        _updateVerseInMemory(verse.id, isBookmarked: true);
        notifyListeners();
      } else {
        await _databaseService.insertBookmark(bookmark);
        await loadBookmarks();
        // Optionally reflect bookmark state in current/search lists
        _updateVerseInMemory(verse.id, isBookmarked: true);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error adding bookmark: $e');
    }
  }

  Future<void> removeBookmark(int bookmarkId) async {
    try {
      if (kIsWeb) {
        final idx = _bookmarks.indexWhere((b) => (b.id ?? -1) == bookmarkId);
        if (idx != -1) {
          final b = _bookmarks[idx];
          _bookmarks.removeAt(idx);
          // Update verse state in memory
          final verseId = _findVerseIdByReference(b.bookId, b.chapter, b.verseNumber);
          if (verseId != null) {
            _updateVerseInMemory(verseId, isBookmarked: false);
          }
          notifyListeners();
        }
        return;
      }

      await _databaseService.deleteBookmark(bookmarkId);
      await loadBookmarks();
    } catch (e) {
      debugPrint('Error removing bookmark: $e');
    }
  }

  Future<void> updateBookmark(Bookmark bookmark) async {
    try {
      if (kIsWeb) {
        final idx = _bookmarks.indexWhere((b) => (b.id ?? -1) == (bookmark.id ?? -2));
        if (idx != -1) {
          _bookmarks[idx] = bookmark.copyWith(updatedAt: DateTime.now());
          notifyListeners();
        }
        return;
      }

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

  // Toggle bookmark for a verse (web-safe)
  Future<void> toggleBookmark(Verse verse) async {
    try {
      // Check if verse is already bookmarked
      final existingIndex = _bookmarks.indexWhere(
        (bookmark) => bookmark.bookId == verse.bookId &&
                      bookmark.chapter == verse.chapter &&
                      bookmark.verseNumber == verse.verseNumber,
      );

      if (existingIndex != -1) {
        // If found, remove it
        if (kIsWeb) {
          final existing = _bookmarks[existingIndex];
          _bookmarks.removeAt(existingIndex);
          _updateVerseInMemory(verse.id, isBookmarked: false);
          notifyListeners();
        } else {
          final existing = _bookmarks[existingIndex];
          if (existing.id != null) {
            await removeBookmark(existing.id!);
          }
          // Reflect change in UI
          _updateVerseInMemory(verse.id, isBookmarked: false);
          notifyListeners();
        }
      } else {
        await addBookmark(verse, null);
      }
    } catch (e) {
      debugPrint('Error toggling bookmark: $e');
    }
  }

  // Update note for a verse (placeholder implementation)
  Future<void> updateNote(int verseId, String? note) async {
    try {
      await updateVerseNote(verseId, note);
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

  // Try to find a verse id by book/chapter/verseNumber in currently loaded data
  int? _findVerseIdByReference(int bookId, int chapter, int verseNumber) {
    final inCurrent = _currentChapterVerses.firstWhere(
      (v) => v.bookId == bookId && v.chapter == chapter && v.verseNumber == verseNumber,
      orElse: () => Verse(
        id: -1,
        bookId: -1,
        chapter: -1,
        verseNumber: -1,
        odiyaText: '',
        englishText: '',
        hindiText: '',
      ),
    );
    if (inCurrent.id != -1) return inCurrent.id;

    final inSearch = _searchResults.firstWhere(
      (v) => v.bookId == bookId && v.chapter == chapter && v.verseNumber == verseNumber,
      orElse: () => Verse(
        id: -1,
        bookId: -1,
        chapter: -1,
        verseNumber: -1,
        odiyaText: '',
        englishText: '',
        hindiText: '',
      ),
    );
    if (inSearch.id != -1) return inSearch.id;

    return null;
  }
}