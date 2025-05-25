class Book {
  final String? id;
  final String title;
  final String author;
  final String? imageUrl;
  final String? description;
  final int? dbId;

  Book({
    this.id,
    required this.title,
    required this.author,
    this.imageUrl,
    this.description,
    this.dbId,
  });

  // Convertir JSON vers Book (pour l'API)
  factory Book.fromJson(Map<String, dynamic> json) {
    final volumeInfo = json['volumeInfo'] ?? {};
    final authors = volumeInfo['authors'] as List<dynamic>?;
    final imageLinks = volumeInfo['imageLinks'] as Map<String, dynamic>?;

    return Book(
      id: json['id'],
      title: volumeInfo['title'] ?? 'Titre non disponible',
      author: authors != null && authors.isNotEmpty 
          ? authors.join(', ') 
          : 'Auteur inconnu',
      imageUrl: imageLinks?['thumbnail'],
      description: volumeInfo['description'],
    );
  }

  // Convertir Book vers Map (pour SQLite)
  Map<String, dynamic> toMap() {
    return {
      'id': dbId,
      'google_id': id,
      'title': title,
      'author': author,
      'image_url': imageUrl,
      'description': description,
    };
  }

  // Convertir Map vers Book (depuis SQLite)
  factory Book.fromMap(Map<String, dynamic> map) {
    return Book(
      dbId: map['id'],
      id: map['google_id'],
      title: map['title'],
      author: map['author'],
      imageUrl: map['image_url'],
      description: map['description'],
    );
  }

  @override
  String toString() {
    return 'Book{id: $id, title: $title, author: $author}';
  }
}