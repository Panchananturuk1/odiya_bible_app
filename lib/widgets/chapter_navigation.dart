import 'package:flutter/material.dart';

class ChapterNavigation extends StatelessWidget {
  final VoidCallback? onPreviousChapter;
  final VoidCallback? onNextChapter;
  final VoidCallback? onTapChapter;

  const ChapterNavigation({
    super.key,
    this.onPreviousChapter,
    this.onNextChapter,
    this.onTapChapter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: SizedBox(
        height: 36,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Previous chapter (compact)
            IconButton(
              tooltip: 'Previous chapter',
              onPressed: onPreviousChapter,
              icon: const Icon(Icons.chevron_left),
              iconSize: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              visualDensity: VisualDensity.compact,
            ),

            // Chapter selector (compact pill)
            Tooltip(
              message: 'Select chapter',
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onTapChapter,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Icon(
                    Icons.menu_book,
                    color: Theme.of(context).colorScheme.primary,
                    size: 16,
                  ),
                ),
              ),
            ),

            // Next chapter (compact)
            IconButton(
              tooltip: 'Next chapter',
              onPressed: onNextChapter,
              icon: const Icon(Icons.chevron_right),
              iconSize: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}