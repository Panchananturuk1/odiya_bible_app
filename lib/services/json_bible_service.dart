import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/book.dart';
import '../models/verse.dart';

class JsonBibleService {
  static const Map<String, String> _bookOdiyaNames = {
    'Genesis': 'ଆଦିପୁସ୍ତକ',
    'Exodus': 'ଯାତ୍ରାପୁସ୍ତକ',
    'Leviticus': 'ଲେବୀୟ ପୁସ୍ତକ',
    'Numbers': 'ଗଣନା ପୁସ୍ତକ',
    'Deuteronomy': 'ଦ୍ୱିତୀୟ ବିବରଣ',
    'Joshua': 'ଯିହୋଶୂୟ',
    'Judges': 'ବିଚାରକର୍ତ୍ତାଗଣ',
    'Ruth': 'ରୂତ',
    '1 Samuel': '୧ ଶାମୁୟେଲ',
    '2 Samuel': '୨ ଶାମୁୟେଲ',
    '1 Kings': '୧ ରାଜାବଳୀ',
    '2 Kings': '୨ ରାଜାବଳୀ',
    '1 Chronicles': '୧ ବଂଶାବଳୀ',
    '2 Chronicles': '୨ ବଂଶାବଳୀ',
    'Ezra': 'ଏଜ୍ରା',
    'Nehemiah': 'ନିହିମିୟା',
    'Esther': 'ଏଷ୍ଟର',
    'Job': 'ଆୟୁବ',
    'Psalms': 'ଗୀତସଂହିତା',
    'Proverbs': 'ହିତୋପଦେଶ',
    'Ecclesiastes': 'ଉପଦେଶକ',
    'Song of Solomon': 'ପରମଗୀତ',
    'Isaiah': 'ଯିଶାଇୟ',
    'Jeremiah': 'ଯିରିମିୟ',
    'Lamentations': 'ବିଳାପ',
    'Ezekiel': 'ଯିହିଜିକଲ',
    'Daniel': 'ଦାନିୟେଲ',
    'Hosea': 'ହୋଶେୟ',
    'Joel': 'ଯୋୟେଲ',
    'Amos': 'ଆମୋଷ',
    'Obadiah': 'ଓବଦିୟ',
    'Jonah': 'ଯୋନା',
    'Micah': 'ମୀଖା',
    'Nahum': 'ନାହୂମ',
    'Habakkuk': 'ହବକ୍କୂକ',
    'Zephaniah': 'ସଫନିୟ',
    'Haggai': 'ହାଗୟ',
    'Zechariah': 'ଜିଖରିୟ',
    'Malachi': 'ମାଲାଖି',
    'Matthew': 'ମାଥିଉ',
    'Mark': 'ମାର୍କ',
    'Luke': 'ଲୂକ',
    'John': 'ଯୋହନ',
    'Acts': 'ପ୍ରେରିତମାନଙ୍କ କାର୍ଯ୍ୟ',
    'Romans': 'ରୋମୀୟ',
    '1 Corinthians': '୧ କରିନ୍ଥୀୟ',
    '2 Corinthians': '୨ କରିନ୍ଥୀୟ',
    'Galatians': 'ଗାଲାତୀୟ',
    'Ephesians': 'ଏଫିସୀୟ',
    'Philippians': 'ଫିଲିପ୍ପୀୟ',
    'Colossians': 'କଲସୀୟ',
    '1 Thessalonians': '୧ ଥେସଲନୀକୀୟ',
    '2 Thessalonians': '୨ ଥେସଲନୀକୀୟ',
    '1 Timothy': '୧ ତୀମଥିୟ',
    '2 Timothy': '୨ ତୀମଥିୟ',
    'Titus': 'ତୀତ',
    'Philemon': 'ଫିଲେମୋନ',
    'Hebrews': 'ଏବ୍ରୀୟ',
    'James': 'ଯାକୁବ',
    '1 Peter': '୧ ପିତର',
    '2 Peter': '୨ ପିତର',
    '1 John': '୧ ଯୋହନ',
    '2 John': '୨ ଯୋହନ',
    '3 John': '୩ ଯୋହନ',
    'Jude': 'ଯିହୂଦା',
    'Revelation': 'ପ୍ରକାଶିତ ବାକ୍ୟ',
  };

