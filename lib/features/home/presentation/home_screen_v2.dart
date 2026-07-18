import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/i18n/app_strings.dart';
import '../../../data/models/belumi_models.dart';
import '../../../data/repositories/belumi_repository.dart';

import '../../auth/application/auth_controller.dart';
import '../../auth/domain/app_user.dart';
import '../../onboarding/onboarding_quiz_sheet.dart';
import '../../../presentation/screens/skin_analysis_screen.dart';

// ─────────────────────────────────────────────
// Design Tokens
// ─────────────────────────────────────────────
class _T {
  _T._();
  static const canvas = Color(0xFFF6F5F4);
  static const ink = Color(0xFF4B3228);
  static const muted = Color(0xFF816A5C);
  static const sand = Color(0xFFE7D8C6);
  static const cream = Color(0xFFF6EDE4);
  static const paper = Color(0xFFFFFAF4);
  static const accent = Color(0xFFC9965D);
  static const espresso = Color(0xFF6A4634);
  static const radius = 16.0;
}

// ═════════════════════════════════════════════
// HOME SCREEN V2
// ═════════════════════════════════════════════
class HomeScreenV2 extends ConsumerStatefulWidget {
  const HomeScreenV2({super.key, required this.repository});

  final BelumiRepository repository;

  @override
  ConsumerState<HomeScreenV2> createState() => _HomeScreenV2State();
}

