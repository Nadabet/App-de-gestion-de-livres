import 'package:flutter/material.dart';
import '../models/book.dart';
import '../services/api_service.dart';
import '../services/db_service.dart';
import 'favorites_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  List<Book> _searchResults = [];
  bool _isLoading = false;
  String _errorMessage = '';
  Set<String> _favoriteIds = {};
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      await _loadFavoriteIds();
    } catch (e) {
      print('Erreur d\'initialisation: $e');
      // Réessayer après un délai
      await Future.delayed(Duration(milliseconds: 500));
      await _loadFavoriteIds();
    }
  }

  Future<void> _loadFavoriteIds() async {
    final favorites = await DBService.getItems();
    setState(() {
      _favoriteIds = favorites.map((book) => book.id ?? '').toSet();
    });
  }

  Widget _buildSearchPage() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rechercher des livres'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Rechercher un livre...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: (_) => _searchBooks(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _searchBooks,
                  child: const Text('Rechercher'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Future<void> _searchBooks() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un terme de recherche')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      print('Starting search for: $query'); // Debug print
      final results = await ApiService.searchBooks(query);
      print('Search completed. Found ${results.length} results'); // Debug print
      
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      print('Error during search: $e'); // Debug print
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFavorite(Book book) async {
    try {
      if (_favoriteIds.contains(book.id)) {
        await DBService.deleteItemByGoogleId(book.id!);
        setState(() {
          _favoriteIds.remove(book.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Livre retiré des favoris')),
        );
      } else {
        await DBService.insertItem(book);
        setState(() {
          _favoriteIds.add(book.id!);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Livre ajouté aux favoris')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  Widget _getSelectedPage() {
    switch (_selectedIndex) {
      case 0:
        return _buildSearchPage();
      case 1:
        return const FavoritesPage();
      default:
        return _buildSearchPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getSelectedPage(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Rechercher',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favoris',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _searchBooks,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.book, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Recherchez des livres pour commencer'),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final book = _searchResults[index];
        final isFavorite = _favoriteIds.contains(book.id);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: book.imageUrl != null
                ? Image.network(
                    book.imageUrl!,
                    width: 50,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.book, size: 50),
                  )
                : const Icon(Icons.book, size: 50),
            title: Text(
              book.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              book.author,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.red : null,
              ),
              onPressed: () => _toggleFavorite(book),
            ),
            onTap: () => _showBookDetails(book),
          ),
        );
      },
    );
  }

  void _showBookDetails(Book book) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(book.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (book.imageUrl != null)
                Center(
                  child: Image.network(
                    book.imageUrl!,
                    height: 150,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.book, size: 100),
                  ),
                ),
              const SizedBox(height: 16),
              Text('Auteur: ${book.author}'),
              if (book.description != null) ...[
                const SizedBox(height: 16),
                Text(
                  book.description!,
                  maxLines: 10,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
