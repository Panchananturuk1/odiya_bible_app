import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/bible_provider.dart';
import '../providers/settings_provider.dart';
import '../models/verse.dart';
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

  void _showVerseOptions(BuildContext context, Verse verse, BibleProvider bibleProvider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              verse.reference,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(
                verse.isHighlighted ? Icons.highlight_off : Icons.highlight,
                color: Colors.yellow[700],
              ),
              title: Text(
                verse.isHighlighted ? 'Remove Highlight' : 'Highlight Verse',
              ),
              onTap: () async {
                Navigator.pop(context);
                await bibleProvider.toggleVerseHighlight(verse.id);
              },
            ),
            ListTile(
              leading: Icon(
                verse.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(
                verse.isBookmarked ? 'Remove Bookmark' : 'Add Bookmark',
              ),
              onTap: () async {
                Navigator.pop(context);
                await bibleProvider.toggleBookmark(verse);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.note_add,
                color: Colors.orange[600],
              ),
              title: const Text('Add/Edit Note'),
              onTap: () async {
                Navigator.pop(context);
                final noteController = TextEditingController(text: verse.note ?? '');
                final result = await showDialog<String?>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Note for ${verse.reference}')
,                    content: TextField(
                      controller: noteController,
                      decoration: const InputDecoration(
                        hintText: 'Add your personal note...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 4,
                      autofocus: true,
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, noteController.text.isEmpty ? null : noteController.text),
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                );
                if (result != null || verse.note?.isNotEmpty == true) {
                  await bibleProvider.updateNote(verse.id, result);
                }
              },
            ),
            ListTile(
              leading: Icon(
                Icons.share,
                color: Colors.blue[600],
              ),
              title: const Text('Share Verse'),
              onTap: () {
                Navigator.pop(context);
                _shareVerse(verse);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.content_copy,
                color: Colors.green[600],
              ),
              title: const Text('Copy to Clipboard'),
              onTap: () {
                Navigator.pop(context);
                final text = '"${verse.odiyaText}" - ${verse.reference}';
                Clipboard.setData(ClipboardData(text: text));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Verse copied to clipboard'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
        ),
      ),
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

        if (bibleProvider.currentChapterParagraphs.isEmpty) {
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

        final paragraphs = bibleProvider.currentChapterParagraphs;

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
                
                // Paragraph list
                Expanded(
                  child: ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: paragraphs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final para = paragraphs[index];
                      return _ParagraphView(
                        verses: para,
                        fontSize: settingsProvider.fontSize,
                        onTapVerse: (v) => _showVerseOptions(context, v, bibleProvider),
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
            Clipboard.setData(ClipboardData(text: text));
          },
        ),
      ),
    );
  }
}

class _ParagraphView extends StatelessWidget {
  const _ParagraphView({
    required this.verses,
    required this.fontSize,
    required this.onTapVerse,
  });

  final List<Verse> verses;
  final double fontSize;
  final void Function(Verse v) onTapVerse;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SelectableText.rich(
      TextSpan(
        children: [
          for (int i = 0; i < verses.length; i++) ...[
            // Verse number as superscript red
            WidgetSpan(
              alignment: PlaceholderAlignment.aboveBaseline,
              baseline: TextBaseline.alphabetic,
              child: GestureDetector(
                onTap: () => onTapVerse(verses[i]),
                onLongPress: () => onTapVerse(verses[i]),
                child: Padding(
                  padding: EdgeInsets.only(right: 4, left: i == 0 ? 0 : 6),
                  child: Text(
                    '${verses[i].verseNumber}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.red,
                      fontSize: fontSize * 0.75,
                      height: 0.8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            TextSpan(
              text: ' ${verses[i].odiyaText.trim()} ',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: fontSize,
                height: 1.6,
                backgroundColor: verses[i].isHighlighted
                    ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.2)
                    : null,
              ),
            ),
          ]
        ],
      ),
      textAlign: TextAlign.start,
    );
  }
}