  static const Map<String, int> _bookChapterCounts = {
    'Genesis': 50, 'Exodus': 40, 'Leviticus': 27, 'Numbers': 36, 'Deuteronomy': 34,
    'Joshua': 24, 'Judges': 21, 'Ruth': 4, '1 Samuel': 31, '2 Samuel': 24,
    '1 Kings': 22, '2 Kings': 25, '1 Chronicles': 29, '2 Chronicles': 36,
    'Ezra': 10, 'Nehemiah': 13, 'Esther': 10, 'Job': 42, 'Psalms': 150,
    'Proverbs': 31, 'Ecclesiastes': 12, 'Song of Solomon': 8, 'Isaiah': 66,
    'Jeremiah': 52, 'Lamentations': 5, 'Ezekiel': 48, 'Daniel': 12,
    'Hosea': 14, 'Joel': 3, 'Amos': 9, 'Obadiah': 1, 'Jonah': 4,
    'Micah': 7, 'Nahum': 3, 'Habakkuk': 3, 'Zephaniah': 3, 'Haggai': 2,
    'Zechariah': 14, 'Malachi': 4, 'Matthew': 28, 'Mark': 16, 'Luke': 24,
    'John': 21, 'Acts': 28, 'Romans': 16, '1 Corinthians': 16, '2 Corinthians': 13,
    'Galatians': 6, 'Ephesians': 6, 'Philippians': 4, 'Colossians': 4,
    '1 Thessalonians': 5, '2 Thessalonians': 3, '1 Timothy': 6, '2 Timothy': 4,
    'Titus': 3, 'Philemon': 1, 'Hebrews': 13, 'James': 5, '1 Peter': 5,
    '2 Peter': 3, '1 John': 5, '2 John': 1, '3 John': 1, 'Jude': 1, 'Revelation': 22,
  };

  static List<Book> getAllBooks() {
    List<Book> books = [];
    int id = 1;
    int order = 1;

    // Old Testament books
    List<String> oldTestamentBooks = [
      'Genesis', 'Exodus', 'Leviticus', 'Numbers', 'Deuteronomy',
      'Joshua', 'Judges', 'Ruth', '1 Samuel', '2 Samuel',
      '1 Kings', '2 Kings', '1 Chronicles', '2 Chronicles',
      'Ezra', 'Nehemiah', 'Esther', 'Job', 'Psalms',
      'Proverbs', 'Ecclesiastes', 'Song of Solomon', 'Isaiah',
      'Jeremiah', 'Lamentations', 'Ezekiel', 'Daniel',
      'Hosea', 'Joel', 'Amos', 'Obadiah', 'Jonah',
      'Micah', 'Nahum', 'Habakkuk', 'Zephaniah', 'Haggai',
      'Zechariah', 'Malachi'
    ];

    // New Testament books
    List<String> newTestamentBooks = [
      'Matthew', 'Mark', 'Luke', 'John', 'Acts',
      'Romans', '1 Corinthians', '2 Corinthians', 'Galatians',
      'Ephesians', 'Philippians', 'Colossians', '1 Thessalonians',
      '2 Thessalonians', '1 Timothy', '2 Timothy', 'Titus',
      'Philemon', 'Hebrews', 'James', '1 Peter', '2 Peter',
      '1 John', '2 John', '3 John', 'Jude', 'Revelation'
    ];

    // Add Old Testament books
    for (String bookName in oldTestamentBooks) {
      books.add(Book(
        id: id++,
        name: bookName,
        odiyaName: _bookOdiyaNames[bookName] ?? bookName,
        abbreviation: _getAbbreviation(bookName),
        testament: 1,
        totalChapters: _bookChapterCounts[bookName] ?? 1,
        order: order++,
      ));
    }

    // Add New Testament books
    for (String bookName in newTestamentBooks) {
      books.add(Book(
        id: id++,
        name: bookName,
        odiyaName: _bookOdiyaNames[bookName] ?? bookName,
        abbreviation: _getAbbreviation(bookName),
        testament: 2,
        totalChapters: _bookChapterCounts[bookName] ?? 1,
        order: order++,
      ));
    }

    return books;
  }

