import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/i18n/app_strings.dart';
import '../../data/models/belumi_models.dart';
import '../../data/repositories/belumi_repository.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key, required this.repository});

  final BelumiRepository repository;

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  String? _category;
  final String _sort = 'newest';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        setState(() {
          _isSearching = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<List<NewsArticle>> _loadNews() {
    return widget.repository.news(
      category: _category,
      search: _searchController.text,
      sort: _sort,
    );
  }

  double _getRating(NewsArticle article) {
    final hash = article.title.hashCode.abs();
    return 3.8 + (hash % 13) * 0.1;
  }

  int _getCommentCount(NewsArticle article) {
    final hash = article.title.hashCode.abs();
    return (hash % 25) + 5;
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header (Bảng tin)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (_isSearching) {
                          setState(() {
                            _isSearching = false;
                            _focusNode.unfocus();
                          });
                        } else {
                          context.go('/home');
                        }
                      },
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Color(0xFF816A5C),
                        size: 20,
                      ),
                    ),
                    Text(
                      isVi ? 'Bảng tin' : 'News',
                      style: GoogleFonts.monaSans(
                        color: const Color(0xFF976D48),
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Icon(
                      Icons.notifications_none_outlined,
                      color: Color(0xFF816A5C),
                      size: 24,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 2. Search Field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(9999),
                    border: Border.all(color: const Color(0xFFE6E1DC)),
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _focusNode,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (val) {
                      setState(() {
                        _isSearching = false;
                      });
                    },
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFFA19891),
                        size: 20,
                      ),
                      hintText: isVi ? 'Tìm bài viết' : 'Search articles',
                      hintStyle: GoogleFonts.monaSans(
                        color: const Color(0xFFA19891),
                        fontSize: 14,
                      ),
                      suffixIcon: _isSearching
                          ? GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                setState(() {
                                  _isSearching = false;
                                  _focusNode.unfocus();
                                });
                              },
                              child: const Icon(
                                Icons.cancel_rounded,
                                color: Color(0xFFA19891),
                                size: 18,
                              ),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 3. Conditional content (Suggestions or News List)
              Expanded(
                child: _isSearching ? _buildSearchSuggestions(isVi) : _buildNewsList(isVi),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Suggestions state (Image 2)
  Widget _buildSearchSuggestions(bool isVi) {
    final Map<String, List<String>> sections = {
      isVi ? '#1 tìm kiếm' : '#1 Search': ['Routine sáng', 'Mặt nạ thạch', 'Retinol'],
      'Blogger': ['Belumi', 'Elly Nguyen', 'Jullie Hg', 'Bbybgie'],
      'Makeup': ['Clean girl', 'Douyin', 'ABG', 'Strawberry Makeup'],
      isVi ? 'Kiến thức' : 'Skincare Knowledge': ['AHA', 'BHA', 'Retinol', 'Tretinol', 'Niacinamide'],
    };

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        Text(
          isVi ? 'Chủ đề' : 'Topics',
          style: GoogleFonts.monaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF3F2E1E),
          ),
        ),
        const SizedBox(height: 16),
        for (var entry in sections.entries) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 90,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      entry.key,
                      style: GoogleFonts.monaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF816A5C),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: entry.value.map((topic) {
                      return GestureDetector(
                        onTap: () {
                          _searchController.text = topic;
                          setState(() {
                            _isSearching = false;
                            _focusNode.unfocus();
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: const Color(0xFFE6E1DC)),
                          ),
                          child: Text(
                            topic,
                            style: GoogleFonts.monaSans(
                              fontSize: 12,
                              color: const Color(0xFF816A5C),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 4),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isVi ? 'Xem thêm' : 'See more',
                style: GoogleFonts.monaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF816A5C),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF816A5C),
                size: 16,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // News list state (Image 1)
  Widget _buildNewsList(bool isVi) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Chips Row
        SizedBox(
          height: 38,
          child: FutureBuilder<List<String>>(
            future: widget.repository.newsCategories(),
            builder: (context, snapshot) {
              final categories = snapshot.data ?? const <String>[];
              final allCategories = [isVi ? 'Tất cả' : 'All', ...categories];

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: allCategories.length,
                itemBuilder: (context, idx) {
                  final cat = allCategories[idx];
                  final isSelected = (idx == 0 && _category == null) || (_category == cat);

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _category = idx == 0 ? null : cat;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF976D48) : Colors.transparent,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF976D48) : const Color(0xFFE6E1DC),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            cat,
                            style: GoogleFonts.monaSans(
                              fontSize: 12,
                              color: isSelected ? Colors.white : const Color(0xFF816A5C),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 14),

        // Articles List View
        Expanded(
          child: FutureBuilder<List<NewsArticle>>(
            future: _loadNews(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    isVi ? 'Lỗi kết nối dữ liệu.' : 'Failed to load news.',
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }

              final posts = snapshot.data ?? const <NewsArticle>[];
              if (posts.isEmpty) {
                return Center(
                  child: Text(isVi ? 'Chưa có bài viết nào.' : 'No articles found.'),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index];
                  final rating = _getRating(post);
                  final comments = _getCommentCount(post);

                  if (index == 0) {
                    // Featured Card (Top)
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: GestureDetector(
                        onTap: () => context.go('/news/${post.slug}'),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE6E1DC)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                child: AspectRatio(
                                  aspectRatio: 16 / 9,
                                  child: Image.network(
                                    post.coverImageUrl ?? 'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?auto=format&fit=crop&w=600&q=80',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      post.title,
                                      style: GoogleFonts.monaSans(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF3F2E1E),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      post.summary,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.monaSans(
                                        fontSize: 11,
                                        color: const Color(0xFF816A5C),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            _buildStars(rating),
                                            const SizedBox(width: 6),
                                            Text(
                                              '${rating.toStringAsFixed(1)} • ${post.viewCount} lượt xem | $comments bình luận',
                                              style: GoogleFonts.monaSans(
                                                fontSize: 10,
                                                color: const Color(0xFF816A5C),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          width: 28,
                                          height: 28,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(color: const Color(0xFF976D48), width: 1.5),
                                          ),
                                          child: const Center(
                                            child: Icon(
                                              Icons.arrow_forward_rounded,
                                              size: 14,
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
                  }

                  // Standard Card (List Items)
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
                                width: 84,
                                height: 84,
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
                                      fontSize: 12,
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
                                          _buildStars(rating),
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
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(color: const Color(0xFF976D48), width: 1.5),
                                        ),
                                        child: const Center(
                                          child: Icon(
                                            Icons.arrow_forward_rounded,
                                            size: 12,
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
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
