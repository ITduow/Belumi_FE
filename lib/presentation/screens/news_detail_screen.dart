import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/i18n/app_strings.dart';
import '../../data/models/belumi_models.dart';
import '../../data/repositories/belumi_repository.dart';

class NewsDetailScreen extends StatefulWidget {
  const NewsDetailScreen({
    super.key,
    required this.repository,
    required this.slug,
  });

  final BelumiRepository repository;
  final String slug;

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  late Future<NewsArticle?> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.newsDetail(widget.slug);
  }

  double _getRating(NewsArticle article) {
    final hash = article.title.hashCode.abs();
    return 3.8 + (hash % 13) * 0.1;
  }

  Widget _buildStars(double rating) {
    List<Widget> stars = [];
    int fullStars = rating.floor();
    bool hasHalf = (rating - fullStars) >= 0.25;
    for (int i = 1; i <= 5; i++) {
      if (i <= fullStars) {
        stars.add(const Icon(Icons.star, color: Color(0xFFFFB300), size: 12));
      } else if (i == fullStars + 1 && hasHalf) {
        stars.add(const Icon(Icons.star_half, color: Color(0xFFFFB300), size: 12));
      } else {
        stars.add(const Icon(Icons.star_border, color: Color(0xFFCCCCCC), size: 12));
      }
    }
    return Row(mainAxisSize: MainAxisSize.min, children: stars);
  }

  @override
  Widget build(BuildContext context) {
    final locale = ProviderScope.containerOf(context).read(appLocaleProvider);
    final isVi = locale == 'vi';

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 402),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFF6F5F4),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.only(bottom: 35),
          child: FutureBuilder<NewsArticle?>(
            future: _future,
            builder: (context, snapshot) {
              final post = snapshot.data;
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (post == null) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isVi ? 'Không tìm thấy bài viết.' : 'Article not found.',
                        style: GoogleFonts.monaSans(fontSize: 16, color: const Color(0xFF816A5C)),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => context.go('/news'),
                        child: Text(isVi ? 'Quay lại' : 'Back'),
                      ),
                    ],
                  ),
                );
              }

              return ListView(
                padding: EdgeInsets.zero,
                children: [
                  // 1. Header with custom back, share and menu options
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => context.go('/news'),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Color(0xFF816A5C),
                            size: 20,
                          ),
                        ),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(isVi ? 'Đã sao chép liên kết chia sẻ!' : 'Link copied!')),
                                );
                              },
                              child: const Icon(
                                Icons.share_outlined,
                                color: Color(0xFF816A5C),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Icon(
                              Icons.more_horiz_rounded,
                              color: Color(0xFF816A5C),
                              size: 24,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 2. Hero cover image with floating title and category pill (Image 3)
                  AspectRatio(
                    aspectRatio: 16 / 10,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          post.coverImageUrl ?? 'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?auto=format&fit=crop&w=800&q=80',
                          fit: BoxFit.cover,
                        ),
                        // Dark overlay gradient
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black38,
                                Colors.black87,
                              ],
                            ),
                          ),
                        ),
                        // Overlay title and category tag
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.24),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: Colors.white30),
                                ),
                                child: Text(
                                  isVi ? 'Bí quyết chuyên gia' : 'Expert Advice',
                                  style: GoogleFonts.monaSans(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                post.title,
                                style: GoogleFonts.monaSans(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  height: 1.25,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 3. Author Section (Blogger)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 18,
                          backgroundImage: NetworkImage(
                            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=200&q=80',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post.author ?? 'Elly Nguyen',
                              style: GoogleFonts.monaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF3F2E1E),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isVi
                                  ? 'Đăng tải vào hôm nay lúc 11:40'
                                  : 'Published today at 11:40',
                              style: GoogleFonts.monaSans(
                                fontSize: 10,
                                color: const Color(0xFF816A5C),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Color(0xFFE6E1DC), indent: 16, endIndent: 16),

                  // 4. Content section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      post.content,
                      style: GoogleFonts.monaSans(
                        fontSize: 13,
                        color: const Color(0xFF3F2E1E),
                        height: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 5. Related articles section (Image 3)
                  _RelatedNews(
                    repository: widget.repository,
                    currentSlug: post.slug,
                    buildStars: _buildStars,
                    getRating: _getRating,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _RelatedNews extends StatelessWidget {
  const _RelatedNews({
    required this.repository,
    required this.currentSlug,
    required this.buildStars,
    required this.getRating,
  });

  final BelumiRepository repository;
  final String currentSlug;
  final Widget Function(double) buildStars;
  final double Function(NewsArticle) getRating;

  @override
  Widget build(BuildContext context) {
    final isVi = ProviderScope.containerOf(context).read(appLocaleProvider) == 'vi';

    return FutureBuilder<List<NewsArticle>>(
      future: repository.news(),
      builder: (context, snapshot) {
        final related = (snapshot.data ?? const <NewsArticle>[])
            .where((post) => post.slug != currentSlug)
            .take(3)
            .toList();

        if (related.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isVi ? 'Bài viết liên quan' : 'Related articles',
                style: GoogleFonts.monaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF3F2E1E),
                ),
              ),
              const SizedBox(height: 12),
              ...related.map((post) {
                final rating = getRating(post);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: () => context.go('/news/${post.slug}'),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE6E1DC)),
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              width: 74,
                              height: 74,
                              child: Image.network(
                                post.coverImageUrl ?? 'https://images.unsplash.com/photo-1556228720-195a672e8a03?auto=format&fit=crop&w=400&q=80',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF976D48).withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        post.category,
                                        style: GoogleFonts.monaSans(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF976D48),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  post.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.monaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF3F2E1E),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        buildStars(rating),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${rating.toStringAsFixed(1)} • ${post.viewCount} lượt xem',
                                          style: GoogleFonts.monaSans(
                                            fontSize: 9,
                                            color: const Color(0xFF816A5C),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: const Color(0xFF976D48), width: 1.5),
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.arrow_forward_rounded,
                                          size: 11,
                                          color: Color(0xFF976D48),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
