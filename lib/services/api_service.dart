import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/book.dart';

class ApiService {
  static const String baseUrl = 'https://www.googleapis.com/books/v1/volumes';

  static Future<List<Book>> searchBooks(String query) async {
    if (query.isEmpty) {
      return [];
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl?q=${Uri.encodeComponent(query)}&maxResults=40'),
      );

      print('API Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        if (!data.containsKey('items')) {
          print('No items found in response');
          return [];
        }

        final List<dynamic> items = data['items'];
        final books = items.map((item) {
          try {
            return Book.fromJson(item);
          } catch (e) {
            print('Error parsing book: $e');
            return null;
          }
        }).whereType<Book>().toList();

        print('Successfully parsed ${books.length} books');
        return books;
      } else {
        print('API Error: ${response.statusCode}');
        throw Exception('Failed to load books');
      }
    } catch (e) {
      print('Search Error: $e');
      throw Exception('Error searching books: $e');
    }
  }
}
