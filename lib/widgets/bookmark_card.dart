import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BookmarkCard extends StatelessWidget {
  final dynamic bookmark;
  final double fontSize;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onShare;

  const BookmarkCard({
    super.key,
    required this.bookmark,
    required this.fontSize,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        onLongPress: () {
          HapticFeedback.mediumImpact();
          _showBookmarkOptions(context);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with reference and date
              Row(
                children: [
                  Expanded(
                    child: Text(
                      bookmark.reference,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  Text(
                    _formatDate(bookmark.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Verse text
              Text(
                bookmark.verseText,
                style: TextStyle(
                  fontSize: fontSize,
                  height: 1.5,
                  fontWeight: FontWeight.w400,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              
              // Note section
              if (bookmark.note?.isNotEmpty == true) ...
              [
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.blue[200]!,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.note,
                        size: 16,
                        color: Colors.blue[600],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          bookmark.note!,
                          style: TextStyle(
                            fontSize: fontSize - 2,
                            color: Colors.blue[800],
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              // Tags section
              if (bookmark.tags?.isNotEmpty == true) ...
              [
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: bookmark.tags!.map<Widget>((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              
              const SizedBox(height: 12),
              
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit, size: 18),
                    tooltip: 'Edit bookmark',
                    style: IconButton.styleFrom(
                      foregroundColor: Colors.orange[600],
                      minimumSize: const Size(40, 40),
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                  IconButton(
                    onPressed: onShare,
                    icon: const Icon(Icons.share, size: 18),
                    tooltip: 'Share bookmark',
                    style: IconButton.styleFrom(
                      foregroundColor: Colors.blue[600],
                      minimumSize: const Size(40, 40),
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete, size: 18),
                    tooltip: 'Delete bookmark',
                    style: IconButton.styleFrom(
                      foregroundColor: Colors.red[600],
                      minimumSize: const Size(40, 40),
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '${weeks}w ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '${months}mo ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '${years}y ago';
    }
  }

  void _showBookmarkOptions(BuildContext context) {
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
              bookmark.reference,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(
                Icons.open_in_new,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('Go to Verse'),
              onTap: () {
                Navigator.pop(context);
                onTap();
              },
            ),
            ListTile(
              leading: Icon(
                Icons.edit,
                color: Colors.orange[600],
              ),
              title: const Text('Edit Bookmark'),
              onTap: () {
                Navigator.pop(context);
                onEdit();
              },
            ),
            ListTile(
              leading: Icon(
                Icons.share,
                color: Colors.blue[600],
              ),
              title: const Text('Share Bookmark'),
              onTap: () {
                Navigator.pop(context);
                onShare();
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
                _copyToClipboard(context);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.delete,
                color: Colors.red[600],
              ),
              title: const Text('Delete Bookmark'),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context) {
    String text = '"${bookmark.verseText}" - ${bookmark.reference}';
    
    if (bookmark.note?.isNotEmpty == true) {
      text += '\n\nNote: ${bookmark.note}';
    }
    
    Clipboard.setData(ClipboardData(text: text));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bookmark copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bookmark'),
        content: Text(
          'Are you sure you want to delete this bookmark?\n\n${bookmark.reference}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete();
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
}