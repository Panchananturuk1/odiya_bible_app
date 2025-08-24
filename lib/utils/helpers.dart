import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../models/verse.dart';
import '../models/bookmark.dart';
import 'constants.dart';

class AppHelpers {
  // Text highlighting helper
  static List<TextSpan> highlightSearchTerms(
    String text,
    String searchTerm, {
    TextStyle? defaultStyle,
    TextStyle? highlightStyle,
  }) {
    if (searchTerm.isEmpty) {
      return [TextSpan(text: text, style: defaultStyle)];
    }

    final List<TextSpan> spans = [];
    final String lowerText = text.toLowerCase();
    final String lowerSearchTerm = searchTerm.toLowerCase();
    
    int start = 0;
    int index = lowerText.indexOf(lowerSearchTerm);
    
    while (index != -1) {
      // Add text before the match
      if (index > start) {
        spans.add(TextSpan(
          text: text.substring(start, index),
          style: defaultStyle,
        ));
      }
      
      // Add highlighted match
      spans.add(TextSpan(
        text: text.substring(index, index + searchTerm.length),
        style: highlightStyle ?? TextStyle(
          backgroundColor: Colors.yellow.withOpacity(0.3),
          fontWeight: FontWeight.bold,
        ),
      ));
      
      start = index + searchTerm.length;
      index = lowerText.indexOf(lowerSearchTerm, start);
    }
    
    // Add remaining text
    if (start < text.length) {
      spans.add(TextSpan(
        text: text.substring(start),
        style: defaultStyle,
      ));
    }
    
    return spans;
  }

  // Share verse helper
  static Future<void> shareVerse(Verse verse, {String? additionalText}) async {
    try {
      final String shareText = _formatVerseForSharing(verse, additionalText);
      await Share.share(shareText);
    } catch (e) {
      debugPrint('Error sharing verse: $e');
    }
  }

  // Share multiple verses
  static Future<void> shareVerses(List<Verse> verses, {String? additionalText}) async {
    try {
      final String shareText = _formatVersesForSharing(verses, additionalText);
      await Share.share(shareText);
    } catch (e) {
      debugPrint('Error sharing verses: $e');
    }
  }

  // Share bookmark
  static Future<void> shareBookmark(Bookmark bookmark) async {
    try {
      final String shareText = _formatBookmarkForSharing(bookmark);
      await Share.share(shareText);
    } catch (e) {
      debugPrint('Error sharing bookmark: $e');
    }
  }

  // Copy to clipboard
  static Future<void> copyToClipboard(String text, {String? successMessage}) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      // You can show a snackbar here if context is available
    } catch (e) {
      debugPrint('Error copying to clipboard: $e');
    }
  }

  // Format verse reference
  static String formatVerseReference(String bookName, int chapter, int verseNumber) {
    return '$bookName $chapter:$verseNumber';
  }

  // Format chapter reference
  static String formatChapterReference(String bookName, int chapter) {
    return '$bookName $chapter';
  }

  // Format date for display
  static String formatDate(DateTime date) {
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
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  // Validate search query
  static bool isValidSearchQuery(String query) {
    return query.trim().length >= AppConstants.minSearchLength;
  }

  // Clean search query
  static String cleanSearchQuery(String query) {
    return query.trim().toLowerCase();
  }

  // Generate verse ID
  static String generateVerseId(int bookId, int chapter, int verseNumber) {
    return '${bookId}_${chapter}_$verseNumber';
  }

  // Parse verse reference (e.g., "John 3:16")
  static Map<String, int>? parseVerseReference(String reference) {
    try {
      final RegExp regex = RegExp(r'^([\w\s]+)\s+(\d+):(\d+)$');
      final Match? match = regex.firstMatch(reference.trim());
      
      if (match != null) {
        return {
          'chapter': int.parse(match.group(2)!),
          'verse': int.parse(match.group(3)!),
        };
      }
    } catch (e) {
      debugPrint('Error parsing verse reference: $e');
    }
    return null;
  }

  // Show snackbar helper
  static void showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Show confirmation dialog
  static Future<bool> showConfirmationDialog(
    BuildContext context,
    String title,
    String message, {
    String confirmText = 'Yes',
    String cancelText = 'No',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // Private helper methods
  static String _formatVerseForSharing(Verse verse, String? additionalText) {
    final buffer = StringBuffer();
    buffer.writeln('"${verse.odiyaText}"');
    buffer.writeln();
    buffer.writeln('- ${verse.reference}');
    
    if (verse.englishText != null && verse.englishText!.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('English: "${verse.englishText}"');
    }
    
    if (additionalText != null && additionalText.isNotEmpty) {
      buffer.writeln();
      buffer.writeln(additionalText);
    }
    
    buffer.writeln();
    buffer.writeln('Shared from ${AppConstants.appName}');
    
    return buffer.toString();
  }

  static String _formatVersesForSharing(List<Verse> verses, String? additionalText) {
    if (verses.isEmpty) return '';
    
    final buffer = StringBuffer();
    
    for (int i = 0; i < verses.length; i++) {
      final verse = verses[i];
      buffer.writeln('${verse.verseNumber}. ${verse.odiyaText}');
      if (i < verses.length - 1) buffer.writeln();
    }
    
    buffer.writeln();
    buffer.writeln('- ${verses.first.reference.split(':')[0]} ${verses.first.chapter}');
    
    if (additionalText != null && additionalText.isNotEmpty) {
      buffer.writeln();
      buffer.writeln(additionalText);
    }
    
    buffer.writeln();
    buffer.writeln('Shared from ${AppConstants.appName}');
    
    return buffer.toString();
  }

  static String _formatBookmarkForSharing(Bookmark bookmark) {
    final buffer = StringBuffer();
    buffer.writeln('"${bookmark.verseText}"');
    buffer.writeln();
    buffer.writeln('- ${bookmark.reference}');
    
    if (bookmark.note != null && bookmark.note!.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Note: ${bookmark.note}');
    }
    
    if (bookmark.tags != null && bookmark.tags!.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Tags: ${bookmark.tags}');
    }
    
    buffer.writeln();
    buffer.writeln('Shared from ${AppConstants.appName}');
    
    return buffer.toString();
  }
}