  static String _getAbbreviation(String bookName) {
    Map<String, String> abbreviations = {
      'Genesis': 'Gen', 'Exodus': 'Exo', 'Leviticus': 'Lev', 'Numbers': 'Num',
      'Deuteronomy': 'Deu', 'Joshua': 'Jos', 'Judges': 'Jdg', 'Ruth': 'Rut',
      '1 Samuel': '1Sa', '2 Samuel': '2Sa', '1 Kings': '1Ki', '2 Kings': '2Ki',
      '1 Chronicles': '1Ch', '2 Chronicles': '2Ch', 'Ezra': 'Ezr', 'Nehemiah': 'Neh',
      'Esther': 'Est', 'Job': 'Job', 'Psalms': 'Psa', 'Proverbs': 'Pro',
      'Ecclesiastes': 'Ecc', 'Song of Solomon': 'Son', 'Isaiah': 'Isa',
      'Jeremiah': 'Jer', 'Lamentations': 'Lam', 'Ezekiel': 'Eze', 'Daniel': 'Dan',
      'Hosea': 'Hos', 'Joel': 'Joe', 'Amos': 'Amo', 'Obadiah': 'Oba',
      'Jonah': 'Jon', 'Micah': 'Mic', 'Nahum': 'Nah', 'Habakkuk': 'Hab',
      'Zephaniah': 'Zep', 'Haggai': 'Hag', 'Zechariah': 'Zec', 'Malachi': 'Mal',
      'Matthew': 'Mat', 'Mark': 'Mar', 'Luke': 'Luk', 'John': 'Joh',
      'Acts': 'Act', 'Romans': 'Rom', '1 Corinthians': '1Co', '2 Corinthians': '2Co',
      'Galatians': 'Gal', 'Ephesians': 'Eph', 'Philippians': 'Phi', 'Colossians': 'Col',
      '1 Thessalonians': '1Th', '2 Thessalonians': '2Th', '1 Timothy': '1Ti',
      '2 Timothy': '2Ti', 'Titus': 'Tit', 'Philemon': 'Phm', 'Hebrews': 'Heb',
      'James': 'Jam', '1 Peter': '1Pe', '2 Peter': '2Pe', '1 John': '1Jo',
      '2 John': '2Jo', '3 John': '3Jo', 'Jude': 'Jud', 'Revelation': 'Rev',
    };
    return abbreviations[bookName] ?? bookName.substring(0, 3);
  }

  static Future<List<Verse>> getVersesByChapter(String bookName, int chapter) async {
    try {
      String jsonString = await rootBundle.loadString('JSON/$bookName/$chapter.json');
      Map<String, dynamic> data = json.decode(jsonString);
      
      List<Verse> verses = [];
      List<dynamic> versesData = data['verses'] ?? [];
      
      for (var verseData in versesData) {
        verses.add(Verse(
          id: verseData['verse'],
          bookId: _getBookId(bookName),
          chapter: chapter,
          verseNumber: verseData['verse'],
          englishText: _cleanText(verseData['text'] ?? ''),
          odiyaText: _getOdiyaTranslation(bookName, chapter, verseData['verse']),
          hindiText: '', // Can be added later
        ));
      }
      
      return verses;
    } catch (e) {
      print('Error loading verses for $bookName chapter $chapter: $e');
      return [];
    }
  }

  static String _cleanText(String text) {
    // Remove HTML tags and special characters
    return text
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('¶ ', '')
        .trim();
  }

