import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'lib/providers/bible_provider.dart';
import 'lib/providers/audio_streaming_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Create providers
  final bibleProvider = BibleProvider();
  final audioProvider = AudioStreamingProvider();
  
  // Initialize
  await bibleProvider.initialize();
  
  // Navigate to Mark (New Testament book)
  // Mark is typically book ID 41 in most Bible numbering systems
  print('Navigating to Mark chapter 1...');
  await bibleProvider.selectBook(41); // Mark
  await bibleProvider.loadChapter(41, 1);
  
  print('Current book: ${bibleProvider.currentBook?.name}');
  print('Current chapter: ${bibleProvider.currentChapter}');
  
  // Load audio for Mark 1
  print('Loading audio for Mark 1...');
  await audioProvider.loadChapterAudio('41', 1, bibleProvider.currentChapterVerses);
  
  print('Test completed');
}