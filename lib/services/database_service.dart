import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/book.dart';
import '../models/verse.dart';
import '../models/bookmark.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'odiya_bible.db');
    return await openDatabase(
      path,
      version: 4, // Incremented version to force upgrade with JSON data
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    print('Upgrading database from version $oldVersion to $newVersion');
    // Clear existing data and recreate
    await db.delete('verses');
    await db.delete('books');
    await _loadDataFromJson(db);
    print('Database upgrade completed');
  }

  Future<void> _createDatabase(Database db, int version) async {
    // Create books table
    await db.execute('''
      CREATE TABLE books (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        odiya_name TEXT NOT NULL,
        abbreviation TEXT NOT NULL,
        testament TEXT NOT NULL,
        total_chapters INTEGER NOT NULL,
        order_index INTEGER NOT NULL
      )
    ''');

    // Create verses table
    await db.execute('''
      CREATE TABLE verses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        book_id INTEGER NOT NULL,
        chapter INTEGER NOT NULL,
        verse_number INTEGER NOT NULL,
        odiya_text TEXT NOT NULL,
        english_text TEXT,
        hindi_text TEXT,
        is_highlighted INTEGER DEFAULT 0,
        note TEXT,
        is_bookmarked INTEGER DEFAULT 0,
        FOREIGN KEY (book_id) REFERENCES books (id)
      )
    ''');

    // Create bookmarks table
    await db.execute('''
      CREATE TABLE bookmarks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        verse_id INTEGER NOT NULL,
        title TEXT,
        note TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (verse_id) REFERENCES verses (id)
      )
    ''');

    // Insert initial data
    await _loadDataFromJson(db);
  }

  Future<void> _loadDataFromJson(Database db) async {
    try {
      // Load JSON data from assets
      final String jsonString = await rootBundle.loadString('assets/data/comprehensive_bible_data.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      
      // Insert books
      final List<dynamic> books = jsonData['books'];
      final bookBatch = db.batch();
      for (var book in books) {
        bookBatch.insert('books', {
          'id': book['id'],
          'name': book['name'],
          'odiya_name': book['odiya_name'],
          'abbreviation': book['abbreviation'],
          'testament': book['testament'],
          'total_chapters': book['total_chapters'],
          'order_index': book['order_index'],
        });
      }
      await bookBatch.commit(noResult: true);
      print('Successfully loaded ${books.length} books from JSON');
      
      // Insert verses
      final List<dynamic> verses = jsonData['verses'];
      final verseBatch = db.batch();
      for (var verse in verses) {
        verseBatch.insert('verses', {
          'book_id': verse['book_id'],
          'chapter': verse['chapter'],
          'verse_number': verse['verse_number'],
          'odiya_text': verse['odiya_text'],
          'english_text': verse['english_text'],
          'hindi_text': '',
          'is_highlighted': 0,
          'note': null,
          'is_bookmarked': 0,
        });
      }
      await verseBatch.commit(noResult: true);
      print('Successfully loaded ${verses.length} verses from JSON');
      
    } catch (e) {
      print('Error loading data from JSON: $e');
      // Fallback to sample data if JSON loading fails
      await _insertSampleBooks(db);
      await _createSampleVerses(db);
    }
  }

  Future<void> _insertSampleBooks(Database db) async {
    final books = [
      // Old Testament
      {'id': 1, 'name': 'Genesis', 'odiya_name': 'ଆଦି ପୁସ୍ତକ', 'abbreviation': 'Gen', 'testament': 'Old', 'total_chapters': 50, 'order_index': 1},
      {'id': 2, 'name': 'Exodus', 'odiya_name': 'ଯାତ୍ରା ପୁସ୍ତକ', 'abbreviation': 'Exo', 'testament': 'Old', 'total_chapters': 40, 'order_index': 2},
      {'id': 3, 'name': 'Leviticus', 'odiya_name': 'ଲେବୀୟ ପୁସ୍ତକ', 'abbreviation': 'Lev', 'testament': 'Old', 'total_chapters': 27, 'order_index': 3},
      {'id': 4, 'name': 'Numbers', 'odiya_name': 'ଗଣନା ପୁସ୍ତକ', 'abbreviation': 'Num', 'testament': 'Old', 'total_chapters': 36, 'order_index': 4},
      {'id': 5, 'name': 'Deuteronomy', 'odiya_name': 'ଦ୍ୱିତୀୟ ବିବରଣ', 'abbreviation': 'Deu', 'testament': 'Old', 'total_chapters': 34, 'order_index': 5},
      {'id': 19, 'name': 'Psalms', 'odiya_name': 'ଗୀତସଂହିତା', 'abbreviation': 'Psa', 'testament': 'Old', 'total_chapters': 150, 'order_index': 19},
      
      // New Testament
      {'id': 40, 'name': 'Matthew', 'odiya_name': 'ମାଥିଉ', 'abbreviation': 'Mat', 'testament': 'New', 'total_chapters': 28, 'order_index': 40},
      {'id': 41, 'name': 'Mark', 'odiya_name': 'ମାର୍କ', 'abbreviation': 'Mar', 'testament': 'New', 'total_chapters': 16, 'order_index': 41},
      {'id': 42, 'name': 'Luke', 'odiya_name': 'ଲୂକ', 'abbreviation': 'Luk', 'testament': 'New', 'total_chapters': 24, 'order_index': 42},
      {'id': 43, 'name': 'John', 'odiya_name': 'ଯୋହନ', 'abbreviation': 'Joh', 'testament': 'New', 'total_chapters': 21, 'order_index': 43},
      {'id': 45, 'name': 'Romans', 'odiya_name': 'ରୋମୀୟ', 'abbreviation': 'Rom', 'testament': 'New', 'total_chapters': 16, 'order_index': 45},
      {'id': 50, 'name': 'Philippians', 'odiya_name': 'ଫିଲିପ୍ପୀୟ', 'abbreviation': 'Phi', 'testament': 'New', 'total_chapters': 4, 'order_index': 50},
      {'id': 62, 'name': '1 John', 'odiya_name': '୧ ଯୋହନ', 'abbreviation': '1Jo', 'testament': 'New', 'total_chapters': 5, 'order_index': 62},
      {'id': 66, 'name': 'Revelation', 'odiya_name': 'ପ୍ରକାଶିତ ବାକ୍ୟ', 'abbreviation': 'Rev', 'testament': 'New', 'total_chapters': 22, 'order_index': 66},
    ];

    final batch = db.batch();
    for (var book in books) {
      batch.insert('books', book);
    }
    await batch.commit(noResult: true);
    print('Sample books inserted successfully');
  }

  Future<void> _createSampleVerses(Database db) async {
    print('Creating sample verses...');
    
    final sampleVerses = [
      // Genesis 1:1-5
      {'book_id': 1, 'chapter': 1, 'verse_number': 1, 'odiya_text': 'ଆଦିରେ ପରମେଶ୍ୱର ଆକାଶ ଓ ପୃଥିବୀ ସୃଷ୍ଟି କଲେ।', 'english_text': 'In the beginning God created the heavens and the earth.'},
      {'book_id': 1, 'chapter': 1, 'verse_number': 2, 'odiya_text': 'ପୃଥିବୀ ନିରାକାର ଓ ଶୂନ୍ୟ ଥିଲା, ଆଉ ଗଭୀର ଜଳ ଉପରେ ଅନ୍ଧକାର ଥିଲା; ପୁଣି ପରମେଶ୍ୱରଙ୍କ ଆତ୍ମା ଜଳ ଉପରେ ବିରାଜ କରୁଥିଲେ।', 'english_text': 'Now the earth was formless and empty, darkness was over the surface of the deep, and the Spirit of God was hovering over the waters.'},
      {'book_id': 1, 'chapter': 1, 'verse_number': 3, 'odiya_text': 'ତହୁଁ ପରମେଶ୍ୱର କହିଲେ, "ଆଲୋକ ହେଉ;" ତହିଁରେ ଆଲୋକ ହେଲା।', 'english_text': 'And God said, "Let there be light," and there was light.'},
      {'book_id': 1, 'chapter': 1, 'verse_number': 4, 'odiya_text': 'ପରମେଶ୍ୱର ଆଲୋକକୁ ଉତ୍ତମ ଦେଖିଲେ; ଆଉ ପରମେଶ୍ୱର ଆଲୋକ ଓ ଅନ୍ଧକାରକୁ ପୃଥକ କଲେ।', 'english_text': 'God saw that the light was good, and he separated the light from the darkness.'},
      {'book_id': 1, 'chapter': 1, 'verse_number': 5, 'odiya_text': 'ପରମେଶ୍ୱର ଆଲୋକର ନାମ ଦିନ ଓ ଅନ୍ଧକାରର ନାମ ରାତ୍ରି ରଖିଲେ। ତହୁଁ ସନ୍ଧ୍ୟା ଓ ପ୍ରଭାତ ହୋଇ ପ୍ରଥମ ଦିନ ହେଲା।', 'english_text': 'God called the light "day," and the darkness he called "night." And there was evening, and there was morning—the first day.'},
      
      // Psalms 23:1-6
      {'book_id': 19, 'chapter': 23, 'verse_number': 1, 'odiya_text': 'ସଦାପ୍ରଭୁ ମୋର ପାଳକ; ମୋର ଅଭାବ ହେବ ନାହିଁ।', 'english_text': 'The Lord is my shepherd, I lack nothing.'},
      {'book_id': 19, 'chapter': 23, 'verse_number': 2, 'odiya_text': 'ସେ ମୋତେ ସବୁଜ ଚରାଣି ଭୂମିରେ ଶୁଆଇ ଦିଅନ୍ତି; ସେ ମୋତେ ଶାନ୍ତ ଜଳ ନିକଟକୁ ନେଇ ଯାଆନ୍ତି।', 'english_text': 'He makes me lie down in green pastures, he leads me beside quiet waters.'},
      {'book_id': 19, 'chapter': 23, 'verse_number': 3, 'odiya_text': 'ସେ ମୋର ପ୍ରାଣ ସଞ୍ଜୀବିତ କରନ୍ତି; ସେ ଆପଣା ନାମ ସକାଶେ ମୋତେ ଧର୍ମପଥରେ ଗମନ କରାନ୍ତି।', 'english_text': 'He refreshes my soul. He guides me along the right paths for his name\'s sake.'},
      
      // Matthew 5:3-8 (Beatitudes)
      {'book_id': 40, 'chapter': 5, 'verse_number': 3, 'odiya_text': 'ଆତ୍ମାରେ ଦରିଦ୍ରମାନେ ଧନ୍ୟ, କାରଣ ସ୍ୱର୍ଗରାଜ୍ୟ ସେମାନଙ୍କର।', 'english_text': 'Blessed are the poor in spirit, for theirs is the kingdom of heaven.'},
      {'book_id': 40, 'chapter': 5, 'verse_number': 4, 'odiya_text': 'ଶୋକକାରୀମାନେ ଧନ୍ୟ, କାରଣ ସେମାନେ ସାନ୍ତ୍ୱନା ପାଇବେ।', 'english_text': 'Blessed are those who mourn, for they will be comforted.'},
      {'book_id': 40, 'chapter': 5, 'verse_number': 5, 'odiya_text': 'ନମ୍ରମାନେ ଧନ୍ୟ, କାରଣ ସେମାନେ ପୃଥିବୀର ଅଧିକାରୀ ହେବେ।', 'english_text': 'Blessed are the meek, for they will inherit the earth.'},
      
      // John 3:16-17
      {'book_id': 43, 'chapter': 3, 'verse_number': 16, 'odiya_text': 'କାରଣ ପରମେଶ୍ୱର ଜଗତକୁ ଏପରି ପ୍ରେମ କଲେ ଯେ, ସେ ଆପଣାର ଏକଜାତ ପୁତ୍ରଙ୍କୁ ଦାନ କଲେ, ଯେପରି ଯେ କେହି ତାହାଙ୍କଠାରେ ବିଶ୍ୱାସ କରେ, ସେ ବିନଷ୍ଟ ନ ହୋଇ ଅନନ୍ତ ଜୀବନ ପାଏ।', 'english_text': 'For God so loved the world that he gave his one and only Son, that whoever believes in him shall not perish but have eternal life.'},
      {'book_id': 43, 'chapter': 3, 'verse_number': 17, 'odiya_text': 'କାରଣ ପରମେଶ୍ୱର ଜଗତକୁ ଦଣ୍ଡ ଦେବା ନିମନ୍ତେ ଆପଣା ପୁତ୍ରଙ୍କୁ ଜଗତକୁ ପଠାଇଲେ ନାହିଁ, ବରଂ ତାହାଙ୍କ ଦ୍ୱାରା ଯେପରି ଜଗତ ପରିତ୍ରାଣ ପାଏ।', 'english_text': 'For God did not send his Son into the world to condemn the world, but to save the world through him.'},
      
      // Romans 8:28
      {'book_id': 45, 'chapter': 8, 'verse_number': 28, 'odiya_text': 'ଆଉ ଆମ୍ଭେମାନେ ଜାଣୁ ଯେ, ଯେଉଁମାନେ ପରମେଶ୍ୱରଙ୍କୁ ପ୍ରେମ କରନ୍ତି, ସେମାନଙ୍କ ନିମନ୍ତେ ସମସ୍ତ ବିଷୟ ମଙ୍ଗଳଜନକ, ଅର୍ଥାତ୍‍ ଯେଉଁମାନେ ତାହାଙ୍କ ସଂକଳ୍ପ ଅନୁସାରେ ଆହୂତ।', 'english_text': 'And we know that in all things God works for the good of those who love him, who have been called according to his purpose.'},
      
      // Philippians 4:13
      {'book_id': 50, 'chapter': 4, 'verse_number': 13, 'odiya_text': 'ଯେ ମୋତେ ଶକ୍ତି ଦିଅନ୍ତି, ତାହାଙ୍କଠାରେ ମୁଁ ସବୁ କରିପାରେ।', 'english_text': 'I can do all this through him who gives me strength.'},
      
      // 1 John 4:8
      {'book_id': 62, 'chapter': 4, 'verse_number': 8, 'odiya_text': 'ଯେ ପ୍ରେମ କରେ ନାହିଁ, ସେ ପରମେଶ୍ୱରଙ୍କୁ ଜାଣେ ନାହିଁ, କାରଣ ପରମେଶ୍ୱର ପ୍ରେମ।', 'english_text': 'Whoever does not love does not know God, because God is love.'},
      
      // Revelation 21:4
      {'book_id': 66, 'chapter': 21, 'verse_number': 4, 'odiya_text': 'ଆଉ ସେ ସେମାନଙ୍କ ଚକ୍ଷୁରୁ ସମସ୍ତ ଲୋତକ ପୋଛି ଦେବେ; ମୃତ୍ୟୁ ଆଉ ହେବ ନାହିଁ, ଶୋକ କି ରୋଦନ କି ବେଦନା ଆଉ ହେବ ନାହିଁ; ପ୍ରଥମ ବିଷୟସବୁ ଅତୀତ ହୋଇଗଲା।', 'english_text': 'He will wipe every tear from their eyes. There will be no more death or mourning or crying or pain, for the old order of things has passed away.'}
    ];

    final batch = db.batch();
    for (var verse in sampleVerses) {
      batch.insert('verses', {
        'book_id': verse['book_id'],
        'chapter': verse['chapter'],
        'verse_number': verse['verse_number'],
        'odiya_text': verse['odiya_text'],
        'english_text': verse['english_text'],
        'hindi_text': '',
        'is_highlighted': 0,
        'note': null,
        'is_bookmarked': 0,
      });
    }
    await batch.commit(noResult: true);
    print('Successfully created ${sampleVerses.length} sample verses');
  }

  // ... existing code ...
  
  // Book operations
  Future<List<Book>> getAllBooks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'books',
      orderBy: 'order_index ASC',
    );
    return List.generate(maps.length, (i) => Book.fromJson(maps[i]));
  }

  Future<Book?> getBookById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'books',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Book.fromJson(maps.first);
    }
    return null;
  }

  // Verse operations
  Future<List<Verse>> getVersesByChapter(int bookId, int chapter) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'verses',
      where: 'book_id = ? AND chapter = ?',
      whereArgs: [bookId, chapter],
      orderBy: 'verse_number ASC',
    );
    return List.generate(maps.length, (i) => Verse.fromJson(maps[i]));
  }

  Future<List<Verse>> searchVerses(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'verses',
      where: 'odiya_text LIKE ? OR english_text LIKE ? OR hindi_text LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'book_id ASC, chapter ASC, verse_number ASC',
      limit: 100,
    );
    return List.generate(maps.length, (i) => Verse.fromJson(maps[i]));
  }

  Future<void> updateVerseHighlight(int verseId, bool isHighlighted) async {
    final db = await database;
    await db.update(
      'verses',
      {'is_highlighted': isHighlighted ? 1 : 0},
      where: 'id = ?',
      whereArgs: [verseId],
    );
  }

  Future<void> updateVerseNote(int verseId, String? note) async {
    final db = await database;
    await db.update(
      'verses',
      {'note': note},
      where: 'id = ?',
      whereArgs: [verseId],
    );
  }

  // Bookmark operations
  Future<int> insertBookmark(Bookmark bookmark) async {
    final db = await database;
    return await db.insert('bookmarks', bookmark.toJson());
  }

  Future<List<Bookmark>> getAllBookmarks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'bookmarks',
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => Bookmark.fromJson(maps[i]));
  }

  Future<void> deleteBookmark(int id) async {
    final db = await database;
    await db.delete(
      'bookmarks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateBookmark(Bookmark bookmark) async {
    final db = await database;
    await db.update(
      'bookmarks',
      bookmark.toJson(),
      where: 'id = ?',
      whereArgs: [bookmark.id],
    );
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}