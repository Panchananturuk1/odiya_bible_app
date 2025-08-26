import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:xml/xml.dart';

class USXParser {
  static const Map<String, String> _usxToEnglishBookMap = {
    'GEN': 'Genesis',
    'EXO': 'Exodus',
    'LEV': 'Leviticus',
    'NUM': 'Numbers',
    'DEU': 'Deuteronomy',
    'JOS': 'Joshua',
    'JDG': 'Judges',
    'RUT': 'Ruth',
    '1SA': '1 Samuel',
    '2SA': '2 Samuel',
    '1KI': '1 Kings',
    '2KI': '2 Kings',
    '1CH': '1 Chronicles',
    '2CH': '2 Chronicles',
    'EZR': 'Ezra',
    'NEH': 'Nehemiah',
    'EST': 'Esther',
    'JOB': 'Job',
    'PSA': 'Psalms',
    'PRO': 'Proverbs',
    'ECC': 'Ecclesiastes',
    'SNG': 'Song of Solomon',
    'ISA': 'Isaiah',
    'JER': 'Jeremiah',
    'LAM': 'Lamentations',
    'EZK': 'Ezekiel',
    'DAN': 'Daniel',
    'HOS': 'Hosea',
    'JOL': 'Joel',
    'AMO': 'Amos',
    'OBA': 'Obadiah',
    'JON': 'Jonah',
    'MIC': 'Micah',
    'NAM': 'Nahum',
    'HAB': 'Habakkuk',
    'ZEP': 'Zephaniah',
    'HAG': 'Haggai',
    'ZEC': 'Zechariah',
    'MAL': 'Malachi',
    'MAT': 'Matthew',
    'MRK': 'Mark',
    'LUK': 'Luke',
    'JHN': 'John',
    'ACT': 'Acts',
    'ROM': 'Romans',
    '1CO': '1 Corinthians',
    '2CO': '2 Corinthians',
    'GAL': 'Galatians',
    'EPH': 'Ephesians',
    'PHP': 'Philippians',
    'COL': 'Colossians',
    '1TH': '1 Thessalonians',
    '2TH': '2 Thessalonians',
    '1TI': '1 Timothy',
    '2TI': '2 Timothy',
    'TIT': 'Titus',
    'PHM': 'Philemon',
    'HEB': 'Hebrews',
    'JAS': 'James',
    '1PE': '1 Peter',
    '2PE': '2 Peter',
    '1JN': '1 John',
    '2JN': '2 John',
    '3JN': '3 John',
    'JUD': 'Jude',
    'REV': 'Revelation',
  };

  static Future<Map<int, Map<int, String>>> parseUSXFile(String fileName) async {
    try {
      final usxContent = await rootBundle.loadString('assets/Odiya_USX/$fileName');
      final document = XmlDocument.parse(usxContent);

      final Map<int, Map<int, String>> chapters = {};
      int currentChapter = 0;
      int? currentVerse;
      final StringBuffer buffer = StringBuffer();

      void commitCurrentVerse() {
        if (currentChapter > 0 && currentVerse != null) {
          final text = _cleanText(buffer.toString());
          if (text.isNotEmpty) {
            chapters.putIfAbsent(currentChapter, () => {});
            chapters[currentChapter]![currentVerse!] = text;
          }
        }
        buffer.clear();
      }

      bool _isInsideExcluded(XmlNode node) {
        XmlNode? p = node.parent;
        while (p != null) {
          if (p is XmlElement) {
            final n = p.name.local;
            if (n == 'note' || n == 'ref' || n == 'figure' || n == 'optbreak' || n == 'xref') {
              return true;
            }
          }
          p = p.parent;
        }
        return false;
      }

      for (final node in document.rootElement.descendants) {
        if (node is XmlElement) {
          final name = node.name.local;
          if (name == 'chapter') {
            // New chapter marker
            commitCurrentVerse();
            currentVerse = null;
            final numStr = node.getAttribute('number');
            currentChapter = int.tryParse(numStr ?? '0') ?? 0;
            if (currentChapter > 0) {
              chapters.putIfAbsent(currentChapter, () => {});
            }
          } else if (name == 'verse') {
            // Start of a new verse
            commitCurrentVerse();
            final numStr = node.getAttribute('number');
            currentVerse = int.tryParse(numStr ?? '');
          }
        } else if (node is XmlText) {
          if (currentChapter > 0 && currentVerse != null && !_isInsideExcluded(node)) {
            buffer.write(node.text);
          }
        }
      }

      // Commit the last verse encountered
      commitCurrentVerse();

      print('[USXParser] Parsed $fileName: ${chapters.length} chapters');
      return chapters;
    } catch (e) {
      print('[USXParser] Error parsing $fileName: $e');
      return {};
    }
  }

