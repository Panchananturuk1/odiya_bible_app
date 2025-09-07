import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bible_provider.dart';
import 'bible_reading_screen.dart';
import 'auth_screen.dart';
class TestamentSelectionScreen extends StatelessWidget {
  final VoidCallback? onNavigateToReading;
  
  const TestamentSelectionScreen({super.key, this.onNavigateToReading});

  @override
  Widget build(BuildContext context) {
    return Consumer<BibleProvider>(builder: (context, bibleProvider, child) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Welcome text
            Text(
              'ଓଡିଆ ବାଇବଲ',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose Testament to Begin Reading',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 12),
            // Bible Version Information
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                'Indian Revised Version (IRV)',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // Testament Cards
            Row(
              children: [
                // Old Testament Card
                Expanded(
                  child: _buildTestamentCard(
                    context,
                    title: 'Old Testament',
                    odiyaTitle: 'ପୁରାତନ ନିୟମ',
                    description: '39 Books',
                    icon: _buildOldTestamentIcon(),
                    onTap: () => _navigateToFirstChapter(context, bibleProvider, 1),
                  ),
                ),
                const SizedBox(width: 16),
                // New Testament Card
                Expanded(
                  child: _buildTestamentCard(
                    context,
                    title: 'New Testament',
                    odiyaTitle: 'ନୂତନ ନିୟମ',
                    description: '27 Books',
                    icon: _buildNewTestamentIcon(),
                    onTap: () => _navigateToFirstChapter(context, bibleProvider, 2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            
            // Login and Signup Buttons
            Row(
              children: [
                // Login Button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AuthScreen(isSignUp: false),
                        ),
                      );
                    },
                    icon: const Icon(Icons.login),
                    label: const Text('Login'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Signup Button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AuthScreen(isSignUp: true),
                        ),
                      );
                    },
                    icon: const Icon(Icons.person_add),
                    label: const Text('Sign Up'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildTestamentCard(
    BuildContext context, {
    required String title,
    required String odiyaTitle,
    required String description,
    required Widget icon,
    required VoidCallback onTap,
  }) {
    final isOldTestament = title == 'Old Testament';
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isOldTestament
              ? [
                  const Color(0xFF8B5A3C).withOpacity(0.8),
                  const Color(0xFFA0522D).withOpacity(0.9),
                ]
              : [
                  const Color(0xFF4A90E2).withOpacity(0.8),
                  const Color(0xFF7B68EE).withOpacity(0.9),
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: (isOldTestament 
                ? const Color(0xFF8B5A3C) 
                : const Color(0xFF4A90E2)).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            constraints: const BoxConstraints(minHeight: 200),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon with enhanced styling
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(35),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Transform.scale(
                    scale: 0.8,
                    child: icon,
                  ),
                ),
                const SizedBox(height: 16),
                // Odiya Title with white color
                Text(
                  odiyaTitle,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                // English Title
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // Description with enhanced styling
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    description,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOldTestamentIcon() {
    return Icon(
      Icons.menu_book,
      size: 40,
      color: Colors.brown.shade700,
    );
  }

  Widget _buildNewTestamentIcon() {
    return Icon(
      Icons.auto_stories,
      size: 40,
      color: Colors.blue.shade700,
    );
  }

  void _navigateToFirstChapter(BuildContext context, BibleProvider bibleProvider, int testament) async {
    // Show book and chapter selector for the selected testament
    _showTestamentBookSelector(context, bibleProvider, testament);
  }

  void _showTestamentBookSelector(BuildContext context, BibleProvider bibleProvider, int testament) {
    final books = testament == 1 
        ? bibleProvider.oldTestamentBooks 
        : bibleProvider.newTestamentBooks;
    final testamentName = testament == 1 ? 'Old Testament' : 'New Testament';
    final testamentOdiyaName = testament == 1 ? 'ପୁରାତନ ନିୟମ' : 'ନୂତନ ନିୟମ';

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
                  testamentOdiyaName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$testamentName • ${books.length} books',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _buildBooksList(books, bibleProvider),
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
              onTap: () async {
                Navigator.pop(context);
                try {
                  await bibleProvider.selectBook(book.id);
                  await bibleProvider.loadChapter(book.id, chapterIndex + 1);
                  
                  // Switch to the Bible reading tab
                  if (context.mounted && onNavigateToReading != null) {
                    onNavigateToReading!();
                  }
                } catch (e) {
                  debugPrint('Error navigating to chapter: $e');
                }
              },
            ),
          ),
        );
      },
    );
  }
}