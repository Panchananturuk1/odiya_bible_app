import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bible_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/auth_provider.dart';
import '../screens/auth_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<BibleProvider, SettingsProvider, AuthProvider>(
      builder: (context, bibleProvider, settingsProvider, auth, child) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (auth.syncStatus == SyncStatus.error && auth.errorMessage != null) {
            final messenger = ScaffoldMessenger.maybeOf(context);
            if (messenger != null) {
              messenger.showSnackBar(
                SnackBar(content: Text(auth.errorMessage!), backgroundColor: Colors.red),
              );
              auth.clearError();
            }
          }
        });

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
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.menu_book,
                            size: 36,
                            color: Colors.white,
                          ),
                          const Spacer(),
                          // Profile/Login action
                          InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () async {
                              Navigator.pop(context);
                              if (auth.isAuthenticated) {
                                // Show account sheet with sign out
                                await showModalBottomSheet(
                                  context: context,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                  ),
                                  builder: (sheetContext) {
                                    return SafeArea(
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            ListTile(
                                              leading: const CircleAvatar(child: Icon(Icons.person)),
                                              title: Text(auth.displayName ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold)),
                                              subtitle: Text(auth.email ?? ''),
                                            ),
                                            const SizedBox(height: 8),
                                            ListTile(
                                              leading: const Icon(Icons.sync),
                                              title: const Text('Sync now'),
                                              subtitle: Text(_syncSubtitle(auth.syncStatus)),
                                              onTap: () async {
                                                // Capture messenger before popping to avoid deactivated context
                                                final messenger = ScaffoldMessenger.maybeOf(sheetContext);
                                                Navigator.of(sheetContext).pop();
                                                await auth.triggerSync();
                                                messenger?.showSnackBar(const SnackBar(content: Text('Syncing data...')));
                                              },
                                              trailing: _syncTrailing(context, auth.syncStatus),
                                            ),
                                            const SizedBox(height: 8),
                                            ListTile(
                                              leading: const Icon(Icons.logout, color: Colors.red),
                                              title: const Text('Sign out'),
                                              onTap: () async {
                                                // Capture messenger before popping to avoid using a deactivated context
                                                final messenger = ScaffoldMessenger.maybeOf(sheetContext);
                                                // Close the bottom sheet using its own context
                                                Navigator.of(sheetContext).pop();
                                                await auth.signOut();
                                                messenger?.showSnackBar(const SnackBar(content: Text('Signed out')));
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              } else {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                                );
                              }
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (auth.isAuthenticated)
                                  const CircleAvatar(radius: 16, child: Icon(Icons.person, size: 18, color: Colors.white)),
                                if (!auth.isAuthenticated)
                                  const Icon(Icons.login, color: Colors.white),
                                const SizedBox(width: 8),
                                Text(
                                  auth.isAuthenticated ? (auth.displayName ?? 'Profile') : 'Sign in',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'ଓଡିଆ ବାଇବଲ',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Odiya Bible',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Sync status chip
                      if (auth.isAuthenticated)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: ActionChip(
                            avatar: _syncTrailing(context, auth.syncStatus),
                            label: Text(_syncChipText(auth.syncStatus)),
                            onPressed: auth.syncStatus == SyncStatus.syncing ? null : () => auth.triggerSync(),
                            backgroundColor: Colors.white.withOpacity(0.15),
                            labelStyle: const TextStyle(color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              
              // Navigation Items
              Expanded(
                child: ListTileTheme(
                  dense: true,
                  minLeadingWidth: 28,
                  horizontalTitleGap: 8,
                  minVerticalPadding: 4,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  style: ListTileStyle.list,
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      // Bible Books Section
                      _buildSectionHeader(context, 'Bible Books'),
                      
                      // Old Testament
                      ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                        childrenPadding: const EdgeInsets.only(left: 44, right: 8, bottom: 4),
                        leading: const Icon(Icons.book, size: 20),
                        title: const Text('Old Testament', style: TextStyle(fontSize: 14)),
                        subtitle: Text('${bibleProvider.oldTestamentBooks.length} books', style: const TextStyle(fontSize: 12)),
                        children: bibleProvider.oldTestamentBooks.map((book) {
                          return ListTile(
                            contentPadding: const EdgeInsets.only(left: 60, right: 12),
                            title: Text(
                              book.odiyaName,
                              style: const TextStyle(fontSize: 13),
                            ),
                            subtitle: Text(
                              '${book.name} • ${book.totalChapters} chapters',
                              style: const TextStyle(fontSize: 11),
                            ),
                            onTap: () {
                              if (context.mounted) {
                                Navigator.pop(context);
                                _showChapterSelector(context, book, bibleProvider);
                              }
                            },
                          );
                        }).toList(),
                      ),
                      
                      // New Testament
                      ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                        childrenPadding: const EdgeInsets.only(left: 44, right: 8, bottom: 4),
                        leading: const Icon(Icons.auto_stories, size: 20),
                        title: const Text('New Testament', style: TextStyle(fontSize: 14)),
                        subtitle: Text('${bibleProvider.newTestamentBooks.length} books', style: const TextStyle(fontSize: 12)),
                        children: bibleProvider.newTestamentBooks.map((book) {
                          return ListTile(
                            contentPadding: const EdgeInsets.only(left: 60, right: 12),
                            title: Text(
                              book.odiyaName,
                              style: const TextStyle(fontSize: 13),
                            ),
                            subtitle: Text(
                              '${book.name} • ${book.totalChapters} chapters',
                              style: const TextStyle(fontSize: 11),
                            ),
                            onTap: () {
                              if (context.mounted) {
                                Navigator.pop(context);
                                _showChapterSelector(context, book, bibleProvider);
                              }
                            },
                          );
                        }).toList(),
                      ),
                      
                      const Divider(),
                      
                      // Quick Actions
                      _buildSectionHeader(context, 'Quick Actions'),
                      
                      ListTile(
                        leading: const Icon(Icons.search),
                        title: const Text('Search Bible', style: TextStyle(fontSize: 14)),
                        onTap: () {
                          if (!context.mounted) return;
                          Navigator.pop(context);
                          DefaultTabController.of(context)?.animateTo(1);
                        },
                      ),
                      
                      ListTile(
                        leading: const Icon(Icons.bookmark),
                        title: const Text('My Bookmarks', style: TextStyle(fontSize: 14)),
                        subtitle: Text('${bibleProvider.bookmarks.length} saved', style: const TextStyle(fontSize: 12)),
                        onTap: () {
                          if (!context.mounted) return;
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
                          style: const TextStyle(fontSize: 14),
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
                          title: Text(bibleProvider.currentBook!.odiyaName, style: const TextStyle(fontSize: 14)),
                          subtitle: Text('Chapter ${bibleProvider.currentChapter}', style: const TextStyle(fontSize: 12)),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            if (!context.mounted) return;
                            Navigator.pop(context);
                            DefaultTabController.of(context)?.animateTo(0);
                          },
                        ),
                        
                        const Divider(),
                      ],
                      
                      // Settings
                      ListTile(
                        leading: const Icon(Icons.settings),
                        title: const Text('Settings', style: TextStyle(fontSize: 14)),
                        onTap: () {
                          if (!context.mounted) return;
                          Navigator.pop(context);
                          DefaultTabController.of(context)?.animateTo(3);
                        },
                      ),

                      // Auth section in list
                      const SizedBox(height: 6),
                      if (!auth.isAuthenticated)
                        ListTile(
                          leading: const Icon(Icons.login),
                          title: const Text('Sign in / Create account', style: TextStyle(fontSize: 14)),
                          onTap: () async {
                            if (!context.mounted) return;
                            Navigator.pop(context);
                            await Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const AuthScreen()),
                            );
                          },
                        ),
                      if (auth.isAuthenticated)
                        ListTile(
                          leading: const Icon(Icons.person),
                          title: Text(auth.displayName ?? 'Profile', style: const TextStyle(fontSize: 14)),
                          subtitle: Text(auth.email ?? '', style: const TextStyle(fontSize: 12)),
                          trailing: _syncTrailing(context, auth.syncStatus),
                          onTap: () async {
                            if (!context.mounted) return;
                            Navigator.pop(context);
                            await auth.triggerSync();
                          },
                        ),
                    ],
                  ),
                ),
              ),
              
              // Footer
              Container(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    const Divider(),
                    Text(
                      'Version 1.0.0',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Made with ❤️ for Odiya Bible readers',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      'Developed by MONU',
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

  static String _syncChipText(SyncStatus status) {
    switch (status) {
      case SyncStatus.syncing:
        return 'Syncing…';
      case SyncStatus.success:
        return 'Synced';
      case SyncStatus.error:
        return 'Sync failed';
      case SyncStatus.idle:
      default:
        return 'Sync idle';
    }
  }

  static String _syncSubtitle(SyncStatus status) {
    switch (status) {
      case SyncStatus.syncing:
        return 'In progress';
      case SyncStatus.success:
        return 'Last sync successful';
      case SyncStatus.error:
        return 'Last sync failed';
      case SyncStatus.idle:
      default:
        return 'Tap to sync';
    }
  }

  static Widget _syncTrailing(BuildContext context, SyncStatus status) {
    switch (status) {
      case SyncStatus.syncing:
        return const SizedBox(
          height: 18,
          width: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case SyncStatus.success:
        return const Icon(Icons.check_circle, color: Colors.green);
      case SyncStatus.error:
        return const Icon(Icons.error, color: Colors.red);
      case SyncStatus.idle:
      default:
        return const Icon(Icons.sync);
    }
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
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