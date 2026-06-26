import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/belumi_models.dart';
import '../../../data/repositories/belumi_repository.dart';
import '../../../presentation/widgets/belumi_luxury.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/app_user.dart';
import '../../onboarding/onboarding_quiz_sheet.dart';

class HomeScreenV2 extends ConsumerStatefulWidget {
  const HomeScreenV2({super.key, required this.repository});

  final BelumiRepository repository;

  static const _ink = Color(0xFF4B3328);
  static const _espresso = Color(0xFF6A4634);
  static const _caramel = Color(0xFFC9965D);
  static const _tan = Color(0xFFDAB58E);
  static const _sand = Color(0xFFE7D8C6);
  static const _paper = Color(0xFFFFFAF4);
  static const _cream = Color(0xFFF6EDE4);
  static const _muted = Color(0xFF816A5C);

  @override
  ConsumerState<HomeScreenV2> createState() => _HomeScreenV2State();
}

class _HomeScreenV2State extends ConsumerState<HomeScreenV2> {
  int _refreshKey = 0;

  /// Flag để tránh hiện quiz nhiều lần trong cùng 1 session.
  bool _quizCheckedForSession = false;

  @override
  void initState() {
    super.initState();
    // Kiểm tra quiz sau frame đầu tiên (user có thể đã đăng nhập sẵn)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowQuiz(ref.read(authControllerProvider).valueOrNull);
    });
  }

  /// Kiểm tra và hiện quiz nếu user chưa hoàn thành.
  Future<void> _maybeShowQuiz(AppUser? user) async {
    if (user == null || _quizCheckedForSession) return;
    _quizCheckedForSession = true;
    try {
      final completed = await widget.repository.getQuizStatus();
      if (!completed && mounted) {
        await showOnboardingQuiz(context, repository: widget.repository);
      }
    } catch (_) {
      // Quiz check thất bại → không block user
    }
  }

  Future<void> _handleRefresh() async {
    try {
      await ref.read(authControllerProvider.notifier).restoreSession();
    } catch (_) {}
    if (mounted) {
      setState(() {
        _refreshKey++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen auth state: khi user thay đổi (login/register) → check quiz
    ref.listen(authControllerProvider, (prev, next) {
      final prevUser = prev?.valueOrNull;
      final nextUser = next.valueOrNull;
      // Chỉ trigger khi user mới login (từ null → có user)
      if (prevUser == null && nextUser != null) {
        _quizCheckedForSession = false; // reset để check lại
        _maybeShowQuiz(nextUser);
      }
    });

    return FutureBuilder(
      key: ValueKey(_refreshKey),
      future: Future.wait([widget.repository.products(), widget.repository.news()]),
      builder: (context, snapshot) {
        final products = snapshot.hasData
            ? snapshot.data![0] as List<Product>
            : sampleProducts;
        final news = snapshot.hasData
            ? snapshot.data![1] as List<NewsArticle>
            : const <NewsArticle>[];

        return DecoratedBox(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topLeft,
              radius: 1.35,
              colors: [Color(0xFFF3E8DD), Color(0xFFFFFAF4)],
            ),
          ),
          child: RefreshIndicator(
            onRefresh: _handleRefresh,
            color: HomeScreenV2._ink,
            backgroundColor: HomeScreenV2._paper,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 34),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1040),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _LuxuryHero(planCode: widget.repository.currentPlan),
                        const SizedBox(height: 26),
                        const _BeautyStartSection(),
                        const SizedBox(height: 28),
                        const _ServicesSection(),
                        const SizedBox(height: 28),
                        _ProductLaunchSection(products: products),
                        const SizedBox(height: 28),
                        const _TransformationSection(),
                        const SizedBox(height: 28),
                        _CatalogueSection(products: products),
                        const SizedBox(height: 28),
                        _NewsAndReviewsSection(news: news),
                        const SizedBox(height: 28),
                        const _HomeFooter(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LuxuryHero extends StatelessWidget {
  const _LuxuryHero({required this.planCode});

  final String planCode;

  @override
  Widget build(BuildContext context) {
    final t = belumiCopy(context).t;
    final isWide = MediaQuery.sizeOf(context).width >= 760;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: AspectRatio(
        aspectRatio: isWide ? 1.95 : 0.78,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/belumi_home_hero.jpg',
              fit: BoxFit.cover,
              alignment: isWide ? Alignment.centerRight : Alignment.topCenter,
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xE06A4634),
                    Color(0xB58A604D),
                    Color(0x2BF6EDE4),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(isWide ? 28 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _HeroPills(),
                  const Spacer(),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: isWide ? 440 : 310),
                    child: Text(
                      t(
                        'Chuyên gia làm đẹp AI của riêng bạn',
                        'Transform Your Look with Expert Beauty AI',
                      ),
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(
                            color: Colors.white,
                            height: 1.02,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: Text(
                      t(
                        'BeautyCenter cho skincare, tra cứu thành phần, trang điểm ảo và routine cá nhân hóa.',
                        'BeautyCenter for skincare, ingredient lookup, virtual makeup and personalized routines.',
                      ),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.88),
                        height: 1.45,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _DarkButton(
                        icon: Icons.auto_awesome,
                        label: 'Skin AI',
                        onTap: () => context.go('/skincare-ai'),
                      ),
                      _GhostButton(
                        icon: Icons.document_scanner_outlined,
                        label: t('Thành phần', 'Ingredients'),
                        onTap: () => context.go('/ingredient-lookup'),
                      ),
                      _GhostButton(
                        icon: Icons.face_retouching_natural,
                        label: t('Makeup', 'Makeup'),
                        onTap: () => context.go('/virtual-makeup'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _HeroBottomBar(planCode: planCode),
                ],
              ),
            ),
            Positioned(
              right: isWide ? 24 : 14,
              top: isWide ? 112 : 92,
              child: const _RoundPlayChip(),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroPills extends StatelessWidget {
  const _HeroPills();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _TopPill(
          label: belumiCopy(context).t('Trang chủ', 'Home'),
          selected: true,
          onTap: () => context.go('/home'),
        ),
        _TopPill(
          label: belumiCopy(context).t('Gói', 'Plans'),
          onTap: () => context.go('/pricing'),
        ),
        _TopPill(label: 'Skin AI', onTap: () => context.go('/skincare-ai')),
        _TopPill(
          label: belumiCopy(context).t('BeautyCenter', 'BeautyCenter'),
          onTap: () => context.go('/about'),
        ),
      ],
    );
  }
}

class _HeroBottomBar extends StatelessWidget {
  const _HeroBottomBar({required this.planCode});

  final String planCode;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _MiniMetric(
          icon: Icons.workspace_premium,
          label: belumiCopy(context).t('Gói', 'Plan'),
          value: planCode.toUpperCase(),
        ),
        const _MiniMetric(
          icon: Icons.auto_awesome,
          label: 'AI Score',
          value: '94%',
        ),
        _MiniMetric(
          icon: Icons.favorite,
          label: belumiCopy(context).t('Yêu thích', 'Wishlist'),
          value: belumiCopy(context).t('Đã chọn lọc', 'Curated'),
        ),
      ],
    );
  }
}

class _BeautyStartSection extends StatelessWidget {
  const _BeautyStartSection();

  @override
  Widget build(BuildContext context) {
    return _WhitePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            eyebrow: belumiCopy(context).t('Hồ sơ làm đẹp', 'Beauty profile'),
            title: belumiCopy(context).t(
              'Hành trình làm đẹp bắt đầu tại đây',
              'Your Beauty And Success Start Here',
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 720;
              final first = _ImageFeatureCard(
                route: '/skincare-ai',
                imageUrl:
                    'https://images.unsplash.com/photo-1616683693504-3ea7e9ad6fec?auto=format&fit=crop&w=900&q=80',
                title: 'Skincare AI',
                subtitle: belumiCopy(context).t(
                  'Phân tích da, gợi ý routine sáng và tối.',
                  'Analyze skin and suggest morning and night routines.',
                ),
              );
              final second = _SoftTextureCard(
                onTap: () => context.go('/ingredient-lookup'),
              );
              final third = _ImageFeatureCard(
                route: '/virtual-makeup',
                imageUrl:
                    'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?auto=format&fit=crop&w=900&q=80',
                title: belumiCopy(context).t(
                  'Khám phá tiềm năng vẻ đẹp',
                  'Discover Your Beauty Potential',
                ),
                subtitle: belumiCopy(context).t(
                  'Makeup theo tone da và dịp sử dụng.',
                  'Makeup by skin tone and occasion.',
                ),
              );

              if (!isWide) {
                return Column(
                  children: [
                    first,
                    const SizedBox(height: 12),
                    second,
                    const SizedBox(height: 12),
                    third,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: first),
                  const SizedBox(width: 12),
                  Expanded(child: second),
                  const SizedBox(width: 12),
                  Expanded(flex: 2, child: third),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ServicesSection extends StatelessWidget {
  const _ServicesSection();

  @override
  Widget build(BuildContext context) {
    final t = belumiCopy(context).t;
    const services = [
      _ServiceItem('Face AI', 'Deep scan and routine', Icons.auto_awesome),
      _ServiceItem('Ingredients', 'OCR label lookup', Icons.document_scanner),
      _ServiceItem(
        'Makeup',
        'Tone and occasion advice',
        Icons.palette_outlined,
      ),
    ];

    return _WhitePanel(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 760;
          final list = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionTitle(
                eyebrow: t('Dịch vụ', 'Services'),
                title: t('Dịch vụ Belumi cung cấp', 'Service We Provide'),
              ),
              const SizedBox(height: 14),
              ...services.map((item) => _ServiceRow(item: item)),
              const SizedBox(height: 12),
              _OutlineTinyButton(
                label: t('Xem dịch vụ', 'View Services'),
                onTap: () => context.go('/skincare-ai'),
              ),
            ],
          );

          final visuals = Row(
            children: [
              Expanded(
                flex: 3,
                child: _ImageFeatureCard(
                  route: '/virtual-makeup',
                  imageUrl:
                      'https://images.unsplash.com/photo-1509967419530-da38b4704bc6?auto=format&fit=crop&w=900&q=80',
                  title: t('Tiếp cận toàn diện', 'Holistic Approach'),
                  subtitle: t(
                    'Makeup, skincare và gợi ý sản phẩm trong một flow.',
                    'Makeup, skincare and product advice in one flow.',
                  ),
                  dark: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: _ImageTile(
                  imageUrl:
                      'https://images.unsplash.com/photo-1608248597279-f99d160bfcbc?auto=format&fit=crop&w=700&q=80',
                  height: 180,
                ),
              ),
            ],
          );

          if (!isWide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [list, const SizedBox(height: 18), visuals],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: list),
              const SizedBox(width: 18),
              Expanded(flex: 4, child: visuals),
            ],
          );
        },
      ),
    );
  }
}

class _ProductLaunchSection extends StatelessWidget {
  const _ProductLaunchSection({required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    final t = belumiCopy(context).t;
    final product = products.isNotEmpty ? products.first : sampleProducts.first;

    return _WhitePanel(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 760;
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionTitle(
                eyebrow: t('Sản phẩm mới', 'Latest Product Launch'),
                title: t('Đã có sẵn!', 'Available Now!'),
              ),
              const SizedBox(height: 10),
              Text(
                t(
                  'AI chọn sản phẩm phù hợp với loại da, routine và wishlist của bạn.',
                  'AI selects products that fit your skin type, routine and wishlist.',
                ),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: HomeScreenV2._muted,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _SmallCategory(
                    label: t('Kem dưỡng', 'Cream'),
                    selected: true,
                  ),
                  const _SmallCategory(label: 'Serum'),
                  const _SmallCategory(label: 'Makeup'),
                  _SmallCategory(label: t('Sữa rửa mặt', 'Cleanser')),
                ],
              ),
            ],
          );

          final productCard = _CircularProduct(product: product);

          if (!isWide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [copy, const SizedBox(height: 18), productCard],
            );
          }

          return Row(
            children: [
              Expanded(flex: 2, child: copy),
              const SizedBox(width: 24),
              Expanded(flex: 3, child: productCard),
            ],
          );
        },
      ),
    );
  }
}