  static String _cleanText(String text) {
    return text
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[¶\u00B6]'), '')
        .trim();
  }

  static String? getBookNameFromUSXCode(String usxCode) {
    return _usxToEnglishBookMap[usxCode.toUpperCase()];
  }

  static String? getUSXCodeFromBookName(String bookName) {
    for (var entry in _usxToEnglishBookMap.entries) {
      if (entry.value == bookName) {
        return entry.key;
      }
    }
    return null;
  }

  // Cache for parsed USX data
  static final Map<String, Map<int, Map<int, String>>> _usxCache = {};

  static Future<String?> getOdiyaVerse(String bookName, int chapter, int verse) async {
    final String? usxCode = getUSXCodeFromBookName(bookName);
    if (usxCode == null) return null;

    final String fileName = '$usxCode.usx';

    // Check cache first
    if (!_usxCache.containsKey(fileName)) {
      _usxCache[fileName] = await parseUSXFile(fileName);
    }

    return _usxCache[fileName]?[chapter]?[verse];
  }

  static Future<Map<int, String>> getOdiyaChapterMap(String bookName, int chapter) async {
    final String? usxCode = getUSXCodeFromBookName(bookName);
    if (usxCode == null) return {};

    final String fileName = '$usxCode.usx';

    if (!_usxCache.containsKey(fileName)) {
      _usxCache[fileName] = await parseUSXFile(fileName);
    }

    return _usxCache[fileName]?[chapter] ?? {};
  }

  // ================== Paragraph parsing support ==================
  // Cache for paragraph groupings: fileName -> chapter -> list of paragraphs (each a list of verse numbers)
  static final Map<String, Map<int, List<List<int>>>> _paraCache = {};

  static Future<Map<int, List<List<int>>>> _parseParagraphs(String fileName) async {
    try {
      final usxContent = await rootBundle.loadString('assets/Odiya_USX/$fileName');
      final document = XmlDocument.parse(usxContent);

      final Map<int, List<List<int>>> chapterParagraphs = {};
      int currentChapter = 0;

      // Iterate through nodes in document order so that chapter markers set the context
      for (final node in document.rootElement.descendants) {
        if (node is XmlElement) {
          final name = node.name.local;
          if (name == 'chapter') {
            final numStr = node.getAttribute('number');
            currentChapter = int.tryParse(numStr ?? '0') ?? 0;
            if (currentChapter > 0) {
              chapterParagraphs.putIfAbsent(currentChapter, () => []);
            }
          } else if (name == 'para') {
            if (currentChapter == 0) continue; // Skip stray paras before any chapter marker

            // Collect verse numbers within this paragraph element
            final List<int> verseNumbers = [];
            for (final v in node.findAllElements('verse')) {
              final numStr = v.getAttribute('number');
              if (numStr != null) {
                final n = int.tryParse(numStr);
                if (n != null && !verseNumbers.contains(n)) {
                  verseNumbers.add(n);
                }
              }
            }

            if (verseNumbers.isNotEmpty) {
              verseNumbers.sort();
              chapterParagraphs[currentChapter]!.add(verseNumbers);
            }
          }
        }
      }

      return chapterParagraphs;
    } catch (e) {
      print('[USXParser] Error parsing paragraphs for $fileName: $e');
      return {};
    }
  }

  static Future<List<List<int>>> getChapterParagraphs(String bookName, int chapter) async {
    final String? usxCode = getUSXCodeFromBookName(bookName);
    if (usxCode == null) return [];

    final String fileName = '$usxCode.usx';

    if (!_paraCache.containsKey(fileName)) {
      _paraCache[fileName] = await _parseParagraphs(fileName);
    }

    return _paraCache[fileName]?[chapter] ?? [];
  }
}