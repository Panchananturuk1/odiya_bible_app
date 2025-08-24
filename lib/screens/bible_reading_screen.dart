import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bible_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/verse_card.dart';
import '../widgets/chapter_navigation.dart';

class BibleReadingScreen extends StatefulWidget {
  const BibleReadingScreen({super.key});

  @override
  State<BibleReadingScreen> createState() => _BibleReadingScreenState();
}

class _BibleReadingScreenState extends State<BibleReadingScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    
    // Load initial chapter after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bibleProvider = Provider.of<BibleProvider>(context, listen: false);
      if (bibleProvider.currentChapterVerses.isEmpty) {
        // Load Genesis 1 by default
        bibleProvider.loadChapter(1, 1);
      }
    });
  }

  void _scrollListener() {
    if (_scrollController.offset >= 400) {
      if (!_showScrollToTop) {
        setState(() {
          _showScrollToTop = true;
        });
      }
    } else {
      if (_showScrollToTop) {
        setState(() {
          _showScrollToTop = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<BibleProvider, SettingsProvider>(
      builder: (context, bibleProvider, settingsProvider, child) {
        if (bibleProvider.isLoading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading chapter...'),
              ],
            ),
          );
        }

        if (bibleProvider.currentChapterVerses.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.menu_book,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'Select a book and chapter to start reading',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final currentBook = bibleProvider.currentBook;
        final currentChapter = bibleProvider.currentChapter;

        return Stack(
          children: [
            Column(
              children: [
                // Chapter header
                if (currentBook != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(16),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          currentBook.odiyaName,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Chapter $currentChapter',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Chapter navigation
                ChapterNavigation(
                  onPreviousChapter: bibleProvider.canGoToPreviousChapter
                      ? bibleProvider.goToPreviousChapter
                      : null,
                  onNextChapter: bibleProvider.canGoNextChapter
                      ? bibleProvider.goToNextChapter
                      : null,
                ),
                
                // Verses list
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: bibleProvider.currentChapterVerses.length,
                    itemBuilder: (context, index) {
                      final verse = bibleProvider.currentChapterVerses[index];
                      return VerseCard(
                        verse: verse,
                        fontSize: settingsProvider.fontSize,
                        onHighlight: () => bibleProvider.toggleHighlight(verse.id),
                        onBookmark: () => bibleProvider.toggleBookmark(verse),
                        onNote: (note) => bibleProvider.updateNote(verse.id, note),
                        onShare: () => _shareVerse(verse),
                      );
                    },
                  ),
                ),
              ],
            ),
            
            // Scroll to top button
            if (_showScrollToTop)
              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingActionButton.small(
                  onPressed: _scrollToTop,
                  tooltip: 'Scroll to top',
                  child: const Icon(Icons.keyboard_arrow_up),
                ),
              ),
          ],
        );
      },
    );
  }

  void _shareVerse(verse) {
    final text = '"${verse.odiyaText}" - ${verse.reference}';
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