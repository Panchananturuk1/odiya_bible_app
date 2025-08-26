import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bible_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/bookmark_card.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Load bookmarks when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bibleProvider = Provider.of<BibleProvider>(context, listen: false);
      bibleProvider.loadBookmarks();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<BibleProvider, SettingsProvider>(
      builder: (context, bibleProvider, settingsProvider, child) {
        final filteredBookmarks = _filterBookmarks(bibleProvider.bookmarks);
        final recentBookmarks = _getRecentBookmarks(filteredBookmarks);
        
        return Column(
          children: [
            // Search bar
            Container(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search bookmarks...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
            
            // Tab bar
            TabBar(
              controller: _tabController,
              tabs: [
                Tab(
                  text: 'All (${filteredBookmarks.length})',
                  icon: const Icon(Icons.bookmark),
                ),
                Tab(
                  text: 'Recent (${recentBookmarks.length})',
                  icon: const Icon(Icons.access_time),
                ),
              ],
            ),
            
            // Tab views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildBookmarksList(filteredBookmarks, bibleProvider, settingsProvider),
                  _buildBookmarksList(recentBookmarks, bibleProvider, settingsProvider),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBookmarksList(
    List bookmarks,
    BibleProvider bibleProvider,
    SettingsProvider settingsProvider,
  ) {
    if (bibleProvider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (bookmarks.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookmarks.length,
      itemBuilder: (context, index) {
        final bookmark = bookmarks[index];
        return BookmarkCard(
          bookmark: bookmark,
          fontSize: settingsProvider.fontSize,
          onTap: () => _navigateToVerse(bookmark, bibleProvider),
          onEdit: () => _editBookmark(bookmark, bibleProvider),
          onDelete: () => _deleteBookmark(bookmark, bibleProvider),
          onShare: () => _shareBookmark(bookmark),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final isSearching = _searchQuery.isNotEmpty;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearching ? Icons.search_off : Icons.bookmark_border,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            isSearching 
                ? 'No bookmarks found for "$_searchQuery"'
                : 'No bookmarks yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            isSearching
                ? 'Try different keywords'
                : 'Bookmark verses while reading to save them here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          if (!isSearching) ...
          [
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to Bible reading screen
                DefaultTabController.of(context)?.animateTo(0);
              },
              icon: const Icon(Icons.menu_book),
              label: const Text('Start Reading'),
            ),
          ],
        ],
      ),
    );
  }

  List _filterBookmarks(List bookmarks) {
    if (_searchQuery.isEmpty) {
      return bookmarks;
    }
    
    return bookmarks.where((bookmark) {
      final query = _searchQuery.toLowerCase();
      return bookmark.verseText.toLowerCase().contains(query) ||
             bookmark.note?.toLowerCase().contains(query) == true ||
             bookmark.reference.toLowerCase().contains(query);
    }).toList();
  }

  List _getRecentBookmarks(List bookmarks) {
    final sortedBookmarks = List.from(bookmarks);
    // Sort by updatedAt if available, otherwise by createdAt; handle nulls safely
    sortedBookmarks.sort((a, b) {
      final DateTime aTime = (a.updatedAt ?? a.createdAt) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final DateTime bTime = (b.updatedAt ?? b.createdAt) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
    return sortedBookmarks.take(20).toList(); // Show last 20 recent bookmarks
  }

  void _navigateToVerse(bookmark, BibleProvider bibleProvider) {
    // Navigate to the specific verse
    bibleProvider.selectBook(bookmark.bookId);
    bibleProvider.loadChapter(bookmark.bookId, bookmark.chapter);
    
    // Switch to Bible reading tab
    DefaultTabController.of(context)?.animateTo(0);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navigated to ${bookmark.reference}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _editBookmark(bookmark, BibleProvider bibleProvider) {
    showDialog(
      context: context,
      builder: (context) => _EditBookmarkDialog(
        bookmark: bookmark,
        onSave: (note, tags) {
          final updatedBookmark = bookmark.copyWith(
            note: note,
            tags: tags,
          );
          bibleProvider.updateBookmark(updatedBookmark);
        },
      ),
    );
  }

  void _deleteBookmark(bookmark, BibleProvider bibleProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bookmark'),
        content: Text('Are you sure you want to delete this bookmark?\n\n${bookmark.reference}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              bibleProvider.deleteBookmark(bookmark.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Bookmark deleted'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _shareBookmark(bookmark) {
    final text = '"${bookmark.verseText}" - ${bookmark.reference}';
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Share: $text'),
        action: SnackBarAction(
          label: 'Copy',
          onPressed: () {
            // TODO: Copy to clipboard
          },
        ),
      ),
    );
  }
}

class _EditBookmarkDialog extends StatefulWidget {
  final dynamic bookmark;
  final Function(String note, List<String> tags) onSave;

  const _EditBookmarkDialog({
    required this.bookmark,
    required this.onSave,
  });

  @override
  State<_EditBookmarkDialog> createState() => _EditBookmarkDialogState();
}

class _EditBookmarkDialogState extends State<_EditBookmarkDialog> {
  late TextEditingController _noteController;
  late TextEditingController _tagsController;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.bookmark.note ?? '');
    _tagsController = TextEditingController(
      text: widget.bookmark.tags?.join(', ') ?? '',
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Bookmark'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.bookmark.reference,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Note',
                hintText: 'Add a personal note...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _tagsController,
              decoration: const InputDecoration(
                labelText: 'Tags',
                hintText: 'prayer, faith, hope (comma separated)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final note = _noteController.text.trim();
            final tagsText = _tagsController.text.trim();
            final tags = tagsText.isNotEmpty 
                ? tagsText.split(',').map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).toList()
                : <String>[];
            
            widget.onSave(note, tags);
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}