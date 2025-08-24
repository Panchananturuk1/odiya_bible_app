import 'package:flutter/material.dart';

class ChapterNavigation extends StatelessWidget {
  final VoidCallback? onPreviousChapter;
  final VoidCallback? onNextChapter;

  const ChapterNavigation({
    super.key,
    this.onPreviousChapter,
    this.onNextChapter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Previous chapter button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onPreviousChapter,
              icon: const Icon(Icons.chevron_left),
              label: const Text('Previous'),
              style: ElevatedButton.styleFrom(
                backgroundColor: onPreviousChapter != null 
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Colors.grey[300],
                foregroundColor: onPreviousChapter != null 
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : Colors.grey[600],
                elevation: onPreviousChapter != null ? 2 : 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Chapter indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              ),
            ),
            child: Icon(
              Icons.menu_book,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Next chapter button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onNextChapter,
              icon: const Icon(Icons.chevron_right),
              label: const Text('Next'),
              style: ElevatedButton.styleFrom(
                backgroundColor: onNextChapter != null 
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Colors.grey[300],
                foregroundColor: onNextChapter != null 
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : Colors.grey[600],
                elevation: onNextChapter != null ? 2 : 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}