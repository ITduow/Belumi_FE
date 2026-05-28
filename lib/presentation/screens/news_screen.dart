import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/belumi_models.dart';
import '../../data/repositories/belumi_repository.dart';
import '../widgets/belumi_luxury.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key, required this.repository});

  final BelumiRepository repository;

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final _searchController = TextEditingController();
  String? _category;
  String _sort = 'newest';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<NewsArticle>> _loadNews() {
    return widget.repository.news(
      category: _category,
      search: _searchController.text,
      sort: _sort,
    );
  }

  bool _requireLogin() {
    if (widget.repository.isLoggedIn) return true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          belumiCopy(
            context,
          ).t('Vui lòng đăng nhập để tiếp tục.', 'Please login to continue.'),
        ),
      ),
    );
    context.go('/login');
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final copy = belumiCopy(context);
    return LuxuryPage(
      children: [
        LuxuryHero(
          title: copy.t('Tin tức làm đẹp', 'Beauty News'),
          subtitle: copy.t(
            'Cập nhật skincare, makeup, thành phần mỹ phẩm và xu hướng làm đẹp được Belumi chọn lọc.',
            'Curated skincare, makeup, ingredient and beauty trend stories from Belumi.',
          ),
          imageUrl:
              'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?auto=format&fit=crop&w=1200&q=80',
          actions: [
            LuxuryButton(
              label: copy.t('Tra cứu thành phần', 'Ingredient Lookup'),
              icon: Icons.document_scanner_outlined,
              onPressed: () => context.go('/ingredient-lookup'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _NewsFilters(
          repository: widget.repository,
          searchController: _searchController,
          selectedCategory: _category,
          selectedSort: _sort,
          onChanged: (category, sort) {
            setState(() {
              _category = category;
              _sort = sort;
            });
          },
          onSearch: () => setState(() {}),
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<NewsArticle>>(
          future: _loadNews(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LuxuryPanel(child: LinearProgressIndicator());
            }

            if (snapshot.hasError) {
              return LuxuryPanel(
                child: Text(
                  copy.t(
                    'Khong tai duoc tin tuc. Vui long kiem tra ket noi API.',
                    'Could not load news. Please check the API connection.',
                  ),
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            final posts = snapshot.data ?? const <NewsArticle>[];
            if (posts.isEmpty) {
              return LuxuryPanel(
                child: Text(
                  copy.t(
                    'Chưa có bài viết phù hợp.',
                    'No matching articles yet.',
                  ),
                ),
              );
            }

            return Column(
              children: posts
                  .map(
                    (post) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _NewsCard(
                        post: post,
                        saved: post.isSaved,
                        onTap: () => context.go('/news/${post.slug}'),
                        onSave: () async {
                          if (!_requireLogin()) return;
                          try {
                            await widget.repository.toggleSaveNews(post);
                            if (!context.mounted) return;
                            setState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  copy.t(
                                    'Đã cập nhật bài viết đã lưu.',
                                    'Saved articles updated.',
                                  ),
                                ),
                              ),
                            );
                          } catch (error) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(error.toString())),
                            );
                          }
                        },
                        onLike: () async {
                          if (!_requireLogin()) return;
                          try {
                            await widget.repository.likeNews(post);
                            if (context.mounted) setState(() {});
                          } catch (error) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(error.toString())),
                            );
                          }
                        },
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _NewsFilters extends StatelessWidget {
  const _NewsFilters({
    required this.repository,
    required this.searchController,
    required this.selectedCategory,
    required this.selectedSort,
    required this.onChanged,
    required this.onSearch,
  });

  final BelumiRepository repository;
  final TextEditingController searchController;
  final String? selectedCategory;
  final String selectedSort;
  final void Function(String?, String) onChanged;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final copy = belumiCopy(context);
    return LuxuryPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => onSearch(),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: copy.t('Tìm bài viết', 'Search articles'),
              suffixIcon: IconButton(
                onPressed: onSearch,
                icon: const Icon(Icons.arrow_forward),
              ),
            ),
          ),
          const SizedBox(height: 14),
          FutureBuilder<List<String>>(
            future: repository.newsCategories(),
            builder: (context, snapshot) {
              final categories =
                  snapshot.data ?? const <String>[];
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: Text(copy.t('Tất cả', 'All')),
                    selected: selectedCategory == null,
                    onSelected: (_) => onChanged(null, selectedSort),
                  ),
                  ...categories.map(
                    (category) => ChoiceChip(
                      label: Text(category),
                      selected: selectedCategory == category,
                      onSelected: (_) => onChanged(category, selectedSort),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: 'newest',
                label: Text(copy.t('Mới nhất', 'Newest')),
                icon: const Icon(Icons.trending_up),
              ),
              ButtonSegment(
                value: 'oldest',
                label: Text(copy.t('Cũ nhất', 'Oldest')),
                icon: const Icon(Icons.history),
              ),
              ButtonSegment(
                value: 'popular',
                label: Text(copy.t('Phổ biến', 'Popular')),
                icon: const Icon(Icons.visibility_outlined),
              ),
            ],
            selected: {selectedSort},
            onSelectionChanged: (value) =>
                onChanged(selectedCategory, value.first),
          ),
        ],
      ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  const _NewsCard({
    required this.post,
    required this.saved,
    required this.onTap,
    required this.onSave,
    required this.onLike,
  });

  final NewsArticle post;
  final bool saved;
  final VoidCallback onTap;
  final VoidCallback onSave;
  final VoidCallback onLike;

  @override
  Widget build(BuildContext context) {
    final date = post.publishedAt == null
        ? ''
        : '${post.publishedAt!.day}/${post.publishedAt!.month}/${post.publishedAt!.year}';
    return LuxuryPanel(
      padding: const EdgeInsets.all(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 96,
                height: 112,
                child: Image.network(
                  post.coverImageUrl ??
                      'https://images.unsplash.com/photo-1556228720-195a672e8a03?auto=format&fit=crop&w=600&q=80',
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Image.asset(
                    'assets/images/belumi_home_hero.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _MetaPill(label: post.category),
                      if (date.isNotEmpty) _MetaPill(label: date),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    post.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    post.summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: BelumiLuxury.muted),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 16,
                        color: BelumiLuxury.muted,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          post.author ?? 'Belumi Team',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                      Icon(
                        Icons.visibility_outlined,
                        size: 16,
                        color: BelumiLuxury.muted,
                      ),
                      const SizedBox(width: 3),
                      Text('${post.viewCount}'),
                      IconButton(
                        tooltip: 'Like',
                        onPressed: onLike,
                        icon: Icon(
                          post.isLiked ? Icons.favorite : Icons.favorite_border,
                          size: 19,
                        ),
                      ),
                      Text('${post.likeCount}'),
                      IconButton(
                        tooltip: 'Save',
                        onPressed: onSave,
                        icon: Icon(
                          saved ? Icons.bookmark : Icons.bookmark_border,
                          size: 20,
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
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: BelumiLuxury.peach,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: BelumiLuxury.ink,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
