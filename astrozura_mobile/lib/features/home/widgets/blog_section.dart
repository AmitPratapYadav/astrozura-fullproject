import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/contants/api_constants.dart';
import '../../../core/services/api_client.dart';
import '../../web/in_app_web_page.dart';

class HomeBlogSection extends StatefulWidget {
  const HomeBlogSection({super.key});

  @override
  State<HomeBlogSection> createState() => _HomeBlogSectionState();
}

class _HomeBlogSectionState extends State<HomeBlogSection> {
  final ApiClient _api = ApiClient();
  List<_BlogSummary> _blogs = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final response = await _api.get(
        ApiConstants.blogs,
        query: const {'per_page': '4'},
      );
      final rawData = response['data'];
      final rawList = rawData is Map ? rawData['data'] : rawData;
      final blogs = rawList is List
          ? rawList
              .whereType<Map>()
              .map((item) => _BlogSummary.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .toList()
          : <_BlogSummary>[];
      if (!mounted) return;
      setState(() {
        _blogs = blogs;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _open(String title, String path) async {
    await InAppWebPage.open(
      context,
      title: title,
      pathOrUrl: path,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null || _blogs.isEmpty) return const SizedBox.shrink();

    return Container(
      color: const Color(0xFF17102F),
      padding: const EdgeInsets.symmetric(vertical: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Cosmic Reads',
                    style: GoogleFonts.playfairDisplay(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => _open('Blogs', '/blogs'),
                  child: const Text(
                    'View More',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 330,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _blogs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final blog = _blogs[index];
                return SizedBox(
                  width: 260,
                  child: Material(
                    color: const Color(0xFF2B164A),
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => _open(blog.title, '/blogs/${blog.slug}'),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: SizedBox(
                                height: 128,
                                width: double.infinity,
                                child: blog.coverImage.isEmpty
                                    ? const ColoredBox(
                                        color: Color(0xFF1E3557),
                                        child: Center(
                                          child: Text(
                                            'AZ',
                                            style: TextStyle(
                                              color: Color(0xFFD4A73C),
                                              fontSize: 38,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                      )
                                    : Image.network(
                                        blog.coverImage,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const ColoredBox(
                                          color: Color(0xFF1E3557),
                                          child: Center(
                                            child: Text(
                                              'AZ',
                                              style: TextStyle(
                                                color: Color(0xFFD4A73C),
                                                fontSize: 38,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              blog.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              blog.excerpt,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                            const Spacer(),
                            SizedBox(
                              width: double.infinity,
                              height: 38,
                              child: ElevatedButton(
                                onPressed: () =>
                                    _open(blog.title, '/blogs/${blog.slug}'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFD4A73C),
                                  foregroundColor: const Color(0xFF1E3557),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                child: const Text(
                                  'Read More',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BlogSummary {
  final String title;
  final String slug;
  final String excerpt;
  final String coverImage;

  const _BlogSummary({
    required this.title,
    required this.slug,
    required this.excerpt,
    required this.coverImage,
  });

  factory _BlogSummary.fromJson(Map<String, dynamic> json) {
    return _BlogSummary(
      title: json['title']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      excerpt: json['excerpt']?.toString() ?? '',
      coverImage: ApiConstants.storageUrl(
        json['cover_image']?.toString() ?? '',
      ),
    );
  }
}
