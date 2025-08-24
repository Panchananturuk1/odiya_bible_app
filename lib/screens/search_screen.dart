import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bible_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/verse_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _performSearch(String query) async {
    if (query.trim().isEmpty) {
      return;
    }

    setState(() {
      _isSearching = true;
    });

    final bibleProvider = Provider.of<BibleProvider>(context, listen: false);
    await bibleProvider.searchVerses(query.trim());

    setState(() {
      _isSearching = false;
    });
  }

  void _clearSearch() {
    _searchController.clear();
    final bibleProvider = Provider.of<BibleProvider>(context, listen: false);
    bibleProvider.clearSearchResults();
    _searchFocusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<BibleProvider, SettingsProvider>(
      builder: (context, bibleProvider, settingsProvider, child) {
        return Column(
          children: [
            // Search bar
            Container(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                decoration: InputDecoration(
                  hintText: 'Search Bible verses in Odiya...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: _clearSearch,
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                ),
                onSubmitted: _performSearch,
                onChanged: (value) {
                  setState(() {}); // Rebuild to show/hide clear button
                },
              ),
            ),
            
            // Search suggestions or recent searches
            if (_searchController.text.isEmpty && bibleProvider.searchResults.isEmpty)
              Expanded(
                child: _buildSearchSuggestions(),
              ),
            
            // Loading indicator
            if (_isSearching)
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Searching...'),
                    ],
                  ),
                ),
              ),
            
            // Search results
            if (!_isSearching && bibleProvider.searchResults.isNotEmpty)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '${bibleProvider.searchResults.length} results found',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: bibleProvider.searchResults.length,
                        itemBuilder: (context, index) {
                          final verse = bibleProvider.searchResults[index];
                          return VerseCard(
                            verse: verse,
                            fontSize: settingsProvider.fontSize,
                            onHighlight: () => bibleProvider.toggleHighlight(verse.id),
                            onBookmark: () => bibleProvider.toggleBookmark(verse),
                            onNote: (note) => bibleProvider.updateNote(verse.id, note),
                            onShare: () => _shareVerse(verse),
                            highlightSearchTerm: _searchController.text.trim(),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            
            // No results
            if (!_isSearching && 
                _searchController.text.isNotEmpty && 
                bibleProvider.searchResults.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No results found for "${_searchController.text}"',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Try different keywords or check spelling',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildSearchSuggestions() {
    final suggestions = [
      'ପ୍ରେମ', // Love
      'ଆଶା', // Hope
      'ବିଶ୍ୱାସ', // Faith
      'ଶାନ୍ତି', // Peace
      'ଆନନ୍ଦ', // Joy
      'କ୍ଷମା', // Forgiveness
      'ପ୍ରାର୍ଥନା', // Prayer
      'ଆଶୀର୍ବାଦ', // Blessing
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Search Suggestions',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions.map((suggestion) {
              return ActionChip(
                label: Text(suggestion),
                onPressed: () {
                  _searchController.text = suggestion;
                  _performSearch(suggestion);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          Text(
            'Search Tips',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildSearchTip(
            Icons.search,
            'Search in Odiya',
            'Type keywords in Odiya script for better results',
          ),
          _buildSearchTip(
            Icons.format_quote,
            'Exact phrases',
            'Use quotes for exact phrase matching',
          ),
          _buildSearchTip(
            Icons.book,
            'Book names',
            'Search by book name to find specific books',
          ),
        ],
      ),
    );
  }

  Widget _buildSearchTip(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _shareVerse(verse) {
    final text = '"${verse.odiyaText}" - ${verse.reference}';
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Share: $text'),
        action: SnackBarAction(
          label: 'Copy',
          onPressed: () {
            // TODO: Copy to clipboard
          },
        ),
      ),
    );
  }
}