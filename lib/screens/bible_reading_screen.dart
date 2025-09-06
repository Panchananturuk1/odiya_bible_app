import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import '../providers/bible_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/audio_streaming_provider.dart';
import '../models/verse.dart';
import '../widgets/chapter_navigation.dart';
import '../widgets/audio_player_widget.dart';

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
      final audioProvider = Provider.of<AudioStreamingProvider>(context, listen: false);
      
      if (bibleProvider.currentChapterVerses.isEmpty) {
        // Load Genesis 1 by default
        bibleProvider.loadChapter(1, 1).then((_) {
          // Load audio for the chapter after text is loaded
          _loadChapterAudio(audioProvider, bibleProvider);
        });
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

  Future<void> _loadChapterAudio(AudioStreamingProvider audioProvider, BibleProvider bibleProvider) async {
    final currentBook = bibleProvider.currentBook;
    final currentChapter = bibleProvider.currentChapter;
    final verses = bibleProvider.currentChapterVerses;
    
    if (currentBook != null && verses.isNotEmpty) {
      try {
        await audioProvider.loadChapterAudio(
          currentBook.id.toString(),
          currentChapter,
          verses,
        );
      } catch (e) {
        debugPrint('Error loading chapter audio: $e');
      }
    }
  }

  void _showVerseOptions(BuildContext context, Verse verse, BibleProvider bibleProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
          ),
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
              const SizedBox(height: 12),
              Text(
                verse.reference,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                dense: true,
                visualDensity: VisualDensity.compact,
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
                dense: true,
                visualDensity: VisualDensity.compact,
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
              Consumer<AudioStreamingProvider>(
                builder: (context, audioProvider, child) {
                  return ListTile(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    leading: Icon(
                      Icons.play_arrow,
                      color: Colors.blue[600],
                    ),
                    title: const Text('Play Audio'),
                    onTap: () async {
                      Navigator.pop(context);
                      // Load chapter audio if not already loaded
                      await audioProvider.loadChapterAudio(
                        bibleProvider.currentBook!.id.toString(),
                        bibleProvider.currentChapter,
                        bibleProvider.currentChapterVerses,
                      );
                      // Start playing
                      await audioProvider.play();
                      // Seek to the specific verse (service manages timings internally)
                      await audioProvider.seekToVerse(verse.verseNumber);
                    },
                  );
                },
              ),
              ListTile(
                dense: true,
                visualDensity: VisualDensity.compact,
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
                      title: Text('Note for ${verse.reference}'),
                      content: TextField(
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
                dense: true,
                visualDensity: VisualDensity.compact,
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
                dense: true,
                visualDensity: VisualDensity.compact,
                leading: Icon(
                  Icons.content_copy,
                  color: Colors.green[600],
                ),
                title: const Text('Copy'),
                onTap: () {
                  Navigator.pop(context);
                  final lang = Provider.of<SettingsProvider>(context, listen: false).readingLanguage;
                  final verseText = (lang == 'english' && (verse.englishText?.isNotEmpty ?? false))
                      ? verse.englishText!
                      : verse.odiyaText;
                  final text = '"$verseText" - ${verse.reference}';
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
                    fontSize: 10,
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
        final bool isCompact = MediaQuery.of(context).size.width < 420;

        return Stack(
          children: [
            Column(
              children: [
                // Navigation row: previous / center logo to select / next
                ChapterNavigation(
                  onPreviousChapter: bibleProvider.canGoToPreviousChapter
                      ? () {
                          bibleProvider.goToPreviousChapter().then((_) {
                            if (mounted) {
                              final audioProvider = Provider.of<AudioStreamingProvider>(context, listen: false);
                              _loadChapterAudio(audioProvider, bibleProvider);
                            }
                          });
                        }
                      : null,
                  onNextChapter: bibleProvider.canGoToNextChapter
                      ? () {
                          bibleProvider.goToNextChapter().then((_) {
                            if (mounted) {
                              final audioProvider = Provider.of<AudioStreamingProvider>(context, listen: false);
                              _loadChapterAudio(audioProvider, bibleProvider);
                            }
                          });
                        }
                      : null,
                  onTapChapter: () => _openChapterSelector(context, bibleProvider),
                ),
               SizedBox(height: isCompact ? 4 : 6),
                

                
                // Content list (verses and headings)
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Theme.of(context).colorScheme.surface,
                          Theme.of(context).colorScheme.surface.withOpacity(0.95),
                        ],
                      ),
                    ),
                    child: ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 119), // Fixed bottom overflow by reducing padding by 121 pixels
                      itemCount: bibleProvider.currentChapterContent?.length ?? 0,
                      separatorBuilder: (_, __) => const SizedBox(height: 2),
                      itemBuilder: (context, index) {
                        final content = bibleProvider.currentChapterContent![index];
                        
                        if (content['type'] == 'heading') {
                          // Display heading as plain text without card background
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                            child: Text(
                              content['text'],
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          );
                        } else {
                          // Display verse with enhanced styling
                          final verse = content['verse'];
                          if (verse == null) {
                            return const SizedBox.shrink();
                          }
                          return Consumer<AudioStreamingProvider>(
                            builder: (context, audioProvider, child) {
                              return _VerseView(
                                verse: verse,
                                fontSize: settingsProvider.fontSize,
                                onTapVerse: (v) => _showVerseOptions(context, v, bibleProvider),
                                readingLanguage: settingsProvider.readingLanguage,
                                currentPlayingVerse: audioProvider.currentPlayingVerse,
                              );
                            },
                          );
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            
            // Audio Player Widget
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: true,
                child: Container(
                  // Removed extra bottom margin to prevent minor overflow
                  margin: EdgeInsets.zero,
                  child: const AudioPlayerWidget(),
                ),
              ),
            ),
            
            // Scroll to top button
            if (_showScrollToTop)
              Positioned(
                bottom: 240, // Keep above expanded audio player
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
    final lang = Provider.of<SettingsProvider>(context, listen: false).readingLanguage;
    final verseText = (lang == 'english' && (verse.englishText?.isNotEmpty ?? false))
        ? verse.englishText!
        : verse.odiyaText;
    final text = '"$verseText" - ${verse.reference}';
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

  void _openChapterSelector(BuildContext context, BibleProvider bibleProvider) {
    final book = bibleProvider.currentBook;
    if (book == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.8,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
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
                  book.odiyaName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${book.name} • ${book.totalChapters} chapters',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.builder(
                    controller: scrollController,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: MediaQuery.of(context).size.width < 500 ? 4 : 6,
                      childAspectRatio: 1.2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: book.totalChapters,
                    itemBuilder: (context, index) {
                      final chapter = index + 1;
                      final isCurrentChapter = bibleProvider.currentChapter == chapter;

                      return Material(
                        color: isCurrentChapter
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        elevation: isCurrentChapter ? 4 : 1,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            Navigator.pop(context);
                            bibleProvider.loadChapter(book.id, chapter).then((_) {
                              if (mounted) {
                                final audioProvider = Provider.of<AudioStreamingProvider>(context, listen: false);
                                _loadChapterAudio(audioProvider, bibleProvider);
                              }
                            });
                          },
                          child: Center(
                            child: Text(
                              chapter.toString(),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isCurrentChapter
                                    ? Colors.white
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _VerseView extends StatefulWidget {
  const _VerseView({
    required this.verse,
    required this.fontSize,
    required this.onTapVerse,
    required this.readingLanguage,
    required this.currentPlayingVerse,
  });

  final Verse verse;
  final double fontSize;
  final void Function(Verse v) onTapVerse;
  final String readingLanguage;
  final int currentPlayingVerse;

  @override
  State<_VerseView> createState() => _VerseViewState();
}

class _VerseViewState extends State<_VerseView> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SelectableText.rich(
      TextSpan(
        children: [
          // Verse number as superscript red
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: GestureDetector(
              onTap: () => widget.onTapVerse(widget.verse),
              onLongPress: () => widget.onTapVerse(widget.verse),
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Transform.translate(
                  offset: const Offset(0, -4),
                  child: Text(
                    '${widget.verse.verseNumber}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: Colors.red,
                      fontSize: widget.fontSize * 0.75,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Verse text: use TextSpan on narrow/mobile screens to keep number and text inline
          ...(() {
            final isNarrow = MediaQuery.of(context).size.width < 600;
            final verseText = (() {
              final eng = widget.verse.englishText;
              final useEng = widget.readingLanguage == 'english' && (eng?.isNotEmpty ?? false);
              return (useEng ? eng! : widget.verse.odiyaText).trim();
            })();
            final highlightColor = widget.verse.isHighlighted
                ? const Color(0xFFFFF59D)
                : (widget.verse.verseNumber == widget.currentPlayingVerse
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                    : (_isHovered
                        ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.12)
                        : Colors.transparent));
            if (isNarrow) {
              return <InlineSpan>[
                TextSpan(
                  text: ' ' + verseText + ' ',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: widget.fontSize,
                    backgroundColor: highlightColor,
                  ),
                  recognizer: TapGestureRecognizer()..onTap = () => widget.onTapVerse(widget.verse),
                ),
              ];
            } else {
              return <InlineSpan>[
                WidgetSpan(
                  alignment: PlaceholderAlignment.baseline,
                  baseline: TextBaseline.alphabetic,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.text,
                    onEnter: (_) => setState(() => _isHovered = true),
                    onExit: (_) => setState(() => _isHovered = false),
                    child: GestureDetector(
                      onTap: () => widget.onTapVerse(widget.verse),
                      onLongPress: () => widget.onTapVerse(widget.verse),
                      child: Container(
                        decoration: BoxDecoration(
                          color: highlightColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 0),
                        margin: const EdgeInsets.only(right: 2),
                        child: Text(
                          ' ' + verseText + ' ',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontSize: widget.fontSize,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ];
            }
          })(),
        ],
      ),
      textAlign: TextAlign.start,
    );
  }
}

class _ParagraphView extends StatefulWidget {
  const _ParagraphView({
    required this.verses,
    required this.fontSize,
    required this.onTapVerse,
    required this.readingLanguage,
    required this.currentPlayingVerse,
  });

  final List<Verse> verses;
  final double fontSize;
  final void Function(Verse v) onTapVerse;
  final String readingLanguage;
  final int currentPlayingVerse;

  @override
  State<_ParagraphView> createState() => _ParagraphViewState();
}

class _ParagraphViewState extends State<_ParagraphView> {
  int? _hoveredIdx;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SelectableText.rich(
      TextSpan(
        children: [
          for (int i = 0; i < widget.verses.length; i++) ...[
            // Verse number as superscript red
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: GestureDetector(
                onTap: () => widget.onTapVerse(widget.verses[i]),
                onLongPress: () => widget.onTapVerse(widget.verses[i]),
                child: Padding(
                  padding: EdgeInsets.only(right: 4, left: i == 0 ? 0 : 6),
                  child: Transform.translate(
                    offset: const Offset(0, -4),
                    child: Text(
                      '${widget.verses[i].verseNumber}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: Colors.red,
                        fontSize: widget.fontSize * 0.75,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Verse text: use TextSpan on narrow/mobile screens to keep number and text inline
            ...(() {
              final isNarrow = MediaQuery.of(context).size.width < 600;
              final verseText = (() {
                final eng = widget.verses[i].englishText;
                final useEng = widget.readingLanguage == 'english' && (eng?.isNotEmpty ?? false);
                return (useEng ? eng! : widget.verses[i].odiyaText).trim();
              })();
              final highlightColor = widget.verses[i].isHighlighted
                  ? const Color(0xFFFFF59D)
                  : (widget.verses[i].verseNumber == widget.currentPlayingVerse
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                      : (_hoveredIdx == i
                          ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.12)
                          : Colors.transparent));
              if (isNarrow) {
                return <InlineSpan>[
                  TextSpan(
                    text: ' ' + verseText + ' ',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontSize: widget.fontSize,
                      backgroundColor: highlightColor,
                    ),
                    recognizer: TapGestureRecognizer()..onTap = () => widget.onTapVerse(widget.verses[i]),
                  ),
                ];
              } else {
                return <InlineSpan>[
                  WidgetSpan(
                    alignment: PlaceholderAlignment.baseline,
                    baseline: TextBaseline.alphabetic,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.text,
                      onEnter: (_) => setState(() => _hoveredIdx = i),
                      onExit: (_) => setState(() => _hoveredIdx = null),
                      child: GestureDetector(
                        onTap: () => widget.onTapVerse(widget.verses[i]),
                        onLongPress: () => widget.onTapVerse(widget.verses[i]),
                        child: Container(
                          decoration: BoxDecoration(
                            color: highlightColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 0),
                          margin: const EdgeInsets.only(right: 2),
                          child: Text(
                            ' ' + verseText + ' ',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontSize: widget.fontSize,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ];
              }
            })(),
          ]
        ],
      ),
      textAlign: TextAlign.start,
    );
  }
}