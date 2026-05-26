import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/belumi_models.dart';
import '../../data/repositories/belumi_repository.dart';
import '../widgets/belumi_luxury.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key, required this.repository});

  final BelumiRepository repository;

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  late Future<List<Product>> future = widget.repository.wishlist();

  void refresh() {
    setState(() => future = widget.repository.wishlist());
  }

  @override
  Widget build(BuildContext context) {
    final t = belumiCopy(context).t;
    return FutureBuilder<List<Product>>(
      future: future,
      builder: (context, snapshot) {
        final products = snapshot.data ?? const <Product>[];
        return LuxuryPage(
          children: [
            LuxuryHero(
              title: t('Danh sách yêu thích', 'Your Beauty Wishlist'),
              subtitle: t(
                'Lưu sản phẩm yêu thích, so sánh routine và quay lại khi bạn sẵn sàng.',
                'Save favorite products, compare routines and come back when you are ready.',
              ),
              imageUrl:
                  'https://images.unsplash.com/photo-1556228720-195a672e8a03?auto=format&fit=crop&w=1200&q=80',
            ),
            const SizedBox(height: 18),
            LuxuryInfoTile(
              icon: Icons.favorite,
              title: widget.repository.isLoggedIn
                  ? t('Wishlist đã đồng bộ', 'Wishlist synced')
                  : t('Wishlist cục bộ', 'Local wishlist'),
              subtitle: widget.repository.isLoggedIn
                  ? t(
                      'Đang đồng bộ qua API với token hiện tại.',
                      'Syncing through the API with the current token.',
                    )
                  : t(
                      'Chưa đăng nhập: tạm lưu trên máy, đăng nhập để đồng bộ.',
                      'Not signed in: saved locally, sign in to sync.',
                    ),
            ),
            const SizedBox(height: 16),
            if (products.isEmpty)
              LuxuryPanel(
                child: Column(
                  children: [
                    const Icon(Icons.favorite_border, size: 48),
                    const SizedBox(height: 10),
                    Text(t('Wishlist đang trống', 'Your wishlist is empty')),
                    const SizedBox(height: 10),
                    LuxuryButton(
                      label: t('Thêm sản phẩm mẫu', 'Add sample product'),
                      icon: Icons.add,
                      onPressed: () async {
                        final all = await widget.repository.products();
                        if (all.isNotEmpty) {
                          await widget.repository.addWishlist(all.first);
                          refresh();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ...products.map(
              (product) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: LuxuryPanel(
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    leading: const Icon(Icons.favorite),
                    title: Text(product.name),
                    subtitle: Text('${product.price.toStringAsFixed(0)} VND'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        await widget.repository.removeWishlist(product);
                        refresh();
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            LuxuryHeader(
              eyebrow: 'Belumi News',
              title: t('Bài viết đã lưu', 'Saved articles'),
              subtitle: t(
                'Các bài tin tức bạn đã bookmark sẽ được đồng bộ theo tài khoản.',
                'Bookmarked news articles are synced with your account.',
              ),
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<BlogPost>>(
              future: widget.repository.isLoggedIn
                  ? widget.repository.savedNews()
                  : Future.value(const <BlogPost>[]),
              builder: (context, newsSnapshot) {
                final posts = newsSnapshot.data ?? const <BlogPost>[];
                if (newsSnapshot.connectionState == ConnectionState.waiting) {
                  return const LuxuryPanel(child: LinearProgressIndicator());
                }
                if (newsSnapshot.hasError) {
                  return LuxuryPanel(
                    child: Text(
                      t(
                        'Không tải được bài viết đã lưu.',
                        'Could not load saved articles.',
                      ),
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }
                if (posts.isEmpty) {
                  return LuxuryPanel(
                    child: Text(
                      widget.repository.isLoggedIn
                          ? t(
                              'Chưa có bài viết đã lưu.',
                              'No saved articles yet.',
                            )
                          : t(
                              'Đăng nhập để xem bài viết đã lưu.',
                              'Login to view saved articles.',
                            ),
                    ),
                  );
                }
                return Column(
                  children: posts
                      .map(
                        (post) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: LuxuryPanel(
                            padding: EdgeInsets.zero,
                            child: ListTile(
                              leading: const Icon(Icons.bookmark),
                              title: Text(post.title),
                              subtitle: Text(post.category),
                              onTap: () => context.go('/news/${post.slug}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () async {
                                  await widget.repository.toggleSaveNews(post);
                                  refresh();
                                },
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
