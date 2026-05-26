import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/belumi_models.dart';
import '../../data/repositories/belumi_repository.dart';
import '../widgets/belumi_luxury.dart';

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
  late Future<BlogPost?> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.newsDetail(widget.slug);
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
    return FutureBuilder<BlogPost?>(
      future: _future,
      builder: (context, snapshot) {
        final post = snapshot.data;
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LuxuryPage(
            children: [LuxuryPanel(child: LinearProgressIndicator())],
          );
        }

        if (post == null) {
          return LuxuryPage(
            children: [
              LuxuryPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      copy.t('Không tìm thấy bài viết.', 'Article not found.'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => context.go('/news'),
                      icon: const Icon(Icons.arrow_back),
                      label: Text(copy.t('Quay lại', 'Back')),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        final date = post.publishedAt == null
            ? ''
            : '${post.publishedAt!.day}/${post.publishedAt!.month}/${post.publishedAt!.year}';

        return LuxuryPage(
          maxWidth: 860,
          children: [
            OutlinedButton.icon(
              onPressed: () => context.go('/news'),
              icon: const Icon(Icons.arrow_back),
              label: Text(copy.t('Tin tức', 'News')),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  post.coverImageUrl ??
                      'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?auto=format&fit=crop&w=1200&q=80',
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Image.asset(
                    'assets/images/belumi_home_hero.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            LuxuryPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _DetailPill(
                        icon: Icons.category_outlined,
                        label: post.category,
                      ),
                      if (date.isNotEmpty)
                        _DetailPill(icon: Icons.event_outlined, label: date),
                      _DetailPill(
                        icon: Icons.visibility_outlined,
                        label: '${post.viewCount}',
                      ),
                      _DetailPill(
                        icon: Icons.favorite_border,
                        label: '${post.likeCount}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    post.title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: BelumiLuxury.black,
                      fontWeight: FontWeight.w900,
                      height: 1.08,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    post.summary,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: BelumiLuxury.muted,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '${copy.t('Tác giả', 'Author')}: ${post.author ?? 'Belumi Team'}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  if (post.tags.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: post.tags
                          .map((tag) => Chip(label: Text('#$tag')))
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Text(
                    post.content,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      height: 1.65,
                      color: BelumiLuxury.black,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      FilledButton.icon(
                        onPressed: () async {
                          if (!_requireLogin()) return;
                          try {
                            await widget.repository.likeNews(post);
                            if (mounted) {
                              setState(() {
                                _future = widget.repository.newsDetail(
                                  widget.slug,
                                );
                              });
                            }
                          } catch (error) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(error.toString())),
                            );
                          }
                        },
                        icon: Icon(
                          post.isLiked ? Icons.favorite : Icons.favorite_border,
                        ),
                        label: Text(copy.t('Thích bài viết', 'Like article')),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        onPressed: () async {
                          if (!_requireLogin()) return;
                          try {
                            await widget.repository.toggleSaveNews(post);
                            if (!context.mounted) return;
                            setState(() {
                              _future = widget.repository.newsDetail(
                                widget.slug,
                              );
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  copy.t('Đã lưu bài viết.', 'Article saved.'),
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
                        icon: Icon(
                          post.isSaved ? Icons.bookmark : Icons.bookmark_border,
                        ),
                        label: Text(copy.t('Lưu', 'Save')),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _RelatedNews(repository: widget.repository, currentSlug: post.slug),
          ],
        );
      },
    );
  }
}

class _RelatedNews extends StatelessWidget {
  const _RelatedNews({required this.repository, required this.currentSlug});

  final BelumiRepository repository;
  final String currentSlug;

  @override
  Widget build(BuildContext context) {
    final copy = belumiCopy(context);
    return FutureBuilder<List<BlogPost>>(
      future: repository.news(),
      builder: (context, snapshot) {
        final related = (snapshot.data ?? sampleBlogs)
            .where((post) => post.slug != currentSlug)
            .take(3)
            .toList();
        if (related.isEmpty) return const SizedBox.shrink();

        return LuxuryPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                copy.t('Bài viết liên quan', 'Related articles'),
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              ...related.map(
                (post) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.article_outlined),
                  title: Text(post.title),
                  subtitle: Text(post.category),
                  onTap: () => context.go('/news/${post.slug}'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DetailPill extends StatelessWidget {
  const _DetailPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: BelumiLuxury.peach,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: BelumiLuxury.ink),
            const SizedBox(width: 5),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}