class _TransformationSection extends StatelessWidget {
  const _TransformationSection();

  @override
  Widget build(BuildContext context) {
    final t = belumiCopy(context).t;
    return _WhitePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _SectionTitle(
                  eyebrow: t('Độc quyền Belumi', 'Exclusive Beauty'),
                  title: t('Sẵn sàng biến hóa', 'Transformation Awaits'),
                ),
              ),
              _OutlineTinyButton(
                label: t('Thêm dịch vụ', 'More Services'),
                onTap: () => context.go('/virtual-makeup'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 210,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                SizedBox(
                  width: 420,
                  child: _ImageFeatureCard(
                    route: '/virtual-makeup',
                    imageUrl:
                        'https://images.unsplash.com/photo-1487412947147-5cebf100ffc2?auto=format&fit=crop&w=1000&q=80',
                    title: t('Trang điểm ảo', 'Virtual Makeup'),
                    subtitle: t(
                      'Thử makeup look mới trước khi mua sản phẩm.',
                      'Try a new makeup look before buying products.',
                    ),
                    dark: true,
                  ),
                ),
                const SizedBox(width: 12),
                const _ImageTile(
                  imageUrl:
                      'https://images.unsplash.com/photo-1596462502278-27bfdc403348?auto=format&fit=crop&w=700&q=80',
                  width: 170,
                  height: 210,
                ),
                SizedBox(width: 12),
                _ImageTile(
                  imageUrl:
                      'https://images.unsplash.com/photo-1508214751196-bcfd4ca60f91?auto=format&fit=crop&w=700&q=80',
                  width: 170,
                  height: 210,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CatalogueSection extends StatelessWidget {
  const _CatalogueSection({required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    final t = belumiCopy(context).t;
    final items = products.take(3).toList();
    final displayItems = items.isEmpty
        ? sampleProducts.take(3).toList()
        : items;

    return _WhitePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _SectionTitle(
                  eyebrow: t('Danh mục làm đẹp', 'Beauty Catalogue'),
                  title: t(
                    'Trải nghiệm tinh chất làm đẹp',
                    'Experience The Beauty Essence',
                  ),
                ),
              ),
              _OutlineTinyButton(
                label: t('Xem thêm', 'Read More'),
                onTap: () => context.go('/wishlist'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 780;
              if (!isWide) {
                return Column(
                  children: displayItems
                      .map(
                        (product) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _CatalogueCard(product: product),
                        ),
                      )
                      .toList(),
                );
              }
              return Row(
                children: displayItems
                    .map(
                      (product) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: _CatalogueCard(product: product),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _NewsAndReviewsSection extends StatelessWidget {
  const _NewsAndReviewsSection({required this.news});

  final List<NewsArticle> news;

  @override
  Widget build(BuildContext context) {
    final t = belumiCopy(context).t;
    final posts = news.take(4).toList();

    return _WhitePanel(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 760;
          final intro = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionTitle(
                eyebrow: t('Đánh giá nổi bật', 'Glowing Reviews'),
                title: t('Câu chuyện làm đẹp', 'Beauty Stories'),
              ),
              const SizedBox(height: 8),
              Text(
                t(
                  'Tin làm đẹp, routine và feedback được chọn lọc cho cộng đồng Belumi.',
                  'Beauty news, routines and feedback curated for the Belumi community.',
                ),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: HomeScreenV2._muted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              _AvatarCloud(),
              const SizedBox(height: 14),
              _OutlineTinyButton(
                label: t('Tin tức', 'News'),
                onTap: () => context.go('/news'),
              ),
            ],
          );

          final cards = Wrap(
            spacing: 12,
            runSpacing: 12,
            children: posts.isEmpty
                ? [
                    _ReviewCard(
                      title: t(
                        'Routine cuối cùng cũng thật sự cá nhân hóa.',
                        'Routine that finally feels personal.',
                      ),
                      author: t('Người dùng Belumi', 'Belumi user'),
                    ),
                    _ReviewCard(
                      title: t(
                        'Quét thành phần giúp tôi mua sắm tự tin hơn.',
                        'Ingredient scan helps me buy with confidence.',
                      ),
                      author: t('Người yêu skincare', 'Skincare lover'),
                    ),
                  ]
                : posts
                      .map(
                        (post) => _ReviewCard(
                          title: post.title,
                          author: post.author ?? 'Belumi',
                        ),
                      )
                      .toList(),
          );

          if (!isWide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [intro, const SizedBox(height: 18), cards],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: intro),
              const SizedBox(width: 20),
              Expanded(flex: 4, child: cards),
            ],
          );
        },
      ),
    );
  }
}

class _WhitePanel extends StatelessWidget {
  const _WhitePanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: HomeScreenV2._paper.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: HomeScreenV2._sand.withValues(alpha: 0.72)),
        boxShadow: [
          BoxShadow(
            color: HomeScreenV2._espresso.withValues(alpha: 0.12),
            blurRadius: 26,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.eyebrow, required this.title});

  final String eyebrow;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: HomeScreenV2._muted,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: HomeScreenV2._ink,
            height: 1.05,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _ImageFeatureCard extends StatelessWidget {
  const _ImageFeatureCard({
    required this.route,
    required this.imageUrl,
    required this.title,
    required this.subtitle,
    this.dark = false,
  });

  final String route;
  final String imageUrl;
  final String title;
  final String subtitle;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => context.go(route),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 180,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _NetworkPhoto(imageUrl: imageUrl),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: dark ? 0.58 : 0.42),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Positioned(
                right: 12,
                top: 12,
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.arrow_outward,
                    size: 15,
                    color: HomeScreenV2._ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SoftTextureCard extends StatelessWidget {
  const _SoftTextureCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              HomeScreenV2._cream,
              HomeScreenV2._tan,
              HomeScreenV2._caramel,
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              bottom: -12,
              child: Icon(
                Icons.spa_outlined,
                size: 126,
                color: Colors.white.withValues(alpha: 0.66),
              ),
            ),
            Positioned(
              left: 16,
              top: 16,
              child: Text(
                belumiCopy(
                  context,
                ).t('Tra cứu\nthành phần', 'Ingredient\nLookup'),
                style: TextStyle(
                  color: HomeScreenV2._ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceRow extends StatelessWidget {
  const _ServiceRow({required this.item});

  final _ServiceItem item;

  @override
  Widget build(BuildContext context) {
    final t = belumiCopy(context).t;
    final displayTitle = switch (item.title) {
      'Face AI' => t('Phân tích da AI', 'Face AI'),
      'Ingredients' => t('Thành phần', 'Ingredients'),
      'Makeup' => t('Trang điểm', 'Makeup'),
      _ => item.title,
    };
    final displaySubtitle = switch (item.title) {
      'Face AI' => t('Quét sâu và routine cá nhân', 'Deep scan and routine'),
      'Ingredients' => t('Quét OCR nhãn sản phẩm', 'OCR label lookup'),
      'Makeup' => t('Tư vấn tone da và dịp dùng', 'Tone and occasion advice'),
      _ => item.subtitle,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () {
          final route = item.title == 'Face AI'
              ? '/skincare-ai'
              : item.title == 'Ingredients'
              ? '/ingredient-lookup'
              : '/virtual-makeup';
          context.go(route);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: HomeScreenV2._sand),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 13,
                backgroundColor: HomeScreenV2._ink,
                child: Icon(item.icon, size: 14, color: Colors.white),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayTitle,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      displaySubtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: HomeScreenV2._muted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward, size: 15),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircularProduct extends StatelessWidget {
  const _CircularProduct({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: HomeScreenV2._sand),
              ),
              padding: const EdgeInsets.all(16),
              child: ClipOval(
                child: product.thumbnailUrl == null
                    ? Image.asset(
                        'assets/images/belumi_home_hero.jpg',
                        fit: BoxFit.cover,
                      )
                    : Image.network(
                        product.thumbnailUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Image.asset(
                          'assets/images/belumi_home_hero.jpg',
                          fit: BoxFit.cover,
                        ),
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                '${product.price.toStringAsFixed(0)} VND',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              _OutlineTinyButton(
                label: belumiCopy(context).t('Thêm vào giỏ', 'Add to Cart'),
                onTap: () => context.go('/wishlist'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CatalogueCard extends StatelessWidget {
  const _CatalogueCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: HomeScreenV2._cream,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HomeScreenV2._sand),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 132,
              width: double.infinity,
              child: product.thumbnailUrl == null
                  ? const _NetworkPhoto(
                      imageUrl:
                          'https://images.unsplash.com/photo-1556228720-195a672e8a03?auto=format&fit=crop&w=700&q=80',
                    )
                  : Image.network(
                      product.thumbnailUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const _NetworkPhoto(
                        imageUrl:
                            'https://images.unsplash.com/photo-1556228720-195a672e8a03?auto=format&fit=crop&w=700&q=80',
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            product.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${product.price.toStringAsFixed(0)} VND',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: HomeScreenV2._muted),
                ),
              ),
              const CircleAvatar(
                radius: 12,
                backgroundColor: HomeScreenV2._ink,
                child: Icon(Icons.add, size: 14, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.title, required this.author});

  final String title;
  final String author;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 210,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: HomeScreenV2._cream,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: HomeScreenV2._sand),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: HomeScreenV2._ink,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const CircleAvatar(
                  radius: 15,
                  backgroundImage: NetworkImage(
                    'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=120&q=80',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageTile extends StatelessWidget {
  const _ImageTile({required this.imageUrl, this.width, this.height = 180});

  final String imageUrl;
  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: width,
        height: height,
        child: _NetworkPhoto(imageUrl: imageUrl),
      ),
    );
  }
}

class _NetworkPhoto extends StatelessWidget {
  const _NetworkPhoto({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [HomeScreenV2._cream, HomeScreenV2._caramel],
          ),
        ),
        child: const Icon(Icons.spa_outlined, color: Colors.white, size: 42),
      ),
    );
  }
}

class _TopPill extends StatelessWidget {
  const _TopPill({
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? HomeScreenV2._ink : Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _SmallCategory extends StatelessWidget {
  const _SmallCategory({required this.label, this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? HomeScreenV2._ink : HomeScreenV2._paper,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: HomeScreenV2._sand),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : HomeScreenV2._ink,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DarkButton extends StatelessWidget {
  const _DarkButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: HomeScreenV2._ink,
        foregroundColor: Colors.white,
        visualDensity: VisualDensity.compact,
      ),
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
    );
  }
}

class _GhostButton extends StatelessWidget {
  const _GhostButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: Colors.white.withValues(alpha: 0.55)),
        visualDensity: VisualDensity.compact,
      ),
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
    );
  }
}

class _OutlineTinyButton extends StatelessWidget {
  const _OutlineTinyButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: HomeScreenV2._ink,
        side: const BorderSide(color: HomeScreenV2._sand),
        visualDensity: VisualDensity.compact,
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
      ),
      onPressed: onTap,
      child: Text(label),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.26)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            '$label: $value',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundPlayChip extends StatelessWidget {
  const _RoundPlayChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.32)),
      ),
      child: const Icon(Icons.play_arrow_rounded, color: Colors.white),
    );
  }
}

class _AvatarCloud extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const urls = [
      'https://images.unsplash.com/photo-1531123897727-8f129e1688ce?auto=format&fit=crop&w=120&q=80',
      'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=120&q=80',
      'https://images.unsplash.com/photo-1502823403499-6ccfcf4fb453?auto=format&fit=crop&w=120&q=80',
    ];

    return SizedBox(
      height: 36,
      width: 112,
      child: Stack(
        children: [
          for (var i = 0; i < urls.length; i++)
            Positioned(
              left: i * 24,
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 16,
                  backgroundImage: NetworkImage(urls[i]),
                ),
              ),
            ),
          const Positioned(
            left: 72,
            child: CircleAvatar(
              radius: 18,
              backgroundColor: HomeScreenV2._ink,
              child: Icon(Icons.arrow_forward, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeFooter extends StatelessWidget {
  const _HomeFooter();

  @override
  Widget build(BuildContext context) {
    final t = belumiCopy(context).t;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              t(
                'BeautyCenter\nAI và tư vấn làm đẹp cá nhân hóa.',
                'BeautyCenter\nAI and personalized beauty consultation.',
              ),
              style: const TextStyle(
                color: HomeScreenV2._ink,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
          ),
          IconButton(
            tooltip: t('Bảng giá', 'Pricing'),
            onPressed: () => context.go('/pricing'),
            icon: const Icon(Icons.workspace_premium_outlined),
          ),
          IconButton(
            tooltip: t('Yêu thích', 'Wishlist'),
            onPressed: () => context.go('/wishlist'),
            icon: const Icon(Icons.favorite_border),
          ),
        ],
      ),
    );
  }
}

class _ServiceItem {
  const _ServiceItem(this.title, this.subtitle, this.icon);

  final String title;
  final String subtitle;
  final IconData icon;
}
