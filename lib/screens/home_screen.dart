import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bible_provider.dart';
import '../providers/settings_provider.dart';
import 'testament_selection_screen.dart';
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

  List<Widget> get _screens => [
    TestamentSelectionScreen(
      onNavigateToReading: () {
        _onTabTapped(1); // Navigate to reading tab
      },
    ),
    const BibleReadingScreen(),
    const SearchScreen(),
    BookmarksScreen(
      onNavigateToReading: () {
        _onTabTapped(1); // Navigate to reading tab
      },
    ),
    const SettingsScreen(),
  ];

  final List<String> _titles = [
    'ଓଡିଆ ବାଇବଲ', // Odiya Bible
    'ଓଡିଆ ବାଇବଲ', // Odiya Bible (Read tab)
    'ଓଡିଆ ବାଇବଲ', // Odiya Bible (Search tab)
    'ଓଡିଆ ବାଇବଲ', // Odiya Bible (Bookmarks tab)
    'ଓଡିଆ ବାଇବଲ', // Odiya Bible (Settings tab)
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

  IconData _getScreenIcon(int index) {
    switch (index) {
      case 0:
        return Icons.home_rounded;
      case 1:
        return Icons.menu_book_rounded;
      case 2:
        return Icons.search_rounded;
      case 3:
        return Icons.bookmark_rounded;
      case 4:
        return Icons.settings_rounded;
      default:
        return Icons.home_rounded;
    }
  }

  String _getScreenSubtitle(int index) {
    switch (index) {
      case 0:
        return 'Welcome to Bible reading';
      case 1:
        return 'Read God\'s word';
      case 2:
        return 'Find verses and passages';
      case 3:
        return 'Your saved verses';
      case 4:
        return 'App preferences';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<BibleProvider, SettingsProvider>(
      builder: (context, bibleProvider, settingsProvider, child) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            toolbarHeight: 70,
            titleSpacing: 20,
            leadingWidth: 60,
            iconTheme: IconThemeData(
              size: 24,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            title: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getScreenIcon(_currentIndex),
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _titles[_currentIndex],
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          _getScreenSubtitle(_currentIndex),
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            elevation: 0,
            backgroundColor: Colors.transparent,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: settingsProvider.isDarkMode
                      ? [
                          const Color(0xFF1E1E2E).withOpacity(0.95),
                          const Color(0xFF2A2A3E).withOpacity(0.95),
                        ]
                      : [
                          const Color(0xFFFAFBFF).withOpacity(0.95),
                          const Color(0xFFF0F4FF).withOpacity(0.95),
                        ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            actions: [
              // Font size controls for reading screen
              if (_currentIndex == 1) ...
              [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.text_decrease_rounded),
                        onPressed: settingsProvider.decreaseFontSize,
                        tooltip: 'Decrease font size',
                        iconSize: 18,
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        visualDensity: VisualDensity.compact,
                      ),
                      Container(
                        width: 1,
                        height: 16,
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                      ),
                      IconButton(
                        icon: const Icon(Icons.text_increase_rounded),
                        onPressed: settingsProvider.increaseFontSize,
                        tooltip: 'Increase font size',
                        iconSize: 18,
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
              ],
              // Language toggle
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: Icon(
                    settingsProvider.readingLanguage == 'odiya'
                        ? Icons.translate_rounded
                        : Icons.translate_rounded,
                  ),
                  onPressed: () => settingsProvider.toggleReadingLanguage(),
                  tooltip: settingsProvider.readingLanguage == 'odiya'
                      ? 'Switch to English'
                      : 'Switch to Odiya',
                  iconSize: 20,
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              // Dark mode toggle
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: Icon(
                    settingsProvider.isDarkMode 
                        ? Icons.light_mode_rounded 
                        : Icons.dark_mode_rounded,
                  ),
                  onPressed: settingsProvider.toggleDarkMode,
                  tooltip: settingsProvider.isDarkMode 
                      ? 'Switch to light mode' 
                      : 'Switch to dark mode',
                  iconSize: 20,
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ],
          ),
          drawer: const AppDrawer(),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: settingsProvider.isDarkMode
                    ? [
                        const Color(0xFF181825),
                        const Color(0xFF1E1E2E),
                        const Color(0xFF2A2A3E),
                      ]
                    : [
                        const Color(0xFFF8F9FA),
                        const Color(0xFFFAFBFF),
                        const Color(0xFFF0F4FF),
                      ],
              ),
            ),
            child: SafeArea(
              child: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                children: _screens,
              ),
            ),
          ),
          bottomNavigationBar: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: settingsProvider.isDarkMode
                    ? [
                        const Color(0xFF2A2A3E).withOpacity(0.95),
                        const Color(0xFF1E1E2E).withOpacity(0.98),
                      ]
                    : [
                        const Color(0xFFFAFBFF).withOpacity(0.95),
                        const Color(0xFFFFFFFF).withOpacity(0.98),
                      ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: _currentIndex,
              onTap: _onTabTapped,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: Theme.of(context).colorScheme.primary,
              unselectedItemColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              selectedLabelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_rounded),
                  activeIcon: Icon(Icons.home),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.menu_book_rounded),
                  activeIcon: Icon(Icons.menu_book),
                  label: 'Read',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.search_rounded),
                  activeIcon: Icon(Icons.search),
                  label: 'Search',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.bookmark_border_rounded),
                  activeIcon: Icon(Icons.bookmark),
                  label: 'Bookmarks',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings_rounded),
                  activeIcon: Icon(Icons.settings),
                  label: 'Settings',
                ),
              ],
            ),
          ),
          floatingActionButton: _currentIndex == 1 
              ? AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: FloatingActionButton(
                    heroTag: "chapterSelector",
                    onPressed: () {
                      _showBookChapterSelector(context, bibleProvider);
                    },
                    tooltip: 'Go to chapter',
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    child: const Icon(
                      Icons.navigation_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
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