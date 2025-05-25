import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/widgets.dart';
import '../models/book.dart';

class DBService {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  static Future<Database> _initDB() async {
    // S'assurer que les bindings Flutter sont initialisés
    WidgetsFlutterBinding.ensureInitialized();
    
    final path = join(await getDatabasesPath(), 'books.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute('''
          CREATE TABLE IF NOT EXISTS favorites (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            google_id TEXT,
            title TEXT,
            author TEXT,
            image_url TEXT,
            description TEXT
          )
        ''');
      },
    );
  }

  // Insérer un livre dans les favoris
  static Future<void> insertItem(Book book) async {
    try {
      final db = await database;
      await db.insert(
        'favorites',
        book.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print('Erreur lors de l\'insertion: $e');
      rethrow;
    }
  }

  // Récupérer tous les favoris
  static Future<List<Book>> getItems() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query('favorites');
      
      return maps.map((map) => Book.fromMap(map)).toList();
    } catch (e) {
      print('Erreur lors de la récupération: $e');
      return [];
    }
  }

  // Supprimer un favori par ID de base de données
  static Future<void> deleteItem(int id) async {
    try {
      final db = await database;
      await db.delete(
        'favorites',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print('Erreur lors de la suppression: $e');
      rethrow;
    }
  }

  // Supprimer un favori par Google ID
  static Future<void> deleteItemByGoogleId(String googleId) async {
    try {
      final db = await database;
      await db.delete(
        'favorites',
        where: 'google_id = ?',
        whereArgs: [googleId],
      );
    } catch (e) {
      print('Erreur lors de la suppression par Google ID: $e');
      rethrow;
    }
  }

  // Vérifier si un livre est en favori
  static Future<bool> isFavorite(String googleId) async {
    try {
      final db = await database;
      final result = await db.query(
        'favorites',
        where: 'google_id = ?',
        whereArgs: [googleId],
      );
      return result.isNotEmpty;
    } catch (e) {
      print('Erreur lors de la vérification: $e');
      return false;
    }
  }
}