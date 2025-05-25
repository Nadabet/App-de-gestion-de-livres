import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/book.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Favoris'),
      ),
      body: FutureBuilder<List<Book>>(
        future: DatabaseHelper.instance.getFavorites(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Aucun favori'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final book = snapshot.data![index];
              return ListTile(
                leading: book.imageUrl != null
                    ? Image.network(book.imageUrl!)
                    : const Icon(Icons.book),
                title: Text(book.title),
                subtitle: Text(book.author),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    await DatabaseHelper.instance.deleteBook(book.id!);
                    setState(() {});
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}