  static int _getBookId(String bookName) {
    List<String> allBooks = [
      'Genesis', 'Exodus', 'Leviticus', 'Numbers', 'Deuteronomy',
      'Joshua', 'Judges', 'Ruth', '1 Samuel', '2 Samuel',
      '1 Kings', '2 Kings', '1 Chronicles', '2 Chronicles',
      'Ezra', 'Nehemiah', 'Esther', 'Job', 'Psalms',
      'Proverbs', 'Ecclesiastes', 'Song of Solomon', 'Isaiah',
      'Jeremiah', 'Lamentations', 'Ezekiel', 'Daniel',
      'Hosea', 'Joel', 'Amos', 'Obadiah', 'Jonah',
      'Micah', 'Nahum', 'Habakkuk', 'Zephaniah', 'Haggai',
      'Zechariah', 'Malachi', 'Matthew', 'Mark', 'Luke', 'John', 'Acts',
      'Romans', '1 Corinthians', '2 Corinthians', 'Galatians',
      'Ephesians', 'Philippians', 'Colossians', '1 Thessalonians',
      '2 Thessalonians', '1 Timothy', '2 Timothy', 'Titus',
      'Philemon', 'Hebrews', 'James', '1 Peter', '2 Peter',
      '1 John', '2 John', '3 John', 'Jude', 'Revelation'
    ];
    return allBooks.indexOf(bookName) + 1;
  }

  static String _getOdiyaTranslation(String bookName, int chapter, int verse) {
    // Basic Odia translations for common verses
    Map<String, String> translations = {
      'Genesis_1_1': 'ଆଦିରେ ଈଶ୍ବର ଆକାଶ ଓ ପୃଥିବୀକୁ ସୃଷ୍ଟି କଲେ |',
      'Genesis_1_2': 'ପୃଥିବୀ ନିରାକାର ଓ ଶୂନ୍ୟ ଥିଲା, ଗଭୀର ଜଳ ଉପରେ ଅନ୍ଧକାର ଛାୟା କରୁଥିଲା, ଏବଂ ଈଶ୍ବରଙ୍କ ଆତ୍ମା ଜଳପୃଷ୍ଠ ଉପରେ ବିଚରଣ କରୁଥିଲେ |',
      'Genesis_1_3': 'ଈଶ୍ବର କହିଲେ, "ଆଲୋକ ହେଉ," ଏବଂ ଆଲୋକ ହେଲା |',
      'John_3_16': 'କାରଣ ଈଶ୍ବର ଜଗତକୁ ଏତେ ପ୍ରେମ କଲେ ଯେ, ସେ ନିଜର ଏକମାତ୍ର ପୁତ୍ରଙ୍କୁ ଦାନ କଲେ, ଯେପରି ଯେକେହି ତାହାଙ୍କଠାରେ ବିଶ୍ବାସ କରେ, ସେ ବିନଷ୍ଟ ନ ହୋଇ ଅନନ୍ତ ଜୀବନ ପାଏ |',
    };
    
    String key = '${bookName}_${chapter}_$verse';
    
    // Return the translation if it exists in our map
    if (translations.containsKey(key)) {
      return translations[key]!;
    }
    
    // Generate a unique placeholder translation for each verse
    // This ensures each verse has a different Odia text
    String odiyaName = _bookOdiyaNames[bookName] ?? bookName;
    return '$odiyaName $chapter:$verse - ଓଡ଼ିଆ ଅନୁବାଦ ଉପଲବ୍ଧ ନାହିଁ';
  }

  static Future<List<Verse>> searchVerses(String query) async {
    List<Verse> results = [];
    List<Book> books = getAllBooks();
    
    for (Book book in books) {
      for (int chapter = 1; chapter <= book.totalChapters; chapter++) {
        try {
          List<Verse> verses = await getVersesByChapter(book.name, chapter);
          for (Verse verse in verses) {
            if (verse.englishText?.toLowerCase().contains(query.toLowerCase()) == true ||
                verse.odiyaText?.toLowerCase().contains(query.toLowerCase()) == true) {
              results.add(verse);
            }
          }
        } catch (e) {
          // Skip chapters that don't exist
          continue;
        }
      }
    }
    
    return results;
  }
}