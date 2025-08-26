import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';

class VerseCard extends StatefulWidget {
  final dynamic verse;
  final double fontSize;
  final VoidCallback onHighlight;
  final VoidCallback onBookmark;
  // Update the onNote callback type to accept nullable String
  final void Function(String?)? onNote;
  final VoidCallback onShare;
  final String? highlightSearchTerm;
  final VoidCallback? onAudioPlay;

  const VerseCard({
    super.key,
    required this.verse,
    required this.fontSize,
    required this.onHighlight,
    required this.onBookmark,
    required this.onNote,
    required this.onShare,
    this.highlightSearchTerm,
    this.onAudioPlay,
  });

  @override
  State<VerseCard> createState() => _VerseCardState();
}

class _VerseCardState extends State<VerseCard>
    with SingleTickerProviderStateMixin {
  bool _showActions = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleActions() {
    setState(() {
      _showActions = !_showActions;
    });
    if (_showActions) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: widget.verse.isHighlighted
            ? Theme.of(context)
                .colorScheme
                .primaryContainer
                .withOpacity(0.2)
            : Colors.transparent,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _toggleActions,
          onLongPress: () {
            HapticFeedback.mediumImpact();
            _showVerseOptions();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Verse text with superscript verse number
                _buildVerseText(),

                // Note display (unchanged)
                if (widget.verse.note?.isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.orange[200]!,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.note,
                          size: 16,
                          color: Colors.orange[600],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.verse.note!,
                            style: TextStyle(
                              fontSize: widget.fontSize - 2,
                              color: Colors.orange[800],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Action buttons (unchanged)
                if (_showActions)
                  AnimatedBuilder(
                    animation: _scaleAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Container(
                          margin: const EdgeInsets.only(top: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildActionButton(
                                icon: widget.verse.isHighlighted
                                    ? Icons.highlight_off
                                    : Icons.highlight,
                                label: widget.verse.isHighlighted
                                    ? 'Remove'
                                    : 'Highlight',
                                onPressed: widget.onHighlight,
                                color: widget.verse.isHighlighted
                                    ? Colors.grey
                                    : Colors.yellow[700],
                              ),
                              _buildActionButton(
                                icon: widget.verse.isBookmarked
                                    ? Icons.bookmark
                                    : Icons.bookmark_border,
                                label: widget.verse.isBookmarked
                                    ? 'Saved'
                                    : 'Bookmark',
                                onPressed: widget.onBookmark,
                                color: widget.verse.isBookmarked
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey,
                              ),
                              _buildActionButton(
                                icon: Icons.note_add,
                                label: 'Note',
                                onPressed: _showNoteDialog,
                                color: Colors.orange[600],
                              ),
                              _buildActionButton(
                                icon: Icons.share,
                                label: 'Share',
                                onPressed: widget.onShare,
                                color: Colors.blue[600],
                              ),
                              _buildAudioButton(),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVerseText() {
    final text = widget.verse.odiyaText;

    // Build the superscript verse number as a WidgetSpan
    final numberSpan = WidgetSpan(
      child: Transform.translate(
        offset: const Offset(0, -6),
        child: Text(
          widget.verse.verseNumber.toString(),
          style: TextStyle(
            fontSize: widget.fontSize * 0.7,
            color: Colors.red[700],
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );

    if (widget.highlightSearchTerm?.isNotEmpty == true) {
      return _buildHighlightedText(text, widget.highlightSearchTerm!);
    }

    return Text.rich(
      TextSpan(
        children: [
          numberSpan,
          const TextSpan(text: ' '),
          TextSpan(
            text: text,
            style: TextStyle(
              fontSize: widget.fontSize,
              height: 1.6,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
      textAlign: TextAlign.start,
    );
  }

  Widget _buildHighlightedText(String text, String searchTerm) {
    final spans = <TextSpan>[];
    final lowerText = text.toLowerCase();
    final lowerSearchTerm = searchTerm.toLowerCase();

    int start = 0;
    int index = lowerText.indexOf(lowerSearchTerm);

    while (index != -1) {
      // Add text before the match
      if (index > start) {
        spans.add(TextSpan(
          text: text.substring(start, index),
          style: TextStyle(
            fontSize: widget.fontSize,
            height: 1.6,
            fontWeight: FontWeight.w400,
          ),
        ));
      }

      // Add highlighted match
      spans.add(TextSpan(
        text: text.substring(index, index + searchTerm.length),
        style: TextStyle(
          fontSize: widget.fontSize,
          height: 1.6,
          fontWeight: FontWeight.bold,
          backgroundColor: Colors.yellow[300],
          color: Colors.black,
        ),
      ));

      start = index + searchTerm.length;
      index = lowerText.indexOf(lowerSearchTerm, start);
    }

    // Add remaining text
    if (start < text.length) {
      spans.add(TextSpan(
        text: text.substring(start),
        style: TextStyle(
          fontSize: widget.fontSize,
          height: 1.6,
          fontWeight: FontWeight.w400,
        ),
      ));
    }

    // Prepend superscript verse number to the highlighted text
    final numberSpan = WidgetSpan(
      child: Transform.translate(
        offset: const Offset(0, -6),
        child: Text(
          widget.verse.verseNumber.toString(),
          style: TextStyle(
            fontSize: widget.fontSize * 0.7,
            color: Colors.red[700],
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );

    return RichText(
      text: TextSpan(children: [numberSpan, const TextSpan(text: ' '), ...spans]),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color? color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onPressed,
          icon: Icon(icon, color: color),
          style: IconButton.styleFrom(
            backgroundColor: color?.withOpacity(0.1),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _showVerseOptions() {
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
              widget.verse.reference,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(
                widget.verse.isHighlighted ? Icons.highlight_off : Icons.highlight,
                color: Colors.yellow[700],
              ),
              title: Text(
                widget.verse.isHighlighted ? 'Remove Highlight' : 'Highlight Verse',
              ),
              onTap: () {
                Navigator.pop(context);
                widget.onHighlight();
              },
            ),
            ListTile(
              leading: Icon(
                widget.verse.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(
                widget.verse.isBookmarked ? 'Remove Bookmark' : 'Add Bookmark',
              ),
              onTap: () {
                Navigator.pop(context);
                widget.onBookmark();
              },
            ),
            ListTile(
              leading: Icon(
                Icons.note_add,
                color: Colors.orange[600],
              ),
              title: const Text('Add/Edit Note'),
              onTap: () {
                Navigator.pop(context);
                _showNoteDialog();
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
                widget.onShare();
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
                _copyToClipboard();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showNoteDialog() {
    final noteController = TextEditingController(text: widget.verse.note ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Note for ${widget.verse.reference}'),
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
            onPressed: () {
              Navigator.pop(context);
              widget.onNote?.call(noteController.text.isEmpty ? null : noteController.text);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard() {
    final text = '"${widget.verse.odiyaText}" - ${widget.verse.reference}';
    Clipboard.setData(ClipboardData(text: text));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Verse copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildAudioButton() {
    return Consumer<AudioProvider>(
      builder: (context, audioProvider, child) {
        final isCurrentVerse = audioProvider.currentVerse?.id == widget.verse.id;
        final isPlaying = audioProvider.isPlaying && isCurrentVerse;
        
        return _buildActionButton(
          icon: isPlaying ? Icons.pause : Icons.play_arrow,
          label: isPlaying ? 'Pause' : 'Play',
          onPressed: () {
            if (isCurrentVerse && audioProvider.isPlaying) {
              audioProvider.pause();
            } else if (widget.onAudioPlay != null) {
              widget.onAudioPlay!();
            }
          },
          color: isCurrentVerse ? Colors.blue[600] : Colors.grey[600],
        );
      },
    );
  }
}