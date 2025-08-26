import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bible_provider.dart';
import '../providers/settings_provider.dart';
import 'bible_reading_screen.dart';
import 'search_screen.dart';
import 'bookmarks_screen.dart';
import 'settings_screen.dart';
import '../widgets/app_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  final List<Widget> _screens = [
    const BibleReadingScreen(),
    const SearchScreen(),
    const BookmarksScreen(),
    const SettingsScreen(),
  ];

  final List<String> _titles = [
    'ଓଡିଆ ବାଇବଲ', // Odiya Bible
    'ଖୋଜନ୍ତୁ', // Search
    'ବୁକମାର୍କ', // Bookmarks
    'ସେଟିଂସ', // Settings
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<BibleProvider, SettingsProvider>(
      builder: (context, bibleProvider, settingsProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              _titles[_currentIndex],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            elevation: 2,
            actions: [
              // Font size controls
              if (_currentIndex == 0) ...
              [
                IconButton(
                  icon: const Icon(Icons.text_decrease),
                  onPressed: settingsProvider.decreaseFontSize,
                  tooltip: 'Decrease font size',
                ),
                IconButton(
                  icon: const Icon(Icons.text_increase),
                  onPressed: settingsProvider.increaseFontSize,
                  tooltip: 'Increase font size',
                ),
              ],
              // Language toggle (Odiya/English)
              IconButton(
                icon: Icon(
                  settingsProvider.readingLanguage == 'odiya'
                      ? Icons.translate
                      : Icons.translate,
                ),
                onPressed: () => settingsProvider.toggleReadingLanguage(),
                tooltip: settingsProvider.readingLanguage == 'odiya'
                    ? 'Switch to English'
                    : 'Switch to Odiya',
              ),
              // Dark mode toggle
              IconButton(
                icon: Icon(
                  settingsProvider.isDarkMode 
                      ? Icons.light_mode 
                      : Icons.dark_mode,
                ),
                onPressed: settingsProvider.toggleDarkMode,
                tooltip: settingsProvider.isDarkMode 
                    ? 'Switch to light mode' 
                    : 'Switch to dark mode',
              ),
            ],
          ),
          drawer: const AppDrawer(),
          body: PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            children: _screens,
          ),
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _currentIndex,
            onTap: _onTabTapped,
            selectedItemColor: Theme.of(context).colorScheme.primary,
            unselectedItemColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.menu_book),
                label: 'Bible',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.search),
                label: 'Search',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.bookmark),
                label: 'Bookmarks',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
          floatingActionButton: _currentIndex == 0 
              ? FloatingActionButton(
                  onPressed: () {
                    _showBookChapterSelector(context, bibleProvider);
                  },
                  tooltip: 'Go to chapter',
                  child: const Icon(Icons.navigation),
                )
              : null,
        );
      },
    );
  }

  void _showBookChapterSelector(BuildContext context, BibleProvider bibleProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
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
                  'Select Book & Chapter',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        const TabBar(
                          tabs: [
                            Tab(text: 'Old Testament'),
                            Tab(text: 'New Testament'),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              _buildBooksList(bibleProvider.oldTestamentBooks, bibleProvider),
                              _buildBooksList(bibleProvider.newTestamentBooks, bibleProvider),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBooksList(List books, BibleProvider bibleProvider) {
    return ListView.builder(
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        return ExpansionTile(
          title: Text(
            '${book.odiyaName} (${book.name})',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          children: List.generate(
            book.totalChapters,
            (chapterIndex) => ListTile(
              title: Text('Chapter ${chapterIndex + 1}'),
              onTap: () {
                Navigator.pop(context);
                bibleProvider.selectBook(book.id);
                bibleProvider.loadChapter(book.id, chapterIndex + 1);
              },
            ),
          ),
        );
      },
    );
  }
}