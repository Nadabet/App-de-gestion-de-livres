import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import '../models/book.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'books.db');

    return await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: _createDB,
      ),
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE favorites(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        google_id TEXT NOT NULL,
        title TEXT NOT NULL,
        author TEXT NOT NULL,
        image_url TEXT,
        description TEXT
      )
    ''');
  }

  Future<int> insertBook(Book book) async {
    final db = await database;
    return await db.insert(
      'favorites',
      book.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Book>> getFavorites() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('favorites');
    return List.generate(maps.length, (i) => Book.fromMap(maps[i]));
  }

  Future<int> deleteBook(String googleId) async {
    final db = await database;
    return await db.delete(
      'favorites',
      where: 'google_id = ?',
      whereArgs: [googleId],
    );
  }
}
