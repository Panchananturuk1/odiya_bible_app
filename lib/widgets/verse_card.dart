import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../providers/settings_provider.dart';

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

class _VerseCardState extends State<VerseCard> {
  @override
  void initState() {
    super.initState();
  }

  void _toggleActions() {
    // Show bottom sheet instead of inline actions
    _showVerseOptions();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: widget.verse.isHighlighted
            ? const Color(0xFFFFF59D)
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
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
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

                // Action buttons removed - now shown in bottom sheet
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVerseText() {
    final settings = Provider.of<SettingsProvider>(context);
    final lang = settings.readingLanguage;
    final eng = widget.verse.englishText as String?;
    final text = (lang == 'english' && (eng?.isNotEmpty ?? false))
        ? eng!
        : widget.verse.odiyaText;

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



  void _showVerseOptions() {
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
                widget.verse.reference,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                dense: true,
                visualDensity: VisualDensity.compact,
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
                dense: true,
                visualDensity: VisualDensity.compact,
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
                dense: true,
                visualDensity: VisualDensity.compact,
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
                dense: true,
                visualDensity: VisualDensity.compact,
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
                dense: true,
                visualDensity: VisualDensity.compact,
                leading: Icon(
                  Icons.content_copy,
                  color: Colors.green[600],
                ),
                title: const Text('Copy'),
                onTap: () {
                  Navigator.pop(context);
                  _copyToClipboard();
                },
              ),
              if (widget.onAudioPlay != null)
                Consumer<AudioProvider>(
                  builder: (context, audioProvider, child) {
                    final isCurrentVerse = audioProvider.currentVerse?.id == widget.verse.id;
                    final isPlaying = audioProvider.isPlaying && isCurrentVerse;
                    
                    return ListTile(
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      leading: Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        color: isCurrentVerse ? Colors.blue[600] : Colors.grey[600],
                      ),
                      title: Text(isPlaying ? 'Pause Audio' : 'Play Audio'),
                      onTap: () {
                        Navigator.pop(context);
                        if (isCurrentVerse && audioProvider.isPlaying) {
                          audioProvider.pause();
                        } else if (widget.onAudioPlay != null) {
                          widget.onAudioPlay!();
                        }
                      },
                    );
                  },
                ),
            ],
          ),
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
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final lang = settings.readingLanguage;
    final eng = widget.verse.englishText as String?;
    final verseText = (lang == 'english' && (eng?.isNotEmpty ?? false)) ? eng! : widget.verse.odiyaText;
    final text = '"$verseText" - ${widget.verse.reference}';
    Clipboard.setData(ClipboardData(text: text));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Verse copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }


}