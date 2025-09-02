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
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          constraints: const BoxConstraints(minHeight: 180),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Transform.scale(
                  scale: 0.75,
                  child: icon,
                ),
              ),
              const SizedBox(height: 12),
              // Odiya Title
              Text(
                odiyaTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // English Title
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              // Description
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
                textAlign: TextAlign.center,
              ),
            ],
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
    // Get the first book of the selected testament
    final books = testament == 1 
        ? bibleProvider.oldTestamentBooks 
        : bibleProvider.newTestamentBooks;
    
    if (books.isNotEmpty) {
      final firstBook = books.first;
      
      // Navigate to the first chapter of the first book
      await bibleProvider.selectBook(firstBook.id);
      await bibleProvider.loadChapter(firstBook.id, 1);
      
      // Switch to the Bible reading tab
      if (context.mounted && onNavigateToReading != null) {
        onNavigateToReading!();
      }
    }
  }
}