class _HomeScreenV2State extends ConsumerState<HomeScreenV2> {
  int _refreshKey = 0;
  bool _quizCheckedForSession = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowQuiz(ref.read(authControllerProvider).valueOrNull);
    });
  }

  Future<void> _maybeShowQuiz(AppUser? user) async {
    if (user == null || _quizCheckedForSession) return;
    _quizCheckedForSession = true;
    try {
      final completed = await widget.repository.getQuizStatus();
      if (!completed && mounted) {
        await showOnboardingQuiz(context, repository: widget.repository);
      }
    } catch (_) {}
  }

  Future<void> _handleRefresh() async {
    try {
      await ref.read(authControllerProvider.notifier).restoreSession();
    } catch (_) {}
    if (mounted) setState(() => _refreshKey++);
  }
  Future<List<Product>> _loadPersonalizedProducts() async {
    try {
      if (ref.read(authControllerProvider).valueOrNull == null) {
        return await widget.repository.products();
      }
      // Check latest skin history
      final history = await widget.repository.getSkinHistory(page: 1, pageSize: 1);
      if (history.isNotEmpty) {
        final latestSkinType = history.first['skinType'] ?? history.first['skin_type'] ?? 'Normal';
        return await widget.repository.recommendProductsBySkin(latestSkinType.toString());
      }
      // Or check beauty profile
      final profile = await widget.repository.getBeautyProfile();
      if (profile != null && profile.skinType != null) {
        return await widget.repository.recommendProductsBySkin(profile.skinType!);
      }
    } catch (_) {}
    return await widget.repository.products();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider, (prev, next) {
      final prevUser = prev?.valueOrNull;
      final nextUser = next.valueOrNull;
      if (prevUser == null && nextUser != null) {
        _quizCheckedForSession = false;
        _maybeShowQuiz(nextUser);
      }
    });

    final authState = ref.watch(authControllerProvider);
    final user = authState.valueOrNull;
    ref.watch(appLocaleProvider);

    return FutureBuilder(
      key: ValueKey(_refreshKey),
      future: Future.wait([
        _loadPersonalizedProducts(),
        widget.repository.news(),
      ]),
      builder: (context, snapshot) {
        final products = snapshot.hasData
            ? snapshot.data![0] as List<Product>
            : sampleProducts;
        final news = snapshot.hasData
            ? snapshot.data![1] as List<NewsArticle>
            : const <NewsArticle>[];

        return Container(
          color: _T.canvas,
          child: RefreshIndicator(
            onRefresh: _handleRefresh,
            color: _T.ink,
            backgroundColor: _T.paper,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 402),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 35),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [


                          // ── 2. Greeting ──
                          _GreetingSection(user: user),
                          const SizedBox(height: 16),

                          // ── 3. AI Banner ──
                          const _AiBanner(),
                          const SizedBox(height: 24),

                          // ── 4. Daily Beauty Tips ──
                          const _DailyTipsSection(),
                          const SizedBox(height: 24),

                          // ── 5. Product Suggestions ──
                          _ProductSuggestionsSection(products: products),
                          const SizedBox(height: 24),

                          // ── 6. News Feed ──
                          _NewsFeedSection(news: news),
                          const SizedBox(height: 16),

                          // ── 7. Footer ──
                          const _HomeFooter(),
                        ],
                      ),
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

// ═════════════════════════════════════════════
// 1. HEADER
// ═════════════════════════════════════════════
class _HomeHeader extends ConsumerWidget {
  const _HomeHeader({required this.user});

  final AppUser? user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (user == null) {
      // PRE-LOGIN
      return Row(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/belumi_logo_mark.png',
                height: 28,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Icon(Icons.spa, color: _T.ink),
              ),
              const SizedBox(width: 6),
              Image.asset(
                'assets/images/belumi_logo_wordmark.png',
                height: 20,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Text(
                  'belumi',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: _T.ink,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          _HeaderButton(
            label: 'Đăng ký ngay',
            filled: true,
            onTap: () => context.go('/register'),
          ),
          const SizedBox(width: 8),
          _HeaderButton(
            label: 'Đăng nhập',
            filled: false,
            onTap: () => context.go('/login'),
          ),
        ],
      );
    } else {
      // POST-LOGIN
      return Row(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/belumi_logo_mark.png',
                height: 28,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Icon(Icons.spa, color: _T.ink),
              ),
              const SizedBox(width: 6),
              Image.asset(
                'assets/images/belumi_logo_wordmark.png',
                height: 20,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Text(
                  'belumi',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: _T.ink,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => context.go('/profile'),
            child: const CircleAvatar(
              radius: 16,
              backgroundColor: _T.ink,
              child: Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ),
        ],
      );
    }
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: filled ? _T.ink : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: filled ? _T.ink : _T.ink.withValues(alpha: 0.35),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: filled ? Colors.white : _T.ink,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════
// 2. GREETING
// ═════════════════════════════════════════════
class _GreetingSection extends StatelessWidget {
  const _GreetingSection({required this.user});

  final AppUser? user;

  @override
  Widget build(BuildContext context) {
    final name = user?.fullName ?? 'bạn mới';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mến chào $name,',
          style: TextStyle(
            color: Color(0xFF44403D),
            fontFamily: 'Mona Sans',
            fontSize: 14,
            fontWeight: FontWeight.w400,
            fontStyle: FontStyle.italic,
            height: 1.25,
            letterSpacing: 0.14,
          ),
        ),
        const Text(
          'Hôm nay làn da bạn thế nào?',
          style: TextStyle(
            color: Color(0xFF44403D),
            fontFamily: 'Mona Sans',
            fontSize: 18,
            fontWeight: FontWeight.w400,
            fontStyle: FontStyle.normal,
            height: 1.25,
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════
// 3. AI SKINCARE BANNER
// ═════════════════════════════════════════════
class _AiBanner extends StatelessWidget {
  const _AiBanner();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/skincare-ai'),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF976D48).withOpacity(0.16),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFD4D0CC), width: 1),
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            // ── Background Box (Text & Button) ──
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    width: double.infinity,
                    child: Text(
                      'Thử ngay một liệu trình chăm sóc da chỉ dành riêng cho bạn.',
                      style: TextStyle(
                        color: Color(0xFF3F2E1E),
                        fontFamily: 'Playfair Display',
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    constraints: const BoxConstraints(minHeight: 24),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF976D48),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Phân tích da AI',
                          style: TextStyle(
                            color: Color(0xFFF6F5F4),
                            fontFamily: 'Mona Sans',
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            height: 1.25,
                            letterSpacing: 0.18,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.auto_awesome,
                          size: 16,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Girl image (Absolute Positioned) ──
            Positioned(
              right: 7.433,
              bottom: -12.208,
              width: 158.208,
              height: 158.208,
              child: Image.asset(
                'assets/images/belumi_hero_girl.png',
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════
// 4. DAILY BEAUTY TIPS (thay "Theo dõi liệu trình")
// ═════════════════════════════════════════════
class _DailyTipsSection extends StatelessWidget {
  const _DailyTipsSection();

  static const _allTips = <List<_TipData>>[
    // Monday
    [
      _TipData('☀️', 'Chống nắng đúng cách',
          'Thoa SPF 30+ trước 15 phút khi ra ngoài, bôi lại mỗi 2h.'),
      _TipData('💧', 'Hydrate từ bên trong',
          'Uống đủ 2 lít nước mỗi ngày giúp da căng mịn.'),
      _TipData('🌿', 'Skincare tối giản',
          'Chỉ cần 3 bước: sữa rửa mặt, dưỡng ẩm, chống nắng.'),
    ],
    // Tuesday
    [
      _TipData('🧴', 'Double Cleansing',
          'Tẩy trang dầu trước, rửa mặt sau để sạch sâu.'),
      _TipData('✨', 'Vitamin C buổi sáng',
          'Serum Vitamin C sáng giúp chống oxy hóa hiệu quả.'),
      _TipData('😴', 'Ngủ đủ giấc',
          '7-8 tiếng mỗi đêm cho da tự phục hồi tốt nhất.'),
    ],
    // Wednesday
    [
      _TipData('🍊', 'Ăn nhiều trái cây',
          'Vitamin từ trái cây giúp da sáng khỏe từ bên trong.'),
      _TipData('🧊', 'Đắp mặt nạ lạnh',
          'Giúp se khít lỗ chân lông và giảm sưng hiệu quả.'),
      _TipData('🌙', 'Retinol ban đêm',
          'Dùng retinol tối để trẻ hóa, tránh ánh nắng.'),
    ],
    // Thursday
    [
      _TipData('💆', 'Massage mặt',
          'Massage 5 phút mỗi tối giúp lưu thông máu tốt hơn.'),
      _TipData('🥒', 'Mặt nạ thiên nhiên',
          'Dưa leo, mật ong - nguyên liệu đơn giản mà hiệu quả.'),
      _TipData('🧽', 'Vệ sinh cọ makeup',
          'Rửa cọ mỗi tuần để tránh vi khuẩn gây mụn.'),
    ],
    // Friday
    [
      _TipData('🫧', 'Tẩy tế bào chết',
          'AHA/BHA 2 lần/tuần giúp da mịn màng, sáng hơn.'),
      _TipData('🎭', 'Sheet mask thư giãn',
          'Đắp mask 15 phút cuối tuần cho da căng bóng.'),
      _TipData('💤', 'Sleeping mask',
          'Kem ngủ qua đêm cấp ẩm sâu khi bạn ngủ.'),
    ],
    // Saturday
    [
      _TipData('🏋️', 'Tập thể dục',
          'Ra mồ hôi giúp thải độc, da hồng hào tự nhiên.'),
      _TipData('🥗', 'Ăn uống lành mạnh',
          'Hạn chế đường, dầu mỡ để giảm mụn hiệu quả.'),
      _TipData('🧘', 'Giảm stress',
          'Thiền 10 phút/ngày giúp cortisol giảm, da khỏe hơn.'),
    ],
    // Sunday
    [
      _TipData('🛁', 'Spa tại nhà',
          'Dành 30 phút cuối tuần chăm sóc da chuyên sâu.'),
      _TipData('📸', 'Chụp ảnh theo dõi',
          'Ghi lại tình trạng da mỗi tuần để thấy tiến triển.'),
      _TipData('📝', 'Review sản phẩm',
          'Ghi chú sản phẩm nào hợp, để tối ưu routine.'),
    ],
  ];

  @override
  Widget build(BuildContext context) {
    // weekday: 1=Mon .. 7=Sun → index 0..6
    final dayIndex = (DateTime.now().weekday - 1).clamp(0, 6);
    final tips = _allTips[dayIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Mẹo chăm sóc da hôm nay',
          actionLabel: 'Xem thêm',
          onAction: () => context.go('/news'),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 145,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: tips.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) => _TipCard(tip: tips[index]),
          ),
        ),
      ],
    );
  }
}

class _TipData {
  const _TipData(this.emoji, this.title, this.description);
  final String emoji;
  final String title;
  final String description;
}

class _TipCard extends StatelessWidget {
  const _TipCard({required this.tip});

  final _TipData tip;

  static const _gradients = [
    [Color(0xFFFFF1E6), Color(0xFFFFE0CC)],
    [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
    [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
  ];

  @override
  Widget build(BuildContext context) {
    final colors = _gradients[tip.title.hashCode % _gradients.length];
    return Container(
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(_T.radius),
        border: Border.all(color: colors[1].withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tip.emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(height: 8),
          Text(
            tip.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _T.ink,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Text(
              tip.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _T.ink.withValues(alpha: 0.7),
                fontSize: 11,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════
// 5. PRODUCT SUGGESTIONS
// ═════════════════════════════════════════════
class _ProductSuggestionsSection extends StatelessWidget {
  const _ProductSuggestionsSection({required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    final items = products.isNotEmpty ? products : sampleProducts;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Gợi ý sản phẩm',
          actionLabel: 'Xem tất cả',
          onAction: () => context.go('/wishlist'),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 210,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length > 10 ? 10 : items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) =>
                _ProductCard(product: items[index]),
          ),
        ),
      ],
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});

  final Product product;

  String _formatPrice(num price) {
    final s = price.toInt().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '${buf.toString()} VND';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => ProductDetailSheet(
            product: product,
            locale: 'vi', // You can pass locale if needed, assuming 'vi' for now
          ),
        );
      },
      child: Container(
        width: 125,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_T.radius),
          border: Border.all(color: _T.sand.withValues(alpha: 0.6)),
          boxShadow: [
            BoxShadow(
              color: _T.espresso.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Product image ──
            Container(
              margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
              height: 95,
              width: double.infinity,
              decoration: BoxDecoration(
                color: _T.canvas,
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: product.thumbnailUrl != null
                  ? Image.network(
                      product.thumbnailUrl!,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => _productPlaceholder(),
                    )
                  : _productPlaceholder(),
            ),
            const SizedBox(height: 8),

            // ── Brand ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                (product.brand ?? product.categoryName ?? 'BELUMI')
                    .toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _T.muted,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),

            // ── Name ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _T.ink,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _productPlaceholder() {
    return Container(
      color: _T.cream,
      child: const Center(
        child: Icon(Icons.spa_outlined, size: 32, color: _T.accent),
      ),
    );
  }
}

// ═════════════════════════════════════════════
// 6. NEWS FEED
// ═════════════════════════════════════════════
class _NewsFeedSection extends StatelessWidget {
  const _NewsFeedSection({required this.news});

  final List<NewsArticle> news;

  @override
  Widget build(BuildContext context) {
    final items = news.take(3).toList();
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Bảng tin',
          actionLabel: 'Xem tất cả',
          onAction: () => context.go('/news'),
        ),
        const SizedBox(height: 12),
        ...items.map((article) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _NewsCard(article: article),
            )),
      ],
    );
  }
}

class _NewsCard extends StatelessWidget {
  const _NewsCard({required this.article});

  final NewsArticle article;

  String _formatViews(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K lượt xem';
    }
    return '$count lượt xem';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/news/${article.slug}'),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_T.radius),
          border: Border.all(color: _T.sand.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: _T.espresso.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Cover image ──
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 90,
                height: 90,
                child: article.coverImageUrl != null
                    ? Image.network(
                        article.coverImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _coverPlaceholder(),
                      )
                    : _coverPlaceholder(),
              ),
            ),
            const SizedBox(width: 12),

            // ── Content ──
            Expanded(
              child: SizedBox(
                height: 90,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tags
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        _TagChip(label: article.category, highlighted: true),
                        if (article.tags.isNotEmpty)
                          _TagChip(label: article.tags.first),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Title
                    Expanded(
                      child: Text(
                        article.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _T.ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          height: 1.3,
                        ),
                      ),
                    ),

                    // Rating + Views
                    Row(
                      children: [
                        // Star rating
                        ...List.generate(
                          5,
                          (i) => Icon(
                            i < 4 ? Icons.star : Icons.star_half,
                            size: 12,
                            color: _T.accent,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatViews(article.viewCount),
                          style: TextStyle(
                            color: _T.muted.withValues(alpha: 0.8),
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 10,
                          color: _T.muted.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${article.likeCount}',
                          style: TextStyle(
                            color: _T.muted.withValues(alpha: 0.8),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 4),

            // ── Arrow button ──
            Align(
              alignment: Alignment.center,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: _T.canvas,
                  shape: BoxShape.circle,
                  border: Border.all(color: _T.sand.withValues(alpha: 0.6)),
                ),
                child: const Icon(
                  Icons.arrow_forward,
                  size: 14,
                  color: _T.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _coverPlaceholder() {
    return Container(
      color: _T.cream,
      child: const Center(
        child: Icon(Icons.article_outlined, size: 28, color: _T.accent),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label, this.highlighted = false});

  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: highlighted
            ? _T.accent.withValues(alpha: 0.15)
            : _T.canvas,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: highlighted ? _T.espresso : _T.muted,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════
// 7. FOOTER
// ═════════════════════════════════════════════
class _HomeFooter extends StatelessWidget {
  const _HomeFooter();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          children: [
            Image.asset(
              'assets/images/belumi_logo_mark_new.png',
              height: 28,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 6),
            Text(
              'Powered by Belumi',
              style: TextStyle(
                color: _T.muted.withValues(alpha: 0.6),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════
// SHARED: Section Header
// ═════════════════════════════════════════════
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _T.ink,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: onAction,
          child: Text(
            actionLabel,
            style: TextStyle(
              color: _T.muted.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
