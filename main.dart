import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ==========================================
// 1. MAIN
// ==========================================

void main() {
  runApp(const NewsReaderApp());
}

class NewsReaderApp extends StatelessWidget {
  const NewsReaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'News Reader',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const NewsHomePage(),
    );
  }
}

// ==========================================
// 2. ARTICLE MODEL
// ==========================================

class Article {
  final int id;
  final String title;
  final String body;
  final int userId;

  Article({
    required this.id,
    required this.title,
    required this.body,
    required this.userId,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      userId: json['userId'],
    );
  }
}

// ==========================================
// 3. NEWS SERVICE
// ==========================================

class NewsService {
  static List<Article> getArticles() {
    // Demo JSON data.
    // This can be replaced with API response data.

    const jsonData = '''
    [
      {
        "userId": 1,
        "id": 1,
        "title": "Technology is changing the world",
        "body": "Technology is transforming education, healthcare and communication. Modern applications make our daily life easier."
      },
      {
        "userId": 1,
        "id": 2,
        "title": "Artificial Intelligence Future",
        "body": "Artificial intelligence is becoming an important part of modern technology. It helps people solve complex problems."
      },
      {
        "userId": 2,
        "id": 3,
        "title": "Flutter App Development",
        "body": "Flutter is a popular framework for building beautiful cross platform mobile applications using Dart."
      },
      {
        "userId": 2,
        "id": 4,
        "title": "Importance of Education",
        "body": "Education helps people develop knowledge, skills and confidence. It plays an important role in society."
      },
      {
        "userId": 3,
        "id": 5,
        "title": "Cyber Security Awareness",
        "body": "Cyber security protects computers, networks and personal information from digital attacks."
      },
      {
        "userId": 3,
        "id": 6,
        "title": "Future of Computer Science",
        "body": "Computer science continues to create opportunities in software engineering, artificial intelligence and data science."
      }
    ]
    ''';

    final List<dynamic> decoded = jsonDecode(jsonData);

    return decoded.map((item) => Article.fromJson(item)).toList();
  }
}

// ==========================================
// 4. NEWS HOME PAGE
// ==========================================

class NewsHomePage extends StatefulWidget {
  const NewsHomePage({super.key});

  @override
  State<NewsHomePage> createState() => _NewsHomePageState();
}

class _NewsHomePageState extends State<NewsHomePage> {
  List<Article> articles = [];
  List<Article> filteredArticles = [];

  Set<int> favorites = {};

  bool isLoading = true;
  bool hasError = false;
  bool showFavoritesOnly = false;

  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadNews();
  }

  // ==========================================
  // 5. LOAD NEWS
  // ==========================================

  Future<void> loadNews() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    await Future.delayed(const Duration(seconds: 1));

    try {
      final result = NewsService.getArticles();

      setState(() {
        articles = result;
        filteredArticles = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  // ==========================================
  // 6. SEARCH NEWS
  // ==========================================

  void searchNews(String query) {
    setState(() {
      List<Article> result = articles;

      if (showFavoritesOnly) {
        result = result
            .where((article) => favorites.contains(article.id))
            .toList();
      }

      if (query.isNotEmpty) {
        result = result
            .where(
              (article) =>
                  article.title.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }

      filteredArticles = result;
    });
  }

  // ==========================================
  // 7. FAVORITE
  // ==========================================

  void toggleFavorite(int id) {
    setState(() {
      if (favorites.contains(id)) {
        favorites.remove(id);
      } else {
        favorites.add(id);
      }

      searchNews(searchController.text);
    });
  }

  void toggleFavoriteFilter() {
    setState(() {
      showFavoritesOnly = !showFavoritesOnly;
      searchNews(searchController.text);
    });
  }

  // ==========================================
  // 8. UI
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'News Reader',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Favorites',
            onPressed: toggleFavoriteFilter,
            icon: Icon(
              showFavoritesOnly ? Icons.favorite : Icons.favorite_border,
              color: showFavoritesOnly ? Colors.red : null,
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                '${favorites.length}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),

      body: Column(
        children: [
          // Search Field

          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: searchController,
              onChanged: searchNews,
              decoration: InputDecoration(
                hintText: 'Search news by title...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    searchController.clear();
                    searchNews('');
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // News Content
          Expanded(child: buildNewsContent()),
        ],
      ),
    );
  }

  // ==========================================
  // 9. LOADING / ERROR / SUCCESS
  // ==========================================

  Widget buildNewsContent() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 12),
            const Text('Failed to load news'),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: loadNews, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (filteredArticles.isEmpty) {
      return const Center(
        child: Text('No news found!', style: TextStyle(fontSize: 18)),
      );
    }

    return RefreshIndicator(
      onRefresh: loadNews,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filteredArticles.length,
        itemBuilder: (context, index) {
          final article = filteredArticles[index];

          return ArticleCard(
            article: article,
            isFavorite: favorites.contains(article.id),
            onFavorite: () {
              toggleFavorite(article.id);
            },
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ArticleDetailPage(
                    article: article,
                    isFavorite: favorites.contains(article.id),
                    onFavorite: () {
                      toggleFavorite(article.id);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}

// ==========================================
// 10. ARTICLE CARD
// ==========================================

class ArticleCard extends StatelessWidget {
  final Article article;
  final bool isFavorite;
  final VoidCallback onFavorite;
  final VoidCallback onTap;

  const ArticleCard({
    super.key,
    required this.article,
    required this.isFavorite,
    required this.onFavorite,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.article, color: Colors.white),
                  ),

                  const SizedBox(width: 10),

                  const Expanded(
                    child: Text(
                      'Latest News',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),

                  IconButton(
                    onPressed: onFavorite,
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : Colors.grey,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Text(
                article.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                article.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[700]),
              ),

              const SizedBox(height: 10),

              const Row(
                children: [
                  Text(
                    'Read More',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 5),
                  Icon(Icons.arrow_forward, color: Colors.blue, size: 16),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 11. ARTICLE DETAIL PAGE
// ==========================================

class ArticleDetailPage extends StatefulWidget {
  final Article article;
  final bool isFavorite;
  final VoidCallback onFavorite;

  const ArticleDetailPage({
    super.key,
    required this.article,
    required this.isFavorite,
    required this.onFavorite,
  });

  @override
  State<ArticleDetailPage> createState() => _ArticleDetailPageState();
}

class _ArticleDetailPageState extends State<ArticleDetailPage> {
  late bool favorite;

  @override
  void initState() {
    super.initState();
    favorite = widget.isFavorite;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Article Details'),
        actions: [
          IconButton(
            onPressed: () {
              widget.onFavorite();

              setState(() {
                favorite = !favorite;
              });
            },
            icon: Icon(
              favorite ? Icons.favorite : Icons.favorite_border,
              color: favorite ? Colors.red : null,
            ),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.newspaper, size: 80, color: Colors.blue),

            const SizedBox(height: 20),

            Text(
              widget.article.title,
              style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 15),

            Text(
              'Article ID: ${widget.article.id}',
              style: const TextStyle(color: Colors.grey),
            ),

            const Divider(height: 30),

            Text(
              widget.article.body,
              style: const TextStyle(fontSize: 17, height: 1.7),
            ),
          ],
        ),
      ),
    );
  }
}
