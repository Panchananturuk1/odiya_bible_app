import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bible_provider.dart';
import '../providers/settings_provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<BibleProvider, SettingsProvider>(
      builder: (context, bibleProvider, settingsProvider, child) {
        return Drawer(
          child: Column(
            children: [
              // Drawer Header
              DrawerHeader(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary.withOpacity(0.8),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.menu_book,
                      size: 48,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'ଓଡିଆ ବାଇବଲ',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Odiya Bible',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Navigation Items
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    // Bible Books Section
                    _buildSectionHeader(context, 'Bible Books'),
                    
                    // Old Testament
                    ExpansionTile(
                      leading: const Icon(Icons.book),
                      title: const Text('Old Testament'),
                      subtitle: Text('${bibleProvider.oldTestamentBooks.length} books'),
                      children: bibleProvider.oldTestamentBooks.map((book) {
                        return ListTile(
                          contentPadding: const EdgeInsets.only(left: 72, right: 16),
                          title: Text(
                            book.odiyaName,
                            style: const TextStyle(fontSize: 14),
                          ),
                          subtitle: Text(
                            '${book.name} • ${book.totalChapters} chapters',
                            style: const TextStyle(fontSize: 12),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            _showChapterSelector(context, book, bibleProvider);
                          },
                        );
                      }).toList(),
                    ),
                    
                    // New Testament
                    ExpansionTile(
                      leading: const Icon(Icons.auto_stories),
                      title: const Text('New Testament'),
                      subtitle: Text('${bibleProvider.newTestamentBooks.length} books'),
                      children: bibleProvider.newTestamentBooks.map((book) {
                        return ListTile(
                          contentPadding: const EdgeInsets.only(left: 72, right: 16),
                          title: Text(
                            book.odiyaName,
                            style: const TextStyle(fontSize: 14),
                          ),
                          subtitle: Text(
                            '${book.name} • ${book.totalChapters} chapters',
                            style: const TextStyle(fontSize: 12),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            _showChapterSelector(context, book, bibleProvider);
                          },
                        );
                      }).toList(),
                    ),
                    
                    const Divider(),
                    
                    // Quick Actions
                    _buildSectionHeader(context, 'Quick Actions'),
                    
                    ListTile(
                      leading: const Icon(Icons.search),
                      title: const Text('Search Bible'),
                      onTap: () {
                        Navigator.pop(context);
                        DefaultTabController.of(context)?.animateTo(1);
                      },
                    ),
                    
                    ListTile(
                      leading: const Icon(Icons.bookmark),
                      title: const Text('My Bookmarks'),
                      subtitle: Text('${bibleProvider.bookmarks.length} saved'),
                      onTap: () {
                        Navigator.pop(context);
                        DefaultTabController.of(context)?.animateTo(2);
                      },
                    ),
                    
                    ListTile(
                      leading: Icon(
                        settingsProvider.isDarkMode 
                            ? Icons.light_mode 
                            : Icons.dark_mode,
                      ),
                      title: Text(
                        settingsProvider.isDarkMode 
                            ? 'Light Mode' 
                            : 'Dark Mode',
                      ),
                      onTap: () {
                        settingsProvider.toggleDarkMode();
                      },
                    ),
                    
                    const Divider(),
                    
                    // Reading Progress
                    if (bibleProvider.currentBook != null) ...
                    [
                      _buildSectionHeader(context, 'Current Reading'),
                      
                      ListTile(
                        leading: const Icon(Icons.bookmark_border),
                        title: Text(bibleProvider.currentBook!.odiyaName),
                        subtitle: Text('Chapter ${bibleProvider.currentChapter}'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.pop(context);
                          DefaultTabController.of(context)?.animateTo(0);
                        },
                      ),
                      
                      const Divider(),
                    ],
                    
                    // Settings
                    ListTile(
                      leading: const Icon(Icons.settings),
                      title: const Text('Settings'),
                      onTap: () {
                        Navigator.pop(context);
                        DefaultTabController.of(context)?.animateTo(3);
                      },
                    ),
                  ],
                ),
              ),
              
              // Footer
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Divider(),
                    Text(
                      'Version 1.0.0',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Made with ❤️ for Odiya Bible readers',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  void _showChapterSelector(BuildContext context, dynamic book, BibleProvider bibleProvider) {
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
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      childAspectRatio: 1.2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: book.totalChapters,
                    itemBuilder: (context, index) {
                      final chapter = index + 1;
                      final isCurrentChapter = bibleProvider.currentBook?.id == book.id &&
                          bibleProvider.currentChapter == chapter;
                      
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
                            bibleProvider.selectBook(book.id);
                            bibleProvider.loadChapter(book.id, chapter);
                            DefaultTabController.of(context)?.animateTo(0);
                          },
                          child: Center(
                            child: Text(
                              chapter.toString(),
                              style: TextStyle(
                                fontSize: 16,
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