import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:url_launcher/url_launcher.dart';
import 'package:bingah/theme.dart';
import 'package:bingah/news_list_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Kelas untuk menampung data artikel berita
class NewsArticle {
  final String title;
  final String description;
  final String imageUrl;
  final String url;

  NewsArticle({
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.url,
  });
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<NewsArticle>> _newsFuture;

  String _displayName = 'Pengguna';

  final String _apiKey = '684a84d957fd4239aa08ce88cbc8f9db';

  @override
  void initState() {
    super.initState();
    _newsFuture = _fetchNews();
  }

  // Fungsi baru: Mengambil nama pengguna dari Firestore
  void _fetchUserName(String uid) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    if (doc.exists) {
      if (mounted) {
        setState(() {
          _displayName = doc.data()?['displayName'] ?? 'Pengguna';
        });
      }
    }
  }

  // Fungsi untuk mengambil data berita dari API nyata (sudah diperbaiki)
  Future<List<NewsArticle>> _fetchNews() async {
    final String query = 'Kesehatan "Indonesia"';
    final String url =
        'https://newsapi.org/v2/everything?q=$query&language=id&sortBy=publishedAt&apiKey=$_apiKey';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> articlesJson = data['articles'];

        return articlesJson.map((json) {
          return NewsArticle(
            title: json['title'] ?? 'Judul tidak tersedia',
            description: json['description'] ?? 'Deskripsi tidak tersedia',
            imageUrl: json['urlToImage'] ?? 'https://via.placeholder.com/150',
            url: json['url'] ?? '',
          );
        }).toList();
      } else {
        // Jangan throw exception, tapi return daftar kosong
        print('Gagal memuat berita. Status code: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Terjadi error saat mengambil berita: $e');
      return [];
    }
  }

  // Fungsi untuk membuka URL
  Future<void> _launchUrl(String url) async {
    print('Mencoba membuka URL: $url');
    if (!await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    )) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text('Pengguna tidak login.'));
    }

    _fetchUserName(user.uid);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipOval(
              child: Image.asset(
                'assets/images/icon_app.png',
                height: 120,
                width: 120,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'Selamat datang, $_displayName!',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onBackground,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Aplikasi Bingah siap membantu memantau tumbuh kembang anak Anda.',
              style: theme.textTheme.bodyLarge?.copyWith(color: bingahTextGrey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Berita Terbaru',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: bingahTextDark,
                ),
              ),
            ),
            const SizedBox(height: 16),

            FutureBuilder<List<NewsArticle>>(
              future: _newsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text('Gagal memuat berita: ${snapshot.error}'),
                  );
                } else if (snapshot.hasData) {
                  final articles = snapshot.data!;
                  return Column(
                    children: [
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: min(4, articles.length),
                        itemBuilder: (context, index) {
                          final article = articles[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            color: bingahWhite,
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: InkWell(
                              onTap: () => _launchUrl(article.url),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        article.imageUrl,
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return const Icon(
                                                Icons.image_not_supported,
                                                size: 80,
                                              );
                                            },
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            article.title,
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: bingahPrimaryGreen,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            article.description,
                                            style: theme.textTheme.bodySmall,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      if (articles.length > 4)
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    NewsListPage(allArticles: articles),
                              ),
                            );
                          },
                          child: Text(
                            'Lihat Semua',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  );
                } else {
                  return const Center(
                    child: Text('Tidak ada berita yang tersedia.'),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
